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
  const state={form,kind,key,business,revision:0,timer:null,dirty:false,pending:false,failed:false,disposed:false,paused:false,initial:JSON.stringify(serialize(form)),savedSnapshot:JSON.stringify(serialize(form)),chain:Promise.resolve(),conflicted:false,session:kind==='listing'?crypto.randomUUID():null,readOnly:false,leaseTimer:null,leaseLost:false};active=state;
  const status=t=>{if(!state.disposed)line.textContent=t;};
  const snapshot=()=>serialize(form);
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
  state.stop=()=>{state.disposed=true;clearTimeout(state.timer);clearInterval(state.leaseTimer);if(state.session&&!state.readOnly)void window.SK_AUTH.releaseDraftLock(kind,key,business,state.session).catch(e=>console.warn('[SK drafts] Lease-Freigabe:',e.message));form.removeEventListener('input',listener);form.removeEventListener('change',listener);if(active===state)active=null;};
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
      if(!granted){state.readOnly=true;
       for(const el of form.querySelectorAll('input,select,textarea,button'))el.disabled=true;
       // X ausserhalb des Formulars bleibt aktiv; Daten werden weiterhin angezeigt.
       status('Nur Ansicht: Dieses Inserat wird bereits in einem anderen Fenster bearbeitet.');
      }else{
       state.leaseTimer=setInterval(async()=>{if(state.disposed||state.readOnly)return;
        try{const ok=await window.SK_AUTH.renewDraftLock(kind,key,business,state.session);
          if(!ok)throw Error('Sperre abgelaufen');
        }catch(e){state.leaseLost=true;state.readOnly=true;clearTimeout(state.timer);state.conflicted=true;
          for(const el of form.querySelectorAll('input,select,textarea,button'))el.disabled=true;
          status('Bearbeitungssperre verloren. Eingaben bitte nicht verwerfen; Seite erneut laden und aktuellen Entwurf prüfen.');}
       },25000);
      }
    }
    const existing=await window.SK_AUTH.readFormDraft(kind,key,business);if(state.disposed)return;
    if(existing){state.revision=Number(existing.revision);if(state.dirty||JSON.stringify(snapshot())!==state.initial){status('Lokale Änderungen vorhanden – gespeicherten Entwurf bitte später erneut öffnen.');return;}status('Gespeicherter privater Entwurf vorhanden.');
     if(state.readOnly){apply(form,existing.payload);state.initial=JSON.stringify(snapshot());state.savedSnapshot=state.initial;return;}
     if(options.restore==='automatic'||(options.restore!=='none'&&window.confirm('Für dieses Formular ist ein privater Entwurf vorhanden. Möchtest du diesen wiederherstellen?\n\nAbbrechen: aktuellen Stand weiter bearbeiten.'))){
       apply(form,existing.payload);state.initial=JSON.stringify(snapshot());state.savedSnapshot=state.initial;status('Privater Entwurf geladen (noch nicht veröffentlicht)');
       // Address listeners are notified; Google-Koordinaten werden NICHT aus alten Formulardaten gesetzt.
       for(const name of ['street','house_number','postal_code','city','country'])form.elements.namedItem(name)?.dispatchEvent(new Event('change',{bubbles:true}));
     } else if(options.restore==='none'){status('Neuer privater Entwurf.');} else {state.dirty=true;status('Gespeicherten Entwurf nicht geladen. Aktuelle Eingaben noch nicht gesichert.');}
    } else if(!state.readOnly)status('Automatische private Entwurfssicherung aktiv.');
   }catch(err){status('Entwurf konnte nicht geladen werden: '+err.message);state.failed=true;state.readOnly=true;}})();
  return state;
 }
 return {attach, current:()=>active};
})();
