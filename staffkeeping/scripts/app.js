/* StaffKeeping 0.33.1.4 – separate business profiles, consistent administration */
'use strict';
const screens=['dashboard','login','register','reset','pending','market','profile','account','my-listings','my-businesses','detail','messages','reviews','admin-businesses','admin-listings','admin-dashboard','admin-docs','admin-home','admin-activity','admin-deletions','help'];
const navOnly=document.querySelectorAll('.nav-only'), guests=document.querySelectorAll('.guest-only');
const publicViews=new Set(['login','register','reset','pending','help']);
let demoSignedIn=false;
let skAdmin=false;
let skPending=false;let skCanProfile=false;let skCanTrade=false;
window.SK_UI={setAccess(isApproved,isAdmin,reviewState,canTrade=false){demoSignedIn=!!isApproved;skAdmin=!!isAdmin;skCanTrade=!!canTrade;skPending=!isApproved;skCanProfile=!!reviewState;performShow(isAdmin?'admin-home':isApproved?'dashboard':(reviewState==='draft'||reviewState==='changes_requested')?'profile':'pending',false);},show,logoutView(){demoSignedIn=false;skAdmin=false;skPending=false;skCanProfile=false;skCanTrade=false;performShow('login',false);}};
let currentScreen='login', navigationBusy=false;
async function show(view,updateUrl=true){
  if(navigationBusy)return;
  if(typeof skDialogRequestClose==='function' && document.getElementById('app-dialog')?.open){
    if(!(await skDialogRequestClose('navigation:'+view))){if(!updateUrl)history.replaceState({view:currentScreen},'','#'+currentScreen);return;}
  }
  // Validate the real user with Supabase before changing between protected views.
  // A deleted account may otherwise keep navigating with stale in-memory UI state.
  if(!publicViews.has(view) && (demoSignedIn||skAdmin||skCanProfile)){
    navigationBusy=true;
    let valid=false;
    try{valid=await window.SK_AUTH?.validateActiveSession?.()===true;}
    finally{navigationBusy=false;}
    if(!valid){if(!updateUrl)history.replaceState({view:'login'},'','#login');return;}
  }
  if(currentScreen==='profile'&&view!=='profile'&&window.SK_PROFILE?.hasPending()){
    navigationBusy=true;
    try{if(!(await window.SK_PROFILE.beforeLeave())){
      if(!updateUrl)history.replaceState({view:'profile'},'', '#profile');
      return;
    }}finally{navigationBusy=false;}
  }
  currentScreen=view;
  performShow(view,updateUrl);
}
function performShow(view,updateUrl=true){
  if(!screens.includes(view))view='login';
  // Demo-Ansicht: Nur ein explizit gestarteter Demo-Zugang darf interne Seiten sehen.
  if(!demoSignedIn && !skAdmin && !publicViews.has(view) && !(['profile','account'].includes(view)&&skCanProfile))view=skPending?'pending':'login';
  if(!skAdmin && view.startsWith('admin-'))view=demoSignedIn?'dashboard':skCanProfile?'profile':'login';
  if(!skCanTrade && ['my-listings','my-businesses','messages','reviews'].includes(view))view=skAdmin?'market':skCanProfile?'profile':'login';
  if(demoSignedIn && view==='login')view='dashboard';
  if(currentScreen==='admin-docs'&&view!=='admin-docs')window.SK_DOCS?.close();
  currentScreen=view;
  screens.forEach(v=>document.getElementById('view-'+v).classList.toggle('hidden',v!==view));
  // The help screen is public, but opening it must not discard the current session navigation.
  const hasSession=demoSignedIn||skCanProfile||skAdmin;
  navOnly.forEach(n=>n.classList.toggle('hidden',!hasSession || (skCanProfile&&!demoSignedIn&&!skAdmin&&!['profile','account','login'].includes(n.dataset.view)) || (!skCanTrade && ['my-listings','my-businesses','messages','reviews'].includes(n.dataset.view))));
  guests.forEach(n=>n.classList.toggle('hidden',hasSession||skPending));
  document.querySelectorAll('.admin-nav, .admin-tabs').forEach(n=>n.classList.toggle('hidden',!skAdmin));
  document.querySelectorAll('.admin-tabs [data-view]').forEach(b=>{const active=b.dataset.view===view;b.classList.toggle('active',active);b.setAttribute('aria-current',active?'page':'false');});
  document.querySelectorAll('.headnav [data-view]').forEach(n=>n.setAttribute('aria-current',n.dataset.view===(['account','my-businesses','profile'].includes(view)?'account':view)?'page':'false'));
  document.querySelectorAll('.sk-profile-tabs [data-view]').forEach(n=>n.setAttribute('aria-current',n.dataset.view===view?'page':'false'));
  if(updateUrl && location.hash!=='#'+view)history.pushState({view},'', '#'+view);
  window.scrollTo(0,0);
  if(view==='profile'){void loadSafeBusinessProfile();}
  if(view==='account'){void loadPersonalAccount();}
  if(view==='dashboard')void loadMemberDashboard();
  if(view==='market')loadMarketplace();
  if(view==='my-listings')loadMyListings();
  if(view==='my-businesses')loadMyBusinesses();
  if(view==='messages')renderChats();
  if(view==='admin-businesses'){renderBusinesses();loadManualAccessAdmin();}
  if(view==='admin-deletions')window.SK_DELETION?.refreshAdmin();
  if(view==='admin-listings')renderAdminListings();
  if(view==='admin-docs'){renderProjectDocs();window.SK_HELP?.loadAdmin();}
  if(view==='admin-home'||view==='admin-activity')window.SK_ADMIN_HOME?.load(view);
  if(view==='help')window.SK_HELP?.load();
}

let skDashboardLoadVersion=0;
async function loadMemberDashboard(){
 const version=++skDashboardLoadVersion;
 const root=document.getElementById('member-dashboard-body');
 if(!root)return;
 root.innerHTML='<p class="muted" role="status">Übersicht wird geladen …</p>';
 const results=await Promise.allSettled([
  window.SK_AUTH.listMyListings(),
  window.SK_AUTH.listMyBusinesses(),
  window.SK_AUTH.chatThreads(),
  window.SK_AUTH.listListingDrafts(),
  window.SK_AUTH.listNewBusinessDrafts()
 ]);
 if(version!==skDashboardLoadVersion||currentScreen!=='dashboard')return;
 const value=i=>results[i].status==='fulfilled'&&Array.isArray(results[i].value)?results[i].value:null;
 const [items,businesses,threads,listingDrafts,businessDrafts]=[0,1,2,3,4].map(value);
 const count=v=>v===null?'–':String(v);
 const expired=items?.filter(x=>skListingEffectiveStatus(x)==='Abgelaufen')||[];
 const ending=items?.filter(x=>x.status==='Aktiv'&&x.date_to>=skTodayCH()&&x.date_to<=skDateOffsetCH(7))||[];
 const pending=businesses?.filter(x=>['submitted','changes_requested','rejected'].includes(x.review_state)||x.status==='Ausstehend')||[];
 const cards=[
  ['Unterhaltungen',count(threads?.length??null),'messages','Nachrichten öffnen'],
  ['Aktive Inserate',count(items?.filter(x=>skListingEffectiveStatus(x)==='Aktiv').length??null),'my-listings','Inserate verwalten'],
  ['Abgelaufene Inserate',count(items===null?null:expired.length),'my-listings','Inserate prüfen'],
  ['Betriebe mit Prüfstatus',count(businesses===null?null:pending.length),'my-businesses','Meine Betriebe']
 ];
 const cardsHtml=cards.map(([label,num,view,action])=>`<article class="sk-dash-card"><span>${esc(label)}</span><strong>${esc(num)}</strong><button type="button" data-view="${view}">${esc(action)} →</button></article>`).join('');
 const notice=(title,subtitle,view)=>`<li><div><strong>${esc(title)}</strong><small>${esc(subtitle)}</small></div><button type="button" class="subtle-btn" data-view="${view}">Öffnen →</button></li>`;
 let alerts=[];
 for(const l of expired.slice(0,5))alerts.push(notice(l.title,'Inserat abgelaufen · Enddatum prüfen','my-listings'));
 for(const l of ending.slice(0,5))alerts.push(notice(l.title,'Inserat läuft innerhalb von 7 Tagen ab','my-listings'));
 for(const b of pending.slice(0,5))alerts.push(notice(b.company_name||'Betrieb',skBusinessStatus(b.review_state||b.status),'my-businesses'));
 if(listingDrafts?.length)alerts.push(notice(`${listingDrafts.length} private Inserateentwürfe`,'Noch nicht veröffentlicht','my-listings'));
 if(businessDrafts?.length)alerts.push(notice(`${businessDrafts.length} private Betriebsentwürfe`,'Noch nicht eingereicht','my-businesses'));
 const failed=results.map((r,i)=>r.status==='rejected'?['Inserate','Betriebe','Unterhaltungen','Inserateentwürfe','Betriebsentwürfe'][i]:null).filter(Boolean);
 root.innerHTML=`<div class="sk-dash-cards">${cardsHtml}</div>
 <section class="panel sk-dash-panel"><h2>Aktuelles und Aufgaben</h2>${alerts.length?`<ul class="sk-dash-alerts">${alerts.join('')}</ul>`:'<p class="muted">Keine anstehenden Aufgaben aus den verfügbaren Daten.</p>'}</section>
 <section class="panel sk-dash-panel"><h2>Direkt starten</h2><div class="sk-dash-actions"><button type="button" class="btn" data-view="market">Marktplatz durchsuchen</button><button type="button" class="btn btn-outline" data-view="my-listings">Meine Inserate</button><button type="button" class="btn btn-outline" data-view="messages">Nachrichten</button><button type="button" class="btn btn-outline" data-view="my-businesses">Meine Betriebe</button></div></section>
 <section class="panel sk-dash-panel"><h2>Geplante Erweiterungen</h2><p class="muted">Ungelesene Nachrichten: Ein serverseitiger Lesestatus wird noch ergänzt. Bis dahin zeigen wir die Anzahl der Unterhaltungen, nicht angeblich ungelesene Nachrichten.</p><p class="muted">Neue Treffer gespeicherter Suchen: verfügbar, sobald die gespeicherten Suchen und die Trefferprüfung umgesetzt sind.</p><p class="muted">Mitgliedschaft: Ablaufhinweise folgen, sobald die verbindlichen Laufzeitdaten und Regeln definiert sind.</p></section>
 ${failed.length?`<p role="alert">Einige Daten konnten nicht geladen werden: ${esc(failed.join(', '))}. Es werden keine Ersatzwerte angezeigt.</p>`:''}`;
}
function skDateOffsetCH(days){
 const day=new Date();day.setUTCDate(day.getUTCDate()+days);
 return new Intl.DateTimeFormat('en-CA',{timeZone:'Europe/Zurich',year:'numeric',month:'2-digit',day:'2-digit'}).format(day);
}
async function loadPersonalAccount(){
 const email=document.getElementById('account-login-email'),info=document.getElementById('account-status');
 try{const user=await window.SK_AUTH.getAccountIdentity();email.textContent=user?.email||'Keine Anmeldeadresse gefunden';info.textContent='';}
 catch(e){email.textContent='Nicht verfügbar';info.textContent='Benutzerkonto konnte nicht geladen werden: '+e.message;}
}
async function loadSafeBusinessProfile(){
 const notice=document.getElementById('multi-business-profile-notice'),body=document.getElementById('legacy-business-profile-content');
 body.classList.add('hidden');notice.classList.add('hidden');
 try{
   const businesses=await window.SK_AUTH.listMyBusinesses();
   if(businesses.length!==1){notice.classList.remove('hidden');return;}
   body.classList.remove('hidden');window.SK_PROFILE?.load();window.SK_DELETION?.refreshMy();
 }catch(e){notice.classList.remove('hidden');notice.querySelector('p').textContent='Betriebsdaten konnten nicht geladen werden: '+e.message;}
}

