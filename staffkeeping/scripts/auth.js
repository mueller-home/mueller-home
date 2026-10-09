/* StaffKeeping 0.23 – Supabase Auth, stabile Callback-URL und Passwort-Recovery */
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
 // Die Auth-Callback-URL muss aus dem App-Verzeichnis stammen, niemals aus
 // location.pathname: z.B. kann sonst die externe Homepage als Ziel übernommen werden.
 // Der Speicherort dieses Skripts ist auch bei /staffkeeping/index.html stabil.
 const authScript=Array.from(document.scripts).find(el=>{
   try{return new URL(el.src,location.href).pathname.endsWith('/scripts/auth.js');}catch{return false;}
 });
 if(!authScript){
   msg('auth-message','Auth-Skriptpfad fehlt: sichere Rücksprungadresse kann nicht bestimmt werden.');
   msg('registration-message','Registrierung nicht möglich: App-Adresse konnte nicht ermittelt werden.');
   return;
 }
 const callbackUrl=new URL('../',authScript.src).href;
 if(new URL(callbackUrl).origin!==location.origin || !new URL(callbackUrl).pathname.endsWith('/staffkeeping/')){
   msg('auth-message','Ungültige StaffKeeping-App-Adresse für Auth-Weiterleitung.');
   msg('registration-message','Registrierung nicht möglich: App-Pfad ist ungültig.');
   return;
 }
 const db=window.supabase.createClient(cfg.supabaseUrl,cfg.supabasePublishableKey,{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}});
 let currentUser=null, isAdmin=false;
 // A confirmed auth account can exist without a company (e.g. redirected to homepage).
 // Such users must resume the COMPANY form, never sign up a second auth account.
 let completionMode=false;
 function setCompletionMode(user){
   completionMode=true;
   const email=document.getElementById('reg-email');
   const password=document.getElementById('reg-password');
   const passwordBlock=document.getElementById('reg-password-field');
   email.value=user.email||'';email.readOnly=true;
   password.required=false;password.value='';passwordBlock.classList.add('hidden');
   document.getElementById('registration-title').textContent='Unternehmensregistrierung abschliessen';
   msg('registration-message','Ihre E-Mail ist bestätigt. Ergänzen oder prüfen Sie die Firmendaten und schliessen Sie die Registrierung ab – ohne neue Bestätigungsmail.');
   const raw=localStorage.getItem('sk-registration-draft');
   if(raw){try{const draft=JSON.parse(raw);if(draft.email?.toLowerCase()===user.email?.toLowerCase()){
     const map={'company':'p_company_name','vat':'p_vat_id','industry':'p_industry','country':'p_country','postal':'p_postal_code','city':'p_city','contact':'p_contact_name','phone':'p_contact_phone'};
     for(const [id,key] of Object.entries(map)){const el=document.getElementById(id);if(el&&draft.details?.[key]!=null)el.value=draft.details[key];}
   }}catch{}}
   ui().show('register',false);
 }
 function exitCompletionMode(){
   completionMode=false;
   const email=document.getElementById('reg-email');const password=document.getElementById('reg-password');
   email.readOnly=false;password.required=true;
   document.getElementById('reg-password-field').classList.remove('hidden');
   document.getElementById('registration-title').textContent='Unternehmen registrieren';
 }

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
  if(!user){exitCompletionMode();ui().logoutView();return;}
  const {data:admin,error:ae}=await db.rpc('sk_is_admin');if(ae)throw ae;
  isAdmin=!!admin;
  if(isAdmin){exitCompletionMode();ui().setAccess(true,true);return;}
  const {data:members,error:me}=await db.from('sk_business_members').select('business_id').eq('user_id',user.id).limit(1);if(me)throw me;
  if(!members?.length){setCompletionMode(user);return;}
  const {data:approved,error:pe}=await db.rpc('sk_is_approved_member',{p_business_id:members[0].business_id});if(pe)throw pe;
  exitCompletionMode();ui().setAccess(!!approved,false);
 }
 async function safeEvaluate(){try{await evaluate();}catch(e){msg('auth-message','Prüfung fehlgeschlagen: '+e.message);if(!recoveryMode)ui().logoutView();else showRecovery();}}
 window.SK_AUTH={
  async logout(){clearRecovery();exitCompletionMode();await db.auth.signOut();currentUser=null;isAdmin=false;ui().logoutView();},
  async loadBusinesses(){if(!isAdmin)throw Error('Nur Administratoren');const {data,error}=await db.from('sk_businesses').select('id,company_name,country,status').order('created_at',{ascending:false});if(error)throw error;return data||[];},
  async getBusinessDetails(id){if(!isAdmin)throw Error('Nur Administratoren');const {data,error}=await db.rpc('sk_admin_get_business_details',{p_business_id:id});if(error)throw error;return data;},
  async addBusinessNote(id,note){if(!isAdmin)throw Error('Nur Administratoren');const {error}=await db.rpc('sk_admin_add_business_note',{p_business_id:id,p_note:note});if(error)throw error;},
  async setBusinessStatus(id,status){if(!isAdmin)throw Error('Nur Administratoren');const {error}=await db.rpc('sk_admin_set_business_status',{p_business_id:id,p_status:status});if(error)throw error;},
  refresh:safeEvaluate
 };
 document.getElementById('login-form').addEventListener('submit',async e=>{
  e.preventDefault();msg('auth-message','Anmeldung läuft …');
  const {error}=await db.auth.signInWithPassword({email:document.getElementById('login-email').value.trim(),password:document.getElementById('login-password').value});
  if(error){msg('auth-message','Anmeldung fehlgeschlagen: '+error.message);return;}
  document.getElementById('login-password').value='';msg('auth-message','');await safeEvaluate();
 });
 function registrationDetails(email){return {p_company_name:document.getElementById('company').value,p_vat_id:document.getElementById('vat').value,p_industry:document.getElementById('industry').value,p_country:document.getElementById('country').value,p_postal_code:document.getElementById('postal').value,p_city:document.getElementById('city').value,p_contact_name:document.getElementById('contact').value,p_contact_email:email,p_contact_phone:document.getElementById('phone').value,p_terms_accepted:true};}
 async function createCompany(details){
   const {error}=await db.rpc('sk_register_business',details);
   if(error)throw error;
   localStorage.removeItem('sk-registration-draft');
   exitCompletionMode();
   await safeEvaluate();
 }
 document.getElementById('registration-form').addEventListener('submit',async e=>{
   e.preventDefault();
   msg('registration-message','Registrierung läuft …');
   const email=document.getElementById('reg-email').value.trim();
   const details=registrationDetails(email);
   try{
     // Already authenticated/verified: NEVER call signUp again and NEVER send email.
     const {data:{user},error:ue}=await db.auth.getUser();
     if(ue && ue.status!==400)throw ue;
     if(user){
       if(!user.email_confirmed_at)throw Error('Bitte zuerst Ihre E-Mail bestätigen.');
       if(user.email?.toLowerCase()!==email.toLowerCase())throw Error('Bitte die E-Mail-Adresse des angemeldeten Kontos verwenden.');
       await createCompany(details);return;
     }
     if(completionMode)throw Error('Sitzung abgelaufen. Bitte erneut anmelden.');
     const password=document.getElementById('reg-password').value;
     // Preserve details before signup, so an auth state change cannot lose the draft.
     localStorage.setItem('sk-registration-draft',JSON.stringify({email,details}));
     const {data,error}=await db.auth.signUp({email,password,options:{emailRedirectTo:callbackUrl}});
     document.getElementById('reg-password').value='';
     if(error)throw error;
     if(!data.session){msg('registration-message','Bestätigungsmail prüfen. Anschliessend anmelden, um das Unternehmen anzulegen.');ui().show('pending');return;}
     await finishRegistration();
     await safeEvaluate();
   }catch(error){msg('registration-message','Registrierung konnte nicht abgeschlossen werden: '+error.message);ui().show('register',false);}
 });
 async function finishRegistration(){
   const raw=localStorage.getItem('sk-registration-draft');if(!raw)return false;
   let draft;try{draft=JSON.parse(raw);}catch{localStorage.removeItem('sk-registration-draft');return false;}
   const {data:{user}}=await db.auth.getUser();
   if(!user||user.email?.toLowerCase()!==draft.email?.toLowerCase()||!user.email_confirmed_at)return false;
   // A draft may outlive a successful registration (refresh / different tab).
   const {data:members,error:me}=await db.from('sk_business_members').select('business_id').eq('user_id',user.id).limit(1);
   if(me)throw me;
   if(members?.length){localStorage.removeItem('sk-registration-draft');return true;}
   try{await createCompany(draft.details);return true;}
   catch(error){msg('registration-message','Unternehmen noch nicht angelegt: '+error.message);setCompletionMode(user);return false;}
 }
 document.getElementById('reset-form').addEventListener('submit',async e=>{
  e.preventDefault();const email=document.getElementById('reset-email').value.trim();
  const {error}=await db.auth.resetPasswordForEmail(email,{redirectTo:callbackUrl});
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
  try{await finishRegistration();}catch(e){msg('registration-message','Registrierung konnte nicht abgeschlossen werden: '+e.message);}
  if(!recoveryMode)await safeEvaluate();
 })();
})();
