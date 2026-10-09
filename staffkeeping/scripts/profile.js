/* StaffKeeping 0.25 · echte Unternehmensprofilpflege und private Medien */
'use strict';
(function(){
 let profile=null, token=0;
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
  $('profile-loading').textContent='Unternehmensprofil wird geladen …';$('profile-form').querySelector('button[type="submit"]').disabled=true;
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
   $('pr-login-email').textContent=result.login_email||'–';
   const writable=b.status==='Freigeschaltet'&&result.role==='owner';
   for(const field of $('profile-form').querySelectorAll('input:not([disabled]),select,textarea,button'))field.disabled=!writable;
   $('pr-logo-file').disabled=!writable;$('pr-logo-delete').disabled=!writable;
   $('profile-loading').textContent=writable?'Angaben werden in Supabase gespeichert.':'Nur freigeschaltete Firmeninhaber können Änderungen speichern.';
   await renderMedia();
  }catch(e){$('profile-loading').textContent='Profil konnte nicht geladen werden: '+e.message;}
 }
 $('profile-form').addEventListener('submit',async ev=>{
  ev.preventDefault();if(!profile)return;
  const submit=$('pr-save');submit.disabled=true;
  try{
   await window.SK_AUTH.saveMyProfile({
    p_company_name:$('pr-company').value,p_industry:$('pr-industry').value,
    p_postal_code:$('pr-postal').value,p_city:$('pr-city').value,
    p_contact_name:$('pr-contact').value,p_contact_email:$('pr-contact-email').value,
    p_contact_phone:$('pr-phone').value,p_description:$('pr-desc').value,
    p_email_notifications_enabled:$('pr-notifications').checked
   });info('profile-info','Profil erfolgreich in Supabase gespeichert.');
   profile.business.description=$('pr-desc').value;
  }catch(e){info('profile-info','Speichern fehlgeschlagen: '+e.message);}
  finally{submit.disabled=false;}
 });
 $('pr-logo-file').addEventListener('change',e=>saveImage('logo','logo',e.target.files?.[0]));
 $('pr-logo-delete').addEventListener('click',()=>removeImage('logo','logo'));
 window.SK_PROFILE={load};
})();