async function logout(){
 if(currentScreen==='profile'&&window.SK_PROFILE?.hasPending()){
   if(!(await window.SK_PROFILE.beforeLeave()))return;
 }
 if(window.SK_AUTH) await window.SK_AUTH.logout(); else window.SK_UI.logoutView();
}
document.addEventListener('click',e=>{
  const el=e.target.closest('[data-view]');if(!el)return;
  e.preventDefault();
  if(el.id==='logout')logout();else show(el.dataset.view);
});
window.addEventListener('popstate',()=>show(location.hash.slice(1)||'login',false));
document.querySelectorAll('.pw-toggle').forEach(b=>b.addEventListener('click',()=>{const i=document.getElementById(b.dataset.target);i.type=i.type==='password'?'text':'password';b.textContent=i.type==='password'?'Anzeigen':'Verbergen'}));
const listings=[
{id:1,title:'Service-Mitarbeitende für Wintersaison',type:'Personal gesucht',branch:'Gastronomie',city:'Luzern',country:'Schweiz',date:'2026-12-01',period:'Dezember – März',stay:true,languages:['DE','EN'],desc:'Verstärkung für Restaurant und Gästebetreuung gesucht.'},
{id:2,title:'Rezeptionistin mit Saisonerfahrung',type:'Personal verfügbar',branch:'Hotellerie',city:'Interlaken',country:'Schweiz',date:'2026-11-15',period:'Ab Mitte November',stay:false,languages:['DE','FR','EN'],desc:'Erfahrene Unterstützung für Front Office und Gästeservice.'},
{id:3,title:'Unterstützung im Housekeeping',type:'Personal gesucht',branch:'Hotellerie',city:'Innsbruck',country:'Österreich',date:'2026-12-10',period:'Dezember – Februar',stay:true,languages:['DE','EN'],desc:'Temporärer Personalbedarf im Housekeeping-Team.'},
{id:4,title:'Küchenteam für Übergangszeit',type:'Personal verfügbar',branch:'Camping',city:'Freiburg',country:'Deutschland',date:'2026-11-01',period:'November – Januar',stay:false,languages:['DE'],desc:'Ein eingespieltes Team für eine befristete Zusammenarbeit.'}
];
const starred=new Set();let favoritesOnly=false,viewMap=false;
let marketplaceListings=[], marketplaceLoadError='', marketplaceLoading=false, marketplaceDistances=new Map(), marketplaceOriginAvailable=false;
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const marketplaceType=t=>t==='Suche'?'Personal gesucht':'Personal verfügbar';
const skTodayCH=()=>new Intl.DateTimeFormat('en-CA',{timeZone:'Europe/Zurich',year:'numeric',month:'2-digit',day:'2-digit'}).format(new Date());
const skListingEffectiveStatus=l=>l.date_to<skTodayCH()?'Abgelaufen':l.status;
const marketplaceDate=d=>/^\d{4}-\d{2}-\d{2}$/.test(String(d||''))?`${d.slice(8,10)}.${d.slice(5,7)}.${d.slice(0,4)}`:'–';
async function loadMarketplace(){
  if(marketplaceLoading)return;
  marketplaceLoading=true;marketplaceLoadError='';
  document.getElementById('listing-grid').innerHTML='<p class="muted" role="status">Inserate werden geladen …</p>';
  try{
    marketplaceListings=await window.SK_AUTH.listMarketplaceListings();
    const distanceRows=await window.SK_AUTH.listMarketplaceDistances();
    marketplaceDistances=new Map(distanceRows.map(row=>[row.listing_id,row.distance_km]));
    marketplaceOriginAvailable=distanceRows.some(row=>row.origin_available);
  }
  catch(error){marketplaceListings=[];marketplaceDistances=new Map();marketplaceLoadError=error?.message||'Unbekannter Fehler';}
  finally{marketplaceLoading=false;render();}
}
function render(){
  const q=document.getElementById('filter-search').value.trim().toLocaleLowerCase('de');
  const type=document.getElementById('filter-type').value;
  const category=document.getElementById('filter-branch').value;
  const stay=document.getElementById('filter-accommodation').checked;
  const date=document.getElementById('filter-date').value;
  const radiusRaw=document.getElementById('filter-radius').value;
  const radius=Number.parseInt(radiusRaw,10);
  const activeRadius=Number.isFinite(radius)&&radius>0;
  const baseItems=marketplaceListings.filter(l=>(!q||[l.title,l.city,l.country,l.category,l.description,l.conditions].join(' ').toLocaleLowerCase('de').includes(q))&&(!type||marketplaceType(l.type)===type)&&(!category||l.category===category)&&(!stay||l.accommodation)&&(!date||l.date_to>=date)&&(!favoritesOnly||starred.has(l.id)));
  let items=baseItems;
  let knownCount=0, unknownCount=0;
  if(activeRadius && marketplaceOriginAvailable){
    const known=baseItems.filter(l=>Number.isFinite(marketplaceDistances.get(l.id))&&marketplaceDistances.get(l.id)<=radius)
      .sort((a,b)=>marketplaceDistances.get(a.id)-marketplaceDistances.get(b.id));
    const unknown=baseItems.filter(l=>!Number.isFinite(marketplaceDistances.get(l.id)));
    knownCount=known.length;unknownCount=unknown.length;
    items=[...known,...unknown];
  }
  document.getElementById('result-count').textContent=items.length+' '+(items.length===1?'Inserat':'Inserate');
  document.getElementById('bookmark-count').textContent=marketplaceListings.filter(l=>starred.has(l.id)).length;
  const grid=document.getElementById('listing-grid');
  if(marketplaceLoadError){grid.innerHTML=`<p role="alert">Inserate konnten nicht geladen werden: ${esc(marketplaceLoadError)}</p><button type="button" class="btn" id="retry-market">Erneut versuchen</button>`;document.getElementById('retry-market').addEventListener('click',loadMarketplace);}
  else grid.innerHTML=(activeRadius&&!marketplaceOriginAvailable?'<p class="muted" role="status">Für diese Anmeldung ist kein freigegebener Betriebsstandort mit gültigen Koordinaten verfügbar. Der Radiusfilter wird nicht angewandt; alle übrigen Suchfilter bleiben aktiv.</p>':'')+items.map((l,i)=>`${activeRadius&&marketplaceOriginAvailable&&unknownCount>0&&i===knownCount?'<h3 class="sk-unknown-distance-title">Weitere Inserate – Entfernung unbekannt</h3>':''}<article class="listing-card"><div class="listing-top"><span class="type-pill ${l.type==='Biete'?'available':''}">${esc(marketplaceType(l.type))}</span><button class="star" type="button" data-star="${esc(l.id)}" title="${starred.has(l.id)?'Aus Merkliste entfernen':'In Merkliste aufnehmen'}" aria-label="${starred.has(l.id)?'Aus Merkliste entfernen':'In Merkliste aufnehmen'}" aria-pressed="${starred.has(l.id)}">${starred.has(l.id)?'★':'☆'}</button></div><h3>${esc(l.title)}</h3><div class="listing-location">⌖ ${esc(l.city)} · ${esc(l.country)}${activeRadius&&marketplaceOriginAvailable?(Number.isFinite(marketplaceDistances.get(l.id))?` · ${Math.round(marketplaceDistances.get(l.id))} km entfernt`:' · Entfernung nicht berechenbar / Standort nicht verifiziert'):''}</div><p>${esc(l.description)}</p><div class="listing-meta"><span>◷ ${esc(marketplaceDate(l.date_from))} – ${esc(marketplaceDate(l.date_to))}</span>${l.accommodation?'<span>⌂ Unterkunft</span>':''}</div><div class="listing-footer"><div class="languages">${(l.languages||[]).map(x=>`<span>${esc(x)}</span>`).join('')}</div><button class="detail-link" type="button" data-detail="${esc(l.id)}">Details ansehen →</button></div></article>`).join('');
  grid.querySelectorAll('[data-star]').forEach(b=>b.addEventListener('click',()=>{const id=b.dataset.star;starred.has(id)?starred.delete(id):starred.add(id);render()}));
  grid.querySelectorAll('[data-detail]').forEach(b=>b.addEventListener('click',()=>openDetail(b.dataset.detail)));
  document.getElementById('no-results').classList.toggle('hidden',marketplaceLoadError||items.length>0);
  grid.classList.remove('hidden');document.getElementById('map-placeholder').classList.add('hidden');
}
let skChatIndex=[];
async function skRefreshChatIndex(){
 if(!window.SK_AUTH?.chatThreads)return [];
 skChatIndex=await window.SK_AUTH.chatThreads();
 return skChatIndex;
}
async function skOpenListingChats(listingId){
 try{
  const threads=await skRefreshChatIndex();
  if(!threads.some(t=>t.listing_id===listingId)){
   alert('Für dieses Inserat sind keine zugänglichen Unterhaltungen vorhanden.');return;
  }
  skChatListingFilterId=listingId;selectedChatId=threads.find(t=>t.listing_id===listingId)?.id||null;
  skChatFilterBusinessId='';
  await show('messages');
  if(currentScreen==='messages')await renderChats(selectedChatId);
 }catch(error){alert('Unterhaltungen konnten nicht geladen werden: '+error.message);}
}
function openDetail(id){
  const l=marketplaceListings.find(x=>x.id===id);if(!l)return;
  document.getElementById('detail-title').textContent=l.title;
  document.getElementById('detail-subtitle').textContent=`${l.city} · ${l.country} · ${marketplaceDate(l.date_from)} – ${marketplaceDate(l.date_to)}`;
  document.getElementById('detail-meta').innerHTML=`<span class="status-tag">${esc(marketplaceType(l.type))}</span> <span class="status-tag">${esc(l.category)}</span>`;
  document.getElementById('detail-description').textContent=l.description;
  document.getElementById('detail-conditions').textContent=l.conditions||'Keine zusätzlichen Rahmenbedingungen angegeben.';
  document.getElementById('detail-features').innerHTML=`${l.accommodation?'<span class="status-tag">Unterkunft vorhanden</span>':'<span class="status-tag">Keine Unterkunft angegeben</span>'} ${(l.languages||[]).map(x=>`<span class="status-tag">${esc(x)}</span>`).join(' ')}`;
  document.getElementById('detail-company').textContent='Betrieb in '+l.city;
  const contact=document.getElementById('detail-contact');contact.disabled=false;contact.textContent='Kontakt aufnehmen →';contact.dataset.listingId=l.id;contact.dataset.existingChat='0';
  document.getElementById('detail-contact-form').classList.add('hidden');
  show('detail');
  // Berechtigungsgeprüfte Liste, keine direkte Abfrage privater Tabellen.
  void skRefreshChatIndex().then(threads=>{
   if(currentScreen!=='detail'||contact.dataset.listingId!==l.id)return;
   const exists=threads.some(t=>t.listing_id===l.id);
   contact.textContent=exists?'Zum Chat →':'Kontakt aufnehmen →';
   contact.dataset.existingChat=exists?'1':'0';
  }).catch(()=>{contact.dataset.existingChat='0';});
}
['filter-search','filter-type','filter-branch','filter-date','filter-accommodation','filter-radius'].forEach(id=>document.getElementById(id).addEventListener('input',render));
document.getElementById('filter-reset').addEventListener('click',()=>{['filter-search','filter-type','filter-branch','filter-date'].forEach(id=>document.getElementById(id).value='');document.getElementById('filter-radius').selectedIndex=0;document.getElementById('filter-accommodation').checked=false;favoritesOnly=false;document.getElementById('bookmarks-only').classList.remove('selected');render()});
document.getElementById('bookmarks-only').addEventListener('click',e=>{favoritesOnly=!favoritesOnly;e.currentTarget.classList.toggle('selected',favoritesOnly);render()});
function setView(map){if(map)return;viewMap=false;document.getElementById('list-btn').classList.add('active');render();}
document.getElementById('list-btn').addEventListener('click',()=>setView(false));
/* Zusätzliche UI-Demoseiten, ohne Backend und ohne dauerhafte Speicherung */
const dialog=document.getElementById('app-dialog');
const skDialogState={snapshot:'',manualDirty:false,saving:false,allowedClose:false,lastAction:'init'};
const skDialogFields=()=>{
 const form=dialog.querySelector('form');
 if(!form)return '';
 return JSON.stringify([...form.elements].filter(el=>el.name&&!['submit','button'].includes(el.type))
  .map(el=>[el.name,el.type==='checkbox'||el.type==='radio'?el.checked:el.value]));
};
function skDialogDirty(){const d=window.SK_DRAFTS?.current();const n=window.SK_NEW_BUSINESS_DRAFT;return dialog.open && (n?.active ? n.unsafe() : (skDialogState.manualDirty||(d ? d.unsafe() : skDialogFields()!==skDialogState.snapshot)));}
function skDialogTrace(action){skDialogState.lastAction=action;console.info('[SK dialog 0.33.1.6.2]',action,{open:dialog.open,dirty:skDialogDirty(),saving:skDialogState.saving});}
function skDialogConfirmDiscard(allowDraftSave=false){
 return new Promise(resolve=>{
  const prompt=document.createElement('dialog');prompt.setAttribute('aria-label','Ungespeicherte Änderungen');
  const wrap=document.createElement('div');wrap.style.cssText='padding:20px;max-width:460px';
  const heading=document.createElement('h2');heading.textContent=allowDraftSave?(dialog.querySelector('#sk-extra-business-form')?'Neuen Betriebsentwurf schliessen?':'Inserat schliessen?'):'Ungespeicherte Änderungen';
  const msg=document.createElement('p');msg.textContent=allowDraftSave
   ?'Es sind noch nicht gesicherte Änderungen vorhanden. Du kannst den privaten Entwurf speichern, nur die letzten Änderungen verwerfen oder weiter bearbeiten.'
   :window.SK_DRAFTS?.current()?'Ungesicherte Änderungen verwerfen? Bereits gespeicherte private Entwürfe bleiben bestehen.':'Deine Änderungen wurden noch nicht gespeichert. Möchtest du weiter bearbeiten oder sie verwerfen?';
  const actions=document.createElement('div');actions.style.cssText='display:flex;gap:12px;flex-wrap:wrap';
  const keep=document.createElement('button');keep.type='button';keep.className='subtle-btn';keep.textContent='Weiter bearbeiten';
  const discard=document.createElement('button');discard.type='button';discard.className='subtle-btn';discard.textContent='Änderungen verwerfen';
  actions.append(keep,discard);
  if(allowDraftSave){const save=document.createElement('button');save.type='button';save.className='btn';save.textContent='Entwurf speichern';save.addEventListener('click',()=>finish('save'));actions.append(save);}
  wrap.append(heading,msg,actions);prompt.append(wrap);document.body.append(prompt);
  let done=false;
  const finish=answer=>{if(done)return;done=true;prompt.close();prompt.remove();resolve(answer);};
  keep.addEventListener('click',()=>finish('keep'));discard.addEventListener('click',()=>finish('discard'));
  prompt.addEventListener('cancel',e=>{e.preventDefault();finish('keep');});
  prompt.showModal();keep.focus();
 });
}
async function skDialogRequestClose(origin){
 if(!dialog.open)return true;
 skDialogTrace('close-request:'+origin);
 if(skDialogState.saving){console.warn('[SK dialog] Schliessen während Speicherung blockiert');return false;}
 const nd=window.SK_NEW_BUSINESS_DRAFT;
 if(nd?.active){
  nd.pause();await nd.waitForIdle();
  if(nd.unsafe()){const choice=await skDialogConfirmDiscard(true);if(choice==='keep'){nd.resume();return false;}if(choice==='save'){try{await nd.saveNow();nd.dispose();skDialogState.allowedClose=true;dialog.close();await loadMyBusinesses();return true;}catch(e){nd.resume();alert('Entwurf nicht gespeichert: '+e.message);return false;}}}
  nd.dispose();skDialogState.allowedClose=true;dialog.close();return true;
 }
 const draft=window.SK_DRAFTS?.current();
 // Eine laufende Auto-Save-Anfrage darf den Entwurf nicht erst nach der Wahl «Verwerfen» sichern.
 if(draft){draft.pause();await draft.waitForIdle();}
 if(!dialog.open)return true;
 if(skDialogDirty()){
  const canSave=!!dialog.querySelector('#listing-form')&&!!draft;
  const choice=await skDialogConfirmDiscard(canSave);
  if(choice==='keep'){draft?.resume();return false;}
  if(choice==='save'){
   const saved=await saveListingDraftAndClose();
   if(!saved)draft?.resume();
   return saved;
  }
 }
 draft?.abandon();
 skDialogState.allowedClose=true;skDialogState.lastAction='user-close:'+origin;dialog.close();return true;
}
// Reguläres Schliessen bei Auto-Save-Formularen: erst den privaten Entwurf sichern.
// X und Escape bleiben ausdrücklich Abbrechen mit Dirty-Guard.
async function skDialogAutosaveClose(button){
 if(!dialog.open||skDialogState.saving)return;
 const draft=window.SK_DRAFTS?.current();
 if(!draft)return void (await skDialogRequestClose('regular-without-draft'));
 const form=button.closest('form');
 const notice=form?.querySelector('.listing-save-error')||form?.querySelector('#sk-business-edit-feedback');
 button.disabled=true;skDialogState.saving=true;
 const oldText=button.textContent;button.textContent='Entwurf wird gesichert …';
 try{
  await draft.ready;
  if(draft.readOnly){
   // Reiner Lesemodus hat keine lokalen Änderungen zu sichern.
   if(draft.unsafe())throw Error('Ungesicherte Änderungen im Lesemodus.');
  }else await draft.flush();
  skDialogSavedClose();
  if(currentScreen==='my-listings')await loadMyListings();
  if(currentScreen==='my-businesses')await loadMyBusinesses();
 }catch(error){
  if(notice)notice.textContent='Schliessen nicht möglich: '+error.message+' Änderungen bleiben im Formular erhalten.';
  else console.warn('[SK dialog] Auto-Save vor Schliessen fehlgeschlagen',error);
 }finally{skDialogState.saving=false;if(button.isConnected){button.disabled=false;button.textContent=oldText;}}
}
document.getElementById('dialog-body').addEventListener('click',event=>{
 const button=event.target.closest('[data-sk-autosave-close]');
 if(button)void skDialogAutosaveClose(button);
});
function skDialogSavedClose(){window.SK_DRAFTS?.current()?.abandon();skDialogState.saving=false;skDialogState.allowedClose=true;skDialogState.lastAction='save-success';dialog.close();}
function modal(title,html){
 if(dialog.open){console.warn('[SK dialog] Versuch, geöffneten Dialog zu ersetzen',title);return false;}
 window.SK_DRAFTS?.current()?.abandon();
 window.SK_NEW_BUSINESS_DRAFT?.dispose();
 document.getElementById('dialog-title').textContent=title;
 document.getElementById('dialog-body').innerHTML=html;
 // Auto-Save-Formulare brauchen einen echten Schliessen-Button statt nur X (= Abbrechen).
 const autosaveForm=dialog.querySelector('#listing-form, #sk-edit-business-form');
 if(autosaveForm){
  const actions=autosaveForm.querySelector('.dialog-actions')||autosaveForm;
  const closeButton=document.createElement('button');closeButton.type='button';
  closeButton.className='subtle-btn';closeButton.textContent='Schliessen';
  closeButton.setAttribute('data-sk-autosave-close','');
  actions.append(closeButton);
 }
 skDialogState.snapshot=skDialogFields();skDialogState.manualDirty=false;skDialogState.saving=false;
 skDialogState.allowedClose=false;skDialogState.lastAction='open:'+title;
 dialog.showModal();return true;
}
dialog.addEventListener('cancel',e=>{e.preventDefault();void skDialogRequestClose('escape');});
dialog.addEventListener('close',()=>{
 if(!skDialogState.allowedClose){console.warn('[SK dialog] Unerwartetes close-Ereignis',skDialogState.lastAction);
  // Bei einem unerwarteten programmatischen Schliessen bleibt das Formular im DOM erhalten.
  if(dialog.isConnected&&!dialog.open){try{dialog.showModal();}catch(err){console.warn('[SK dialog] Wiederherstellung fehlgeschlagen',err);}}
 }
 skDialogState.allowedClose=false;
});
dialog.addEventListener('input',()=>{if(dialog.open)skDialogTrace('input');});
dialog.addEventListener('change',()=>{if(dialog.open)skDialogTrace('change');});
dialog.addEventListener('click',e=>{if(e.target.closest('#sk-edit-location-correct'))skDialogState.manualDirty=true;});
window.addEventListener('beforeunload',e=>{if(skDialogDirty()||skDialogState.saving){e.preventDefault();e.returnValue='';}});


