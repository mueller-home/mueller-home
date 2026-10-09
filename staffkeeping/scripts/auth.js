/* StaffKeeping 0.20 – echte Authentifizierung und Firmenfreigabe */
'use strict';
(function(){
 const cfg=window.SK_CONFIG||{};
 const msg=(id,text)=>{const el=document.getElementById(id);if(el)el.textContent=text;};
 const ui=()=>window.SK_UI;
 if(!/^https:\/\/[^\s]+\.supabase\.co$/.test(cfg.supabaseUrl)||!cfg.supabasePublishableKey){
   msg('auth-message','Supabase noch nicht konfiguriert. Bitte scripts/config.js ergänzen.');
   msg('registration-message','Die Registrierung ist erst nach Einrichtung der Supabase-Verbindung möglich.');return;
 }
 if(!window.supabase?.createClient){msg('auth-message','Supabase-Bibliothek konnte nicht geladen werden. Netzwerk/Content-Blocker prüfen.');return;}
 const db=window.supabase.createClient(cfg.supabaseUrl,cfg.supabasePublishableKey,{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}});
 let currentUser=null, isAdmin=false, latestCheck=0;
 async function evaluate(){
  const {data:{user},error}=await db.auth.getUser(); if(error&&error.status!==400)throw error;
  currentUser=user||null;isAdmin=false;
  if(!user){ui().logoutView();return;}
  const {data:admin,error:ae}=await db.rpc('sk_is_admin');if(ae)throw ae;
  isAdmin=!!admin;
  if(isAdmin){ui().setAccess(true,true);return;}
  const {data:members,error:me}=await db.from('sk_business_members').select('business_id').eq('user_id',user.id).limit(1);if(me)throw me;
  if(!members?.length){ui().setAccess(false,false);return;}
  const {data:approved,error:pe}=await db.rpc('sk_is_approved_member',{p_business_id:members[0].business_id});if(pe)throw pe;
  ui().setAccess(!!approved,false);
 }
 async function safeEvaluate(){try{await evaluate();}catch(e){msg('auth-message','Prüfung fehlgeschlagen: '+e.message);ui().logoutView();}}
 window.SK_AUTH={
  async logout(){await db.auth.signOut();currentUser=null;isAdmin=false;ui().logoutView();},
  async loadBusinesses(){if(!isAdmin)throw Error('Nur Administratoren');const {data,error}=await db.from('sk_businesses').select('id,company_name,country,status').order('created_at',{ascending:false});if(error)throw error;return data||[];},
  async setBusinessStatus(id,status){if(!isAdmin)throw Error('Nur Administratoren');const {error}=await db.rpc('sk_admin_set_business_status',{p_business_id:id,p_status:status});if(error)throw error;},
  refresh:safeEvaluate
 };
 document.getElementById('login-form').addEventListener('submit',async e=>{
  e.preventDefault();msg('auth-message','Anmeldung läuft …');
  const {error}=await db.auth.signInWithPassword({email:document.getElementById('login-email').value.trim(),password:document.getElementById('login-password').value});
  if(error){msg('auth-message','Anmeldung fehlgeschlagen: '+error.message);return;}
  document.getElementById('login-password').value='';msg('auth-message','');await safeEvaluate();
 });
 document.getElementById('registration-form').addEventListener('submit',async e=>{
  e.preventDefault();msg('registration-message','Registrierung läuft …');
  const email=document.getElementById('reg-email').value.trim();
  const password=document.getElementById('reg-password').value;
  const details={p_company_name:document.getElementById('company').value,p_vat_id:document.getElementById('vat').value,p_industry:document.getElementById('industry').value,p_country:document.getElementById('country').value,p_postal_code:document.getElementById('postal').value,p_city:document.getElementById('city').value,p_contact_name:document.getElementById('contact').value,p_contact_email:email,p_contact_phone:document.getElementById('phone').value,p_terms_accepted:true};
  const {data,error}=await db.auth.signUp({email,password,emailRedirectTo:location.origin+location.pathname});
  document.getElementById('reg-password').value='';
  if(error){msg('registration-message','Registrierung fehlgeschlagen: '+error.message);return;}
  // Pending registration exists only in current browser. Require confirmed auth before RPC.
  localStorage.setItem('sk-registration-draft',JSON.stringify({email,details}));
  if(!data.session){msg('registration-message','Bestätigungsmail prüfen. Anschliessend in diesem Browser wieder öffnen und anmelden.');ui().show('pending');return;}
  await finishRegistration();
 });
 async function finishRegistration(){
  const raw=localStorage.getItem('sk-registration-draft');if(!raw)return;
  let draft;try{draft=JSON.parse(raw);}catch{return;}
  const {data:{user}}=await db.auth.getUser();if(!user||user.email?.toLowerCase()!==draft.email.toLowerCase()||!user.email_confirmed_at)return;
  const {error}=await db.rpc('sk_register_business',draft.details);
  if(error){msg('registration-message','Firma konnte nicht angelegt werden: '+error.message);return;}
  localStorage.removeItem('sk-registration-draft');
 }
 document.getElementById('reset-form').addEventListener('submit',async e=>{
  e.preventDefault();const email=document.getElementById('reset-email').value.trim();
  const {error}=await db.auth.resetPasswordForEmail(email,{redirectTo:location.origin+location.pathname});
  const result=document.getElementById('reset-result');result.classList.remove('hidden');result.textContent=error?'Zurücksetzen fehlgeschlagen: '+error.message:'Wenn ein Konto existiert, wurde eine E-Mail angefordert.';
 });
 document.getElementById('new-password-form').addEventListener('submit',async e=>{
  e.preventDefault();const pwd=document.getElementById('new-password').value;const {error}=await db.auth.updateUser({password:pwd});
  msg('new-password-result',error?'Passwortänderung fehlgeschlagen: '+error.message:'Passwort geändert. Bitte melden Sie sich erneut an.');
  if(!error){await db.auth.signOut();document.getElementById('new-password-form').classList.add('hidden');ui().show('login');}
 });
 db.auth.onAuthStateChange((event)=>{
  if(event==='SIGNED_OUT')ui().logoutView();
  if(event==='PASSWORD_RECOVERY'){ui().show('reset');document.getElementById('new-password-form').classList.remove('hidden');msg('auth-message','Wiederherstellungslink erkannt. Bitte neues Passwort setzen.');}
 });
 (async()=>{await finishRegistration();await safeEvaluate();})();
})();
