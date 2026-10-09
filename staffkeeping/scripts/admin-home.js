/* StaffKeeping 0.30 – live Admin-Steuerungsdashboard */
'use strict';
(function(){
 const $=id=>document.getElementById(id);
 const safe=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
 const date=s=>s?new Date(s).toLocaleString('de-CH'):'–';
 let model=null;
 async function refresh(){
  if(!window.SK_AUTH)return;
  try{model=await window.SK_AUTH.adminActivity();draw();}
  catch(e){for(const id of ['admin-queue','admin-activity-list']){const el=$(id);if(el)el.textContent='Dashboard konnte nicht geladen werden: '+e.message;}}
 }
 function draw(){if(!model)return;
  const stats=$('admin-summary');if(stats){stats.replaceChildren();
   for(const [n,label] of [[model.pending_businesses,'Eingereichte Betriebe'],[model.pending_changes,'Prüfpflichtige Änderungen'],[model.open_count,'Offene Aktivitäten']]){
    const el=document.createElement('div');el.className='stat';const title=document.createElement('strong');title.textContent=n;
    const cap=document.createElement('span');cap.textContent=label;el.append(cap,title);stats.append(el);
   }
  }
  const list=model.events||[];
  for(const [id,items] of [['admin-queue',list.filter(x=>!x.resolved_at)],['admin-activity-list',list]]){
   const root=$(id);if(!root)continue;root.replaceChildren();
   if(!items.length){root.textContent=id==='admin-queue'?'Keine offenen Aktivitäten.':'Noch keine Aktivitäten.';continue;}
   for(const e of items){const row=document.createElement('div');row.className='activity-row';
    const info=document.createElement('div');const t=document.createElement('strong');t.textContent=e.title;
    const p=document.createElement('p');p.className='muted';p.textContent=(e.detail||'')+' · '+date(e.created_at)+(e.resolved_at?' · Erledigt':' · Offen');info.append(t,p);row.append(info);
    const actions=document.createElement('div');actions.className='activity-actions';
    if(e.business_id){const open=document.createElement('button');open.type='button';open.className='subtle-btn';open.textContent='Betrieb prüfen';open.addEventListener('click',()=>{
      Promise.resolve(window.SK_UI.show('admin-businesses')).then(()=>window.SK_ADMIN_UI?.openBusinessReview(e.business_id));
    });actions.append(open);}
    if(!e.resolved_at){const btn=document.createElement('button');btn.type='button';btn.className='subtle-btn';btn.textContent='Als erledigt markieren';btn.addEventListener('click',async()=>{
       btn.disabled=true;try{await window.SK_AUTH.resolveAdminEvent(e.id);await refresh();}catch(err){btn.textContent=err.message;btn.disabled=false;}
    });actions.append(btn);}row.append(actions);root.append(row);
   }
  }
  const listRoot=$('admin-queue');if(listRoot){
   const old=$('admin-change-requests');if(old)old.remove();
   const requests=model.changes||[];if(requests.length){
    const wrap=document.createElement('section');wrap.id='admin-change-requests';const h=document.createElement('h3');h.textContent='Prüfpflichtige Änderungen';wrap.append(h);
    for(const r of requests){const row=document.createElement('div');row.className='activity-row';
      const info=document.createElement('p');info.textContent=r.field+': '+r.old_value+' → '+r.new_value+' · '+date(r.created_at);row.append(info);
      for(const [text,approve] of [['Genehmigen',true],['Ablehnen',false]]){
       const btn=document.createElement('button');btn.className='subtle-btn';btn.textContent=text;btn.type='button';
       btn.addEventListener('click',async()=>{
        if(!confirm('Änderungsantrag '+(approve?'genehmigen':'ablehnen')+'?'))return;
        const reason=approve?null:prompt('Begründung (optional)');if(!approve&&reason===null)return;
        btn.disabled=true;try{await window.SK_AUTH.reviewSensitiveChange(r.id,approve,reason);await refresh();}catch(e){alert('Prüfung fehlgeschlagen: '+e.message);btn.disabled=false;}
       });row.append(btn);
      }wrap.append(row);
    }listRoot.parentElement.append(wrap);
   }
  }
 }
 window.SK_ADMIN_HOME={load:refresh,refresh};
})();
