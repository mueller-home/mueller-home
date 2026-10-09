/* StaffKeeping 0.21 – Supabase Auth und stabiler Passwort-Recovery-Ablauf */
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
 let currentUser=null, isAdmin=false;
 // Recovery-Links erzeugen eine Supabase-Sitzung, dürfen aber NICHT als normale Anmeldung
 // behandelt werden. Nur der Modus-Marker wird für Reloads gespeichert, niemals Tokens.
 const RECOVERY_KEY='sk-password-recovery-in-progress';
 const initialRecoveryLink=(new URLSearchParams(location.search).get('type')==='recovery') ||
   (new URLSearchParams(location.hash.slice(1)).get('type')==='recovery');
 let recoveryMode=initialRecoveryLink || sessionStorage.getItem(RECOVERY_KEY)==='1';
 function showRecovery(){
   recoveryMode=true;
   sessionStorage.setItem(RECOVERY_KEY,'1');
   document.getElementById('reset-form').classList.add('hidden');
   document.getElementById('new-password-form').classList.remove('hidden');
   document.getElementById('reset-result').classList.add('hidden');
   ui().show('reset',false);
   msg('new-password-result','Geben Sie jetzt Ihr neues Passwort ein.');
 }
 function clearRecovery(){
   recoveryMode=false;
   sessionStorage.removeItem(RECOVERY_KEY);
   document.getElementById('reset-form').classList.remove('hidden');
   document.getElementById('new-password-form').classList.add('hidden');
   document.getElementById('new-password-form').reset();
 }
 if(recoveryMode)showRecovery();
 async function evaluate(){
  if(recoveryMode){showRecovery();return;}
  const {data:{user},error}=await db.auth.getUser(); if(error&&error.status!==400)throw error;
  if(recoveryMode){showRecovery();return;}
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
 async function safeEvaluate(){try{await evaluate();}catch(e){msg('auth-message','Prüfung fehlgeschlagen: '+e.message);if(!recoveryMode)ui().logoutView();else showRecovery();}}
 window.SK_AUTH={
  async logout(){clearRecovery();await db.auth.signOut();currentUser=null;isAdmin=false;ui().logoutView();},
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
 document.querySelector('#view-reset [data-view="login"]').addEventListener('click',async e=>{
  if(!recoveryMode)return;
  e.preventDefault();e.stopPropagation();
  clearRecovery();
  await db.auth.signOut();
  ui().logoutView();
 });
 document.getElementById('new-password-form').addEventListener('submit',async e=>{
  e.preventDefault();
  if(!recoveryMode){msg('new-password-result','Bitte zuerst einen gültigen Wiederherstellungslink öffnen.');return;}
  const form=e.currentTarget;
  const pwd=document.getElementById('new-password').value;
  const confirmation=document.getElementById('new-password-confirm').value;
  if(pwd.length<8){msg('new-password-result','Bitte ein Passwort mit mindestens 8 Zeichen eingeben.');return;}
  if(pwd!==confirmation){msg('new-password-result','Die beiden Passwörter stimmen nicht überein.');return;}
  const submit=form.querySelector('button[type="submit"]');
  submit.disabled=true;
  msg('new-password-result','Passwort wird gespeichert …');
  try{
   const {data:{session},error:se}=await db.auth.getSession();
   if(se)throw se;
   if(!session)throw Error('Der Wiederherstellungslink ist ungültig oder abgelaufen. Bitte einen neuen Link anfordern.');
   const {error}=await db.auth.updateUser({password:pwd});
   if(error)throw error;
   // Sign-out erst nach erfolgreicher Passwortänderung. Ereignis SIGNED_OUT darf
   // erst danach wieder zum normalen Login leiten.
   clearRecovery();
   const {error:outError}=await db.auth.signOut();
   if(outError)throw outError;
   ui().logoutView();
   msg('auth-message','Passwort erfolgreich geändert. Bitte mit dem neuen Passwort anmelden.');
  }catch(err){msg('new-password-result','Passwortänderung fehlgeschlagen: '+err.message);if(recoveryMode)showRecovery();}
  finally{submit.disabled=false;}
 });
 db.auth.onAuthStateChange((event)=>{
  // Listener ohne await/weitere Supabase-API-Aufrufe: verhindert Auth-Deadlocks.
  if(event==='PASSWORD_RECOVERY'){showRecovery();return;}
  if(event==='SIGNED_OUT'&&!recoveryMode)ui().logoutView();
 });
 (async()=>{
  if(recoveryMode){
   // Supabase verarbeitet den Callback asynchron; niemals voreilig evaluate() starten.
   showRecovery();return;
  }
  await finishRegistration();
  if(!recoveryMode)await safeEvaluate();
 })();
})();
