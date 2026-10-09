/* StaffKeeping 0.27 – EIN führender Datenbestand: sk_internal.project_doc_chapters. */
'use strict';
(function(){
 const $=id=>document.getElementById(id);
 let chapters=[], selected=null, editing=false, originalUrl=null, loaded=false;
 const status=(msg)=>{$('doc-save-status').textContent=msg;};
 const update=()=>{
   const chapter=chapters.find(x=>x.slug===selected);
   if(!chapter)return;
   $('doc-heading').textContent=chapter.title;
   $('doc-body').textContent=chapter.body;
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
 $('private-doc-file').addEventListener('change',async e=>{const file=e.target.files?.[0];if(!file)return;originalStatus('Lade Original geschützt hoch …');try{await window.SK_AUTH.uploadPrivateMigrationConcept(file);originalStatus('Original hochgeladen. Über «Originalkonzept anzeigen» öffnen.');}catch(e){originalStatus('Upload fehlgeschlagen: '+e.message);}finally{e.target.value='';}});
 window.SK_DOCS={load,close};
})();
