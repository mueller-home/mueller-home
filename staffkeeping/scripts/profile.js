/* StaffKeeping 0.26 · echte Unternehmensprofilpflege und private Medien */
'use strict';
(function(){
 let profile=null, token=0, writable=false;
 let timer=null, changed=false, saving=null, savedJson=null, savedLegal=null, generation=0;
 const dataIds=['pr-company','pr-industry','pr-postal','pr-city','pr-contact','pr-contact-email','pr-phone','pr-desc','pr-notifications','pr-street','pr-number','pr-address-extra','pr-public-address'];
 function legalPayload(){return {p_vat_id:$('pr-vat').value,p_country:$('pr-country').value};}
 function legalEditable(){return writable&&profile?.business?.status==='Ausstehend';}
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
 function changedNow(){return writable && (changed || JSON.stringify(payload())!==savedJson || (legalEditable()&&JSON.stringify(legalPayload())!==savedLegal) || !!saving);}
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
   if(snapshot===savedJson&&(!legalEditable()||JSON.stringify(legalPayload())===savedLegal)){changed=false;status('Gespeichert ✓');return true;}
   if(!$('profile-form').reportValidity()){status('Bitte ungültige Angaben korrigieren, bevor du die Seite verlässt.',true);return false;}
   const sequence=generation;
   status('Speichert …');
   const legalSnapshot=JSON.stringify(legalPayload());
   saving=(async()=>{if(snapshot!==savedJson)await window.SK_AUTH.saveMyProfile(JSON.parse(snapshot));if(legalEditable()&&legalSnapshot!==savedLegal)await window.SK_AUTH.saveRegistrationLegal(JSON.parse(legalSnapshot));})();
   try{
     await saving;
     if(sequence!==generation)return false;
     savedJson=snapshot;savedLegal=legalSnapshot;changed=JSON.stringify(payload())!==snapshot||(legalEditable()&&JSON.stringify(legalPayload())!==legalSnapshot);
     status(changed?'Weitere Änderungen warten auf Speicherung …':'Gespeichert ✓');
     if(!changed)void window.SK_LOCATION?.addressSaved(profile.business,JSON.parse(snapshot));
     if(changed){clearTimeout(timer);timer=setTimeout(()=>{void flush();},250);}
     return true;
   }catch(e){changed=true;status('Nicht gespeichert: '+e.message,true);return false;}
   finally{saving=null;}
 }
 
 const $=id=>document.getElementById(id);
 function updateDescCounter(){const count=$('pr-desc').value.trim().length;const el=$('pr-desc-counter');if(el){el.textContent=count+' / 30 Zeichen';el.classList.toggle('save-error',count>0&&count<30);}}
 $('pr-desc').addEventListener('input',updateDescCounter);
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
   const choose=document.createElement('label');choose.textContent=item?'Ersetzen':'Hochladen';if(!writable)choose.classList.add('hidden');
   const input=document.createElement('input');input.type='file';input.accept='image/png,image/jpeg,image/webp';input.setAttribute('aria-label','Betriebsbild '+slot+' hochladen');
   input.addEventListener('change',()=>saveImage('photos',slot,input.files?.[0]));choose.append(input);wrapper.append(choose);
   if(item&&writable)wrapper.append(mediaButton('Entfernen',()=>removeImage('photos',slot)));
   photos.append(wrapper);
  }
 }
 async function saveImage(kind,slot,file){
  if(!file||!profile)return;
  info('pr-media-info','Bild wird hochgeladen …');
  try{if(!writable)throw Error('Profil zur Prüfung gesperrt');await window.SK_AUTH.uploadBusinessMedia(profile.business.id,kind,slot,file);await renderMedia();info('pr-media-info','Bild erfolgreich gespeichert.');}
  catch(e){info('pr-media-info','Upload fehlgeschlagen: '+e.message);}
  finally{if(kind==='logo')$('pr-logo-file').value='';}
 }
 async function removeImage(kind,slot){
  if(!profile||!writable||!confirm('Dieses Bild wirklich entfernen?'))return;
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
   field('pr-country',b.country);
   field('pr-vat',b.vat_id);field('pr-postal',b.postal_code);field('pr-city',b.city);
   field('pr-contact',b.contact_name);field('pr-contact-email',b.contact_email);field('pr-phone',b.contact_phone);
   field('pr-desc',b.description);updateDescCounter();$('pr-notifications').checked=b.email_notifications_enabled;
   field('pr-street',b.street);field('pr-number',b.house_number);field('pr-address-extra',b.address_extra);$('pr-public-address').checked=!!b.show_street_address;
   $('pr-login-email').textContent=result.login_email||'–';
   writable=result.role==='owner' && (b.status==='Freigeschaltet'||(b.status==='Ausstehend'&&['draft','changes_requested'].includes(b.review_state)));
   const pending=b.status==='Ausstehend';const locked=pending&&b.review_state==='submitted';
   $('profile-review-bar').classList.toggle('hidden',!pending);
   $('profile-review-title').textContent=locked?'Zur Prüfung eingereicht – Profil gesperrt':b.review_state==='rejected'?'Antrag abgelehnt':b.review_state==='changes_requested'?'Nachbesserung erforderlich':'Profil vervollständigen';
   $('profile-review-message').textContent=locked?'Die Administration prüft deinen eingereichten Profilstand.':b.review_state==='rejected'?(b.review_message||'Bitte wende dich an die Administration.'):b.review_state==='changes_requested'?(b.review_message||'Bitte Angaben korrigieren und neu einreichen.'):'Ergänze die Profilangaben, Logo und Bilder. Danach zur Prüfung einreichen.';
   $('profile-submit').classList.toggle('hidden',!writable||!pending);
   $('sensitive-change-panel').classList.toggle('hidden',b.status!=='Freigeschaltet');
   generation++;changed=false;savedJson=JSON.stringify(payload());savedLegal=JSON.stringify(legalPayload());clearTimeout(timer);timer=null;status(writable?'Gespeichert ✓':'Nur lesbar');
   for(const field of $('profile-form').querySelectorAll('input:not([disabled]),select,textarea,button'))field.disabled=!writable;
   $('pr-logo-file').disabled=!writable;$('pr-logo-delete').disabled=!writable;
   $('pr-company').disabled=!writable||b.status==='Freigeschaltet';
   $('pr-vat').disabled=!legalEditable();$('pr-country').disabled=!legalEditable();
   $('profile-loading').textContent=writable?'Änderungen werden automatisch in Supabase gespeichert.':locked?'Profil ist während der Prüfung gesperrt.':'Profil nur lesbar.';
   await renderMedia();
   void window.SK_LOCATION?.load(b,writable);
  }catch(e){$('profile-loading').textContent='Profil konnte nicht geladen werden: '+e.message;}
 }
 for(const id of [...dataIds,'pr-vat','pr-country']){
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
 $('profile-submit').addEventListener('click',async()=>{
  if(!writable||profile?.business?.status!=='Ausstehend')return;
  updateDescCounter();
  if($('pr-desc').value.trim().length<30){$('profile-submit-status').textContent='Bitte eine Betriebsbeschreibung mit mindestens 30 Zeichen eingeben.';$('pr-desc').focus();return;}
  $('profile-submit-status').textContent='Prüfe und speichere das Profil …';
  if(!(await flush()))return void ($('profile-submit-status').textContent='Bitte Speicherfehler zuerst korrigieren.');
  if(!confirm('Profil verbindlich zur Prüfung einreichen? Bis zur Entscheidung wird die Bearbeitung gesperrt.'))return;
  try{await window.SK_AUTH.submitMyBusiness();$('profile-submit-status').textContent='Erfolgreich eingereicht.';}
  catch(e){$('profile-submit-status').textContent='Einreichung fehlgeschlagen: '+e.message;}
 });
 $('sensitive-request').addEventListener('click',async()=>{
   const field=$('sensitive-field').value,value=$('sensitive-value').value.trim();
   if(!value)return void ($('sensitive-status').textContent='Bitte neuen Wert eingeben.');
   try{await window.SK_AUTH.requestSensitiveChange(field,value);$('sensitive-status').textContent='Änderungsantrag eingereicht. Er wird erst nach Admin-Freigabe wirksam.';}
   catch(e){$('sensitive-status').textContent='Antrag fehlgeschlagen: '+e.message;}
 });
 window.SK_PROFILE={load,async beforeLeave(){return await flush();},hasPending:changedNow};
})();
