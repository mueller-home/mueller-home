/* StaffKeeping 0.31 – Datenschutz, Löschantrag, geschützte Ausführung */
'use strict';
(function(){
 const $=id=>document.getElementById(id);
 const escape=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
 let myBusiness=null;
 async function refreshMy(){
  const box=$('deletion-my-status');if(!box)return;
  try {
   const result=await window.SK_AUTH.getMyProfile();myBusiness=result.business;
   const request=await window.SK_AUTH.myDeletionStatus();
   box.textContent=request&&request.status!=='cancelled'?'Letzter Löschvorgang: '+request.status:'Kein offener Löschvorgang.';
   $('deletion-my-request').disabled=!myBusiness||!!(request&&['requested','approved','processing','database_removed','failed'].includes(request.status));
   $('deletion-my-business-name').textContent=myBusiness?.company_name||'–';
  } catch(e){box.textContent='Löschstatus konnte nicht geladen werden: '+e.message;}
 }
 $('deletion-my-request')?.addEventListener('click',async()=>{
  const b=myBusiness;if(!b)return;
  if(!confirm('Die Löschung von „'+b.company_name+'“ kann nicht rückgängig gemacht werden. Fortfahren?'))return;
  const name=prompt('Zur Bestätigung den EXAKTEN Firmennamen eingeben:');
  if(name===null)return;
  const reason=prompt('Optional: Grund für die Löschung (kann leer bleiben):','');
  if(reason===null)return;
  const button=$('deletion-my-request');button.disabled=true;
  try{
   const r=await window.SK_AUTH.requestMyDeletion(name,reason);
   if(r.immediate){
    $('deletion-my-status').textContent='Registrierungsabbruch: Daten werden gelöscht …';
    await window.SK_AUTH.executeDeletion(r.id);
    alert('Registrierung und zugehörige Daten wurden gelöscht.');
    await window.SK_AUTH.logout?.();
    window.location.hash='#login';window.location.reload();return;
   }
   $('deletion-my-status').textContent='Löschantrag eingereicht. Der Administrator wird den Vorgang prüfen.';
  }catch(e){$('deletion-my-status').textContent='Löschung nicht abgeschlossen: '+e.message;button.disabled=false;}
 });
 async function refreshAdmin(){
  if(!window.SK_AUTH?.isAdmin())return;
  const root=$('deletion-admin-requests');root.textContent='Löschanträge werden geladen …';
  try{
   const rows=await window.SK_AUTH.adminDeletionQueue();root.replaceChildren();
   if(!rows.length){root.textContent='Keine Löschanträge vorhanden.';return;}
   for(const r of rows){
    const box=document.createElement('div');box.className='panel sk-deletion-card';
    box.innerHTML=`<strong>${escape(r.business_name)}</strong><p class="muted">${escape(r.request_type)} · ${escape(r.status)} · ${escape(new Date(r.created_at).toLocaleString('de-CH'))}</p><p>${escape(r.reason)}</p>`;
    const actions=document.createElement('div');actions.className='doc-actions';
    const btn=(label,callback)=>{const b=document.createElement('button');b.type='button';b.className='subtle-btn';b.textContent=label;b.onclick=async()=>{b.disabled=true;try{await callback();await refreshAdmin();}catch(e){alert('Aktion fehlgeschlagen: '+e.message);b.disabled=false;}};actions.append(b);};
    if(r.status==='requested'&&r.request_type==='owner'){
     btn('Löschung genehmigen',async()=>{if(!confirm('Betrieb sperren und Löschung genehmigen?'))return;await window.SK_AUTH.decideDeletion(r.id,true,'');});
     btn('Rückfrage / ablehnen',async()=>{const reason=prompt('Begründung (mindestens 5 Zeichen):');if(reason===null)return;await window.SK_AUTH.decideDeletion(r.id,false,reason);});
    }
    if(['approved','failed','database_removed'].includes(r.status))btn('Endgültige Löschung ausführen',async()=>{
      if(!confirm('Endgültig sämtliche löschbaren Betriebsdaten, Medien und zugehörige Login-Konten entfernen?'))return;
      await window.SK_AUTH.executeDeletion(r.id);
    });
    if(r.error_detail){const e=document.createElement('p');e.className='save-error';e.textContent='Fehler: '+r.error_detail;box.append(e);}
    box.append(actions);root.append(box);
   }
  }catch(e){root.textContent='Löschanträge konnten nicht geladen werden: '+e.message;}
 }
 $('deletion-test-open')?.addEventListener('click',async()=>{
  try{
   const rows=await window.SK_AUTH.loadBusinesses();
   const eligible=rows.filter(b=>b.status!=='Freigeschaltet'&&b.review_state!=='approved');
   if(!eligible.length){alert('Keine nicht freigegebenen Unternehmen vorhanden.');return;}
   const ids=eligible.map(b=>`${b.company_name} | ${b.id}`).join('\n');
   const id=prompt('UUID des nie freigegebenen Test-/Fehlbetriebs eingeben:\n'+ids);
   if(id===null)return;
   const company=eligible.find(b=>b.id===id.trim());if(!company)throw Error('Kein zulässiger Betrieb gewählt.');
   const name=prompt('Exakten Firmennamen zur endgültigen Löschung eingeben:');if(name===null)return;
   const reason=prompt('Begründung (mindestens 12 Zeichen):');if(reason===null)return;
   if(!confirm('Ausnahmelöschung „'+company.company_name+'“ wirklich vorbereiten?'))return;
   const requestId=await window.SK_AUTH.exceptionalDeletion(company.id,name,reason);
   alert('Ausnahmelöschung wurde vorbereitet. Im Löschantrag separat ausführen.');
   await refreshAdmin();
  }catch(e){alert('Antrag fehlgeschlagen: '+e.message);}
 });
 window.SK_DELETION={refreshMy,refreshAdmin};
})();
