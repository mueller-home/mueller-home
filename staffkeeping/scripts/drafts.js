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
 const apply=(form,payload)=>{for(const [name,value] of Object.entries(payload||{})){const fields=form.querySelectorAll(`[name="${CSS.escape(name)}"]`);for(const el of fields){if(el.type==='checkbox')el.checked=name==='languages'?Array.isArray(value)&&value.includes(el.value):!!value;else if(el.type!=='radio'&&!el.disabled)el.value=String(value??'');}}};
 function attach(form,kind,key,business){
  if(active)active.stop();if(!form||!business)return;
  const line=document.createElement('p');line.setAttribute('role','status');line.setAttribute('aria-live','polite');line.style.cssText='font-size:.9em;margin:10px 0';line.textContent='Entwurf wird geprüft …';form.prepend(line);
  const state={form,kind,key,business,revision:0,timer:null,dirty:false,pending:false,failed:false,disposed:false,initial:JSON.stringify(serialize(form)),chain:Promise.resolve()};active=state;
  const status=t=>{if(!state.disposed)line.textContent=t;};
  const snapshot=()=>serialize(form);
  function schedule(){if(state.disposed)return;state.dirty=true;state.failed=false;status('Ungespeicherte Änderungen …');clearTimeout(state.timer);state.timer=setTimeout(()=>void save(),1050);}
  async function save(){
   if(state.disposed||!state.dirty)return;
   const data=snapshot(),str=JSON.stringify(data);state.dirty=false;state.pending=true;status('Entwurf wird gespeichert …');
   state.chain=state.chain.catch(()=>{}).then(async()=>{
     if(state.disposed)return;
     try{const rev=await window.SK_AUTH.writeFormDraft(kind,key,business,data,state.revision);
      state.revision=rev;if(state.disposed)return;
      state.pending=false;if(str===JSON.stringify(snapshot())&&!state.dirty){state.initial=str;status('Privater Entwurf gespeichert (nicht veröffentlicht)');}
      else{state.dirty=true;status('Weitere Änderungen werden gespeichert …');schedule();}
     }catch(err){state.pending=false;state.failed=true;state.dirty=true;status('Entwurf nicht gespeichert: '+err.message+' – bitte erneut bearbeiten oder speichern');}
   });await state.chain;
  }
  const listener=()=>schedule();form.addEventListener('input',listener);form.addEventListener('change',listener);
  state.stop=()=>{state.disposed=true;clearTimeout(state.timer);form.removeEventListener('input',listener);form.removeEventListener('change',listener);if(active===state)active=null;};
  state.unsafe=()=>state.dirty||state.pending||state.failed;
  state.flush=async()=>{clearTimeout(state.timer);if(state.dirty)await save();await state.chain;if(state.failed)throw Error('Privater Entwurf konnte nicht gespeichert werden.');};
  state.finish=async()=>{await state.flush();await window.SK_AUTH.discardFormDraft(kind,key,business,state.revision);state.stop();};
  state.abandon=()=>state.stop();
  (async()=>{try{const existing=await window.SK_AUTH.readFormDraft(kind,key,business);if(state.disposed)return;
    if(existing){state.revision=Number(existing.revision);if(state.dirty||JSON.stringify(snapshot())!==state.initial){status('Lokale Änderungen vorhanden – gespeicherten Entwurf bitte später erneut öffnen.');return;}status('Gespeicherter privater Entwurf vorhanden.');
     if(window.confirm('Für dieses Formular ist ein privater Entwurf vorhanden. Möchtest du diesen wiederherstellen?\n\nAbbrechen: aktuellen Stand weiter bearbeiten.')){
       apply(form,existing.payload);state.initial=JSON.stringify(snapshot());status('Privater Entwurf wiederhergestellt (noch nicht veröffentlicht)');
       // Address listeners are notified; Google-Koordinaten werden NICHT aus alten Formulardaten gesetzt.
       for(const name of ['street','house_number','postal_code','city','country'])form.elements.namedItem(name)?.dispatchEvent(new Event('change',{bubbles:true}));
     } else status('Privater Entwurf vorhanden, aktuelles Formular wird angezeigt.');
    } else status('Automatische private Entwurfssicherung aktiv.');
   }catch(err){status('Entwurf konnte nicht geladen werden: '+err.message);state.failed=true;}})();
  return state;
 }
 return {attach, current:()=>active};
})();
