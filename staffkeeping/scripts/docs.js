/* StaffKeeping 0.27.2 – EIN führender Datenbestand: sk_internal.project_doc_chapters. */
'use strict';
(function(){
 const $=id=>document.getElementById(id);
 let chapters=[], selected=null, editing=false, originalUrl=null, loaded=false;
 const status=(msg)=>{$('doc-save-status').textContent=msg;};
 // Untrusted Markdown: create DOM nodes and text nodes, never parse user HTML.
 function renderMarkdown(raw){
   const root=document.createDocumentFragment();
   const lines=String(raw||'').replace(/\r\n?/g,'\n').split('\n');
   const put=(parent,tag,value)=>{const n=document.createElement(tag);if(value!==undefined)n.textContent=value;parent.append(n);return n;};
   function inline(parent,value){
     const pattern=/(\[([^\]\n]+)\]\((https?:\/\/[^\s)]+)\)|\*\*([^*\n]+)\*\*|`([^`\n]+)`|\*([^*\n]+)\*)/g;
     let last=0,m;while((m=pattern.exec(value))){if(m.index>last)parent.append(document.createTextNode(value.slice(last,m.index)));
       if(m[2]){try{const u=new URL(m[3]);if(!['https:','http:'].includes(u.protocol))throw Error('link');const a=put(parent,'a',m[2]);a.href=u.href;a.target='_blank';a.rel='noopener noreferrer';}catch{parent.append(document.createTextNode(m[0]));}}
       else if(m[4])put(parent,'strong',m[4]);else if(m[5])put(parent,'code',m[5]);else if(m[6])put(parent,'em',m[6]);last=pattern.lastIndex;}
     if(last<value.length)parent.append(document.createTextNode(value.slice(last)));
   }
   const isRule=x=>/^\s*(?:-{3,}|\*{3,}|_{3,})\s*$/.test(x);
   const isHeading=x=>/^\s{0,3}#{1,6}\s+/.test(x);
   const isBullet=x=>/^\s*[-*+]\s+/.test(x);
   const isNumbered=x=>/^\s*\d+[.)]\s+/.test(x);
   const isTableLine=x=>/^\s*\|.*\|\s*$/.test(x);
   const isSpecial=x=>isRule(x)||isHeading(x)||isBullet(x)||isNumbered(x)||/^\s*```/.test(x)||isTableLine(x)||/^\s*>\s?/.test(x);
   const cells=x=>x.trim().replace(/^\|/,'').replace(/\|$/,'').split('|').map(y=>y.trim());
   let i=0;
   while(i<lines.length){const line=lines[i];if(!line.trim()){i++;continue;}
     if(/^\s*```/.test(line)){const code=[];i++;while(i<lines.length&&!/^\s*```/.test(lines[i]))code.push(lines[i++]);if(i<lines.length)i++;put(put(root,'pre'),'code',code.join('\n'));continue;}
     if(isRule(line)){put(root,'hr');i++;continue;}
     const hm=line.match(/^\s{0,3}(#{1,6})\s+(.+?)\s*#*\s*$/);
     if(hm){inline(put(root,'h'+Math.min(6,hm[1].length+1)),hm[2]);i++;continue;}
     if(isTableLine(line)&&i+1<lines.length&&/^\s*\|?[\s:|-]+\|[\s:|-]*$/.test(lines[i+1])&&lines[i+1].includes('-')){
       const table=put(root,'table'),thead=put(table,'thead'),tr=put(thead,'tr');cells(line).forEach(v=>inline(put(tr,'th'),v));i+=2;const tbody=put(table,'tbody');while(i<lines.length&&isTableLine(lines[i])){const row=put(tbody,'tr');cells(lines[i]).forEach(v=>inline(put(row,'td'),v));i++;}continue;
     }
     if(isBullet(line)||isNumbered(line)){
       const numbered=isNumbered(line),list=put(root,numbered?'ol':'ul');
       while(i<lines.length&&(numbered?isNumbered(lines[i]):isBullet(lines[i]))){const item=put(list,'li');const t=lines[i].replace(numbered?/^\s*\d+[.)]\s+/:/^\s*[-*+]\s+/,'');const check=t.match(/^\[([ xX])\]\s*(.*)$/);if(check){const checkbox=put(item,'span',check[1].toLowerCase()==='x'?'☑ ':'☐ ');checkbox.setAttribute('aria-hidden','true');inline(item,check[2]);}else inline(item,t);i++;}continue;
     }
     if(/^\s*>\s?/.test(line)){const quote=put(root,'blockquote');while(i<lines.length&&/^\s*>\s?/.test(lines[i])){inline(put(quote,'p'),lines[i].replace(/^\s*>\s?/,''));i++;}continue;}
     const para=[];while(i<lines.length&&lines[i].trim()&&(!para.length||!isSpecial(lines[i]))){para.push(lines[i].trim());i++;}
     if(para.length)inline(put(root,'p'),para.join(' '));else{inline(put(root,'p'),lines[i]);i++;}
   }
   return root;
 }

 const update=()=>{
   const chapter=chapters.find(x=>x.slug===selected);
   if(!chapter)return;
   $('doc-heading').textContent=chapter.title;
   $('doc-body').replaceChildren(renderMarkdown(chapter.body));
   $('doc-updated').textContent='Letzte Aktualisierung: '+new Date(chapter.updated_at).toLocaleString('de-CH');
   $('doc-editor').classList.toggle('hidden',!editing);
   $('doc-body').classList.toggle('hidden',editing);
   $('doc-edit').textContent=editing?'Bearbeitung läuft':'Bearbeiten';
   if(editing)$('doc-edit-body').value=chapter.body;
   renderMenu();
 };
 function renderMenu(){
   const q=$('doc-search').value.trim().toLocaleLowerCase('de');
   const list=$('doc-chapter-list');list.replaceChildren();
   for(const ch of chapters.filter(x=>!q || (x.title+' '+x.body).toLocaleLowerCase('de').includes(q))){
     const button=document.createElement('button');button.type='button';button.textContent=ch.title;
     button.classList.toggle('active',ch.slug===selected);button.setAttribute('aria-current',ch.slug===selected?'true':'false');
     button.addEventListener('click',()=>{if(editing&&$('doc-edit-body').value!==chapters.find(x=>x.slug===selected).body){status('Bitte zuerst speichern oder abbrechen.');return;}editing=false;selected=ch.slug;status('');update();});
     list.append(button);
   }
 }
 async function load(){
   if(loaded)return;
   status('Lade geschützte Kapitel aus Supabase …');
   try{chapters=await window.SK_AUTH.listProjectDocs();loaded=true;selected=chapters[0]?.slug||null;editing=false;renderMenu();if(selected)update();status(chapters.length+' Kapitel geladen. Änderungen werden direkt in der zentralen Dokumentation gespeichert.');}
   catch(e){status('Dokumentation nicht verfügbar: '+e.message+' (Migration 0.27 prüfen).');}
 }
 $('doc-search').addEventListener('input',renderMenu);
 $('doc-edit').addEventListener('click',()=>{if(!selected)return;if(editing){status('Bitte speichern oder abbrechen.');return;}editing=true;update();status('Änderung noch nicht gespeichert.');});
 $('doc-cancel').addEventListener('click',()=>{editing=false;update();status('Bearbeitung verworfen.');});
 $('doc-save').addEventListener('click',async()=>{
   const chapter=chapters.find(x=>x.slug===selected);if(!chapter)return;
   const body=$('doc-edit-body').value;
   const button=$('doc-save');button.disabled=true;status('Speichert …');
   try{await window.SK_AUTH.saveProjectDoc(chapter.slug,body);chapter.body=body;chapter.updated_at=new Date().toISOString();editing=false;update();status('In Supabase gespeichert.');}
   catch(e){status('Nicht gespeichert: '+e.message+' – Änderungen bleiben im Editor.');}
   finally{button.disabled=false;}
 });
 $('copy-doc').addEventListener('click',async()=>{const c=chapters.find(x=>x.slug===selected);if(!c)return;try{await navigator.clipboard.writeText(c.title+'\n\n'+c.body);$('doc-copy-info').textContent='Kapitel kopiert.';}catch(e){$('doc-copy-info').textContent='Bitte Text markieren und kopieren.';}});
 function close(){if(originalUrl){URL.revokeObjectURL(originalUrl);originalUrl=null;}$('private-doc-frame').removeAttribute('src');$('private-doc-viewer').classList.add('hidden');}
 const originalStatus=t=>{$('private-doc-status').textContent=t;};
 $('private-doc-close').addEventListener('click',()=>{close();originalStatus('Historisches Original geschlossen.');});
 $('private-doc-open').addEventListener('click',async()=>{
   close();originalStatus('Lade historisches Original aus privatem Storage …');
   try{
     const html=await window.SK_AUTH.getPrivateMigrationConcept();
     // Keine Ausführung eingebetteter Skripte, keine Origin-Berechtigung, keine Fremdrequests.
     const csp=`<meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src data: blob:; style-src 'unsafe-inline'; font-src data:; form-action 'none'; base-uri 'none'">`;
     const secureHtml=/<head[^>]*>/i.test(html)?html.replace(/<head([^>]*)>/i,'<head$1>'+csp):csp+html;
     originalUrl=URL.createObjectURL(new Blob([secureHtml],{type:'text/html'}));
     $('private-doc-frame').src=originalUrl;$('private-doc-viewer').classList.remove('hidden');
     originalStatus('Historisches Original v2.2 – unveränderte Referenz, keine zweite Arbeitsdokumentation.');
   }catch(e){originalStatus('Nicht geladen: '+e.message+' – privaten Bucket und Upload prüfen.');}
 });
 $('private-doc-upload').addEventListener('click',()=>{$('private-doc-file').click();});
 $('private-doc-file').addEventListener('change',async e=>{const file=e.target.files?.[0];if(!file)return;originalStatus('Lade Original geschützt hoch …');try{await window.SK_AUTH.uploadPrivateMigrationConcept(file);originalStatus('Original hochgeladen. Über «Originalkonzept anzeigen» öffnen.');}catch(e){originalStatus('Upload fehlgeschlagen: '+e.message);}finally{e.target.value='';}});
 window.SK_DOCS={load,close};
})();
