/* StaffKeeping 0.26 · echte Unternehmensprofilpflege und private Medien */
'use strict';
(function(){
 let profile=null, token=0, writable=false;
 let timer=null, changed=false, saving=null, savedJson=null, generation=0;
 const dataIds=['pr-company','pr-industry','pr-postal','pr-city','pr-contact','pr-contact-email','pr-phone','pr-desc','pr-notifications','pr-street','pr-number','pr-address-extra','pr-public-address'];
 function payload(){return {
   p_company_name:$('pr-company').value,p_industry:$('pr-industry').value,
   p_postal_code:$('pr-postal').value,p_city:$('pr-city').value,
   p_contact_name:$('pr-contact').value,p_contact_email:$('pr-contact-email').value,
   p_contact_phone:$('pr-phone').value,p_description:$('pr-desc').value,
   p_email_notifications_enabled:$('pr-notifications').checked,
   p_street:$('pr-street').value,p_house_number:$('pr-number').value,p_address_extra:$('pr-address-extra').value,
   p_show_street_address:$('pr-public-address').checked
 };}
 function status(t,error=false){const el=$('profile-info');el.textContent=t;el.classList.remove('hidden');el.classList.toggle('save-error',error);$('pr-retry-save').classList.toggle('hidden',!error);}
 function changedNow(){return writable && (changed || JSON.stringify(payload())!==savedJson || !!saving);}
 function schedule(immediate=false){
   if(!writable)return;
   changed=true;status('Nicht gespeicherte Änderungen …');
   clearTimeout(timer);timer=setTimeout(()=>{void flush();},immediate?0:1050);
 }
 async function flush(){
   clearTimeout(timer);timer=null;
   if(!writable||!profile)return true;
   if(saving){try{await saving;}catch{} if(!changedNow())return true;}
   const snapshot=JSON.stringify(payload());
   if(snapshot===savedJson){changed=false;status('Gespeichert ✓');return true;}
   if(!$('profile-form').reportValidity()){status('Bitte ungültige Angaben korrigieren, bevor du die Seite verlässt.',true);return false;}
   const sequence=generation;
   status('Speichert …');
   saving=window.SK_AUTH.saveMyProfile(JSON.parse(snapshot));
   try{
     await saving;
     if(sequence!==generation)return false;
     savedJson=snapshot;changed=JSON.stringify(payload())!==snapshot;
     status(changed?'Weitere Änderungen warten auf Speicherung …':'Gespeichert ✓');
     if(!changed)void window.SK_LOCATION?.addressSaved(profile.business,JSON.parse(snapshot));
     if(changed){clearTimeout(timer);timer=setTimeout(()=>{void flush();},250);}
     return true;
   }catch(e){changed=true;status('Nicht gespeichert: '+e.message,true);return false;}
   finally{saving=null;}
 }
 
 const $=id=>document.getElementById(id);
 function info(id,message){const el=$(id);el.textContent=message;el.classList.remove('hidden');}
 function field(id,value){$(id).value=value??'';}
 function mediaButton(text,fn){const b=document.createElement('button');b.type='button';b.className='subtle-btn';b.textContent=text;b.addEventListener('click',fn);return b;}
 async function renderMedia(){
  const business=profile?.business;if(!business)return;
  const sequence=++token;
  const logo=$('pr-logo-preview'),photos=$('pr-photo-grid');
  logo.replaceChildren();photos.replaceChildren();
  const media=await window.SK_AUTH.listBusinessMedia(business.id);
  if(sequence!==token)return;
  if(media.logo.length){const im=document.createElement('img');im.src=media.logo[0].url;im.alt='Firmenlogo';logo.append(im);}
  else{const s=document.createElement('span');s.textContent='Noch kein Firmenlogo';logo.append(s);}
  for(let slot=1;slot<=5;slot++){
   const item=media.photos.find(x=>x.name.startsWith(slot+'.'));
   const wrapper=document.createElement('div');wrapper.className='profile-photo-slot';
   if(item){const im=document.createElement('img');im.src=item.url;im.alt='Betriebsbild '+slot;wrapper.append(im);}
   else{const label=document.createElement('small');label.textContent='Bild '+slot;wrapper.append(label);}
   const choose=document.createElement('label');choose.textContent=item?'Ersetzen':'Hochladen';
   const input=document.createElement('input');input.type='file';input.accept='image/png,image/jpeg,image/webp';input.setAttribute('aria-label','Betriebsbild '+slot+' hochladen');
   input.addEventListener('change',()=>saveImage('photos',slot,input.files?.[0]));choose.append(input);wrapper.append(choose);
   if(item)wrapper.append(mediaButton('Entfernen',()=>removeImage('photos',slot)));
   photos.append(wrapper);
  }
 }
 async function saveImage(kind,slot,file){
  if(!file||!profile)return;
  info('pr-media-info','Bild wird hochgeladen …');
  try{await window.SK_AUTH.uploadBusinessMedia(profile.business.id,kind,slot,file);await renderMedia();info('pr-media-info','Bild erfolgreich gespeichert.');}
  catch(e){info('pr-media-info','Upload fehlgeschlagen: '+e.message);}
  finally{if(kind==='logo')$('pr-logo-file').value='';}
 }
 async function removeImage(kind,slot){
  if(!profile||!confirm('Dieses Bild wirklich entfernen?'))return;
  try{await window.SK_AUTH.removeBusinessMedia(profile.business.id,kind,slot);await renderMedia();info('pr-media-info','Bild entfernt.');}
  catch(e){info('pr-media-info','Löschen fehlgeschlagen: '+e.message);}
 }
 async function load(){
  writable=false;clearTimeout(timer);timer=null;$('profile-loading').textContent='Unternehmensprofil wird geladen …';
  try{
   const result=await window.SK_AUTH?.getMyProfile();
   if(!result?.business)throw Error('Kein zugeordnetes Unternehmen gefunden.');
   profile=result;const b=result.business;
   const marketName=document.querySelector('.market-profile strong');if(marketName)marketName.textContent=b.company_name;
   field('pr-company',b.company_name);field('pr-industry',b.industry);
   field('pr-country',({CH:'Schweiz',DE:'Deutschland',AT:'Österreich'})[b.country]||b.country);
   field('pr-vat',b.vat_id);field('pr-postal',b.postal_code);field('pr-city',b.city);
   field('pr-contact',b.contact_name);field('pr-contact-email',b.contact_email);field('pr-phone',b.contact_phone);
   field('pr-desc',b.description);$('pr-notifications').checked=b.email_notifications_enabled;
   field('pr-street',b.street);field('pr-number',b.house_number);field('pr-address-extra',b.address_extra);$('pr-public-address').checked=!!b.show_street_address;
   $('pr-login-email').textContent=result.login_email||'–';
   writable=b.status==='Freigeschaltet'&&result.role==='owner';
   generation++;changed=false;savedJson=JSON.stringify(payload());clearTimeout(timer);timer=null;status(writable?'Gespeichert ✓':'Nur lesbar');
   for(const field of $('profile-form').querySelectorAll('input:not([disabled]),select,textarea,button'))field.disabled=!writable;
   $('pr-logo-file').disabled=!writable;$('pr-logo-delete').disabled=!writable;
   $('profile-loading').textContent=writable?'Angaben werden in Supabase gespeichert.':'Nur freigeschaltete Firmeninhaber können Änderungen speichern.';
   await renderMedia();
   void window.SK_LOCATION?.load(b,writable);
  }catch(e){$('profile-loading').textContent='Profil konnte nicht geladen werden: '+e.message;}
 }
 for(const id of dataIds){
   const el=$(id);
   el.addEventListener('input',()=>schedule());
   el.addEventListener('change',()=>schedule(true));
   el.addEventListener('blur',()=>{if(changedNow())void flush();});
 }
 $('profile-form').addEventListener('submit',ev=>{ev.preventDefault();void flush();});
 $('pr-retry-save').addEventListener('click',()=>{void flush();});
 window.addEventListener('beforeunload',ev=>{
   if(changedNow()){ev.preventDefault();ev.returnValue='';}
 });
 $('pr-logo-file').addEventListener('change',e=>saveImage('logo','logo',e.target.files?.[0]));
 $('pr-logo-delete').addEventListener('click',()=>removeImage('logo','logo'));
 window.SK_PROFILE={load,async beforeLeave(){return await flush();},hasPending:changedNow};
})();