const skBusinessStatusLabels={Freigeschaltet:'Freigeschaltet',Ausstehend:'Freigabe ausstehend',Gesperrt:'Gesperrt',approved:'Genehmigt',submitted:'Zur Prüfung eingereicht',draft:'Entwurf',changes_requested:'Nachbesserung erforderlich',rejected:'Abgelehnt',suspended:'Gesperrt'};
const skBusinessStatus=s=>skBusinessStatusLabels[s]||'Unbekannter Status';
async function loadMyBusinesses(){
 const root=document.getElementById('my-businesses-list');root.textContent='Betriebe werden geladen …';
 try{const rows=await window.SK_AUTH.listMyBusinesses();
 root.innerHTML=rows.length?rows.map(b=>`<article class="panel sk-business-item"><div><strong>${esc(b.company_name)}</strong><p class="muted">${esc(b.postal_code||'')} ${esc(b.city||'')} · ${esc(b.country||'')}</p><p><span class="status-tag ${b.status==='Freigeschaltet'?'sk-list-status-active':''}">${esc(skBusinessStatus(b.status))}</span> <span class="status-tag">${esc(skBusinessStatus(b.review_state))}</span></p>${b.review_state==='changes_requested'?`<p role="alert">Nachbesserung: ${esc(b.review_message||'Bitte Angaben korrigieren')}</p>`:''}</div><div class="sk-business-actions"><button type="button" class="subtle-btn" data-edit-business="${esc(b.id)}">${b.review_state==='changes_requested'?'Nachbessern':'Betriebsprofil bearbeiten'}</button><button type="button" class="subtle-btn" data-business-media="${esc(b.id)}">Logo &amp; Bilder</button>${b.member_role==='owner'&&b.status==='Freigeschaltet'&&b.review_state==='approved'?`<button type="button" class="subtle-btn" data-business-sensitive="${esc(b.id)}">Rechtliche Änderungen beantragen</button>`:''}${b.member_role==='owner'&&b.status==='Ausstehend'&&['draft','changes_requested'].includes(b.review_state)?`<button type="button" class="subtle-btn" data-business-submit="${esc(b.id)}">Zur Freischaltung einreichen</button>`:''}${b.member_role==='owner'&&b.status!=='Gesperrt'?`<button type="button" class="subtle-btn" data-business-deletion="${esc(b.id)}">Löschung beantragen</button>`:''}</div></article>`).join(''):'<p>Keine Betriebe zugeordnet.</p>';
 const draftRows=await window.SK_AUTH.listNewBusinessDrafts();
 if(draftRows.length){
  const holder=document.createElement('section');holder.className='panel';
  holder.innerHTML='<h3>Private Entwürfe für neue Betriebe</h3><p class="muted">Noch nicht eingereicht – es wurde kein Betrieb angelegt.</p>'+draftRows.map(d=>'<div style="display:flex;flex-wrap:wrap;gap:8px;align-items:center;margin:10px 0"><strong>'+esc(d.payload?.company_name||'Unbenannter Betrieb')+'</strong><button class="subtle-btn" type="button" data-new-business-resume="'+esc(d.draft_id)+'">Entwurf fortsetzen</button><button class="subtle-btn" type="button" data-new-business-delete="'+esc(d.draft_id)+'">Entwurf löschen</button></div>').join('');
  root.prepend(holder);
 }
}
 catch(e){root.textContent='Betriebe konnten nicht geladen werden: '+e.message;}
}
function skBusinessForm(b){
 const pending=b.status!=='Freigeschaltet';const editLegal=pending&&b.review_state==='changes_requested';
 const readOnly=b.review_state==='submitted'||b.review_state==='rejected'||b.status==='Gesperrt';
 const legalLock=editLegal?'':'disabled';
 return `<form id="sk-edit-business-form" data-business="${esc(b.id)}"><p class="muted">${esc(skBusinessStatus(b.status))} · ${esc(skBusinessStatus(b.review_state))}</p>${b.review_state==='changes_requested'?`<p role="alert"><strong>Hinweis von Annette:</strong> ${esc(b.review_message||'Bitte Angaben ergänzen')}</p>`:''}${readOnly?'<p role="status">Dieser Betrieb ist derzeit nur lesbar. Während der Prüfung sind Änderungen gesperrt.</p>':''}
 <label>Betriebsname *</label><input name="company_name" required minlength="2" maxlength="160" value="${esc(b.company_name)}" ${pending?'':'disabled'}>
 <label>UID / USt-ID *</label><input name="vat_id" required minlength="2" maxlength="64" value="${esc(b.vat_id||'')}" ${legalLock}>
 <label>Branche *</label><select name="industry" required>${[['Hotel','Hotellerie'],['Gastro','Gastronomie'],['Camping','Camping']].map(([v,t])=>`<option value="${v}" ${b.industry===v?'selected':''}>${t}</option>`).join('')}</select>
 <label>Land *</label><select name="country" required ${legalLock}>${[['CH','Schweiz'],['DE','Deutschland'],['AT','Österreich']].map(([v,t])=>`<option value="${v}" ${b.country===v?'selected':''}>${t}</option>`).join('')}</select>
 <div class="field-grid"><div><label>PLZ *</label><input name="postal_code" required minlength="2" maxlength="16" value="${esc(b.postal_code||'')}"></div><div><label>Ort *</label><input name="city" required minlength="2" maxlength="120" value="${esc(b.city||'')}"></div></div>
 <div class="field-grid"><div><label>Strasse</label><input name="street" maxlength="180" value="${esc(b.street||'')}"></div><div><label>Hausnummer</label><input name="house_number" maxlength="24" value="${esc(b.house_number||'')}"></div></div>
 <label>Adresszusatz</label><input name="address_extra" maxlength="180" value="${esc(b.address_extra||'')}">
 <label>Kontaktperson *</label><input name="contact_name" required minlength="2" maxlength="160" value="${esc(b.contact_name||'')}">
 <label>Kontakt-E-Mail *</label><input name="contact_email" type="email" required maxlength="254" value="${esc(b.contact_email||'')}">
 <label>Telefon *</label><input name="contact_phone" required minlength="5" maxlength="60" value="${esc(b.contact_phone||'')}">
 <label>Beschreibung *</label><textarea name="description" required minlength="30" maxlength="1000">${esc(b.description||'')}</textarea>
 <label class="check"><input type="checkbox" name="show_street_address" ${b.show_street_address?'checked':''} ${readOnly?'disabled':''}><span>Strassenadresse öffentlich anzeigen (standardmässig aus)</span></label>
 <label class="check"><input type="checkbox" name="email_notifications_enabled" ${b.email_notifications_enabled!==false?'checked':''} ${readOnly?'disabled':''}><span>E-Mail-Benachrichtigungen: persönliche Betriebseinstellung; der eigentliche Nachrichtenversand wird dadurch noch nicht implementiert.</span></label>
 <section class="sk-business-location-panel"><h3>Standort des Betriebs</h3><p class="muted">Adresse erfassen und automatisch ermitteln. Falls Google sie nicht findet, mit «Marker manuell setzen» den Standort auf der Karte wählen und bestätigen. Strasse und Hausnummer bleiben unverändert.</p><div class="business-map" id="sk-edit-business-map" role="region" aria-label="Karte des ausgewählten Betriebs"></div><p id="sk-edit-location-status" role="status">Noch keine neue Standortbestimmung durchgeführt.</p><button type="button" class="subtle-btn" id="sk-edit-location-search" ${readOnly?'disabled':''}>Standort aus Adresse ermitteln</button><button type="button" class="subtle-btn" id="sk-edit-location-correct" ${readOnly?'disabled':''}>Marker manuell setzen</button><button type="button" class="subtle-btn" id="sk-edit-location-accept" hidden>Position bestätigen</button><p class="muted">Ohne bestätigte Koordinaten wird der Standort als «Entfernung unbekannt» behandelt. Annette kann eine eingereichte Adresse separat prüfen.</p></section>
 <p class="form-feedback" id="sk-business-edit-feedback" role="alert"></p>
 ${readOnly?'':`<button type="submit" class="btn">${b.review_state==='changes_requested'?'Korrigieren und erneut einreichen':'Änderungen speichern'}</button>`}
 </form>`;
}
// 0.33.1.8.4: Existing owner-scoped Storage operations, now reachable per business UUID.
// Media are saved immediately, independently of the private business-profile draft.
async function skOpenBusinessMedia(business){
 const canWrite=business.member_role==='owner'&&(business.status==='Freigeschaltet'||(business.status==='Ausstehend'&&['draft','changes_requested'].includes(business.review_state)));
 if(!modal('Logo und Bilder · '+business.company_name,`<section id="sk-business-media-panel"><p class="muted">Bilder werden beim Hochladen oder Entfernen sofort gespeichert – unabhängig von Änderungen am Betriebsprofil.</p><div id="sk-business-media-content">Medien werden geladen …</div><p id="sk-business-media-feedback" role="status" aria-live="polite"></p></section>`))return;
 const panel=document.getElementById('sk-business-media-panel');
 let busy=false;
 const feedback=()=>panel.querySelector('#sk-business-media-feedback');
 function makeButton(title,fn){const button=document.createElement('button');button.type='button';button.className='subtle-btn';button.textContent=title;button.addEventListener('click',fn);return button;}
 async function act(action,description){
  if(busy||!panel.isConnected)return;
  busy=true;skDialogState.saving=true;feedback().textContent=description+' …';
  try{await action();if(panel.isConnected){await render();feedback().textContent='Änderung gespeichert.';}}
  catch(err){if(panel.isConnected)feedback().textContent='Nicht gespeichert: '+err.message;}
  finally{busy=false;skDialogState.saving=false;}
 }
 async function render(){
  const media=await window.SK_AUTH.listBusinessMedia(business.id);
  if(!panel.isConnected)return;
  const root=panel.querySelector('#sk-business-media-content');root.replaceChildren();
  const slots=[{kind:'logo',slot:'logo',title:'Firmenlogo',file:media.logo[0],max:'2 MB'},...Array.from({length:5},(_,i)=>({kind:'photos',slot:i+1,title:'Betriebsbild '+(i+1),file:media.photos.find(f=>f.name.startsWith((i+1)+'.')),max:'5 MB'}))];
  for(const item of slots){
   const block=document.createElement('div');block.className='panel';
   const heading=document.createElement('h3');heading.textContent=item.title;block.append(heading);
   if(item.file){const img=document.createElement('img');img.src=item.file.url;img.alt=item.title;img.loading='lazy';img.style.cssText='display:block;max-width:100%;max-height:190px;object-fit:contain;margin-bottom:10px';block.append(img);}
   else{const info=document.createElement('p');info.textContent='Noch kein Bild vorhanden.';block.append(info);}
   if(canWrite){
    const label=document.createElement('label');label.textContent=item.file?'Bild ersetzen (JPG, PNG, WebP; max. '+item.max+')':'Bild hochladen (JPG, PNG, WebP; max. '+item.max+')';
    const input=document.createElement('input');input.type='file';input.accept='image/jpeg,image/png,image/webp';
    input.setAttribute('aria-label',item.title+' hochladen');
    input.addEventListener('change',()=>{const file=input.files?.[0];if(file)void act(()=>window.SK_AUTH.uploadBusinessMedia(business.id,item.kind,item.slot,file),'Bild hochladen');});
    label.append(input);block.append(label);
    if(item.file)block.append(makeButton('Bild entfernen',()=>{if(confirm(item.title+' wirklich entfernen?'))void act(()=>window.SK_AUTH.removeBusinessMedia(business.id,item.kind,item.slot),'Bild entfernen');}));
   }root.append(block);
  }
  if(!canWrite){const info=document.createElement('p');info.textContent='Dieser Betrieb ist derzeit nur lesbar. Bilder können nicht geändert werden.';root.prepend(info);}
 }
 try{await render();}catch(err){feedback().textContent='Medien konnten nicht geladen werden: '+err.message;}
}
// 0.33.1.8.6: Sensible Aenderungen werden stets explizit dem gewaehlten Betrieb zugeordnet.
// Ein Antrag veraendert den Live-Stand nicht; Annette entscheidet separat.
async function skOpenBusinessSensitiveRequest(business){
 if(business.member_role!=='owner'||business.status!=='Freigeschaltet'||business.review_state!=='approved'){
  throw Error('Rechtliche Änderungsanträge sind für diesen Betrieb nicht möglich.');
 }
 if(!modal('Rechtliche Änderung beantragen · '+business.company_name,`<form id="sk-sensitive-business-form">
  <p>Firmenname, UID / USt-ID oder Land können bei freigeschalteten Betrieben nur nach Genehmigung durch Annette geändert werden. Der bisherige Wert bleibt bis dahin bestehen.</p>
  <label for="sk-sensitive-business-field">Zu ändernde Angabe</label>
  <select id="sk-sensitive-business-field" name="field" required>
   <option value="company_name">Firmenname</option><option value="vat_id">UID / USt-ID</option><option value="country">Land</option>
  </select>
  <label for="sk-sensitive-business-value">Neuer Wert</label>
  <input id="sk-sensitive-business-value" name="value" required maxlength="160" autocomplete="off">
  <p class="muted" id="sk-sensitive-business-current"></p>
  <p class="form-feedback" id="sk-sensitive-business-feedback" role="alert"></p>
  <div class="dialog-actions" id="sk-sensitive-business-actions">
   <button type="button" class="subtle-btn" id="sk-sensitive-business-cancel">Abbrechen</button>
   <button type="submit" class="btn">Antrag einreichen</button>
  </div>
 </form>`))return;
 const form=document.getElementById('sk-sensitive-business-form');
 const cancelButton=form.querySelector('#sk-sensitive-business-cancel');
 const cancelRequest=()=>{void skDialogRequestClose('sensitive-request-cancel');};
 cancelButton.addEventListener('click',cancelRequest);
 function showAlreadyPending(){
  // Nach SK409/23505 kann fuer dieses Feld kein weiterer Antrag eingereicht werden.
  // Die lokalen, nie gespeicherten Eingaben werden verworfen, der Dialog ist nur noch informativ.
  const submit=form.querySelector('[type="submit"]');
  form.elements.namedItem('field').disabled=true;
  form.elements.namedItem('value').disabled=true;
  submit.hidden=true;
  submit.disabled=true;
  cancelButton.textContent='Schliessen';
  cancelButton.removeEventListener('click',cancelRequest);
  cancelButton.addEventListener('click',()=>{
   if(skDialogState.saving)return;
   skDialogState.allowedClose=true;
   skDialogState.lastAction='sensitive-request-info-close';
   dialog.close();
  });
  // Der Formularzustand ist nur eine Information; keine unsicheren lokalen Aenderungen behalten.
  skDialogState.snapshot=skDialogFields();
  skDialogState.manualDirty=false;
 }
 const field=form.elements.namedItem('field'),value=form.elements.namedItem('value'),current=form.querySelector('#sk-sensitive-business-current');
 const currentValue=()=>field.value==='company_name'?business.company_name:field.value==='vat_id'?business.vat_id:business.country;
 const update=()=>{
  const map={CH:'Schweiz',DE:'Deutschland',AT:'Österreich'};
  current.textContent='Aktueller Wert: '+String(currentValue()??'–');
  value.placeholder=field.value==='country'?'CH, DE oder AT':'Neuen Wert eingeben';
  value.maxLength=field.value==='country'?2:field.value==='vat_id'?64:160;
  if(field.value==='country')current.textContent+=' · Neuer Wert als Ländercode ('+Object.keys(map).join(', ')+')';
 };
 field.addEventListener('change',()=>{value.value='';update();});update();
 form.addEventListener('submit',async event=>{
  event.preventDefault();if(!form.reportValidity())return;
  const next=value.value.trim();
  if(next===String(currentValue()??'').trim())return void (form.querySelector('#sk-sensitive-business-feedback').textContent='Bitte einen anderen Wert eingeben.');
  if(!confirm('Änderungsantrag für „'+business.company_name+'“ verbindlich an Annette einreichen? Die bestehenden Betriebsdaten bleiben unverändert.'))return;
  const submit=form.querySelector('[type="submit"]');submit.disabled=true;skDialogState.saving=true;
  try{await window.SK_AUTH.requestBusinessSensitiveChangeById(business.id,field.value,next);
   // Erfolgreiche verbindliche Einreichung ist KEIN ungesicherter Formularzustand.
   skDialogSavedClose();
   try{await loadMyBusinesses();}catch(refreshError){console.warn('[SK] Nach Einreichung konnte Betriebsübersicht nicht aktualisiert werden',refreshError);}
   const overview=document.getElementById('my-businesses-list');
   const confirmation=document.createElement('p');
   confirmation.className='form-feedback';confirmation.setAttribute('role','status');
   confirmation.textContent='Änderungsantrag für „'+business.company_name+'“ eingereicht. Die Änderung wird erst nach Genehmigung durch Annette wirksam.';
   overview.prepend(confirmation);
  }catch(error){
   const duplicate=error?.code==='SK409'||error?.code==='23505'||/sk_change_one_pending|offener Aenderungsantrag|offener Änderungsantrag/i.test(error?.message||'');
   form.querySelector('#sk-sensitive-business-feedback').textContent=duplicate
    ?'Für dieses Feld liegt bereits ein offener Änderungsantrag vor. Bitte zuerst die Entscheidung von Annette abwarten. Es wurde kein weiterer Antrag eingereicht.'
    :'Antrag nicht eingereicht: '+error.message;
   if(duplicate)showAlreadyPending();
   else submit.disabled=false;
  }
  finally{skDialogState.saving=false;}
 });
}
// Eindeutige Freischaltung und Löschanträge je Betrieb. Keine automatische Konto-Löschung.
async function skOpenBusinessSubmission(b){
 if(!modal('Freischaltung einreichen · '+b.company_name,`<div><p>Der Antrag betrifft ausschliesslich <strong>${esc(b.company_name)}</strong>. Bitte das Betriebsprofil zuerst speichern. Annette prüft die Einreichung separat.</p><p id="sk-submit-business-status" class="form-feedback" role="status"></p><div class="dialog-actions"><button type="button" class="subtle-btn" data-business-dialog-cancel>Abbrechen</button><button type="button" class="btn" id="sk-business-submit-confirm">Jetzt einreichen</button></div></div>`))return;
 document.getElementById('sk-business-submit-confirm').addEventListener('click',async e=>{
  const button=e.currentTarget;button.disabled=true;skDialogState.saving=true;
  try{await window.SK_AUTH.submitBusinessById(b.id);skDialogSavedClose();await loadMyBusinesses();}
  catch(err){document.getElementById('sk-submit-business-status').textContent='Nicht eingereicht: '+err.message;button.disabled=false;skDialogState.saving=false;}
 });
}
async function skOpenBusinessDeletion(b){
 const intro=b.status==='Ausstehend'&&['draft','changes_requested'].includes(b.review_state)
  ?'Diese noch nicht eingereichte Registrierung kann abgebrochen werden. Der Vorgang wird für die kontrollierte Löschung vorgemerkt; andere Betriebe und dein Login bleiben bestehen.'
  :'Der Löschantrag wird von Annette geprüft. Es erfolgt keine sofortige Löschung.';
 if(!modal('Löschung beantragen · '+b.company_name,`<form id="sk-business-deletion-form"><p>${intro}</p><p id="sk-business-deletion-history" role="status">Löschstatus wird geprüft …</p><label>Firmenname zur Bestätigung exakt eingeben *</label><input name="confirm_name" required autocomplete="off"><label>Begründung (optional)</label><textarea name="reason" maxlength="2000" rows="3"></textarea><p class="form-feedback" id="sk-business-deletion-feedback" role="alert"></p><div class="dialog-actions"><button type="button" class="subtle-btn" data-business-dialog-cancel>Abbrechen</button><button type="submit" class="btn">Löschung verbindlich beantragen</button></div></form>`))return;
 const form=document.getElementById('sk-business-deletion-form');
 try{const r=await window.SK_AUTH.deletionStatusById(b.id);if(!dialog.open||!form.isConnected)return;
  form.querySelector('#sk-business-deletion-history').textContent=r?'Letzter Löschvorgang: '+r.status:'Kein früherer Löschantrag.';
  if(r&&['requested','approved','processing','database_removed','failed'].includes(r.status)){
   form.querySelector('[type=submit]').disabled=true;
   form.querySelector('#sk-business-deletion-feedback').textContent='Für diesen Betrieb existiert bereits ein laufender Löschvorgang.';
  }
 }catch(err){if(form.isConnected){form.querySelector('#sk-business-deletion-history').textContent='Löschstatus konnte nicht geprüft werden: '+err.message;form.querySelector('[type=submit]').disabled=true;}}
 form.addEventListener('submit',async e=>{
  e.preventDefault();if(!form.reportValidity())return;
  const name=form.elements.namedItem('confirm_name').value.trim();
  if(name!==b.company_name){form.querySelector('#sk-business-deletion-feedback').textContent='Der Firmenname stimmt nicht mit dem ausgewählten Betrieb überein.';return;}
  if(!window.confirm('Löschung für «'+b.company_name+'» verbindlich beantragen? Dieser Schritt ist nicht rückgängig zu machen.'))return;
  const button=form.querySelector('[type=submit]');button.disabled=true;skDialogState.saving=true;
  try{const result=await window.SK_AUTH.requestBusinessDeletionById(b.id,name,form.elements.namedItem('reason').value);
   skDialogSavedClose();await loadMyBusinesses();
   const summary=document.getElementById('my-businesses-list');
   const note=document.createElement('p');note.setAttribute('role','status');note.textContent=result?.immediate?'Registrierungsabbruch vorgemerkt. Die endgültige Löschung wird kontrolliert durchgeführt.':'Löschantrag eingereicht. Annette prüft den Antrag.';summary.prepend(note);
  }catch(err){form.querySelector('#sk-business-deletion-feedback').textContent='Antrag nicht eingereicht: '+err.message;button.disabled=false;skDialogState.saving=false;}
 });
}
document.getElementById('dialog-body').addEventListener('click',e=>{if(e.target.closest('[data-business-dialog-cancel]'))void skDialogRequestClose('cancel-business-action');});
document.getElementById('my-businesses-list').addEventListener('click',async e=>{
 const submitBtn=e.target.closest('[data-business-submit]');
 const deletionBtn=e.target.closest('[data-business-deletion]');
 if(submitBtn||deletionBtn){const button=submitBtn||deletionBtn;button.disabled=true;try{const items=await window.SK_AUTH.listMyBusinesses();const business=items.find(b=>b.id===(submitBtn?submitBtn.dataset.businessSubmit:deletionBtn.dataset.businessDeletion));if(!business||business.member_role!=='owner')throw Error('Kein eigener Betrieb ausgewählt.');if(submitBtn)await skOpenBusinessSubmission(business);else await skOpenBusinessDeletion(business);}catch(err){alert('Aktion konnte nicht geöffnet werden: '+err.message);}finally{button.disabled=false;}return;}
 const sensitiveBtn=e.target.closest('[data-business-sensitive]');
 if(sensitiveBtn){sensitiveBtn.disabled=true;try{
  const businesses=await window.SK_AUTH.listMyBusinesses();const business=businesses.find(b=>b.id===sensitiveBtn.dataset.businessSensitive);
  if(!business)throw Error('Betrieb nicht mehr zugeordnet.');
  await skOpenBusinessSensitiveRequest(business);
 }catch(err){alert('Änderungsantrag konnte nicht geöffnet werden: '+err.message);}finally{sensitiveBtn.disabled=false;}return;}
 const mediaBtn=e.target.closest('[data-business-media]');
 if(mediaBtn){mediaBtn.disabled=true;try{const businesses=await window.SK_AUTH.listMyBusinesses();const business=businesses.find(b=>b.id===mediaBtn.dataset.businessMedia);if(!business)throw Error('Betrieb nicht mehr zugeordnet.');await skOpenBusinessMedia(business);}catch(err){alert('Medien konnten nicht geöffnet werden: '+err.message);}finally{mediaBtn.disabled=false;}return;}
 const btn=e.target.closest('[data-edit-business]');if(!btn)return;
 btn.disabled=true;
 try{const all=await window.SK_AUTH.listMyBusinesses(),b=all.find(x=>x.id===btn.dataset.editBusiness);if(!b)throw Error('Betrieb nicht mehr zugeordnet.');modal('Betriebsprofil · '+b.company_name,skBusinessForm(b)); const editForm=document.getElementById('sk-edit-business-form'); void window.SK_LOCATION?.editBusiness(editForm,b); if(editForm.querySelector('[type=submit]'))window.SK_DRAFTS?.attach(editForm,'business',b.id,b.id);}
 catch(err){alert('Betriebsprofil konnte nicht geöffnet werden: '+err.message);}finally{btn.disabled=false;}
});
document.getElementById('dialog-body').addEventListener('submit',async e=>{
 const form=e.target;if(form.id!=='sk-edit-business-form')return;e.preventDefault();if(!form.reportValidity())return;
 const coordsBefore=window.SK_LOCATION?.editorPosition(form);
 if(!coordsBefore&&!window.confirm('Für diese Adresse ist kein bestätigter Kartenstandort vorhanden.\n\nOK: Adresse trotzdem ohne Standort speichern (Entfernung unbekannt).\nAbbrechen: Weiter bearbeiten und ggf. Marker manuell setzen.'))return;
 const button=form.querySelector('[type="submit"]');button.disabled=true;skDialogState.saving=true;
 const val=n=>form.elements.namedItem(n).value.trim();
 try{const coords=window.SK_LOCATION?.editorPosition(form);await window.SK_AUTH.saveBusinessWithPreferencesAndLocation({p_profile:{p_email_notifications_enabled:form.elements.namedItem('email_notifications_enabled').checked,p_show_street_address:form.elements.namedItem('show_street_address').checked,p_business_id:form.dataset.business,p_company_name:val('company_name'),p_vat_id:val('vat_id'),p_industry:val('industry'),p_country:val('country'),p_postal_code:val('postal_code'),p_city:val('city'),p_street:val('street'),p_house_number:val('house_number'),p_address_extra:val('address_extra'),p_contact_name:val('contact_name'),p_contact_email:val('contact_email'),p_contact_phone:val('contact_phone'),p_description:val('description')},p_latitude:coords?.lat??null,p_longitude:coords?.lng??null,p_source:coords?.source??null,p_address_key:coords?.addressKey??null});const draft=window.SK_DRAFTS?.current();if(draft){try{await draft.finish();}catch(draftErr){console.warn('[SK drafts] Nach Live-Speicherung konnte Entwurf nicht bereinigt werden',draftErr);draft.abandon();}}skDialogSavedClose();await loadMyBusinesses();}
 catch(err){document.getElementById('sk-business-edit-feedback').textContent='Nicht gespeichert: '+err.message;button.disabled=false;skDialogState.saving=false;}
});
document.getElementById('my-businesses-list').addEventListener('click',async e=>{
 const resume=e.target.closest('[data-new-business-resume]'),remove=e.target.closest('[data-new-business-delete]');if(!resume&&!remove)return;
 const button=resume||remove;button.disabled=true;
 try{const draft=(await window.SK_AUTH.listNewBusinessDrafts()).find(d=>d.draft_id===(resume?resume.dataset.newBusinessResume:remove.dataset.newBusinessDelete));if(!draft)throw Error('Entwurf nicht mehr vorhanden.');
  if(remove){if(window.confirm('Privaten Entwurf «'+(draft.payload?.company_name||'Unbenannter Betrieb')+'» unwiderruflich löschen?')){await window.SK_AUTH.deleteNewBusinessDraft(draft.draft_id,Number(draft.revision));await loadMyBusinesses();}}
  else skOpenAdditionalBusiness(draft);
 }catch(error){alert('Entwurf: '+error.message);}finally{button.disabled=false;}
});
let skNewBusinessDraftController=null;
window.SK_NEW_BUSINESS_DRAFT={get active(){return !!skNewBusinessDraftController?.active;},unsafe(){return skNewBusinessDraftController?.unsafe()||false;},pause(){skNewBusinessDraftController?.pause();},resume(){skNewBusinessDraftController?.resume();},waitForIdle(){return skNewBusinessDraftController?.waitForIdle()||Promise.resolve();},saveNow(){return skNewBusinessDraftController?.saveNow();},dispose(){skNewBusinessDraftController?.dispose();}};
function skAttachNewBusinessDraft(form,existing){
 const id=existing?.draft_id||crypto.randomUUID();let rev=Number(existing?.revision||0),active=true,dirty=false,failed=false,paused=false,timer=null,chain=Promise.resolve();
 const line=form.querySelector('#sk-new-business-draft-status');
 const serialize=()=>{const p={};for(const el of form.elements){if(!el.name||['button','submit','file'].includes(el.type))continue;p[el.name]=el.type==='checkbox'?el.checked:el.value;}const loc=window.SK_LOCATION?.editorPosition(form);p._latitude=loc?.lat??null;p._longitude=loc?.lng??null;p._source=loc?.source??null;p._address_key=loc?.addressKey??null;return p;};
 let saved=JSON.stringify(existing?.payload||serialize());
 const report=message=>{if(active)line.textContent=message;};
 const queue=async()=>{clearTimeout(timer);const value=serialize(),str=JSON.stringify(value);if(!dirty&&str===saved&&rev)return;dirty=false;report('Privater Entwurf wird gespeichert …');
  chain=chain.catch(()=>{}).then(async()=>{if(!active)return;try{const next=await window.SK_AUTH.saveNewBusinessDraft(id,value,rev);rev=next;saved=str;failed=false;report('Privater Entwurf gespeichert – kein Betrieb eingereicht.');if(JSON.stringify(serialize())!==str){dirty=true;if(!paused)schedule();}}catch(error){failed=true;dirty=true;report('Entwurf nicht gespeichert: '+error.message);throw error;}});await chain;
 };
 const schedule=()=>{dirty=true;failed=false;report('Nicht gesicherte Änderungen …');clearTimeout(timer);if(!paused)timer=setTimeout(()=>{void queue().catch(()=>{});},1100);};
 const onInput=()=>schedule();form.addEventListener('input',onInput);form.addEventListener('change',onInput);
 const controller={active:true,unsafe:()=>dirty||failed||JSON.stringify(serialize())!==saved,pause(){paused=true;clearTimeout(timer);},resume(){paused=false;if(dirty)schedule();},async waitForIdle(){try{await chain;}catch{}},async saveNow(){clearTimeout(timer);paused=true;await controller.waitForIdle();if(!active)throw Error('Formular geschlossen.');if(!rev||dirty||JSON.stringify(serialize())!==saved){dirty=true;await queue();}if(failed||controller.unsafe())throw Error('Entwurf konnte nicht vollständig gespeichert werden.');},dispose(){active=false;controller.active=false;clearTimeout(timer);form.removeEventListener('input',onInput);form.removeEventListener('change',onInput);if(skNewBusinessDraftController===controller)skNewBusinessDraftController=null;},id,get revision(){return rev;}};
 skNewBusinessDraftController=controller;report(existing?'Gespeicherter privater Entwurf geladen.':'Noch kein privater Entwurf gespeichert.');
}
document.getElementById('dialog-body').addEventListener('click',async e=>{
 const save=e.target.closest('[data-new-business-draft-save]'),close=e.target.closest('[data-new-business-draft-close]');if(!save&&!close)return;
 const controller=skNewBusinessDraftController;if(!controller||skDialogState.saving)return;
 const button=save||close;button.disabled=true;skDialogState.saving=true;
 try{await controller.saveNow();if(close){controller.dispose();skDialogState.allowedClose=true;dialog.close();await loadMyBusinesses();}else{controller.resume();}}
 catch(error){const message=document.getElementById('sk-extra-business-error');if(message)message.textContent='Entwurf nicht gespeichert: '+error.message;controller.resume();}
 finally{skDialogState.saving=false;if(button.isConnected)button.disabled=false;}
});
function skOpenAdditionalBusiness(existing=null){
 if(!modal('Weiteren Betrieb beantragen',`<form id="sk-extra-business-form">
 <p>Der neue Betrieb wird unabhängig geprüft. Er erhält kein automatisch gemeinsames Abonnement.</p>
 <label>Firmenname *</label><input name="company_name" required minlength="2" maxlength="160">
 <label>UID / USt-ID *</label><input name="vat_id" required minlength="2" maxlength="64">
 <label>Branche *</label><select name="industry" required><option value="">Bitte wählen</option><option value="Hotel">Hotellerie</option><option value="Gastro">Gastronomie</option><option value="Camping">Camping</option></select>
 <label>Land *</label><select name="country" required><option value="">Bitte wählen</option><option value="CH">Schweiz</option><option value="DE">Deutschland</option><option value="AT">Österreich</option></select>
 <div class="field-grid"><div><label>PLZ *</label><input name="postal_code" required minlength="2" maxlength="16"></div><div><label>Ort *</label><input name="city" required minlength="2" maxlength="120"></div></div>
 <div class="field-grid"><div><label>Strasse</label><input name="street" maxlength="180"></div><div><label>Hausnummer</label><input name="house_number" maxlength="24"></div></div>
 <section class="sk-business-location-panel"><h3>Standort des neuen Betriebs</h3><p class="muted">Google ermittelt den Standort automatisch. Falls die Adresse nicht gefunden wird, kannst du den Marker manuell setzen und bestätigen.</p><div class="business-map" id="sk-edit-business-map" role="region" aria-label="Karte des neuen Betriebs"></div><p id="sk-edit-location-status" role="status">Bitte Adresse eingeben.</p><button type="button" class="subtle-btn" id="sk-edit-location-search">Standort aus Adresse ermitteln</button><button type="button" class="subtle-btn" id="sk-edit-location-correct">Marker manuell setzen</button><button type="button" class="subtle-btn" id="sk-edit-location-accept" hidden>Position bestätigen</button></section>
 <label>Kontaktperson *</label><input name="contact_name" required minlength="2" maxlength="160">
 <label>Telefon *</label><input name="contact_phone" required minlength="5" maxlength="60"><label>Beschreibung des Betriebs *</label><textarea name="description" required minlength="30" maxlength="1000"></textarea>
 <label class="check"><input type="checkbox" name="terms" required><span>Ich akzeptiere die geltenden Nutzungsbedingungen auch für diesen Betrieb.</span></label>
 <p id="sk-extra-business-error" role="alert"></p><p id="sk-new-business-draft-status" role="status"></p><div class="dialog-actions"><button class="subtle-btn" type="button" data-new-business-draft-save>Entwurf speichern</button><button class="subtle-btn" type="button" data-new-business-draft-close>Schliessen</button><button class="btn" type="submit">Betrieb zur Prüfung erfassen</button></div></form>`))return;
 const form=document.getElementById('sk-extra-business-form');
 const payload=existing?.payload||{};
 for(const el of form.elements){if(!el.name||!(el.name in payload))continue;if(el.type==='checkbox')el.checked=!!payload[el.name];else el.value=payload[el.name]??'';}
 void window.SK_LOCATION?.editBusiness(form,{...payload,latitude:payload._latitude??null,longitude:payload._longitude??null,location_source:payload._source||null,location_address_key:payload._address_key||null});
 skAttachNewBusinessDraft(form,existing);
}
document.getElementById('add-business-button').addEventListener('click',()=>skOpenAdditionalBusiness());
document.getElementById('dialog-body').addEventListener('submit',async e=>{
 const form=e.target;if(form.id!=='sk-extra-business-form')return;e.preventDefault();
 if(!form.reportValidity())return;
 if(!window.SK_LOCATION?.editorPosition(form)&&!window.confirm('Kein Kartenstandort bestätigt.\n\nOK: Betrieb ohne Standort einreichen.\nAbbrechen: Marker manuell setzen oder Adresse weiter bearbeiten.'))return;
 const get=k=>form.elements.namedItem(k).value.trim(),btn=form.querySelector('[type="submit"]');btn.disabled=true;skDialogState.saving=true;const draftBeforeSubmit=skNewBusinessDraftController;draftBeforeSubmit?.pause();if(draftBeforeSubmit)await draftBeforeSubmit.waitForIdle();
 try{const coords=window.SK_LOCATION?.editorPosition(form);await window.SK_AUTH.addAdditionalBusinessWithLocation({p_company_name:get('company_name'),p_vat_id:get('vat_id'),p_industry:get('industry'),p_country:get('country'),p_postal_code:get('postal_code'),p_city:get('city'),p_street:get('street'),p_house_number:get('house_number'),p_contact_name:get('contact_name'),p_contact_phone:get('contact_phone'),p_description:get('description'),p_latitude:coords?.lat??null,p_longitude:coords?.lng??null,p_source:coords?.source??null,p_address_key:coords?.addressKey??null});const nd=skNewBusinessDraftController;if(nd){nd.pause();await nd.waitForIdle();if(nd.revision){try{await window.SK_AUTH.deleteNewBusinessDraft(nd.id,nd.revision);}catch(e){console.warn('[SK neuer Betrieb] Eingereichter Entwurf konnte nicht bereinigt werden:',e.message);}}nd.dispose();}skDialogSavedClose();await loadMyBusinesses();alert('Betrieb zur Prüfung durch Annette eingereicht. Er ist noch nicht für den Marktplatz freigegeben.');}
 catch(err){document.getElementById('sk-extra-business-error').textContent=err.message;btn.disabled=false;skDialogState.saving=false;draftBeforeSubmit?.resume();}
});
async function loadManualAccessAdmin(){
 const root=document.getElementById('sk-admin-manual-access');if(!root)return;
 root.textContent='Kundenkonten werden geladen …';
 try{const rows=await window.SK_AUTH.adminManualAccounts();
 root.innerHTML=rows.length?`<div class="sk-admin-table-wrap"><table class="sk-admin-table"><thead><tr><th scope="col">Kundenkonto</th><th scope="col">Manuelle Freigabe</th><th scope="col">Gültig bis</th><th scope="col">Grund</th><th scope="col">Aktionen</th></tr></thead><tbody>${rows.map(c=>`<tr><td><strong>${esc(c.account_label)}</strong></td><td><span class="status-tag ${c.manual_active?'sk-list-status-active':''}">${c.manual_active?'Aktiv':'Keine gültige Freigabe'}</span></td><td>${c.valid_until?esc(dateDisplay(c.valid_until)):'–'}</td><td>${esc(c.reason||'–')}</td><td><div class="sk-table-actions"><button type="button" class="subtle-btn sk-action-edit" title="Manuelle Freigabe erteilen oder bearbeiten" aria-label="Freigabe für ${esc(c.account_label)} bearbeiten" data-sk-grant="${esc(c.account_id)}">✎</button><button type="button" class="subtle-btn sk-action-delete" title="Manuelle Freigabe widerrufen" aria-label="Freigabe für ${esc(c.account_label)} widerrufen" data-sk-revoke="${esc(c.account_id)}" ${!c.manual_active?'disabled':''}>✕</button></div></td></tr>`).join('')}</tbody></table></div>`:'<p>Keine Kundenkonten vorhanden.</p>';
 }catch(e){root.textContent='Freigaben konnten nicht geladen werden: '+e.message;}
}
document.getElementById('sk-admin-manual-access').addEventListener('click',async e=>{
 const give=e.target.closest('[data-sk-grant]');const revoke=e.target.closest('[data-sk-revoke]');if(!give&&!revoke)return;
 if(revoke){if(!confirm('Manuelle Freigabe widerrufen? Ein gültiges bezahltes Abo bleibt davon unberührt.'))return;revoke.disabled=true;try{await window.SK_AUTH.adminSetManualAccess(revoke.dataset.skRevoke,false);await loadManualAccessAdmin();}catch(err){alert(err.message);revoke.disabled=false;}return;}
 const id=give.dataset.skGrant;
 modal('Manuelle Nutzungsfreigabe',`<form id="sk-manual-access-form" data-account="${esc(id)}"><p>Diese Freigabe ersetzt kein bezahltes Abonnement. Stufe 2 ist noch nicht als Marktplatzsperre aktiviert.</p><label>Grund *</label><select name="category"><option>Testphase</option><option>Kulanz</option><option>Partnervereinbarung</option><option>Sonstiges</option></select><label>Erläuterung *</label><textarea name="reason" required minlength="4" maxlength="500"></textarea><label>Gültig bis (leer = unbefristet)</label><input type="date" name="until"><p id="sk-manual-error" role="alert"></p><button class="btn" type="submit">Manuelle Freigabe speichern</button></form>`);
});
document.getElementById('dialog-body').addEventListener('submit',async e=>{
 const form=e.target;if(form.id!=='sk-manual-access-form')return;e.preventDefault();if(!form.reportValidity())return;
 const btn=form.querySelector('[type="submit"]');btn.disabled=true;skDialogState.saving=true;
 try{const reason=form.elements.namedItem('category').value+': '+form.elements.namedItem('reason').value.trim();await window.SK_AUTH.adminSetManualAccess(form.dataset.account,true,reason,form.elements.namedItem('until').value);skDialogSavedClose();await loadManualAccessAdmin();}
 catch(err){document.getElementById('sk-manual-error').textContent=err.message;btn.disabled=false;skDialogState.saving=false;}
});

