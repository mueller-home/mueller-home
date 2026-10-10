/* StaffKeeping 0.32.2.2 – Auth, Rollen, echte Inserate und Radius */
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
 // Only a conclusive "user does not exist" response authorizes a stale-session reset.
 // Network errors, 401/403 from unrelated services, rate limits and expired recovery
 // links must NOT silently discard a still-valid account's local state.
 function missingAuthUser(error){
   if(!error)return false;
   const code=String(error.code||'').toLowerCase();
   const detail=String(error.message||'').toLowerCase();
   return code==='user_not_found' ||
     detail.includes('user from sub claim in jwt does not exist');
 }
 const authStorageKey='sb-'+new URL(cfg.supabaseUrl).hostname.split('.')[0]+'-auth-token';
 async function clearOrphanedSession(){
   // Prefer Supabase's public API; when a deleted user makes signOut fail,
   // remove ONLY the project-specific local session, never unrelated app data.
   try{await db.auth.signOut({scope:'local'});}catch(e){console.warn('Lokaler Session-Abschluss:',e.message);}
   try{localStorage.removeItem(authStorageKey);}catch{}
   currentUser=null;isAdmin=false;
   exitCompletionMode();
   ui()?.logoutView();
 }
 async function verifiedCurrentUser(){
   const {data,error}=await db.auth.getUser();
   if(missingAuthUser(error)){
     await clearOrphanedSession();
     return null;
   }
   if(error){
     // Supabase returns auth-session-missing when there is no signed-in user.
     if(error.name==='AuthSessionMissingError')return null;
     throw error;
   }
   return data?.user||null;
 }

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
 function pendingStatus(business){
   const confirmed=!!currentUser?.email_confirmed_at;
   const mark=(id,yes,symbol,status)=>{
     const el=document.getElementById('pending-'+id+'-step');if(el)el.classList.toggle('complete',yes);
     const icon=document.getElementById('pending-'+id+'-symbol');if(icon)icon.textContent=yes?'✓':symbol;
     const info=document.getElementById('pending-'+id+'-status');if(info)info.textContent=status;
   };
   mark('email',confirmed,'2',confirmed?'Bestätigt':'Noch nicht bestätigt');
   mark('company',!!business,'3',business?'Unternehmen erfasst':'Noch nicht vollständig');
   mark('approval',business?.status==='Freigeschaltet','4',business?.status==='Gesperrt'?'Gesperrt':business?.status==='Freigeschaltet'?'Freigegeben':'Warten auf die Freigabe');
   const blocked=business?.status==='Gesperrt';
   const submitted=business?.review_state==='submitted';const edit=business&&['draft','changes_requested'].includes(business.review_state);
   document.getElementById('pending-status-label').textContent=blocked?'Status · Gesperrt':submitted?'Status · Zur Prüfung eingereicht':'Status · Profil vorbereiten';
   document.getElementById('pending-profile-button').classList.toggle('hidden',!edit);
   document.getElementById('pending-title').textContent=blocked?'Zugang derzeit gesperrt.':'Vielen Dank für Ihre Registrierung.';
   document.getElementById('pending-description').textContent=blocked?'Bitte wenden Sie sich an die StaffKeeping-Administration.':
     business?(business.review_state==='rejected'?'Antrag abgelehnt: '+(business.review_message||'Bitte kontaktiere die Administration.'):business.review_state==='changes_requested'?'Nachbesserung: '+(business.review_message||'Bitte Profil korrigieren.'):
    submitted?'Ihr Betrieb «'+business.company_name+'» ist eingereicht. Das Profil ist bis zur Entscheidung gesperrt.':
    'Vervollständige das Profil deines Betriebs «'+business.company_name+'» und reiche es anschliessend zur Prüfung ein.'):
     'Bitte schliessen Sie zunächst die Unternehmensregistrierung ab.';
 }
 async function evaluate(){
  if(recoveryMode){showRecovery();return;}
  const user=await verifiedCurrentUser();
  if(recoveryMode){showRecovery();return;}
  currentUser=user||null;isAdmin=false;
  if(!user){exitCompletionMode();ui().logoutView();return;}
  const {data:admin,error:ae}=await db.rpc('sk_is_admin');if(ae)throw ae;
  isAdmin=!!admin;
  if(isAdmin){
    // An admin may inspect the marketplace, but business actions require
    // an independently verified, approved membership.
    const {data:adminMemberships,error:ame}=await db.from('sk_business_members').select('business_id').eq('user_id',user.id);
    if(ame)throw ame;
    let eligible=false;
    for(const member of adminMemberships||[]){
      const {data:approved,error:ae2}=await db.rpc('sk_is_approved_member',{p_business_id:member.business_id});
      if(ae2)throw ae2;
      if(approved){eligible=true;break;}
    }
    exitCompletionMode();ui().setAccess(true,true,'approved',eligible);return;
  }
  const {data:members,error:me}=await db.from('sk_business_members').select('business_id').eq('user_id',user.id).limit(1);if(me)throw me;
  if(!members?.length){setCompletionMode(user);return;}
  const {data:approved,error:pe}=await db.rpc('sk_is_approved_member',{p_business_id:members[0].business_id});if(pe)throw pe;
  exitCompletionMode();
  let business=null;
  if(!approved){
    const {data:record,error:be}=await db.from('sk_businesses').select('company_name,status,review_state,review_message').eq('id',members[0].business_id).single();
    if(be)throw be;business=record;pendingStatus(business);
  }
  ui().setAccess(!!approved,false,approved?'approved':business.review_state||'draft',!!approved);
 }
 async function safeEvaluate(){try{await evaluate();}catch(e){msg('auth-message','Prüfung fehlgeschlagen: '+e.message);if(!recoveryMode)ui().logoutView();else showRecovery();}}
 window.SK_AUTH={
  async myListingBusiness(){
    const user=await verifiedCurrentUser();if(!user)throw Error('Bitte erneut anmelden.');
    const {data:members,error:me}=await db.from('sk_business_members').select('business_id').eq('user_id',user.id).limit(1);if(me)throw me;
    if(!members?.length)throw Error('Kein Betrieb zugeordnet.');
    const id=members[0].business_id;
    const {data:approved,error:ae}=await db.rpc('sk_is_approved_member',{p_business_id:id});if(ae)throw ae;
    if(!approved)throw Error('Der Betrieb ist nicht freigegeben.');
    return id;
  },
  async listMarketplaceListings(){
    const user=await verifiedCurrentUser();if(!user)throw Error('Bitte erneut anmelden.');
    // Admins may read for moderation; regular participants must have an
    // approved business. Own listings never belong in the marketplace.
    const {data:admin,error:adminError}=await db.rpc('sk_is_admin');
    if(adminError)throw adminError;
    const {data:members,error:membersError}=await db.from('sk_business_members').select('business_id').eq('user_id',user.id);
    if(membersError)throw membersError;
    const ownIds=(members||[]).map(m=>m.business_id);
    if(!admin){
      let eligible=false;
      for(const id of ownIds){
        const {data:approved,error:approvalError}=await db.rpc('sk_is_approved_member',{p_business_id:id});
        if(approvalError)throw approvalError;
        if(approved){eligible=true;break;}
      }
      if(!eligible)throw Error('Marktplatz nur für freigegebene Betriebe.');
    }
    let query=db.from('sk_listings')
      .select('id,business_id,type,category,title,description,date_from,date_to,conditions,accommodation,languages,city,country')
      .eq('status','Aktiv').gte('date_to',new Intl.DateTimeFormat('en-CA',{timeZone:'Europe/Zurich',year:'numeric',month:'2-digit',day:'2-digit'}).format(new Date()))
      .order('date_from',{ascending:true}).limit(200);
    if(ownIds.length===1)query=query.neq('business_id',ownIds[0]);
    const {data,error}=await query;
    if(error)throw error;
    return (data||[]).filter(row=>!ownIds.includes(row.business_id));
  },
  async listMarketplaceDistances(){
    const user=await verifiedCurrentUser();if(!user)throw Error('Bitte erneut anmelden.');
    const {data,error}=await db.rpc('sk_marketplace_distances');
    if(error)throw error;
    return data||[];
  },
  async listMyListings(){
    const businessId=await this.myListingBusiness();
    const {data,error}=await db.from('sk_listings').select('id,business_id,type,category,title,description,date_from,date_to,conditions,accommodation,languages,city,country,status,created_at').eq('business_id',businessId).order('created_at',{ascending:false});
    if(error)throw error;return data||[];
  },
  async saveMyListing(payload,id=null){
    const businessId=await this.myListingBusiness();
    if(id){const {data,error}=await db.from('sk_listings').update(payload).eq('id',id).eq('business_id',businessId).select('id').single();if(error)throw error;return data;}
    const {data,error}=await db.from('sk_listings').insert({...payload,business_id:businessId}).select('id').single();if(error)throw error;return data;
  },
  async setMyListingStatus(id,status){
    const businessId=await this.myListingBusiness();
    const {error}=await db.from('sk_listings').update({status}).eq('id',id).eq('business_id',businessId).select('id').single();if(error)throw error;
  },
  async deleteMyListing(id){
    const businessId=await this.myListingBusiness();
    const {error}=await db.from('sk_listings').delete().eq('id',id).eq('business_id',businessId).select('id').single();if(error)throw error;
  },
  // Re-check account on protected navigation; revoked/deleted auth users must not
  // continue browsing a previously rendered authenticated SPA after admin deletion.
  async validateActiveSession(){
   if(recoveryMode)return true;
   try{
    const user=await verifiedCurrentUser();
    if(!user){currentUser=null;isAdmin=false;ui().logoutView();return false;}
    // Keep the active identity tied to this browser's original signed-in user.
    if(currentUser && user.id!==currentUser.id){await clearOrphanedSession();return false;}
    return true;
   }catch(error){
    console.warn('StaffKeeping: Sitzungsprüfung nicht verfügbar',error?.message||error);
    msg('auth-message','Die Sitzung kann derzeit nicht geprüft werden. Bitte Verbindung prüfen und erneut versuchen.');
    return false; // Fail closed for navigation, without destroying valid sessions.
   }
  },
  async listProjectDocs(){if(!isAdmin)throw Error('Nur Administratoren');const {data,error}=await db.rpc('sk_admin_list_project_docs');if(error)throw error;return data||[];},
  async saveProjectDoc(slug,body){if(!isAdmin)throw Error('Nur Administratoren');const {error}=await db.rpc('sk_admin_save_project_doc',{p_slug:slug,p_body:body});if(error)throw error;},
  async logout(){clearRecovery();exitCompletionMode();try{const {error}=await db.auth.signOut({scope:'local'});if(error&&!missingAuthUser(error))throw error;}finally{try{localStorage.removeItem(authStorageKey);}catch{}currentUser=null;isAdmin=false;ui().logoutView();}},
  async loadBusinesses(){if(!isAdmin)throw Error('Nur Administratoren');const {data,error}=await db.from('sk_businesses').select('id,company_name,country,postal_code,city,status,review_state,submitted_at,reviewed_at,updated_at').order('created_at',{ascending:false});if(error)throw error;return data||[];},
  async getBusinessDetails(id){if(!isAdmin)throw Error('Nur Administratoren');const {data,error}=await db.rpc('sk_admin_get_business_details',{p_business_id:id});if(error)throw error;return data;},
  async addBusinessNote(id,note){if(!isAdmin)throw Error('Nur Administratoren');const {error}=await db.rpc('sk_admin_add_business_note',{p_business_id:id,p_note:note});if(error)throw error;},
  async setBusinessStatus(id,status){if(!isAdmin)throw Error('Nur Administratoren');const {error}=await db.rpc('sk_admin_set_business_status',{p_business_id:id,p_status:status});if(error)throw error;},
  async requestMyDeletion(name,reason){const {data,error}=await db.rpc('sk_request_my_business_deletion',{p_confirm_name:name,p_reason:reason});if(error)throw error;return data;},
  async myDeletionStatus(){const {data,error}=await db.rpc('sk_my_business_deletion_status');if(error)throw error;return data;},
  async adminDeletionQueue(){if(!isAdmin)throw Error('Nur Administratoren');const {data,error}=await db.rpc('sk_admin_deletion_queue');if(error)throw error;return data||[];},
  async decideDeletion(id,approve,reason){if(!isAdmin)throw Error('Nur Administratoren');const {error}=await db.rpc('sk_admin_decide_deletion',{p_request_id:id,p_approve:approve,p_reason:reason});if(error)throw error;},
  async exceptionalDeletion(id,name,reason){if(!isAdmin)throw Error('Nur Administratoren');const {data,error}=await db.rpc('sk_admin_request_exceptional_deletion',{p_business_id:id,p_confirm_name:name,p_reason:reason});if(error)throw error;return data;},
  async executeDeletion(id){const {data,error}=await db.functions.invoke('sk-delete-business',{body:{request_id:id}});if(error)throw new Error(error.message);if(data?.error)throw new Error(data.error);if(data?.status!=='completed')throw Error('Löschung nicht bestätigt');return data;},
  async submitMyBusiness(){const {error}=await db.rpc('sk_submit_my_business');if(error)throw error;await safeEvaluate();},
  async reviewBusiness(id,action,message){if(!isAdmin)throw Error('Nur Admins');const {error}=await db.rpc('sk_admin_review_business',{p_business_id:id,p_action:action,p_message:message||null});if(error)throw error;},
  async requestSensitiveChange(field,value){const {error}=await db.rpc('sk_request_sensitive_change',{p_field:field,p_new_value:value});if(error)throw error;},
  async adminActivity(){if(!isAdmin)throw Error('Nur Admins');const {data,error}=await db.rpc('sk_admin_activity');if(error)throw error;return data;},
  async resolveAllNormalAdminEvents(){if(!isAdmin)throw Error('Nur Admins');const {data,error}=await db.rpc('sk_admin_resolve_normal_events');if(error)throw error;return data;},
  async resolveAdminEvent(id){if(!isAdmin)throw Error('Nur Admins');const {error}=await db.rpc('sk_admin_resolve_event',{p_event_id:id});if(error)throw error;},
  async reviewSensitiveChange(id,approved,message){if(!isAdmin)throw Error('Nur Admins');const {error}=await db.rpc('sk_admin_review_sensitive_change',{p_request_id:id,p_approve:approved,p_message:message||null});if(error)throw error;},
  async logMediaChange(message){const {error}=await db.rpc('sk_log_my_media_change',{p_detail:message});if(error)throw error;},
  isAdmin(){return isAdmin;},
  async listHelp(preview=false){const {data,error}=await db.rpc('sk_help_list',{p_preview:preview});if(error)throw error;return data||[];},
  async saveHelp(payload){if(!isAdmin)throw Error('Nur Admins');const {error}=await db.rpc('sk_admin_save_help',payload);if(error)throw error;},
  async uploadHelpScreenshot(slug,imageId,file){if(!isAdmin)throw Error('Nur Admins');if(!/^[a-z0-9-]{2,60}$/.test(slug)||!/^[a-z0-9-]{2,80}$/.test(imageId))throw Error('Ungültige ID');
    const ext={'image/png':'png','image/jpeg':'jpg','image/webp':'webp'}[file?.type];if(!ext||file.size>5242880)throw Error('Nur PNG/JPG/WebP bis 5 MB');
    const store=db.storage.from('sk-help-images');
    const oldPaths=['png','jpg','webp'].filter(e=>e!==ext).map(e=>slug+'/'+imageId+'.'+e);
    const {error:deleteError}=await store.remove(oldPaths);if(deleteError)throw deleteError;
    const path=slug+'/'+imageId+'.'+ext;const {error}=await store.upload(path,file,{upsert:true,contentType:file.type});if(error)throw error;return db.storage.from('sk-help-images').getPublicUrl(path).data.publicUrl;},
  helpImageUrl(slug,imageId,ext){return db.storage.from('sk-help-images').getPublicUrl(slug+'/'+imageId+'.'+ext).data.publicUrl;},
  async getMyProfile(){
    const {data,error}=await db.rpc('sk_get_my_business_profile');if(error)throw error;return data;
  },
  async saveMyProfile(payload){const {error}=await db.rpc('sk_update_my_business_profile',payload);if(error)throw error;},
  async saveRegistrationLegal(payload){const {error}=await db.rpc('sk_update_my_registration_legal',payload);if(error)throw error;},
  async saveMyLocation(payload){const {error}=await db.rpc('sk_set_my_business_location',payload);if(error)throw error;},
  async listBusinessMedia(businessId){
    const result={logo:[],photos:[]};
    for(const [kind,bucket] of [['logo','sk-business-logos'],['photos','sk-business-photos']]){
      const {data,error}=await db.storage.from(bucket).list(businessId,{limit:20});if(error)throw error;
      const allowed=kind==='logo'?/^logo\.(png|jpg|webp)$/:/^[1-5]\.(png|jpg|webp)$/;
      for(const file of data||[]){if(!allowed.test(file.name))continue;
        const path=businessId+'/'+file.name;
        const {data:signed,error:se}=await db.storage.from(bucket).createSignedUrl(path,300);
        if(se)throw se;
        result[kind].push({name:file.name,path,url:signed.signedUrl});
      }
    }return result;
  },
  async uploadBusinessMedia(businessId,kind,slot,file){
    if(!currentUser||isAdmin)throw Error('Bitte als berechtigter Betrieb anmelden.');
    const types={'image/jpeg':'jpg','image/png':'png','image/webp':'webp'};
    const ext=types[file.type];if(!ext)throw Error('Nur JPG, PNG oder WebP erlaubt.');
    const max=kind==='logo'?2097152:5242880;
    if(file.size<=0||file.size>max)throw Error('Datei ist leer oder zu gross.');
    if(kind!=='logo'&&kind!=='photos')throw Error('Unbekannter Medientyp');
    const prefix=kind==='logo'?'logo':String(slot);
    if(kind==='photos'&&!/^[1-5]$/.test(prefix))throw Error('Ungültiger Bildplatz');
    const bucket=kind==='logo'?'sk-business-logos':'sk-business-photos';
    const {data:existing,error:le}=await db.storage.from(bucket).list(businessId,{limit:20});if(le)throw le;
    // Forbid duplicate formats in same slot: first remove prior file, then upload.
    const matches=(existing||[]).filter(x=>x.name===prefix+'.jpg'||x.name===prefix+'.png'||x.name===prefix+'.webp');
    if(matches.length){const {error:de}=await db.storage.from(bucket).remove(matches.map(x=>businessId+'/'+x.name));if(de)throw de;}
    const {error}=await db.storage.from(bucket).upload(businessId+'/'+prefix+'.'+ext,file,{upsert:false,contentType:file.type});if(error)throw error;
  },
  async removeBusinessMedia(businessId,kind,slot){
    const bucket=kind==='logo'?'sk-business-logos':'sk-business-photos';
    const prefix=kind==='logo'?'logo':String(slot);
    if(kind!=='logo'&&kind!=='photos')throw Error('Unbekannter Medientyp');
    if(kind==='photos'&&!/^[1-5]$/.test(prefix))throw Error('Ungültiger Bildplatz');
    const {data,error}=await db.storage.from(bucket).list(businessId,{limit:20});if(error)throw error;
    const matches=(data||[]).filter(x=>x.name===prefix+'.jpg'||x.name===prefix+'.png'||x.name===prefix+'.webp');
    if(matches.length){const {error:de}=await db.storage.from(bucket).remove(matches.map(x=>businessId+'/'+x.name));if(de)throw de;}
  },
  async getPrivateMigrationConcept(){
    if(!isAdmin)throw Error('Nur Administratoren');
    const {data,error}=await db.storage.from('sk-project-docs').download('original/staffkeeping_migrationskonzept_v2.2.html');
    if(error)throw error;return await data.text();
  },
  async uploadPrivateMigrationConcept(file){
    if(!isAdmin)throw Error('Nur Administratoren');
    if(!file||file.size>6*1024*1024||file.size===0||!file.name.toLowerCase().endsWith('.html'))throw Error('Nur HTML-Dateien bis 6 MB erlaubt.');
    const {error}=await db.storage.from('sk-project-docs').upload('original/staffkeeping_migrationskonzept_v2.2.html',file,{upsert:true,contentType:'text/html'});
    if(error)throw error;
  },
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
     const user=await verifiedCurrentUser();
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
   const user=await verifiedCurrentUser();
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
  try{await verifiedCurrentUser();await finishRegistration();}catch(e){msg('registration-message','Anmeldesitzung konnte nicht geprüft werden: '+e.message);}
  if(!recoveryMode)await safeEvaluate();
 })();
})();
