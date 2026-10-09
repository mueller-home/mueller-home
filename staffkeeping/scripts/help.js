/* StaffKeeping 0.30 – full searchable handbook, contextual drawer, admin editor. */
'use strict';
(function(){
 const $=id=>document.getElementById(id);
 let chapters=[],preview=[],chosen=null,editSlug=null;
 const escape=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
 // A deliberately limited Markdown renderer. No untrusted HTML injection.
 function render(target,chapter){target.replaceChildren();if(!chapter){target.textContent='Für diese Seite ist noch kein veröffentlichtes Handbuchkapitel verfügbar.';return;}
  const h=document.createElement('h2');h.textContent=chapter.title;target.append(h);
  const lines=chapter.body.replace(/\r\n?/g,'\n').split('\n');let list=null;
  for(const text of lines){if(!text.trim()){list=null;continue;}
   const shot=text.match(/^!\[([^\]]*)\]\(screenshot:([a-z0-9-]{2,80})\)$/);
   if(shot){const container=document.createElement('figure');container.className='help-screenshot';container.classList.toggle('hidden',!window.SK_AUTH?.isAdmin());
    const img=document.createElement('img');img.alt=shot[1];img.loading='lazy';img.className='hidden';
    const placeholder=document.createElement('p');placeholder.textContent='Screenshot: '+shot[1]+' ('+shot[2]+')';placeholder.classList.toggle('hidden',!window.SK_AUTH?.isAdmin());container.append(placeholder,img);
    for(const ext of ['webp','png','jpg']){
      const url=window.SK_AUTH?.helpImageUrl(chapter.slug,shot[2],ext);
      if(!url)continue;const probe=new Image();probe.onload=()=>{if(!img.classList.contains('hidden'))return;img.src=url;img.classList.remove('hidden');container.classList.remove('hidden');placeholder.classList.add('hidden');};probe.src=url;
    }target.append(container);continue;
   }
   const heading=text.match(/^(#{1,4})\s+(.+)$/);
   if(heading){const el=document.createElement('h'+Math.min(5,heading[1].length+1));el.textContent=heading[2];target.append(el);list=null;continue;}
   const item=text.match(/^\s*(?:\d+[.)]|[-*])\s+(.+)$/);
   if(item){if(!list){list=document.createElement(/^\s*\d/.test(text)?'ol':'ul');target.append(list);}const li=document.createElement('li');li.textContent=item[1];list.append(li);continue;}
   list=null;const p=document.createElement('p');
   // Support safe **bold** and `code` without interpreting HTML.
   let i=0;const re=/(\*\*([^*]+)\*\*|`([^`]+)`)/g;let m;
   while((m=re.exec(text))){p.append(document.createTextNode(text.slice(i,m.index)));const node=document.createElement(m[2]?'strong':'code');node.textContent=m[2]||m[3];p.append(node);i=re.lastIndex;}
   p.append(document.createTextNode(text.slice(i)));target.append(p);
  }
 }
 async function load(force=false){
  if(force||!chapters.length){try{chapters=await window.SK_AUTH.listHelp(false);}catch(e){$('help-content').textContent='Handbuch nicht verfügbar: '+e.message;return;}}
  const query=$('help-search').value.toLocaleLowerCase('de');const list=$('help-chapter-list');list.replaceChildren();
  const filtered=chapters.filter(c=>!query||(c.title+' '+c.body+' '+c.section).toLocaleLowerCase('de').includes(query));
  for(const c of filtered){const b=document.createElement('button');b.type='button';b.textContent=c.title;b.className=c.slug===chosen?'active':'';b.addEventListener('click',()=>{chosen=c.slug;render($('help-content'),c);load(false);});list.append(b);}
  const chapter=chapters.find(c=>c.slug===chosen)||filtered[0];if(chapter){chosen=chapter.slug;render($('help-content'),chapter);}else $('help-content').textContent='Keine passenden Kapitel.';
 }
 async function openContext(page){
  const view=page||location.hash.slice(1)||'login';
  if(!chapters.length)try{chapters=await window.SK_AUTH.listHelp(false);}catch(e){$('help-context-body').textContent=e.message;return;}
  const chapter=chapters.find(c=>c.page_key===view)||chapters.find(c=>c.page_key==='start')||chapters[0];
  render($('help-context-body'),chapter);$('help-drawer').classList.remove('hidden');
 }
 $('context-help').addEventListener('click',()=>openContext(location.hash.slice(1)||'login'));
 $('help-close').addEventListener('click',()=>$('help-drawer').classList.add('hidden'));
 $('help-search').addEventListener('input',()=>load(false));
 function form(c){editSlug=c.slug;$('help-admin-editor').classList.remove('hidden');$('help-admin-title').value=c.title;$('help-admin-section').value=c.section;
  $('help-admin-page').value=c.page_key;$('help-admin-audience').value=c.audience;$('help-admin-body').value=c.body;
  $('help-admin-status').value=c.status;$('help-image-id').value='';$('help-admin-message').textContent='Kapitel '+c.slug+' bearbeiten.';
 }
 async function loadAdmin(){const root=$('help-admin-list');if(!root)return;
  root.textContent='Handbuchkapitel laden …';
  try{preview=await window.SK_AUTH.listHelp(true);root.replaceChildren();
    for(const c of preview){const b=document.createElement('button');b.className='subtle-btn';b.type='button';b.textContent=c.title+' · '+(c.status==='published'?'Veröffentlicht':'Entwurf');b.addEventListener('click',()=>form(c));root.append(b);}
   }catch(e){root.textContent='Handbuch konnte nicht geladen werden: '+e.message;}
 }
 $('help-admin-save').addEventListener('click',async()=>{
  const c=preview.find(x=>x.slug===editSlug);if(!c)return;const b=$('help-admin-save');b.disabled=true;
  try{await window.SK_AUTH.saveHelp({p_slug:editSlug,p_title:$('help-admin-title').value,p_body:$('help-admin-body').value,p_section:$('help-admin-section').value,p_page_key:$('help-admin-page').value,p_audience:$('help-admin-audience').value,p_status:$('help-admin-status').value,p_position:c.position});
   $('help-admin-message').textContent='Gespeichert ✓';chapters=[];await loadAdmin();}catch(e){$('help-admin-message').textContent='Fehler: '+e.message;}finally{b.disabled=false;}
 });
 $('help-admin-new').addEventListener('click',()=>{const slug=prompt('Neuer Kapitel-Schlüssel (Kleinbuchstaben, Zahlen, Bindestrich):');if(!slug)return;if(!/^[a-z0-9-]{2,60}$/.test(slug))return alert('Ungültiger Kapitel-Schlüssel');if(preview.some(c=>c.slug===slug))return alert('Kapitel ist bereits vorhanden');const c={slug,title:'Neues Handbuchkapitel',section:'Allgemein',page_key:'profile',audience:'business',body:'# Neues Kapitel\n\nHier Anleitung ergänzen.\n\n![Screenshot](screenshot:beispiel-01)',status:'draft',position:200};preview.push(c);form(c);});
 $('help-admin-cancel').addEventListener('click',()=>$('help-admin-editor').classList.add('hidden'));
 $('help-image-upload').addEventListener('click',async()=>{
  const file=$('help-image-file').files[0],id=$('help-image-id').value.trim();
  if(!file||!id||!editSlug)return void ($('help-admin-message').textContent='Bild, Kapitel und Platzhalter-ID wählen.');
  if(!confirm('Dieses Screenshot-Bild wird öffentlich abrufbar. Sind alle persönlichen Daten und Geheimnisse entfernt?'))return;
  try{await window.SK_AUTH.uploadHelpScreenshot(editSlug,id,file);$('help-admin-message').textContent='Screenshot hochgeladen. Handbuch neu laden, um ihn anzuzeigen.';chapters=[];}
  catch(e){$('help-admin-message').textContent='Upload fehlgeschlagen: '+e.message;}
 });
 window.SK_HELP={load,loadAdmin,openContext,close:()=>$('help-drawer').classList.add('hidden')};
})();
