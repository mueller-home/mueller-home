/* StaffKeeping 0.27.1 – zentrale Administration und Navigation */
'use strict';
const screens=['login','register','reset','pending','market','profile','my-listings','detail','messages','reviews','admin-businesses','admin-listings','admin-dashboard','admin-docs'];
const navOnly=document.querySelectorAll('.nav-only'), guests=document.querySelectorAll('.guest-only');
const publicViews=new Set(['login','register','reset','pending']);
let demoSignedIn=false;
let skAdmin=false;
let skPending=false;
window.SK_UI={setAccess(isApproved,isAdmin){demoSignedIn=!!isApproved;skAdmin=!!isAdmin;skPending=!isApproved;performShow(isApproved?'market':'pending',false);},show,logoutView(){demoSignedIn=false;skAdmin=false;skPending=false;performShow('login',false);}};
let currentScreen='login', navigationBusy=false;
async function show(view,updateUrl=true){
  if(navigationBusy)return;
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
  if(!demoSignedIn && !publicViews.has(view))view=skPending?'pending':'login';
  if(!skAdmin && view.startsWith('admin-'))view=demoSignedIn?'market':'login';
  if(demoSignedIn && view==='login')view='market';
  if(currentScreen==='admin-docs'&&view!=='admin-docs')window.SK_DOCS?.close();
  currentScreen=view;
  screens.forEach(v=>document.getElementById('view-'+v).classList.toggle('hidden',v!==view));
  const inApp=demoSignedIn && !publicViews.has(view);
  navOnly.forEach(n=>n.classList.toggle('hidden',!inApp));
  guests.forEach(n=>n.classList.toggle('hidden',inApp||skPending));
  document.querySelectorAll('.admin-nav, .admin-tabs').forEach(n=>n.classList.toggle('hidden',!skAdmin));
  document.querySelectorAll('.admin-tabs [data-view]').forEach(b=>{const active=b.dataset.view===view;b.classList.toggle('active',active);b.setAttribute('aria-current',active?'page':'false');});
  document.querySelectorAll('.headnav [data-view]').forEach(n=>n.setAttribute('aria-current',n.dataset.view===view?'page':'false'));
  if(updateUrl && location.hash!=='#'+view)history.pushState({view},'', '#'+view);
  window.scrollTo(0,0);
  if(view==='profile')window.SK_PROFILE?.load();
  if(view==='market')render();
  if(view==='my-listings')renderMyListings();
  if(view==='messages')renderChats();
  if(view==='admin-businesses')renderBusinesses();
  if(view==='admin-listings')renderAdminListings();
  if(view==='admin-docs')renderProjectDocs();
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
const esc=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
function render(){const q=document.getElementById('filter-search').value.toLocaleLowerCase('de'),type=document.getElementById('filter-type').value,branch=document.getElementById('filter-branch').value,stay=document.getElementById('filter-accommodation').checked,date=document.getElementById('filter-date').value;
const items=listings.filter(l=>(!q||[l.title,l.city,l.branch,l.desc].join(' ').toLocaleLowerCase('de').includes(q))&&(!type||l.type===type)&&(!branch||l.branch===branch)&&(!stay||l.stay)&&(!date||l.date>=date)&&(!favoritesOnly||starred.has(l.id)));
document.getElementById('result-count').textContent=items.length+' '+(items.length===1?'Inserat':'Inserate');document.getElementById('bookmark-count').textContent=starred.size;
document.getElementById('listing-grid').innerHTML=items.map(l=>`<article class="listing-card"><div class="listing-top"><span class="type-pill ${l.type==='Personal verfügbar'?'available':''}">${esc(l.type)}</span><button class="star" type="button" data-star="${l.id}" aria-label="${starred.has(l.id)?'Aus Merkliste entfernen':'Zur Merkliste hinzufügen'}" aria-pressed="${starred.has(l.id)}">${starred.has(l.id)?'★':'☆'}</button></div><h3>${esc(l.title)}</h3><div class="listing-location">⌖ ${esc(l.city)} · ${esc(l.country)}</div><p>${esc(l.desc)}</p><div class="listing-meta"><span>◷ ${esc(l.period)}</span>${l.stay?'<span>⌂ Unterkunft</span>':''}</div><div class="listing-footer"><div class="languages">${l.languages.map(s=>`<span>${esc(s)}</span>`).join('')}</div><button class="detail-link" type="button" data-detail="${l.id}">Details ansehen →</button></div></article>`).join('');
document.querySelectorAll('[data-star]').forEach(b=>b.addEventListener('click',()=>{const id=Number(b.dataset.star);starred.has(id)?starred.delete(id):starred.add(id);render()}));document.querySelectorAll('[data-detail]').forEach(b=>b.addEventListener('click',()=>openDetail(Number(b.dataset.detail))));
document.getElementById('no-results').classList.toggle('hidden',items.length>0||viewMap);document.getElementById('listing-grid').classList.toggle('hidden',viewMap);document.getElementById('map-placeholder').classList.toggle('hidden',!viewMap);}
['filter-search','filter-type','filter-branch','filter-date','filter-accommodation'].forEach(id=>document.getElementById(id).addEventListener('input',render));
document.getElementById('filter-reset').addEventListener('click',()=>{['filter-search','filter-type','filter-branch','filter-date'].forEach(id=>document.getElementById(id).value='');document.getElementById('filter-radius').selectedIndex=0;document.getElementById('filter-accommodation').checked=false;favoritesOnly=false;document.getElementById('bookmarks-only').classList.remove('selected');render()});
document.getElementById('bookmarks-only').addEventListener('click',e=>{favoritesOnly=!favoritesOnly;e.currentTarget.classList.toggle('selected',favoritesOnly);render()});
function setView(map){viewMap=map;document.getElementById('list-btn').classList.toggle('active',!map);document.getElementById('map-btn').classList.toggle('active',map);render()};document.getElementById('list-btn').addEventListener('click',()=>setView(false));document.getElementById('map-btn').addEventListener('click',()=>setView(true));
/* Zusätzliche UI-Demoseiten, ohne Backend und ohne dauerhafte Speicherung */
const dialog=document.getElementById('app-dialog');
function modal(title,html){document.getElementById('dialog-title').textContent=title;document.getElementById('dialog-body').innerHTML=html;dialog.showModal();}
document.getElementById('dialog-close').addEventListener('click',()=>dialog.close());dialog.addEventListener('click',e=>{if(e.target===dialog)dialog.close()});
let chosenListing=1, listTab='inserate';const listingStatus=new Map(listings.map(l=>[l.id,'Aktiv']));
const ownListings=[{id:101,title:'Saisonaushilfe im Frühstücksservice',type:'Suche',category:'Service',city:'Luzern',period:'November – Februar',status:'Aktiv'},{id:102,title:'Erfahrene Köchin für Wintersaison',type:'Biete',category:'Küche',city:'Zürich',period:'Dezember – März',status:'Inaktiv'},{id:103,title:'Unterstützung in der Animation',type:'Suche',category:'Animation',city:'Thun',period:'Juni – August',status:'Vergeben'}];
function openDetail(id){const l=listings.find(x=>x.id===id);if(!l)return;chosenListing=id;document.getElementById('detail-title').textContent=l.title;document.getElementById('detail-subtitle').textContent=l.city+' · '+l.country+' · '+l.period;document.getElementById('detail-meta').innerHTML='<span class="type-pill">'+esc(l.type)+'</span><span class="type-pill">'+esc(l.branch)+'</span><span class="type-pill">'+esc(l.period)+'</span>';document.getElementById('detail-description').textContent=l.desc;document.getElementById('detail-features').innerHTML=l.languages.map(x=>'<span class="type-pill">'+esc(x)+'</span>').join('')+(l.stay?'<span class="type-pill">⌂ Unterkunft vorhanden</span>':'');document.getElementById('detail-company').textContent=['Hotel Seeblick','Alpenhof Interlaken','Gastbetrieb Tirol','Camping am Park'][id-1];show('detail');}
document.getElementById('detail-contact').addEventListener('click',()=>modal('Vor dem Kontakt',`<p>Bitte lesen Sie den Kontakt-Disclaimer. Die Zusammenarbeit wird zwischen den Betrieben eigenverantwortlich vereinbart.</p><label class="check"><input type="checkbox" id="disclaimer-accept"><span>Ich habe den Hinweis verstanden.</span></label><div class="dialog-actions"><button class="subtle-btn" type="button" id="dialog-cancel">Abbrechen</button><button class="btn" type="button" id="contact-confirm" disabled>Verstanden – Kontakt aufnehmen</button></div>`));
document.getElementById('detail-reviews').addEventListener('click',()=>modal('Bewertungen des Betriebs','<p>★ 4,5 / 5 · Beispielbewertung</p><p>Gute Kommunikation und zuverlässige Zusammenarbeit.</p>'));
document.getElementById('dialog-body').addEventListener('change',e=>{if(e.target.id==='disclaimer-accept')document.getElementById('contact-confirm').disabled=!e.target.checked});
document.getElementById('dialog-body').addEventListener('click',e=>{if(e.target.closest('#dialog-cancel'))dialog.close();if(e.target.closest('#contact-confirm')){dialog.close();selectedChat=0;show('messages');}if(e.target.closest('#save-demo-listing')){const form=document.getElementById('listing-form');if(!form.reportValidity())return;const id=Number(form.dataset.edit||Date.now());const record={id,title:form.elements.title.value,type:form.elements.type.value,category:form.elements.category.value,city:'Demo-Ort',period:form.elements.from.value+' – '+form.elements.to.value,status:'Aktiv'};const i=ownListings.findIndex(l=>l.id===id);if(i>=0)ownListings[i]=record;else ownListings.unshift(record);dialog.close();renderMyListings();}if(e.target.closest('#submit-demo-review')){const form=document.getElementById('review-form');if(!form.reportValidity())return;dialog.close();modal('Bewertung erfasst','<p>Die Bewertung wurde nur in dieser Designvorschau bestätigt und nicht gespeichert.</p>');}});
function listingForm(id){const l=ownListings.find(x=>x.id===id);modal(l?'Inserat bearbeiten':'Neues Inserat',`<form id="listing-form" data-edit="${l?.id||''}"><div class="field-grid"><div><label>Typ *</label><select name="type" required><option ${l?.type==='Suche'?'selected':''}>Suche</option><option ${l?.type==='Biete'?'selected':''}>Biete</option></select></div><div><label>Kategorie *</label><select name="category">${['Küche','Service','Housekeeping','Technik','Animation'].map(x=>`<option ${l?.category===x?'selected':''}>${x}</option>`).join('')}</select></div></div><label>Titel (5–80 Zeichen) *</label><input name="title" required minlength="5" maxlength="80" value="${esc(l?.title||'')}"><label>Beschreibung (20–1000 Zeichen) *</label><textarea name="description" required minlength="20" maxlength="1000" rows="3">${l?'Vereinbarter temporärer Einsatz mit dem Partnerbetrieb.':''}</textarea><div class="field-grid"><div><label>Von *</label><input name="from" type="date" required value="2026-12-01"></div><div><label>Bis *</label><input name="to" type="date" required value="2027-02-28"></div></div><label>Rahmenbedingungen (max. 500 Zeichen)</label><textarea maxlength="500" rows="2"></textarea><label class="check"><input type="checkbox"><span>Unterkunft vorhanden</span></label><p class="muted">Sprachen: <label class="inline-check"><input type="checkbox" checked> DE</label> <label class="inline-check"><input type="checkbox"> FR</label> <label class="inline-check"><input type="checkbox"> IT</label> <label class="inline-check"><input type="checkbox"> EN</label> <label class="inline-check"><input type="checkbox"> ES</label></p><div class="dialog-actions"><button type="button" class="btn" id="save-demo-listing">Demo-Inserat übernehmen</button></div></form>`);}
document.getElementById('new-listing').addEventListener('click',()=>listingForm());
document.querySelectorAll('[data-list-tab]').forEach(b=>b.addEventListener('click',()=>{listTab=b.dataset.listTab;document.querySelectorAll('[data-list-tab]').forEach(x=>x.classList.toggle('active',x===b));renderMyListings()}));
function renderMyListings(){const rows=listTab==='inserate'?ownListings.filter(x=>!['Vergeben','Abgeschlossen'].includes(x.status)):ownListings.filter(x=>x.status==='Vergeben'||x.status==='Abgeschlossen');document.getElementById('my-list-table').innerHTML='<h2>'+(listTab==='inserate'?'Eigene Inserate':listTab==='vergeben'?'Vergebene Inserate':'Partnerschaften als Partner')+'</h2>'+(listTab==='partner'?'<p class="muted">In der Demo werden beispielhaft vergebene Inserate angezeigt.</p>':'')+'<div class="table-wrap"><table class="data-table"><thead><tr><th>Inserat</th><th>Typ / Kategorie</th><th>Zeitraum</th><th>Status</th><th>Aktionen</th></tr></thead><tbody>'+rows.map(l=>`<tr><td><strong>${esc(l.title)}</strong><small>${esc(l.city)}</small></td><td>${esc(l.type)} · ${esc(l.category)}</td><td>${esc(l.period)}</td><td><span class="status-tag">${esc(l.status)}</span></td><td class="table-actions"><button data-own="edit" data-id="${l.id}">✎</button><button data-own="toggle" data-id="${l.id}">↻</button><button data-own="assign" data-id="${l.id}">🤝</button><button data-own="review" data-id="${l.id}">★</button><button data-own="messages" data-id="${l.id}">✉</button><button data-own="delete" data-id="${l.id}">✕</button></td></tr>`).join('')+'</tbody></table></div>'+(rows.length?'':'<p class="muted">Keine Inserate in dieser Ansicht.</p>');}
document.getElementById('my-list-table').addEventListener('click',e=>{const b=e.target.closest('[data-own]');if(!b)return;const id=Number(b.dataset.id),l=ownListings.find(x=>x.id===id);if(!l)return;switch(b.dataset.own){case'edit':listingForm(id);break;case'toggle':l.status=l.status==='Aktiv'?'Inaktiv':'Aktiv';renderMyListings();break;case'delete':if(confirm('Demo-Inserat aus der aktuellen Ansicht entfernen?')){ownListings.splice(ownListings.indexOf(l),1);renderMyListings()}break;case'assign':modal('Inserat vergeben','<p>Wählen Sie einen Partner aus bestehenden Konversationen (Demodaten).</p><label>Partner</label><select id="assign-partner"><option>Hotel Seeblick</option><option>Restaurant Seeblick</option></select><div class="dialog-actions"><button type="button" class="btn" id="confirm-assign">Vergeben</button></div>');document.getElementById('confirm-assign').addEventListener('click',()=>{l.status='Vergeben';dialog.close();renderMyListings()});break;case'review':modal('Bewertung abgeben',`<form id="review-form"><label>Kommunikation *</label><select required><option value="">Bitte wählen</option>${[1,2,3,4,5].map(n=>'<option>'+n+' ★</option>').join('')}</select><label>Zuverlässigkeit *</label><select required><option value="">Bitte wählen</option>${[1,2,3,4,5].map(n=>'<option>'+n+' ★</option>').join('')}</select><label class="check"><input type="checkbox"><span>Weiterempfehlung</span></label><label>Kommentar</label><textarea rows="3"></textarea><div class="dialog-actions"><button class="btn" type="button" id="submit-demo-review">Bewertung abschicken</button></div></form>`);break;case'messages':show('messages');break;}});
const chats=[{name:'Hotel Sonnenblick',topic:'Service-Mitarbeitende für Wintersaison',messages:[['other','Guten Tag, wir interessieren uns für einen Austausch.'],['mine','Vielen Dank für die Anfrage! Gerne besprechen wir Details.']]},{name:'Camping am Park',topic:'Küchenteam für Übergangszeit',messages:[['other','Guten Morgen, wäre eine Zusammenarbeit im Dezember möglich?']]}];let selectedChat=0;
function renderChats(){document.getElementById('conversation-buttons').innerHTML=chats.map((c,i)=>`<button class="conversation-btn ${i===selectedChat?'active':''}" data-chat="${i}"><strong>${esc(c.name)}</strong><small>${esc(c.topic)}</small></button>`).join('');const c=chats[selectedChat];document.getElementById('chat-heading').innerHTML='<strong>'+esc(c.name)+'</strong><small>'+esc(c.topic)+'</small>';document.getElementById('chat-history').innerHTML=c.messages.map(([who,message])=>'<div class="bubble '+who+'">'+esc(message)+'</div>').join('');}
document.getElementById('conversation-buttons').addEventListener('click',e=>{const b=e.target.closest('[data-chat]');if(b){selectedChat=Number(b.dataset.chat);renderChats()}});document.getElementById('chat-form').addEventListener('submit',e=>{e.preventDefault();const field=document.getElementById('chat-entry');chats[selectedChat].messages.push(['mine',field.value]);field.value='';renderChats()});
const companies=[{name:'Alpenhotel Panorama',land:'Schweiz',status:'Ausstehend'},{name:'Restaurant Seeblick',land:'Schweiz',status:'Ausstehend'},{name:'Camping am Park',land:'Deutschland',status:'Aktiv'},{name:'Hotel Tirol',land:'Österreich',status:'Aktiv'}];
let skBusinessList=[];
let skSelectedBusiness=null;
const dateTimeDisplay=d=>d?new Intl.DateTimeFormat('de-CH',{dateStyle:'medium',timeStyle:'short'}).format(new Date(d)):'–';
const valueOrDash=v=>v===null||v===undefined||v===''?'–':String(v);
function renderBusinesses(){
 const root=document.getElementById('admin-business-table');
 if(!skAdmin){root.textContent='Nur für Administratoren.';return;}
 if(!window.SK_AUTH){root.textContent='Supabase-Verbindung wird geladen …';return;}
 root.textContent='Unternehmen werden geladen …';
 window.SK_AUTH.loadBusinesses().then(rows=>{
  skBusinessList=rows;
  root.innerHTML='<div class="table-wrap"><table class="data-table"><thead><tr><th>Betrieb</th><th>Land</th><th>Status</th><th>Prüfung</th></tr></thead><tbody>'+
   rows.map(c=>`<tr><td>${esc(c.company_name)}</td><td>${esc(c.country)}</td><td>${esc(c.status)}</td><td><button class="subtle-btn" type="button" data-review-business="${esc(c.id)}">Details / Prüfen</button></td></tr>`).join('')+
   '</tbody></table></div>';
  if(!rows.length)root.textContent='Noch keine registrierten Betriebe.';
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
   <div class="business-review-grid"><section><h3>Unternehmensangaben</h3><dl class="business-info">${detailsRow('Firmenname',b.company_name)}${detailsRow('Branche',b.industry)}${detailsRow('Land',b.country)}${detailsRow('PLZ / Ort',[b.postal_code,b.city].filter(Boolean).join(' '))}${detailsRow('Strasse / Hausnummer',[b.street,b.house_number].filter(Boolean).join(' '))}${detailsRow('Adresszusatz',b.address_extra)}${detailsRow('Strassenadresse öffentlich',b.show_street_address?'Ja':'Nein')}${detailsRow('USt-/UID-Nr.',b.vat_id)}${detailsRow('Beschreibung',b.description)}${detailsRow('E-Mail-Benachrichtigungen (Vorliebe)',b.email_notifications_enabled?'Ja':'Nein')}${detailsRow('Registriert',dateTimeDisplay(b.created_at))}${detailsRow('Nutzungsbedingungen bestätigt',dateTimeDisplay(b.terms_accepted_at))}</dl></section>
   <section><h3>Kontakt &amp; Benutzer</h3><dl class="business-info">${detailsRow('Kontaktperson',b.contact_name)}${detailsRow('E-Mail',b.contact_email)}${detailsRow('Telefon',b.contact_phone)}</dl><div class="business-contact-actions"><a class="subtle-btn" href="mailto:${encodeURIComponent(b.contact_email||'')}">E-Mail schreiben ↗</a>${b.contact_phone?`<a class="subtle-btn" href="tel:${encodeURIComponent(b.contact_phone)}">Anrufen ↗</a>`:''}</div><h4>Konten</h4>${members.length?members.map(m=>`<p class="business-minor">${esc(m.email)} · ${esc(m.role)}</p>`).join(''):'<p class="muted">Keine Benutzerzuordnung</p>'}</section></div>
   <section class="business-review-media"><h3>Standort des Betriebs</h3><div id="business-admin-map" class="business-map" role="region" aria-label="Standortkarte des Betriebs"></div><p id="business-admin-map-status" class="muted"></p></section><section class="business-review-media"><h3>Firmenlogo und Betriebsbilder</h3><div id="business-admin-media" class="admin-media-preview">Medien werden geladen …</div></section>
   <div class="business-review-grid"><section><h3>Interne Admin-Notizen</h3><p class="muted">Nur für Administratoren. Einträge werden mit Datum und Autor protokolliert.</p><form id="business-note-form"><label for="business-note">Neue Notiz</label><textarea id="business-note" rows="3" maxlength="3000" required placeholder="Rückfrage, Gesprächsnotiz, Prüfergebnis …"></textarea><button class="btn btn-small" type="submit">Notiz speichern</button><p class="form-feedback" id="business-note-status" role="status"></p></form><div class="business-events">${notes.length?notes.map(n=>`<article><small>${esc(dateTimeDisplay(n.created_at))} · ${esc(n.author)}</small><p>${esc(n.note)}</p></article>`).join(''):'<p class="muted">Noch keine Notizen.</p>'}</div></section>
   <section><h3>Freigabehistorie</h3><div class="business-events">${audit.length?audit.map(a=>`<article><small>${esc(dateTimeDisplay(a.changed_at))} · ${esc(a.changed_by)}</small><p>${esc(a.old_status)} → ${esc(a.new_status)}</p></article>`).join(''):'<p class="muted">Noch keine Statusänderungen.</p>'}</div></section></div>
   <div class="business-review-actions"><button type="button" class="btn" data-review-status="Freigeschaltet">Betrieb freischalten</button><button type="button" class="subtle-btn" data-review-status="Gesperrt">Betrieb sperren</button><p class="form-feedback" role="status" id="business-review-status"></p></div>`;
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
function renderAdminListings(){const country=document.getElementById('admin-country').value,status=document.getElementById('admin-status').value;const filtered=listings.filter(l=>(!country||l.country===country)&&(!status||listingStatus.get(l.id)===status));document.getElementById('admin-listing-table').innerHTML='<div class="table-wrap"><table class="data-table"><thead><tr><th>Inserat</th><th>Land</th><th>Status</th><th>Aktionen</th></tr></thead><tbody>'+filtered.map(l=>`<tr><td>${esc(l.title)}</td><td>${esc(l.country)}</td><td><span class="status-tag">${esc(listingStatus.get(l.id))}</span></td><td class="table-actions"><button data-moderate="${l.id}" data-action="edit">Bearbeiten</button><button data-moderate="${l.id}" data-action="toggle">${listingStatus.get(l.id)==='Aktiv'?'Sperren':'Aktivieren'}</button></td></tr>`).join('')+'</tbody></table></div>';}
document.getElementById('admin-listing-table').addEventListener('click',e=>{const b=e.target.closest('[data-moderate]');if(!b)return;const id=Number(b.dataset.moderate);if(b.dataset.action==='toggle'){listingStatus.set(id,listingStatus.get(id)==='Aktiv'?'Gesperrt':'Aktiv');renderAdminListings()}else{const l=listings.find(x=>x.id===id);modal('Inserat prüfen','<p><strong>'+esc(l.title)+'</strong></p><p>'+esc(l.desc)+'</p><p class="muted">Bearbeitung und dauerhafte Löschung folgen mit Backend und Berechtigungsprüfung.</p>')}});
['admin-country','admin-status'].forEach(id=>document.getElementById(id).addEventListener('change',renderAdminListings));
show('login',false);

/* 0.27 – Dokumentation wird ausschliesslich aus der geschützten Admin-Datenbank gelesen. */
function renderProjectDocs(){window.SK_DOCS?.load();}