document.getElementById('dialog-close').addEventListener('click',()=>{void skDialogRequestClose('button');});
// Ein Klick auf den Overlay-Hintergrund schliesst bearbeitbare Dialoge nicht mehr.
let chosenListing=1, listTab='inserate';const listingStatus=new Map(listings.map(l=>[l.id,'Aktiv']));
let ownListings=[];
let ownListingDrafts=[];
let ownBusinessList=[];
window.SK_SELECTED_BUSINESS=null;
let ownListingsBusy=false;
const listingFormField=(form,name)=>form.elements.namedItem(name);
function listingError(error){modal('Inserat nicht gespeichert',`<p>${esc(error?.message||'Unbekannter Fehler')}</p><p>Das Inserat wurde nicht als gespeichert bestätigt. Bitte überprüfe deine Anmeldung und die Datenbankmigration 0.32.1.</p>`);}
// Refresh only the visible list. Never rerender an open editor or apply stale responses.
let skListingsRefreshGeneration=0;
let skListingsRefreshBusy=false;
let skListingsRefreshPending=false;
let skListingsLastRefresh=0;
async function loadMyListings({silent=false}={}){
  if(currentScreen!=='my-listings')return;
  if(dialog.open){skListingsRefreshPending=true;return;}
  if(skListingsRefreshBusy){skListingsRefreshPending=true;return;}
  const generation=++skListingsRefreshGeneration;
  const root=document.getElementById('my-list-table');
  skListingsRefreshBusy=true;
  if(!silent)root.innerHTML='<p class="muted">Eigene Inserate werden geladen …</p>';
  try{
    // Keep all three results local until a complete, current snapshot is ready.
    const businesses=await window.SK_AUTH.listApprovedBusinesses();
    const listings=await window.SK_AUTH.listMyListings();
    const drafts=await window.SK_AUTH.listListingDrafts();
    if(generation!==skListingsRefreshGeneration||currentScreen!=='my-listings'||dialog.open){
      if(dialog.open)skListingsRefreshPending=true;
      return;
    }
    ownBusinessList=businesses;ownListings=listings;ownListingDrafts=drafts;
    try{await skRefreshChatIndex();}catch(error){skChatIndex=[];console.warn('Chat-Verknüpfungen nicht verfügbar',error);}
    if(generation!==skListingsRefreshGeneration||currentScreen!=='my-listings')return;
    renderMyListings();skListingsLastRefresh=Date.now();
  }catch(error){
    if(generation===skListingsRefreshGeneration&&currentScreen==='my-listings'&&!dialog.open){
      if(!silent)root.innerHTML=`<p role="alert">Inserate konnten nicht geladen werden: ${esc(error.message)}</p>`;
      else console.warn('[SK listings] Hintergrundaktualisierung fehlgeschlagen',error);
    }
  }finally{
    skListingsRefreshBusy=false;
    if(skListingsRefreshPending&&currentScreen==='my-listings'&&!dialog.open){
      skListingsRefreshPending=false;
      void loadMyListings({silent:true});
    }
  }
}
function skRefreshVisibleListings(){
  if(currentScreen!=='my-listings'||document.hidden)return;
  if(dialog.open){skListingsRefreshPending=true;return;}
  // Focus and visibilitychange can fire together. Avoid duplicate network requests.
  if(Date.now()-skListingsLastRefresh<900)return;
  void loadMyListings({silent:true});
}
window.addEventListener('focus',skRefreshVisibleListings);
document.addEventListener('visibilitychange',()=>{if(!document.hidden)skRefreshVisibleListings();});
dialog.addEventListener('close',()=>{
  if(currentScreen!=='my-listings')return;
  skListingsRefreshPending=false;
  void loadMyListings({silent:true});
});
async function saveListingDraftAndClose(){
 if(ownListingsBusy)return false;
 const form=document.getElementById('listing-form');
 const draft=window.SK_DRAFTS?.current();
 if(!form||!draft){const note=form?.querySelector('.listing-save-error');if(note)note.textContent='Entwurfssicherung nicht verfügbar. Bitte Formular geöffnet lassen.';return false;}
 const button=document.getElementById('save-listing-draft');
 const note=form.querySelector('.listing-save-error');
 if(note)note.textContent='';
 ownListingsBusy=true;skDialogState.saving=true;
 if(button){button.disabled=true;button.textContent='Entwurf wird gespeichert …';}
 try{
  // Keine Pflichtfeldvalidierung: auch unvollständige Entwürfe müssen speicherbar sein.
  await draft.saveNow();
  skDialogSavedClose();
  await loadMyListings();
  return true;
 }catch(error){
  if(note)note.textContent='Entwurf konnte nicht gespeichert werden: '+error.message+' Deine Eingaben bleiben geöffnet.';
  return false;
 }finally{
  ownListingsBusy=false;skDialogState.saving=false;
  if(button?.isConnected){button.disabled=false;button.textContent='Entwurf speichern';}
 }
}
async function saveListing(){
  if(ownListingsBusy)return;
  const form=document.getElementById('listing-form');if(!form?.reportValidity())return;
  const from=listingFormField(form,'from').value,to=listingFormField(form,'to').value;
  if(to<from){listingFormField(form,'to').setCustomValidity('Das Bis-Datum muss am oder nach dem Von-Datum liegen.');form.reportValidity();listingFormField(form,'to').setCustomValidity('');return;}
  const payload={type:listingFormField(form,'type').value,category:listingFormField(form,'category').value,title:listingFormField(form,'title').value.trim(),description:listingFormField(form,'description').value.trim(),date_from:from,date_to:to,conditions:listingFormField(form,'conditions').value.trim(),accommodation:listingFormField(form,'accommodation').checked,languages:[...form.querySelectorAll('input[name="languages"]:checked')].map(e=>e.value)};
  const id=form.dataset.edit||null;const businessId=listingFormField(form,'business_id').value;
  const draftGuard=window.SK_DRAFTS?.current();try{await draftGuard?.requireEdit?.();}catch(error){const note=form.querySelector('.listing-save-error');if(note)note.textContent=error.message;return;}
 const button=document.getElementById('save-real-listing');button.disabled=true;button.textContent='Wird veröffentlicht …';ownListingsBusy=true;skDialogState.saving=true;
  try{await window.SK_AUTH.saveMyListing(payload,id,businessId);const draft=window.SK_DRAFTS?.current();if(draft){try{await draft.finish();}catch(draftErr){console.warn('[SK drafts] Entwurf nach Live-Speichern nicht bereinigt',draftErr);draft.abandon();}}skDialogSavedClose();await loadMyListings();}
  catch(error){button.disabled=false;button.textContent=id?(ownListings.find(l=>l.id===id)?.status==='Aktiv'?'Änderungen veröffentlichen':'Änderungen speichern'):'Veröffentlichen';const note=form.querySelector('.listing-save-error');if(note)note.textContent='Speichern fehlgeschlagen: '+error.message;}
  finally{ownListingsBusy=false;skDialogState.saving=false;}
}
function listingForm(id,preferredBusiness=null,restoreDraft=false,draftKey=null){
  const l=ownListings.find(x=>x.id===id);
  const today=skTodayCH();
  const dateFrom=l?.date_from||today,dateTo=l?.date_to||today;
  modal(l?'Inserat bearbeiten':'Neues Inserat',`<form id="listing-form" data-edit="${esc(l?.id||'')}"><label>Betrieb / Einsatzstandort *</label><select name="business_id" required ${l?"disabled":""}>${ownBusinessList.map(b=>`<option value="${esc(b.id)}" ${(l?.business_id||preferredBusiness||window.SK_SELECTED_BUSINESS||ownBusinessList[0]?.id)===b.id?"selected":""}>${esc(b.company_name)} · ${esc(b.city||"")}</option>`).join("")}</select><div class="field-grid"><div><label>Typ *</label><select name="type" required>${['Suche','Biete'].map(x=>`<option ${l?.type===x?'selected':''}>${x}</option>`).join('')}</select></div><div><label>Kategorie *</label><select name="category" required>${['Küche','Service','Housekeeping','Technik','Animation'].map(x=>`<option ${l?.category===x?'selected':''}>${x}</option>`).join('')}</select></div></div><p class="muted">Ort und Land werden automatisch aus dem freigegebenen Betriebsprofil übernommen.</p><label>Titel (5–80 Zeichen) *</label><input name="title" required minlength="5" maxlength="80" value="${esc(l?.title||'')}"><label>Beschreibung (20–1000 Zeichen) *</label><textarea name="description" required minlength="20" maxlength="1000" rows="3">${esc(l?.description||'')}</textarea><div class="field-grid"><div><label>Von *</label><input name="from" type="date" required value="${esc(dateFrom)}"></div><div><label>Bis *</label><input name="to" type="date" required value="${esc(dateTo)}"></div></div><label>Rahmenbedingungen (max. 500 Zeichen)</label><textarea name="conditions" maxlength="500" rows="2">${esc(l?.conditions||'')}</textarea><label class="check"><input type="checkbox" name="accommodation" ${l?.accommodation?'checked':''}><span>Unterkunft vorhanden</span></label><p class="muted">Sprachen: ${['DE','FR','IT','EN','ES'].map(x=>`<label class="inline-check"><input type="checkbox" name="languages" value="${x}" ${(l?.languages||['DE']).includes(x)?'checked':''}> ${x}</label>`).join(' ')}</p><p class="listing-save-error" role="alert"></p><div class="dialog-actions"><button type="button" class="subtle-btn" id="save-listing-draft">Entwurf speichern</button><button type="button" class="btn" id="save-real-listing">${l?(l.status==='Aktiv'?'Änderungen veröffentlichen':'Änderungen speichern'):'Veröffentlichen'}</button></div></form>`);
 const f=document.getElementById('listing-form');const bid=f?.elements.namedItem('business_id')?.value;
 // Jeder neue Entwurf bekommt eine eigene ID; alte new:<business_id>-Entwuerfe bleiben ueber die Liste erreichbar.
 if(bid)window.SK_DRAFTS?.attach(f,'listing',l?.id||draftKey||('new:'+crypto.randomUUID()),bid,{restore:restoreDraft?'automatic':'none'});
 if(!l)f?.elements.namedItem('business_id')?.addEventListener('change',async e=>{
  const select=e.currentTarget, next=select.value, current=window.SK_DRAFTS?.current();
  if(!next || !current || next===current.business)return;
  try{
   await current.flush();
   select.disabled=true;
   // A fresh form prevents form fields from business A being silently copied into business B.
   current.abandon();skDialogState.allowedClose=true;dialog.close();
   listingForm(null,next);
  }catch(err){select.value=current.business;const note=f.querySelector('.listing-save-error');if(note)note.textContent='Betriebswechsel nicht möglich: '+err.message+' – Entwurf nicht gesichert.';}
  finally{select.disabled=false;}
 });
}
document.getElementById('new-listing').addEventListener('click',()=>listingForm());
document.querySelectorAll('[data-list-tab]').forEach(b=>b.addEventListener('click',()=>{listTab=b.dataset.listTab;document.querySelectorAll('[data-list-tab]').forEach(x=>x.classList.toggle('active',x===b));renderMyListings()}));
function renderMyListings(){
  const root=document.getElementById('my-list-table');
  if(listTab==='partner'){root.innerHTML='<h2>Als Partner</h2><p class="muted">Partnerschaften werden in einer späteren Marktplatzphase angebunden.</p>';return;}
  const rows=listTab==='inserate'?ownListings.filter(x=>!['Vergeben','Abgeschlossen'].includes(x.status)):ownListings.filter(x=>['Vergeben','Abgeschlossen'].includes(x.status));
    const draftsMarkup=listTab==='inserate' && ownListingDrafts.length ?
   '<h3>Private Entwürfe (nicht veröffentlicht)</h3><div class="table-wrap"><table class="data-table"><thead><tr><th>Entwurf</th><th>Betrieb</th><th>Zuletzt gespeichert</th><th>Aktionen</th></tr></thead><tbody>'+
   ownListingDrafts.map(d=>{
     const business=ownBusinessList.find(b=>b.id===d.business_id);
     const title=String(d.payload?.title||'Unbenannter Entwurf').trim()||'Unbenannter Entwurf';
     const existing=(!String(d.draft_key).startsWith('new:'))?ownListings.find(l=>l.id===d.draft_key):null;
     return `<tr><td><strong>${esc(title)}</strong><small>${existing?'Änderungen an veröffentlichtem Inserat':'Neues Inserat · privat'}</small></td><td>${esc(business?.company_name||'Betrieb')}</td><td>${esc(new Date(d.updated_at).toLocaleString('de-CH'))}</td><td class="table-actions"><button type="button" data-draft="edit" data-key="${esc(d.draft_key)}" data-business="${esc(d.business_id)}">Bearbeiten</button><button type="button" data-draft="delete" data-key="${esc(d.draft_key)}" data-business="${esc(d.business_id)}">Verwerfen</button></td></tr>`;
   }).join('')+'</tbody></table></div>':'';
root.innerHTML='<h2>'+(listTab==='inserate'?'Eigene Inserate':'Vergebene Inserate')+'</h2><div class="table-wrap"><table class="data-table"><thead><tr><th>Inserat / Ort</th><th>Typ / Kategorie</th><th>Zeitraum</th><th>Status</th><th>Aktionen</th></tr></thead><tbody>'+rows.map(l=>`<tr><td><strong>${esc(l.title)}</strong><small>${esc(l.city)} · ${esc(l.country)}</small>${skChatIndex.some(t=>t.listing_id===l.id)?`<button type="button" class="sk-listing-chat-link" data-own="chats" data-id="${esc(l.id)}">${skChatIndex.filter(t=>t.listing_id===l.id).length} ${skChatIndex.filter(t=>t.listing_id===l.id).length===1?'Unterhaltung':'Unterhaltungen'} ansehen →</button>`:''}</td><td>${esc(l.type)} · ${esc(l.category)}</td><td>${esc(dateDisplay(l.date_from))} – ${esc(dateDisplay(l.date_to))}</td><td><span class="status-tag sk-list-status ${skListingEffectiveStatus(l)==='Aktiv'?'sk-list-status-active':skListingEffectiveStatus(l)==='Abgelaufen'?'sk-list-status-inactive':'sk-list-status-inactive'}">${esc(skListingEffectiveStatus(l))}</span></td><td class="table-actions sk-own-actions"><button type="button" class="sk-action-edit" data-own="edit" data-id="${esc(l.id)}" aria-label="Inserat bearbeiten" title="Inserat bearbeiten">✎</button><button type="button" class="sk-action-toggle" data-own="toggle" data-id="${esc(l.id)}" ${skListingEffectiveStatus(l)==='Abgelaufen'?'disabled':''} aria-label="${skListingEffectiveStatus(l)==='Abgelaufen'?'Zuerst Enddatum verlängern':l.status==='Aktiv'?'Inserat deaktivieren':'Inserat aktivieren'}" title="${skListingEffectiveStatus(l)==='Abgelaufen'?'Zuerst Enddatum verlängern':l.status==='Aktiv'?'Inserat deaktivieren':'Inserat aktivieren'}">↻</button><button type="button" class="sk-action-delete" data-own="delete" data-id="${esc(l.id)}" aria-label="Inserat dauerhaft löschen" title="Inserat dauerhaft löschen">✕</button></td></tr>`).join('')+'</tbody></table></div>'+(rows.length?'':'<p class="muted">Keine veröffentlichten Inserate in dieser Ansicht.</p>')+draftsMarkup;
}
document.getElementById('dialog-body').addEventListener('click',e=>{if(e.target.closest('#save-listing-draft')){void saveListingDraftAndClose();return;}if(e.target.closest('#save-real-listing'))void saveListing();});
document.getElementById('my-list-table').addEventListener('click',async e=>{
 const btn=e.target.closest('[data-draft]');if(!btn)return;
 const d=ownListingDrafts.find(x=>x.draft_key===btn.dataset.key&&x.business_id===btn.dataset.business);
 if(!d)return;
 if(btn.dataset.draft==='delete'){
  if(!confirm('Diesen privaten Entwurf dauerhaft verwerfen? Ein veröffentlichtes Inserat bleibt unverändert.'))return;
  btn.disabled=true;
  try{await window.SK_AUTH.discardFormDraft('listing',d.draft_key,d.business_id,Number(d.revision));await loadMyListings();}
  catch(err){alert('Entwurf konnte nicht verworfen werden: '+err.message);btn.disabled=false;}
 }else{
  const existing=ownListings.find(l=>l.id===d.draft_key);
  if(existing)listingForm(existing.id,null,true);
  else listingForm(null,d.business_id,true,d.draft_key);
 }
});
document.getElementById('my-list-table').addEventListener('click',async e=>{
  const b=e.target.closest('[data-own]');if(!b||ownListingsBusy)return;
  const id=b.dataset.id,l=ownListings.find(x=>x.id===id);if(!l)return;
  if(b.dataset.own==='chats'){await skOpenListingChats(id);return;}
  if(b.dataset.own==='edit'){listingForm(id);return;}
  if(b.dataset.own==='toggle'&&skListingEffectiveStatus(l)==='Abgelaufen'){alert('Inserat abgelaufen: Bitte zuerst das Enddatum verlängern und speichern.');return;}
  if(b.dataset.own==='delete'&&!confirm('Dieses Inserat dauerhaft löschen?'))return;
  ownListingsBusy=true;b.disabled=true;
  try{
    if(b.dataset.own==='toggle')await window.SK_AUTH.setMyListingStatus(id,l.status==='Aktiv'?'Inaktiv':'Aktiv',l.business_id);
    else if(b.dataset.own==='delete')await window.SK_AUTH.deleteMyListing(id,l.business_id);
    await loadMyListings();
  }catch(error){alert('Aktion fehlgeschlagen: '+error.message);b.disabled=false;}
  finally{ownListingsBusy=false;}
});
let selectedChatId=null, chatThreads=[], chatBusy=false, skChatFilterBusinessId="", skChatListingFilterId=null;
let skChatSnapshot='',skChatRefreshing=false,skChatRenderVersion=0;
const skChatThreadsKey=threads=>JSON.stringify((threads||[]).map(t=>[t.id,t.listing_title,t.own_business_id,t.other_business_name,t.last_message_at]));
const skChatMessagesKey=messages=>JSON.stringify((messages||[]).map(m=>[m.id,m.body,m.sender_business_id,m.created_at]));

