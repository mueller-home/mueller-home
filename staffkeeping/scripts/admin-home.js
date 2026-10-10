/* StaffKeeping 0.31.3 – action queue separate from informational events */
'use strict';
(function(){
 const $=id=>document.getElementById(id);
 const date=s=>s?new Date(s).toLocaleString('de-CH'):'–';
 const NORMAL=new Set(['profile_changed','location_changed','media_changed']);
 const REQUIRED=new Set(['submitted','change_requested','deletion_requested']);
 let model=null,loading=false;
 function button(text,fn,style='subtle-btn'){
  const b=document.createElement('button');b.type='button';b.className=style;b.textContent=text;
  b.addEventListener('click',async()=>{b.disabled=true;try{await fn();await refresh()}catch(err){alert('Aktion fehlgeschlagen: '+err.message);b.disabled=false}});
  return b;
 }
 function goBusiness(id){return Promise.resolve(window.SK_UI.show('admin-businesses')).then(()=>window.SK_ADMIN_UI?.openBusinessReview(id))}
 function classify(e){return REQUIRED.has(e.kind)?'required':NORMAL.has(e.kind)?'normal':'log'}
 function name(e){return e.business_name||'Betrieb inzwischen gelöscht / nicht zugeordnet'}
 function displayRow(e,opts={}){
  const row=document.createElement('div');row.className='activity-row';
  const info=document.createElement('div');const t=document.createElement('strong');t.textContent=name(e)+' – '+e.title;
  const p=document.createElement('p');p.className='muted';p.textContent=(e.detail||'')+' · '+date(e.created_at)+(e.resolved_at?' · Gelesen':' · Neu');
  info.append(t,p);row.append(info);
  const actions=document.createElement('div');actions.className='activity-actions';
  if(e.business_exists && e.business_id)actions.append(button('Betrieb prüfen',()=>goBusiness(e.business_id)));
  if(e.kind==='deletion_requested')actions.append(button('Datenschutz öffnen',()=>window.SK_UI.show('admin-deletions')));
  if(opts.normal&&!e.resolved_at)actions.append(button('Als gelesen markieren',()=>window.SK_AUTH.resolveAdminEvent(e.id)));
  row.append(actions);return row;
 }
 function grouped(items){
  // UI-only grouping of notifications within 5 minutes; underlying events remain intact.
  const buckets=[];for(const e of items){const last=buckets[buckets.length-1];
   if(last&&last[0].business_id===e.business_id&&last[0].kind===e.kind&&Math.abs(new Date(last[last.length-1].created_at)-new Date(e.created_at))<=300000)last.push(e);
   else buckets.push([e]);
  }return buckets;
 }
 function draw(){if(!model)return;
  const events=model.events||[];const normal=events.filter(e=>classify(e)==='normal'&&!e.resolved_at);
  const required=events.filter(e=>classify(e)==='required'&&!e.resolved_at);
  const stats=$('admin-summary');if(stats){stats.replaceChildren();
   for(const [n,label] of [[model.pending_businesses,'Eingereichte Betriebe'],[model.pending_changes,'Prüfpflichtige Änderungen'],[normal.length,'Neue Informationen']]){
    const el=document.createElement('div');el.className='stat';const cap=document.createElement('span');cap.textContent=label;const title=document.createElement('strong');title.textContent=n;el.append(cap,title);stats.append(el);
   }
  }
  const root=$('admin-queue');if(root){root.replaceChildren();
   const h=document.createElement('h3');h.textContent='Prüfpflichtige Vorgänge';root.append(h);
   const q=required.filter(e=>e.kind!=='change_requested');
   if(!q.length){const p=document.createElement('p');p.className='muted';p.textContent='Keine offenen Prüfereignisse.';root.append(p)}
   else for(const e of q)root.append(displayRow(e));
   const changes=model.changes||[];
   if(changes.length){const h2=document.createElement('h3');h2.textContent='Offene Änderungsanträge';root.append(h2);
    for(const r of changes){const row=document.createElement('div');row.className='activity-row';const info=document.createElement('div');
     const t=document.createElement('strong');t.textContent=(r.business_name||'Betrieb nicht zugeordnet')+' – '+r.field;
     const p=document.createElement('p');p.className='muted';p.textContent=r.old_value+' → '+r.new_value+' · '+date(r.created_at);info.append(t,p);row.append(info);
     const actions=document.createElement('div');actions.className='activity-actions';
     for(const [label,approve] of [['Genehmigen',true],['Ablehnen',false]])actions.append(button(label,async()=>{
      if(!confirm('Änderungsantrag '+(approve?'genehmigen':'ablehnen')+'?'))return;
      const reason=approve?null:prompt('Begründung (optional)');if(!approve&&reason===null)return;
      await window.SK_AUTH.reviewSensitiveChange(r.id,approve,reason);
     }));row.append(actions);root.append(row);
    }
   }
   const title=document.createElement('h3');title.textContent='Weitere Aktivitäten';root.append(title);
   const toolbar=document.createElement('div');toolbar.className='sk-activity-toolbar';
   const all=button('Alle Aktivitäten als gelesen markieren',async()=>{
    if(!confirm('Alle normalen Profil-, Medien- und Standortmeldungen als gelesen markieren? Prüfaufträge bleiben offen.'))return;
    await window.SK_AUTH.resolveAllNormalAdminEvents();
   });all.disabled=!normal.length;toolbar.append(all);root.append(toolbar);
   if(!normal.length){const p=document.createElement('p');p.className='muted';p.textContent='Keine neuen Informationen.';root.append(p)}
   for(const batch of grouped(normal)){
    if(batch.length===1){root.append(displayRow(batch[0],{normal:true}));continue}
    const e=batch[0];const row=document.createElement('div');row.className='activity-row';const info=document.createElement('div');
    const t=document.createElement('strong');t.textContent=name(e)+' – '+batch.length+' '+(e.kind==='location_changed'?'Standortmeldungen':e.kind==='media_changed'?'Medienmeldungen':'Profiländerungen');
    const p=document.createElement('p');p.className='muted';p.textContent=date(e.created_at)+' · '+batch.length+' Einträge im Aktivitätsprotokoll';info.append(t,p);row.append(info);
    const actions=document.createElement('div');actions.className='activity-actions';if(e.business_exists&&e.business_id)actions.append(button('Betrieb ansehen',()=>goBusiness(e.business_id)));
    row.append(actions);root.append(row);
   }
  }
  const history=$('admin-activity-list');if(history){history.replaceChildren();
   if(!events.length)history.textContent='Noch keine Aktivitäten.';
   for(const e of events)history.append(displayRow(e,{normal:classify(e)==='normal'}));
  }
 }
 async function refresh(){if(!window.SK_AUTH||loading)return;loading=true;try{model=await window.SK_AUTH.adminActivity();draw()}catch(err){for(const id of ['admin-queue','admin-activity-list']){const el=$(id);if(el)el.textContent='Laden fehlgeschlagen: '+err.message}}finally{loading=false}}
 window.SK_ADMIN_HOME={load:refresh,refresh};
})();
