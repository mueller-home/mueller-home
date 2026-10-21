/* StaffKeeping 0.33.1.7 – private, versionierte Entwurfs-Sicherung */
'use strict';
window.SK_DRAFTS = (() => {
 let active=null;
 const serialize=form=>{
  const out={};for(const el of [...form.elements]){
   if(!el.name||el.disabled||['submit','button','file'].includes(el.type))continue;
   if(el.type==='checkbox'&&el.name==='languages'){if(!out.languages)out.languages=[];if(el.checked)out.languages.push(el.value);continue;}
   out[el.name]=el.type==='checkbox'?el.checked:el.value;
  }return out;
 };
 const apply=(form,payload)=>{for(const [name,value] of Object.entries(payload||{})){const fields=form.querySelectorAll(`[name="${CSS.escape(name)}"]`);for(const el of fields){if(el.type==='checkbox')el.checked=name==='languages'?Array.isArray(value)&&value.includes(el.value):!!value;else if(el.type!=='radio')el.value=String(value??'');}}};
 function attach(form,kind,key,business,options={}){
  if(active)active.stop();if(!form||!business)return;
  const line=document.createElement('p');line.setAttribute('role','status');line.setAttribute('aria-live','polite');line.style.cssText='font-size:.9em;margin:10px 0';line.textContent='Entwurf wird geprüft …';form.prepend(line);
  const state={form,kind,key,business,revision:0,timer:null,dirty:false,pending:false,failed:false,disposed:false,paused:false,initial:JSON.stringify(serialize(form)),savedSnapshot:JSON.stringify(serialize(form)),chain:Promise.resolve(),conflicted:false,session:kind==='listing'?crypto.randomUUID():null,readOnly:false,leaseTimer:null,leaseLost:false,takeoverButton:null};active=state;
  const status=t=>{if(!state.disposed)line.textContent=t;};
  const snapshot=()=>serialize(form);
  // Read-only is a presentation mode, never a reason to hide draft content.
  function setReadOnly(on){
   for(const el of form.querySelectorAll('input,select,textarea')){
    if(el.name==='business_id'&&form.dataset.edit){el.disabled=true;continue;}
    if(el.tagName==='SELECT'||el.type==='checkbox'||el.type==='radio')el.disabled=on;
    else el.readOnly=on;
   }
   for(const el of form.querySelectorAll('button'))el.disabled=on;
  }
  function startLeaseRenewal(){
   clearInterval(state.leaseTimer);
   state.leaseTimer=setInterval(async()=>{
    if(state.disposed||state.readOnly)return;
    try{const ok=await window.SK_AUTH.renewDraftLock(kind,key,business,state.session);
     if(!ok)throw Error('Sperre abgelaufen oder übernommen');
    }catch(e){state.leaseLost=true;state.readOnly=true;clearTimeout(state.timer);state.conflicted=true;
     setReadOnly(true);
     status('Bearbeitungssperre verloren. Nicht gesicherte lokale Eingaben bitte vor dem Schliessen separat sichern.');
    }
   },25000);
  }
  async function offerTakeover(){
   if(state.disposed||!state.readOnly||kind!=='listing')return;
   if(!window.confirm('Bearbeitung jetzt übernehmen?\n\nFalls das bisherige Fenster noch geöffnet ist, verliert es seine Schreibberechtigung. Ungespeicherte Änderungen dort können verloren gehen. Nur übernehmen, wenn du die bisherige Bearbeitung wirklich beenden möchtest.'))return;
   const btn=state.takeoverButton;
   if(btn)btn.disabled=true;
   try{
    const granted=await window.SK_AUTH.takeoverDraftLock(kind,key,business,state.session);
    if(!granted)throw Error('Übernahme wurde abgelehnt.');
    // Always get a fresh revision after fencing the previous editor.
    const current=await window.SK_AUTH.readFormDraft(kind,key,business);
    if(state.disposed){void window.SK_AUTH.releaseDraftLock(kind,key,business,state.session).catch(()=>{});return;}
    if(current){state.revision=Number(current.revision);apply(form,current.payload);}
    state.readOnly=false;state.leaseLost=false;state.conflicted=false;state.dirty=false;state.failed=false;
    setReadOnly(false);
    state.initial=JSON.stringify(snapshot());state.savedSnapshot=state.initial;
    btn?.remove();state.takeoverButton=null;
    startLeaseRenewal();
    status('Bearbeitung übernommen. Aktueller privater Entwurf geladen.');
   }catch(e){status('Übernahme fehlgeschlagen: '+e.message);if(btn?.isConnected)btn.disabled=false;}
  }
  function showTakeover(){
   if(state.takeoverButton)return;
   const btn=document.createElement('button');btn.type='button';btn.className='subtle-btn';
   btn.textContent='Bearbeitung übernehmen';btn.style.margin='8px 0';
   btn.addEventListener('click',()=>void offerTakeover());
   line.insertAdjacentElement('afterend',btn);state.takeoverButton=btn;
  }
  function schedule(){if(state.disposed||state.readOnly)return;state.dirty=true;if(state.conflicted){status('Entwurf wurde in einer anderen Sitzung verändert. Bitte Formular schliessen und Entwurf neu öffnen; lokale Änderungen nicht gesichert.');return;}state.failed=false;status('Ungespeicherte Änderungen …');clearTimeout(state.timer);if(!state.paused)state.timer=setTimeout(()=>void save(),1050);}
  async function save(){
   await state.ready;if(state.disposed||state.readOnly||!state.dirty)return;
   const data=snapshot(),str=JSON.stringify(data);state.dirty=false;state.pending=true;status('Entwurf wird gespeichert …');
   state.chain=state.chain.catch(()=>{}).then(async()=>{
     await state.ready;if(state.disposed||state.readOnly)return;
     try{const rev=await window.SK_AUTH.writeFormDraft(kind,key,business,data,state.revision,state.session);
      state.revision=rev;if(state.disposed)return;
      state.pending=false;if(str===JSON.stringify(snapshot())&&!state.dirty){state.initial=str;state.savedSnapshot=str;status('Privater Entwurf gespeichert (nicht veröffentlicht)');}
      else{state.dirty=true;status('Weitere Änderungen werden gespeichert …');schedule();}
     }catch(err){state.pending=false;state.failed=true;state.dirty=true;if(err?.code==='SK409'||err?.code==='40001'||err?.code==='SK423')state.conflicted=true;status(state.conflicted?'Versionskonflikt: Entwurf wurde anderswo verändert. Bitte neu öffnen; deine Eingaben sind noch nicht gesichert.':'Entwurf nicht gespeichert: '+err.message+' – bitte erneut bearbeiten oder speichern');}
   });await state.chain;
  }
  const listener=()=>schedule();form.addEventListener('input',listener);form.addEventListener('change',listener);
  state.stop=()=>{state.disposed=true;clearTimeout(state.timer);clearInterval(state.leaseTimer);state.takeoverButton?.remove();if(state.session&&!state.readOnly)void window.SK_AUTH.releaseDraftLock(kind,key,business,state.session).catch(e=>console.warn('[SK drafts] Lease-Freigabe:',e.message));form.removeEventListener('input',listener);form.removeEventListener('change',listener);if(active===state)active=null;};
  state.pause=()=>{state.paused=true;clearTimeout(state.timer);};
  state.resume=()=>{state.paused=false;if(state.dirty&&!state.conflicted){clearTimeout(state.timer);state.timer=setTimeout(()=>void save(),1050);}};
  state.waitForIdle=async()=>{await state.ready;await state.chain;};
  state.unsafe=()=>!state.readOnly&&(state.dirty||state.pending||state.failed||state.conflicted||JSON.stringify(snapshot())!==state.savedSnapshot);
  state.flush=async()=>{clearTimeout(state.timer);await state.ready;if(state.readOnly)throw Error('Dieses Inserat wird in einem anderen Fenster bearbeitet.');if(state.dirty)await save();await state.chain;if(state.failed||state.conflicted||state.unsafe())throw Error('Privater Entwurf konnte nicht vollständig gespeichert werden.');};
  state.saveNow=async()=>{await state.ready;if(state.readOnly)throw Error('Inserat ist in einem anderen Fenster zur Bearbeitung gesperrt.');if(state.disposed)throw Error('Formular nicht mehr geöffnet.');
   // Auch leere / bisher unveränderte Neuentwürfe ausdrücklich auf dem Server anlegen.
   if(!state.revision)state.dirty=true;
   state.failed=false;
   await state.flush();
  };
  state.finish=async()=>{await state.flush();await window.SK_AUTH.discardFormDraft(kind,key,business,state.revision);state.stop();};
  state.abandon=()=>state.stop();
  state.requireEdit=async()=>{await state.ready;if(state.disposed||state.readOnly||state.leaseLost)throw Error('Inserat ist in einem anderen Fenster zur Bearbeitung gesperrt.');};
  state.ready=(async()=>{try{
    if(kind==='listing'){
      const granted=await window.SK_AUTH.acquireDraftLock(kind,key,business,state.session);
      if(state.disposed){if(granted)void window.SK_AUTH.releaseDraftLock(kind,key,business,state.session).catch(()=>{});return;}
      if(!granted){state.readOnly=true;setReadOnly(true);
       // Block edits immediately; load draft content into the read-only fields.
       status('Entwurf wird für die schreibgeschützte Ansicht geladen …');
      }else{
       startLeaseRenewal();
      }
    }
    const existing=await window.SK_AUTH.readFormDraft(kind,key,business);if(state.disposed)return;
    if(existing){state.revision=Number(existing.revision);if(state.dirty||JSON.stringify(snapshot())!==state.initial){status('Lokale Änderungen vorhanden – gespeicherten Entwurf bitte später erneut öffnen.');return;}status('Gespeicherter privater Entwurf vorhanden.');
     if(state.readOnly){apply(form,existing.payload);state.initial=JSON.stringify(snapshot());state.savedSnapshot=state.initial;setReadOnly(true);showTakeover();status('Nur Ansicht: Entwurf wird in einer anderen Sitzung bearbeitet.');return;}
     if(options.restore==='automatic'||(options.restore!=='none'&&window.confirm('Für dieses Formular ist ein privater Entwurf vorhanden. Möchtest du diesen wiederherstellen?\n\nAbbrechen: aktuellen Stand weiter bearbeiten.'))){
       apply(form,existing.payload);state.initial=JSON.stringify(snapshot());state.savedSnapshot=state.initial;status('Privater Entwurf geladen (noch nicht veröffentlicht)');
       // Address listeners are notified; Google-Koordinaten werden NICHT aus alten Formulardaten gesetzt.
       for(const name of ['street','house_number','postal_code','city','country'])form.elements.namedItem(name)?.dispatchEvent(new Event('change',{bubbles:true}));
     } else if(options.restore==='none'){status('Neuer privater Entwurf.');} else {state.dirty=true;status('Gespeicherten Entwurf nicht geladen. Aktuelle Eingaben noch nicht gesichert.');}
    } else if(state.readOnly){setReadOnly(true);showTakeover();status('Nur Ansicht: Noch kein gespeicherter Entwurfsinhalt vorhanden.');}
    else status('Automatische private Entwurfssicherung aktiv.');
   }catch(err){status('Entwurf konnte nicht geladen werden: '+err.message);state.failed=true;state.readOnly=true;}})();
  return state;
 }
 return {attach, current:()=>active};
})();