const chatStatus=()=>document.getElementById('chat-status');
async function renderChats(preselect=null){
 const renderVersion=++skChatRenderVersion;
 const list=document.getElementById('conversation-buttons'),historyBox=document.getElementById('chat-history'),heading=document.getElementById('chat-heading');
 chatStatus().textContent='Unterhaltungen werden geladen …';
 try{
  chatThreads=await window.SK_AUTH.chatThreads();
  if(renderVersion!==skChatRenderVersion||currentScreen!=='messages')return;
  if(preselect)selectedChatId=preselect;
  const filter=document.getElementById('chat-own-business-filter');
  let names=[];try{names=await window.SK_AUTH.listApprovedBusinesses();}catch(_error){}
  const nameById=new Map(names.map(b=>[b.id,b.company_name||'Betrieb']));
  const choices=[...new Map(chatThreads.map(t=>[t.own_business_id,nameById.get(t.own_business_id)||'Mein Betrieb'])).entries()];
  filter.innerHTML='<option value="">Alle meine Betriebe</option>'+choices.map(([id,name])=>`<option value="${esc(id)}">${esc(name)}</option>`).join('');
  if(skChatFilterBusinessId && !choices.some(([id])=>id===skChatFilterBusinessId))skChatFilterBusinessId='';
  filter.value=skChatFilterBusinessId;
  const visible=chatThreads.filter(t=>(!skChatFilterBusinessId||t.own_business_id===skChatFilterBusinessId)&&(!skChatListingFilterId||t.listing_id===skChatListingFilterId));
  const clear=document.getElementById('chat-clear-listing-filter');
  clear.classList.toggle('hidden',!skChatListingFilterId);
  if(!visible.some(t=>t.id===selectedChatId))selectedChatId=visible[0]?.id||null;
  list.innerHTML=visible.length?visible.map(t=>`<button type="button" class="conversation-btn ${t.id===selectedChatId?'active':''}" data-chat="${esc(t.id)}"><strong>${esc(t.listing_title||'Inserat')}</strong><small>${esc(t.other_business_name||'Betrieb')}</small></button>`).join(''):'<p class="muted">Keine Unterhaltungen für diese Auswahl vorhanden.</p>';
  const thread=visible.find(t=>t.id===selectedChatId);
  heading.innerHTML=thread?`<strong>${esc(thread.listing_title||'Inserat')}</strong><small>${esc(thread.other_business_name||'Betrieb')}</small><button type="button" class="sk-chat-listing-link" data-chat-listing="${esc(thread.listing_id)}">Zum Inserat →</button>`:'<strong>Unterhaltung auswählen</strong>';
  document.getElementById('chat-form').classList.toggle('hidden',!thread);
  historyBox.innerHTML=thread?'<p class="muted">Nachrichten werden geladen …</p>':'';
  if(thread){const messages=await window.SK_AUTH.chatMessages(thread.id);if(renderVersion===skChatRenderVersion&&currentScreen==='messages'&&selectedChatId===thread.id){historyBox.innerHTML=messages.map(m=>`<div class="bubble ${m.sender_business_id===thread.own_business_id?'mine':'other'}">${esc(m.body)}<small style="display:block;opacity:.7">${esc(new Date(m.created_at).toLocaleString('de-CH'))}</small></div>`).join('')||'<p class="muted">Noch keine Nachrichten.</p>';historyBox.scrollTop=historyBox.scrollHeight;skChatSnapshot=skChatThreadsKey(chatThreads)+'|'+thread.id+'|'+skChatMessagesKey(messages);}}
  else skChatSnapshot=skChatThreadsKey(chatThreads)+'|';
  if(renderVersion===skChatRenderVersion)chatStatus().textContent='';
 }catch(e){chatStatus().textContent='Unterhaltungen konnten nicht geladen werden: '+e.message;historyBox.innerHTML='';}
}
// Aktualisierung ohne manuelles Neuladen: nur solange der Nachrichtenbereich sichtbar ist.
// Lesen erfolgt ausschliesslich über die bestehenden, berechtigungsgeschützten RPCs.
async function skChatCheckUpdates(){
 if(currentScreen!=='messages'||document.hidden||chatBusy||skChatRefreshing||!window.SK_AUTH)return;
 skChatRefreshing=true;
 const inspectedThread=selectedChatId;
 try{
  const threads=await window.SK_AUTH.chatThreads();
  const active=threads.find(t=>t.id===inspectedThread);
  const messages=active?await window.SK_AUTH.chatMessages(inspectedThread):[];
  if(currentScreen!=='messages'||document.hidden||selectedChatId!==inspectedThread)return;
  const signature=skChatThreadsKey(threads)+'|'+(active?inspectedThread+'|'+skChatMessagesKey(messages):'');
  if(signature!==skChatSnapshot)await renderChats();
 }catch(error){
  // Bei Verbindungsproblemen bleibt die bisherige Unterhaltung erhalten.
  const status=chatStatus();if(status&&currentScreen==='messages')status.textContent='Automatische Aktualisierung vorübergehend nicht möglich: '+error.message;
 }finally{skChatRefreshing=false;}
}
setInterval(()=>{void skChatCheckUpdates();},2000);
document.addEventListener('visibilitychange',()=>{if(!document.hidden)void skChatCheckUpdates();});
// Direkt aus der Unterhaltung zum zugehörigen Inserat wechseln.
// Das Inserat wird nur geöffnet, wenn es im berechtigten Marktplatz abrufbar ist.
document.getElementById('chat-heading').addEventListener('click',async e=>{
 const button=e.target.closest('[data-chat-listing]');if(!button)return;
 const id=button.dataset.chatListing;
 if(!id)return;
 button.disabled=true;
 try{
  let listing=marketplaceListings.find(l=>l.id===id);
  if(!listing){
   const latest=await window.SK_AUTH.listMarketplaceListings();
   marketplaceListings=latest;
   listing=latest.find(l=>l.id===id);
  }
  if(!listing){chatStatus().textContent='Dieses Inserat ist aktuell nicht im Marktplatz verfügbar.';return;}
  await show('detail');
  if(currentScreen==='detail')openDetail(id);
 }catch(error){chatStatus().textContent='Inserat konnte nicht geöffnet werden: '+(error?.message||'Unbekannter Fehler');}
 finally{button.disabled=false;}
});
document.getElementById('chat-clear-listing-filter').addEventListener('click',()=>{skChatListingFilterId=null;void renderChats();});
document.getElementById('chat-own-business-filter').addEventListener('change',e=>{skChatFilterBusinessId=e.target.value;selectedChatId=null;void renderChats();});
document.getElementById('conversation-buttons').addEventListener('click',e=>{const b=e.target.closest('[data-chat]');if(b){selectedChatId=b.dataset.chat;void renderChats();}});
document.getElementById('chat-form').addEventListener('submit',async e=>{
 e.preventDefault();if(chatBusy)return;const t=chatThreads.find(x=>x.id===selectedChatId),field=document.getElementById('chat-entry');if(!t||!field.value.trim())return;
 chatBusy=true;try{await window.SK_AUTH.chatSend(t.id,t.own_business_id,field.value.trim());field.value='';await renderChats(t.id);}catch(error){chatStatus().textContent='Nachricht konnte nicht gesendet werden: '+error.message;}finally{chatBusy=false;}
});
// Kontaktaufnahme direkt in der Inseratseite statt über Browser-Pop-ups.
let skContactListingId=null,skContactBusy=false;
const contactForm=document.getElementById('detail-contact-form');
const contactStatus=document.getElementById('detail-contact-status');
document.getElementById('detail-contact-cancel').addEventListener('click',()=>{contactForm.classList.add('hidden');contactStatus.textContent='';});
document.getElementById('detail-contact').addEventListener('click',async ()=>{
 const id=document.getElementById('detail-contact').dataset.listingId;
 if(document.getElementById('detail-contact').dataset.existingChat==='1'){await skOpenListingChats(id);return;}
 contactStatus.textContent='Betriebe werden geladen …';contactForm.classList.remove('hidden');
 let businesses;try{businesses=await window.SK_AUTH.listApprovedBusinesses();}catch(e){contactStatus.textContent='Betriebe konnten nicht geladen werden: '+e.message;return;}
 const listing=marketplaceListings.find(l=>l.id===id);
 const own=businesses.filter(b=>b.id!==listing?.business_id);
 if(!own.length){contactStatus.textContent='Für dieses Inserat ist kein eigener freigegebener Betrieb verfügbar.';return;}
 skContactListingId=id;
 const select=document.getElementById('detail-contact-business');
 select.replaceChildren();
 for(const business of own){const option=document.createElement('option');option.value=business.id;option.textContent=business.company_name||'Betrieb';select.append(option);}
 document.getElementById('detail-contact-business-wrap').classList.toggle('hidden',own.length===1);
 contactStatus.textContent='';document.getElementById('detail-contact-message').focus();
});
contactForm.addEventListener('submit',async e=>{
 e.preventDefault();if(skContactBusy||!skContactListingId)return;
 const selected=document.getElementById('detail-contact-business').value;
 const body=document.getElementById('detail-contact-message').value.trim();
 if(!selected||!body)return;
 skContactBusy=true;document.getElementById('detail-contact-submit').disabled=true;
 contactStatus.textContent='Nachricht wird gesendet …';
 try{const threadId=await window.SK_AUTH.chatStart(skContactListingId,selected,body);selectedChatId=threadId;skChatFilterBusinessId='';contactForm.reset();contactForm.classList.add('hidden');await show('messages');await renderChats(threadId);}
 catch(error){contactStatus.textContent='Kontaktaufnahme fehlgeschlagen: '+error.message;}
 finally{skContactBusy=false;document.getElementById('detail-contact-submit').disabled=false;}
});
const companies=[{name:'Alpenhotel Panorama',land:'Schweiz',status:'Ausstehend'},{name:'Restaurant Seeblick',land:'Schweiz',status:'Ausstehend'},{name:'Camping am Park',land:'Deutschland',status:'Aktiv'},{name:'Hotel Tirol',land:'Österreich',status:'Aktiv'}];
let skBusinessList=[];
let skSelectedBusiness=null;
// Dates are stored as YYYY-MM-DD; presentation is always dd.mm.yyyy.
// Do not parse date-only values using Date(): timezone shifts can change the day.
const dateDisplay=d=>{
  const raw=String(d||'');
  const match=/^(\d{4})-(\d{2})-(\d{2})$/.exec(raw);
  return match?`${match[3]}.${match[2]}.${match[1]}`:(raw||'–');
};
const dateTimeDisplay=d=>d?new Intl.DateTimeFormat('de-CH',{day:'2-digit',month:'2-digit',year:'numeric',hour:'2-digit',minute:'2-digit',hourCycle:'h23'}).format(new Date(d)):'–';
const valueOrDash=v=>v===null||v===undefined||v===''?'–':String(v);
const businessReviewLabel={draft:'Entwurf',submitted:'Eingereicht',changes_requested:'Nachbesserung',approved:'Freigegeben',rejected:'Abgelehnt'};
function businessStatusBadge(value){
 const kind=value==='Freigeschaltet'?'good':value==='Gesperrt'?'bad':'wait';
 const symbol=kind==='good'?'✓':kind==='bad'?'✕':'◷';
 return `<span class="sk-business-badge sk-business-badge--${kind}"><span aria-hidden="true">${symbol}</span>${esc(value||'Unbekannt')}</span>`;
}
function businessReviewBadge(c){
 const key=c.review_state||'';
 const kind=key==='approved'?'good':key==='changes_requested'?'bad':key==='submitted'?'wait':'neutral';
 const label=businessReviewLabel[key]||'Nicht erfasst';
 const date=key==='approved'?c.reviewed_at:key==='submitted'?c.submitted_at:null;
 const dateLabel=key==='approved'?'Freigegeben am':key==='submitted'?'Eingereicht am':null;
 return `<div class="sk-review-status"><span class="sk-business-badge sk-business-badge--${kind}"><span aria-hidden="true">${kind==='good'?'✓':kind==='bad'?'!':'◷'}</span>${esc(label)}</span>${dateLabel?`<small>${dateLabel}: ${date?esc(dateTimeDisplay(date)):'Datum nicht erfasst'}</small>`:''}</div>`;
}
function drawBusinessRows(){
 const table=document.getElementById('admin-business-rows');
 const counter=document.getElementById('admin-business-count');
 if(!table)return;
 const input=document.getElementById('admin-business-search');
 const query=(input?.value||'').normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLocaleLowerCase('de-CH').trim();
 const visible=skBusinessList.filter(c=>[c.company_name,c.country,c.postal_code,c.city,c.status,businessReviewLabel[c.review_state]||c.review_state].join(' ').normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLocaleLowerCase('de-CH').includes(query));
 counter.textContent=`${visible.length} von ${skBusinessList.length} Betrieben`;
 table.innerHTML=visible.length?visible.map(c=>`<tr><td><strong>${esc(c.company_name||'–')}</strong></td><td>${esc(c.country||'–')}</td><td>${esc([c.postal_code,c.city].filter(Boolean).join(' ')||'–')}</td><td>${businessStatusBadge(c.status)}</td><td>${businessReviewBadge(c)}</td><td class="sk-table-date">${esc(dateTimeDisplay(c.updated_at))}</td><td><button class="subtle-btn" type="button" data-review-business="${esc(c.id)}">Details / Prüfen</button></td></tr>`).join(''):'<tr><td colspan="7" class="sk-business-empty">Keine passenden Betriebe gefunden.</td></tr>';
}
function renderBusinesses(){
 const root=document.getElementById('admin-business-table');
 if(!skAdmin){root.textContent='Nur für Administratoren.';return;}
 if(!window.SK_AUTH){root.textContent='Supabase-Verbindung wird geladen …';return;}
 root.textContent='Unternehmen werden geladen …';
 window.SK_AUTH.loadBusinesses().then(rows=>{
  skBusinessList=rows;
  root.innerHTML=`<div class="sk-business-tools"><label for="admin-business-search">Betriebe suchen</label><input id="admin-business-search" type="search" placeholder="Name, PLZ, Ort, Land oder Status …" autocomplete="off"><span id="admin-business-count" class="muted" role="status"></span></div><div class="table-wrap"><table class="data-table sk-business-table"><thead><tr><th>Betrieb</th><th>Land</th><th>PLZ / Ort</th><th>Zugangsstatus</th><th>Registrierungsprüfung</th><th>Letzte Änderung</th><th>Prüfung</th></tr></thead><tbody id="admin-business-rows"></tbody></table></div>`;
  root.querySelector('#admin-business-search').addEventListener('input',drawBusinessRows);
  drawBusinessRows();
 }).catch(e=>root.textContent='Laden fehlgeschlagen: '+e.message);
}
function detailsRow(label,value){return `<div class="business-info-row"><dt>${esc(label)}</dt><dd>${esc(valueOrDash(value))}</dd></div>`;}
async function openBusinessReview(id){
 if(!skAdmin||!window.SK_AUTH)return;
 skSelectedBusiness=id;
 const panel=document.getElementById('business-review-panel');
 panel.classList.remove('hidden');panel.textContent='Unternehmensdetails werden geladen …';
 panel.scrollIntoView({behavior:'smooth',block:'start'});
 try{
   const info=await window.SK_AUTH.getBusinessDetails(id);
   if(skSelectedBusiness!==id)return;
   const b=info.business; const notes=info.notes||[], audit=info.audit||[], members=info.members||[];
   panel.innerHTML=`<div class="business-review-heading"><div><span class="overline">ADMIN · BETRIEBSPRÜFUNG</span><h2>${esc(b.company_name)}</h2><span class="status-tag">${esc(b.status)}</span></div><button type="button" class="subtle-btn" id="business-review-close">Schliessen</button></div>
   <div class="business-review-grid"><section><h3>Unternehmensangaben</h3><dl class="business-info">${detailsRow('Firmenname',b.company_name)}${detailsRow('Branche',b.industry)}${detailsRow('Land',b.country)}${detailsRow('PLZ / Ort',[b.postal_code,b.city].filter(Boolean).join(' '))}${detailsRow('Strasse / Hausnummer',[b.street,b.house_number].filter(Boolean).join(' '))}${detailsRow('Adresszusatz',b.address_extra)}${detailsRow('Strassenadresse öffentlich',b.show_street_address?'Ja':'Nein')}${detailsRow('USt-/UID-Nr.',b.vat_id)}${detailsRow('Beschreibung',b.description)}${detailsRow('Prüfstatus',b.review_state)}${detailsRow('Eingereicht',dateTimeDisplay(b.submitted_at))}${detailsRow('Nachbesserungsgrund',b.review_message)}${detailsRow('E-Mail-Benachrichtigungen',b.email_notifications_enabled?'Ja':'Nein')}${detailsRow('Registriert',dateTimeDisplay(b.created_at))}${detailsRow('Nutzungsbedingungen bestätigt',dateTimeDisplay(b.terms_accepted_at))}</dl></section>
   <section><h3>Kontakt &amp; Benutzer</h3><dl class="business-info">${detailsRow('Kontaktperson',b.contact_name)}${detailsRow('E-Mail',b.contact_email)}${detailsRow('Telefon',b.contact_phone)}</dl><div class="business-contact-actions"><a class="subtle-btn" href="mailto:${encodeURIComponent(b.contact_email||'')}">E-Mail schreiben ↗</a>${b.contact_phone?`<a class="subtle-btn" href="tel:${encodeURIComponent(b.contact_phone)}">Anrufen ↗</a>`:''}</div><h4>Konten</h4>${members.length?members.map(m=>`<p class="business-minor">${esc(m.email)} · ${esc(m.role)}</p>`).join(''):'<p class="muted">Keine Benutzerzuordnung</p>'}</section></div>
   <section class="business-review-media"><h3>Standort des Betriebs</h3><div id="business-admin-map" class="business-map" role="region" aria-label="Standortkarte des Betriebs"></div><p id="business-admin-map-status" class="muted"></p></section><section class="business-review-media"><h3>Firmenlogo und Betriebsbilder</h3><div id="business-admin-media" class="admin-media-preview">Medien werden geladen …</div></section>
   <div class="business-review-grid"><section><h3>Interne Admin-Notizen</h3><p class="muted">Nur für Administratoren. Einträge werden mit Datum und Autor protokolliert.</p><form id="business-note-form"><label for="business-note">Neue Notiz</label><textarea id="business-note" rows="3" maxlength="3000" required placeholder="Rückfrage, Gesprächsnotiz, Prüfergebnis …"></textarea><button class="btn btn-small" type="submit">Notiz speichern</button><p class="form-feedback" id="business-note-status" role="status"></p></form><div class="business-events">${notes.length?notes.map(n=>`<article><small>${esc(dateTimeDisplay(n.created_at))} · ${esc(n.author)}</small><p>${esc(n.note)}</p></article>`).join(''):'<p class="muted">Noch keine Notizen.</p>'}</div></section>
   <section><h3>Freigabehistorie</h3><div class="business-events">${audit.length?audit.map(a=>`<article><small>${esc(dateTimeDisplay(a.changed_at))} · ${esc(a.changed_by)}</small><p>${esc(a.old_status)} → ${esc(a.new_status)}</p></article>`).join(''):'<p class="muted">Noch keine Statusänderungen.</p>'}</div></section></div>
   <div class="business-review-actions">${b.status==='Ausstehend'&&b.review_state==='submitted'?'<button type="button" class="btn" data-review-action="approve">Eingereichten Betrieb freigeben</button><button type="button" class="subtle-btn" data-review-action="changes">Nachbesserung verlangen</button><button type="button" class="subtle-btn" data-review-action="reject">Antrag ablehnen</button>':''}<button type="button" class="subtle-btn" data-review-status="Gesperrt">Betrieb sperren</button><p class="form-feedback" role="status" id="business-review-status"></p></div>`;
   loadAdminBusinessMedia(id);
   void window.SK_LOCATION?.showAdmin(b);
   document.getElementById('business-review-close').addEventListener('click',()=>{skSelectedBusiness=null;panel.classList.add('hidden');});
   document.getElementById('business-note-form').addEventListener('submit',async e=>{
     e.preventDefault(); const note=document.getElementById('business-note').value.trim();if(!note)return;
     const submit=e.currentTarget.querySelector('button');submit.disabled=true;
     try{await window.SK_AUTH.addBusinessNote(id,note);await openBusinessReview(id);}
     catch(err){document.getElementById('business-note-status').textContent='Notiz konnte nicht gespeichert werden: '+err.message;submit.disabled=false;}
   });
 }catch(err){panel.textContent='Details konnten nicht geladen werden: '+err.message+' (Ist die SQL-Migration 0.24 ausgeführt?)';}
}
async function loadAdminBusinessMedia(id){
 const root=document.getElementById('business-admin-media');if(!root)return;
 try{
  const media=await window.SK_AUTH.listBusinessMedia(id);
  if(skSelectedBusiness!==id)return;
  root.replaceChildren();
  const all=[...media.logo,...media.photos];
  if(!all.length){root.textContent='Noch keine Medien hinterlegt.';return;}
  for(const item of all){const im=document.createElement('img');im.src=item.url;im.alt=item.name.startsWith('logo.')?'Firmenlogo':'Betriebsbild '+item.name.split('.')[0];im.loading='lazy';root.append(im);}
 }catch(err){root.textContent='Medien konnten nicht geladen werden: '+err.message;}
}
document.getElementById('business-review-panel').addEventListener('click',async e=>{
 const button=e.target.closest('[data-review-action]');if(!button||!skSelectedBusiness)return;
 const action=button.dataset.reviewAction;
 const message=['changes','reject'].includes(action)?prompt(action==='changes'?'Welche Angaben soll der Betrieb nachbessern?':'Begründung der Ablehnung (mindestens 5 Zeichen):'):null;
 if(['changes','reject'].includes(action)&&(message===null||message.trim().length<5))return;
 if(action==='approve'&&!confirm('Vollständigen Betriebsantrag verbindlich freigeben?'))return;
 if(action==='reject'&&!confirm('Den Antrag wirklich ablehnen? Der Betrieb erhält eine E-Mail mit der Begründung.'))return;
 button.disabled=true;
 try{await window.SK_AUTH.reviewBusiness(skSelectedBusiness,action,message);renderBusinesses();await openBusinessReview(skSelectedBusiness);window.SK_ADMIN_HOME?.refresh();}
 catch(err){document.getElementById('business-review-status').textContent='Prüfung fehlgeschlagen: '+err.message;button.disabled=false;}
});
document.getElementById('admin-business-table').addEventListener('click',e=>{
 const button=e.target.closest('[data-review-business]');if(button)openBusinessReview(button.dataset.reviewBusiness);
});
document.getElementById('business-review-panel').addEventListener('click',async e=>{
 const button=e.target.closest('[data-review-status]');
 if(!button||!skSelectedBusiness||!skAdmin||!window.SK_AUTH)return;
 const id=skSelectedBusiness,status=button.dataset.reviewStatus;
 if(!confirm('Unternehmen wirklich auf '+status+' setzen?'))return;
 button.disabled=true;
 try{await window.SK_AUTH.setBusinessStatus(id,status);renderBusinesses();await openBusinessReview(id);}
 catch(err){document.getElementById('business-review-status').textContent='Statusänderung fehlgeschlagen: '+err.message;button.disabled=false;}
});
window.SK_ADMIN_UI={openBusinessReview};
function renderAdminListings(){const country=document.getElementById('admin-country').value,status=document.getElementById('admin-status').value;const filtered=listings.filter(l=>(!country||l.country===country)&&(!status||listingStatus.get(l.id)===status));document.getElementById('admin-listing-table').innerHTML='<div class="table-wrap"><table class="data-table"><thead><tr><th>Inserat</th><th>Land</th><th>Status</th><th>Aktionen</th></tr></thead><tbody>'+filtered.map(l=>`<tr><td>${esc(l.title)}</td><td>${esc(l.country)}</td><td><span class="status-tag">${esc(listingStatus.get(l.id))}</span></td><td class="table-actions"><button data-moderate="${l.id}" data-action="edit">Bearbeiten</button><button data-moderate="${l.id}" data-action="toggle">${listingStatus.get(l.id)==='Aktiv'?'Sperren':'Aktivieren'}</button></td></tr>`).join('')+'</tbody></table></div>';}
document.getElementById('admin-listing-table').addEventListener('click',e=>{const b=e.target.closest('[data-moderate]');if(!b)return;const id=Number(b.dataset.moderate);if(b.dataset.action==='toggle'){listingStatus.set(id,listingStatus.get(id)==='Aktiv'?'Gesperrt':'Aktiv');renderAdminListings()}else{const l=listings.find(x=>x.id===id);modal('Inserat prüfen','<p><strong>'+esc(l.title)+'</strong></p><p>'+esc(l.desc)+'</p><p class="muted">Bearbeitung und dauerhafte Löschung folgen mit Backend und Berechtigungsprüfung.</p>')}});
['admin-country','admin-status'].forEach(id=>document.getElementById(id).addEventListener('change',renderAdminListings));
show('login',false);

/* 0.27 – Dokumentation wird ausschliesslich aus der geschützten Admin-Datenbank gelesen. */
function renderProjectDocs(){window.SK_DOCS?.load();}
