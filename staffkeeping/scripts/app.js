/* StaffKeeping 0.33.1.1 – profile subnavigation and protected business views */
'use strict';
const screens=['login','register','reset','pending','market','profile','account','my-listings','my-businesses','detail','messages','reviews','admin-businesses','admin-listings','admin-dashboard','admin-docs','admin-home','admin-activity','admin-deletions','help'];
const navOnly=document.querySelectorAll('.nav-only'), guests=document.querySelectorAll('.guest-only');
const publicViews=new Set(['login','register','reset','pending','help']);
let demoSignedIn=false;
let skAdmin=false;
let skPending=false;let skCanProfile=false;let skCanTrade=false;
window.SK_UI={setAccess(isApproved,isAdmin,reviewState,canTrade=false){demoSignedIn=!!isApproved;skAdmin=!!isAdmin;skCanTrade=!!canTrade;skPending=!isApproved;skCanProfile=!!reviewState;performShow(isAdmin?'admin-home':isApproved?'market':(reviewState==='draft'||reviewState==='changes_requested')?'profile':'pending',false);},show,logoutView(){demoSignedIn=false;skAdmin=false;skPending=false;skCanProfile=false;skCanTrade=false;performShow('login',false);}};
let currentScreen='login', navigationBusy=false;
async function show(view,updateUrl=true){
  if(navigationBusy)return;
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
  if(!skAdmin && view.startsWith('admin-'))view=demoSignedIn?'market':skCanProfile?'profile':'login';
  if(!skCanTrade && ['my-listings','my-businesses','messages','reviews'].includes(view))view=skAdmin?'market':skCanProfile?'profile':'login';
  if(demoSignedIn && view==='login')view='market';
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
function openDetail(id){
  const l=marketplaceListings.find(x=>x.id===id);if(!l)return;
  document.getElementById('detail-title').textContent=l.title;
  document.getElementById('detail-subtitle').textContent=`${l.city} · ${l.country} · ${marketplaceDate(l.date_from)} – ${marketplaceDate(l.date_to)}`;
  document.getElementById('detail-meta').innerHTML=`<span class="status-tag">${esc(marketplaceType(l.type))}</span> <span class="status-tag">${esc(l.category)}</span>`;
  document.getElementById('detail-description').textContent=l.description;
  document.getElementById('detail-conditions').textContent=l.conditions||'Keine zusätzlichen Rahmenbedingungen angegeben.';
  document.getElementById('detail-features').innerHTML=`${l.accommodation?'<span class="status-tag">Unterkunft vorhanden</span>':'<span class="status-tag">Keine Unterkunft angegeben</span>'} ${(l.languages||[]).map(x=>`<span class="status-tag">${esc(x)}</span>`).join(' ')}`;
  document.getElementById('detail-company').textContent='Betrieb in '+l.city;
  document.getElementById('detail-contact').disabled=true;
  document.getElementById('detail-contact').textContent='Kontaktaufnahme ab 0.32.3';
  show('detail');
}
['filter-search','filter-type','filter-branch','filter-date','filter-accommodation','filter-radius'].forEach(id=>document.getElementById(id).addEventListener('input',render));
document.getElementById('filter-reset').addEventListener('click',()=>{['filter-search','filter-type','filter-branch','filter-date'].forEach(id=>document.getElementById(id).value='');document.getElementById('filter-radius').selectedIndex=0;document.getElementById('filter-accommodation').checked=false;favoritesOnly=false;document.getElementById('bookmarks-only').classList.remove('selected');render()});
document.getElementById('bookmarks-only').addEventListener('click',e=>{favoritesOnly=!favoritesOnly;e.currentTarget.classList.toggle('selected',favoritesOnly);render()});
function setView(map){if(map)return;viewMap=false;document.getElementById('list-btn').classList.add('active');render();}
document.getElementById('list-btn').addEventListener('click',()=>setView(false));
/* Zusätzliche UI-Demoseiten, ohne Backend und ohne dauerhafte Speicherung */
const dialog=document.getElementById('app-dialog');
function modal(title,html){document.getElementById('dialog-title').textContent=title;document.getElementById('dialog-body').innerHTML=html;dialog.showModal();}

async function loadMyBusinesses(){
 const root=document.getElementById('my-businesses-list');root.textContent='Betriebe werden geladen …';
 try{const rows=await window.SK_AUTH.listMyBusinesses();root.innerHTML=rows.length?rows.map(b=>`<div class="panel" style="margin:0 0 12px"><strong>${esc(b.company_name)}</strong><p>${esc(b.city)} · ${esc(b.country)} · ${esc(b.status)} / ${esc(b.review_state||'–')}</p><small>${b.status==='Freigeschaltet'?'Für Marktplatz freigegeben':'Annette muss diesen Betrieb separat freigeben; keine automatische Abo-Zuordnung.'}</small>${rows.length===1?'<p><button class="subtle-btn" data-view="profile">Betriebsprofil bearbeiten</button></p>':'<p><small>Einzelne Betriebsprofile bearbeiten: folgt nach der eindeutigen Betriebs-ID-Anbindung.</small></p>'}${b.review_state==='changes_requested'?`<p role="alert">Nachbesserung: ${esc(b.review_message||'Bitte Angaben ergänzen')}</p><button class="subtle-btn" data-rework-business="${esc(b.id)}">Nachbessern und erneut einreichen</button>`:''}</div>`).join(''):'<p>Keine Betriebe zugeordnet.</p>';}
 catch(e){root.textContent='Betriebe konnten nicht geladen werden: '+e.message;}
}
document.getElementById('my-businesses-list').addEventListener('click',async e=>{
 const btn=e.target.closest('[data-rework-business]');if(!btn)return;
 const businesses=await window.SK_AUTH.listMyBusinesses();const b=businesses.find(x=>x.id===btn.dataset.reworkBusiness);
 if(!b||b.review_state!=='changes_requested')return;
 modal('Nachbesserung für '+b.company_name,`<form id="sk-rework-business-form" data-business="${esc(b.id)}"><p>Änderungsgrund von Annette: ${esc(b.review_message||'Keine Details')}</p><label>Kontaktperson *</label><input name="contact_name" required minlength="2" value="${esc(b.contact_name||'')}"><label>Telefon *</label><input name="contact_phone" required minlength="5" value="${esc(b.contact_phone||'')}"><label>Beschreibung *</label><textarea name="description" required minlength="30" maxlength="1000">${esc(b.description||'')}</textarea><p id="sk-rework-error" role="alert"></p><button class="btn" type="submit">Erneut einreichen</button></form>`);
});
document.getElementById('dialog-body').addEventListener('submit',async e=>{
 const form=e.target;if(form.id!=='sk-rework-business-form')return;e.preventDefault();if(!form.reportValidity())return;const btn=form.querySelector('[type="submit"]');btn.disabled=true;
 try{await window.SK_AUTH.resubmitAdditionalBusiness(form.dataset.business,form.elements.namedItem('description').value,form.elements.namedItem('contact_phone').value,form.elements.namedItem('contact_name').value);dialog.close();await loadMyBusinesses();}
 catch(err){document.getElementById('sk-rework-error').textContent=err.message;btn.disabled=false;}
});
document.getElementById('add-business-button').addEventListener('click',()=>{
 modal('Weiteren Betrieb beantragen',`<form id="sk-extra-business-form">
 <p>Der neue Betrieb wird unabhängig geprüft. Er erhält kein automatisch gemeinsames Abonnement.</p>
 <label>Firmenname *</label><input name="company_name" required minlength="2" maxlength="160">
 <label>UID / USt-ID *</label><input name="vat_id" required minlength="2" maxlength="64">
 <label>Branche *</label><select name="industry" required><option value="">Bitte wählen</option><option value="Hotel">Hotellerie</option><option value="Gastro">Gastronomie</option><option value="Camping">Camping</option></select>
 <label>Land *</label><select name="country" required><option value="">Bitte wählen</option><option value="CH">Schweiz</option><option value="DE">Deutschland</option><option value="AT">Österreich</option></select>
 <div class="field-grid"><div><label>PLZ *</label><input name="postal_code" required minlength="2" maxlength="16"></div><div><label>Ort *</label><input name="city" required minlength="2" maxlength="120"></div></div>
 <label>Kontaktperson *</label><input name="contact_name" required minlength="2" maxlength="160">
 <label>Telefon *</label><input name="contact_phone" required minlength="5" maxlength="60"><label>Beschreibung des Betriebs *</label><textarea name="description" required minlength="30" maxlength="1000"></textarea>
 <label class="check"><input type="checkbox" name="terms" required><span>Ich akzeptiere die geltenden Nutzungsbedingungen auch für diesen Betrieb.</span></label>
 <p id="sk-extra-business-error" role="alert"></p><button class="btn" type="submit">Betrieb zur Prüfung erfassen</button></form>`);
});
document.getElementById('dialog-body').addEventListener('submit',async e=>{
 const form=e.target;if(form.id!=='sk-extra-business-form')return;e.preventDefault();
 if(!form.reportValidity())return;
 const get=k=>form.elements.namedItem(k).value.trim(),btn=form.querySelector('[type="submit"]');btn.disabled=true;
 try{await window.SK_AUTH.addAdditionalBusiness({p_company_name:get('company_name'),p_vat_id:get('vat_id'),p_industry:get('industry'),p_country:get('country'),p_postal_code:get('postal_code'),p_city:get('city'),p_contact_name:get('contact_name'),p_contact_phone:get('contact_phone'),p_description:get('description')});dialog.close();await loadMyBusinesses();alert('Betrieb zur Prüfung durch Annette eingereicht. Er ist noch nicht für den Marktplatz freigegeben.');}
 catch(err){document.getElementById('sk-extra-business-error').textContent=err.message;btn.disabled=false;}
});
async function loadManualAccessAdmin(){
 const root=document.getElementById('sk-admin-manual-access');if(!root)return;
 root.textContent='Kundenkonten werden geladen …';
 try{const rows=await window.SK_AUTH.adminManualAccounts();
 root.innerHTML=rows.length?rows.map(c=>`<article class="panel" style="margin-bottom:12px"><strong>${esc(c.account_label)}</strong><p>${c.manual_active?'<span class="status-tag sk-list-status-active">Manuell freigegeben</span>':'<span class="status-tag">Keine aktive manuelle Freigabe</span>'}${c.valid_until?' · bis '+esc(dateDisplay(c.valid_until)):''}</p>${c.reason?`<p class="muted">Grund: ${esc(c.reason)}</p>`:''}<div class="dialog-actions"><button type="button" class="subtle-btn" data-sk-grant="${esc(c.account_id)}">Freigabe erteilen / ändern</button><button type="button" class="subtle-btn" data-sk-revoke="${esc(c.account_id)}" ${!c.manual_active?'disabled':''}>Manuelle Freigabe widerrufen</button></div></article>`).join(''):'<p>Keine Kundenkonten vorhanden.</p>';
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
 const btn=form.querySelector('[type="submit"]');btn.disabled=true;
 try{const reason=form.elements.namedItem('category').value+': '+form.elements.namedItem('reason').value.trim();await window.SK_AUTH.adminSetManualAccess(form.dataset.account,true,reason,form.elements.namedItem('until').value);dialog.close();await loadManualAccessAdmin();}
 catch(err){document.getElementById('sk-manual-error').textContent=err.message;btn.disabled=false;}
});

document.getElementById('dialog-close').addEventListener('click',()=>dialog.close());dialog.addEventListener('click',e=>{if(e.target===dialog)dialog.close()});
let chosenListing=1, listTab='inserate';const listingStatus=new Map(listings.map(l=>[l.id,'Aktiv']));
let ownListings=[];
let ownBusinessList=[];
window.SK_SELECTED_BUSINESS=null;
let ownListingsBusy=false;
const listingFormField=(form,name)=>form.elements.namedItem(name);
function listingError(error){modal('Inserat nicht gespeichert',`<p>${esc(error?.message||'Unbekannter Fehler')}</p><p>Das Inserat wurde nicht als gespeichert bestätigt. Bitte überprüfe deine Anmeldung und die Datenbankmigration 0.32.1.</p>`);}
async function loadMyListings(){
  const root=document.getElementById('my-list-table');
  root.innerHTML='<p class="muted">Eigene Inserate werden geladen …</p>';
  try{ownBusinessList=await window.SK_AUTH.listApprovedBusinesses();ownListings=await window.SK_AUTH.listMyListings();renderMyListings();}
  catch(error){root.innerHTML=`<p role="alert">Inserate konnten nicht geladen werden: ${esc(error.message)}</p>`;}
}
async function saveListing(){
  if(ownListingsBusy)return;
  const form=document.getElementById('listing-form');if(!form?.reportValidity())return;
  const from=listingFormField(form,'from').value,to=listingFormField(form,'to').value;
  if(to<from){listingFormField(form,'to').setCustomValidity('Das Bis-Datum muss am oder nach dem Von-Datum liegen.');form.reportValidity();listingFormField(form,'to').setCustomValidity('');return;}
  const payload={type:listingFormField(form,'type').value,category:listingFormField(form,'category').value,title:listingFormField(form,'title').value.trim(),description:listingFormField(form,'description').value.trim(),date_from:from,date_to:to,conditions:listingFormField(form,'conditions').value.trim(),accommodation:listingFormField(form,'accommodation').checked,languages:[...form.querySelectorAll('input[name="languages"]:checked')].map(e=>e.value)};
  const id=form.dataset.edit||null;const businessId=listingFormField(form,'business_id').value;
  const button=document.getElementById('save-real-listing');button.disabled=true;button.textContent='Wird gespeichert …';ownListingsBusy=true;
  try{await window.SK_AUTH.saveMyListing(payload,id,businessId);dialog.close();await loadMyListings();}
  catch(error){button.disabled=false;button.textContent='Inserat speichern';const note=form.querySelector('.listing-save-error');if(note)note.textContent='Speichern fehlgeschlagen: '+error.message;}
  finally{ownListingsBusy=false;}
}
function listingForm(id){
  const l=ownListings.find(x=>x.id===id);
  const today=skTodayCH();
  const dateFrom=l?.date_from||today,dateTo=l?.date_to||today;
  modal(l?'Inserat bearbeiten':'Neues Inserat',`<form id="listing-form" data-edit="${esc(l?.id||'')}"><label>Betrieb / Einsatzstandort *</label><select name="business_id" required ${l?"disabled":""}>${ownBusinessList.map(b=>`<option value="${esc(b.id)}" ${(l?.business_id||window.SK_SELECTED_BUSINESS||ownBusinessList[0]?.id)===b.id?"selected":""}>${esc(b.company_name)} · ${esc(b.city||"")}</option>`).join("")}</select><div class="field-grid"><div><label>Typ *</label><select name="type" required>${['Suche','Biete'].map(x=>`<option ${l?.type===x?'selected':''}>${x}</option>`).join('')}</select></div><div><label>Kategorie *</label><select name="category" required>${['Küche','Service','Housekeeping','Technik','Animation'].map(x=>`<option ${l?.category===x?'selected':''}>${x}</option>`).join('')}</select></div></div><p class="muted">Ort und Land werden automatisch aus dem freigegebenen Betriebsprofil übernommen.</p><label>Titel (5–80 Zeichen) *</label><input name="title" required minlength="5" maxlength="80" value="${esc(l?.title||'')}"><label>Beschreibung (20–1000 Zeichen) *</label><textarea name="description" required minlength="20" maxlength="1000" rows="3">${esc(l?.description||'')}</textarea><div class="field-grid"><div><label>Von *</label><input name="from" type="date" required value="${esc(dateFrom)}"></div><div><label>Bis *</label><input name="to" type="date" required value="${esc(dateTo)}"></div></div><label>Rahmenbedingungen (max. 500 Zeichen)</label><textarea name="conditions" maxlength="500" rows="2">${esc(l?.conditions||'')}</textarea><label class="check"><input type="checkbox" name="accommodation" ${l?.accommodation?'checked':''}><span>Unterkunft vorhanden</span></label><p class="muted">Sprachen: ${['DE','FR','IT','EN','ES'].map(x=>`<label class="inline-check"><input type="checkbox" name="languages" value="${x}" ${(l?.languages||['DE']).includes(x)?'checked':''}> ${x}</label>`).join(' ')}</p><p class="listing-save-error" role="alert"></p><div class="dialog-actions"><button type="button" class="btn" id="save-real-listing">Inserat speichern</button></div></form>`);
}
document.getElementById('new-listing').addEventListener('click',()=>listingForm());
document.querySelectorAll('[data-list-tab]').forEach(b=>b.addEventListener('click',()=>{listTab=b.dataset.listTab;document.querySelectorAll('[data-list-tab]').forEach(x=>x.classList.toggle('active',x===b));renderMyListings()}));
function renderMyListings(){
  const root=document.getElementById('my-list-table');
  if(listTab==='partner'){root.innerHTML='<h2>Als Partner</h2><p class="muted">Partnerschaften werden in einer späteren Marktplatzphase angebunden.</p>';return;}
  const rows=listTab==='inserate'?ownListings.filter(x=>!['Vergeben','Abgeschlossen'].includes(x.status)):ownListings.filter(x=>['Vergeben','Abgeschlossen'].includes(x.status));
  root.innerHTML='<h2>'+(listTab==='inserate'?'Eigene Inserate':'Vergebene Inserate')+'</h2><div class="table-wrap"><table class="data-table"><thead><tr><th>Inserat / Ort</th><th>Typ / Kategorie</th><th>Zeitraum</th><th>Status</th><th>Aktionen</th></tr></thead><tbody>'+rows.map(l=>`<tr><td><strong>${esc(l.title)}</strong><small>${esc(l.city)} · ${esc(l.country)}</small></td><td>${esc(l.type)} · ${esc(l.category)}</td><td>${esc(dateDisplay(l.date_from))} – ${esc(dateDisplay(l.date_to))}</td><td><span class="status-tag sk-list-status ${skListingEffectiveStatus(l)==='Aktiv'?'sk-list-status-active':skListingEffectiveStatus(l)==='Abgelaufen'?'sk-list-status-inactive':'sk-list-status-inactive'}">${esc(skListingEffectiveStatus(l))}</span></td><td class="table-actions sk-own-actions"><button type="button" class="sk-action-edit" data-own="edit" data-id="${esc(l.id)}" aria-label="Inserat bearbeiten" title="Inserat bearbeiten">✎</button><button type="button" class="sk-action-toggle" data-own="toggle" data-id="${esc(l.id)}" ${skListingEffectiveStatus(l)==='Abgelaufen'?'disabled':''} aria-label="${skListingEffectiveStatus(l)==='Abgelaufen'?'Zuerst Enddatum verlängern':l.status==='Aktiv'?'Inserat deaktivieren':'Inserat aktivieren'}" title="${skListingEffectiveStatus(l)==='Abgelaufen'?'Zuerst Enddatum verlängern':l.status==='Aktiv'?'Inserat deaktivieren':'Inserat aktivieren'}">↻</button><button type="button" class="sk-action-delete" data-own="delete" data-id="${esc(l.id)}" aria-label="Inserat dauerhaft löschen" title="Inserat dauerhaft löschen">✕</button></td></tr>`).join('')+'</tbody></table></div>'+(rows.length?'':'<p class="muted">Keine Inserate in dieser Ansicht.</p>');
}
document.getElementById('dialog-body').addEventListener('click',e=>{if(e.target.closest('#save-real-listing'))saveListing();});
document.getElementById('my-list-table').addEventListener('click',async e=>{
  const b=e.target.closest('[data-own]');if(!b||ownListingsBusy)return;
  const id=b.dataset.id,l=ownListings.find(x=>x.id===id);if(!l)return;
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
const chats=[{name:'Hotel Sonnenblick',topic:'Service-Mitarbeitende für Wintersaison',messages:[['other','Guten Tag, wir interessieren uns für einen Austausch.'],['mine','Vielen Dank für die Anfrage! Gerne besprechen wir Details.']]},{name:'Camping am Park',topic:'Küchenteam für Übergangszeit',messages:[['other','Guten Morgen, wäre eine Zusammenarbeit im Dezember möglich?']]}];let selectedChat=0;
function renderChats(){document.getElementById('conversation-buttons').innerHTML=chats.map((c,i)=>`<button class="conversation-btn ${i===selectedChat?'active':''}" data-chat="${i}"><strong>${esc(c.name)}</strong><small>${esc(c.topic)}</small></button>`).join('');const c=chats[selectedChat];document.getElementById('chat-heading').innerHTML='<strong>'+esc(c.name)+'</strong><small>'+esc(c.topic)+'</small>';document.getElementById('chat-history').innerHTML=c.messages.map(([who,message])=>'<div class="bubble '+who+'">'+esc(message)+'</div>').join('');}
document.getElementById('conversation-buttons').addEventListener('click',e=>{const b=e.target.closest('[data-chat]');if(b){selectedChat=Number(b.dataset.chat);renderChats()}});document.getElementById('chat-form').addEventListener('submit',e=>{e.preventDefault();const field=document.getElementById('chat-entry');chats[selectedChat].messages.push(['mine',field.value]);field.value='';renderChats()});
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
   <div class="business-review-grid"><section><h3>Unternehmensangaben</h3><dl class="business-info">${detailsRow('Firmenname',b.company_name)}${detailsRow('Branche',b.industry)}${detailsRow('Land',b.country)}${detailsRow('PLZ / Ort',[b.postal_code,b.city].filter(Boolean).join(' '))}${detailsRow('Strasse / Hausnummer',[b.street,b.house_number].filter(Boolean).join(' '))}${detailsRow('Adresszusatz',b.address_extra)}${detailsRow('Strassenadresse öffentlich',b.show_street_address?'Ja':'Nein')}${detailsRow('USt-/UID-Nr.',b.vat_id)}${detailsRow('Beschreibung',b.description)}${detailsRow('Prüfstatus',b.review_state)}${detailsRow('Eingereicht',dateTimeDisplay(b.submitted_at))}${detailsRow('Nachbesserungsgrund',b.review_message)}${detailsRow('E-Mail-Benachrichtigungen (Vorliebe)',b.email_notifications_enabled?'Ja':'Nein')}${detailsRow('Registriert',dateTimeDisplay(b.created_at))}${detailsRow('Nutzungsbedingungen bestätigt',dateTimeDisplay(b.terms_accepted_at))}</dl></section>
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
