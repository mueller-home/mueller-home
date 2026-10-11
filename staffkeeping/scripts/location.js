/* StaffKeeping 0.29.1 – Maps JS Geocoder, kein hartcodierter Schlüssel */
'use strict';
(function(){
 const $=id=>document.getElementById(id);
 let sdk=null, map=null, marker=null, activeBusiness=null, writable=false, lastAddress='', request=0, locationBusy=false;
 const cfg=window.SK_MAPS_CONFIG||{};
 const label={CH:'Schweiz',DE:'Deutschland',AT:'Österreich'};
 const clean=v=>String(v||'').trim();
 const key=b=>[b.country,b.postal_code,b.city,b.street,b.house_number].map(v=>clean(v).toLowerCase()).join('|');
 const address=b=>[clean(b.street)+' '+clean(b.house_number),clean(b.postal_code)+' '+clean(b.city),label[b.country]||clean(b.country)].filter(x=>x.trim()).join(', ');
 function say(text){$('pr-location-status').textContent=text;}
 function updateReset(){const button=$('pr-location-reset');if(button){button.classList.toggle('hidden',!writable||activeBusiness?.location_source!=='manual');button.disabled=!writable||locationBusy;}}
 function current(){return {...activeBusiness,country:$('pr-country').value,postal_code:$('pr-postal').value,city:$('pr-city').value,street:$('pr-street').value,house_number:$('pr-number').value};}
 function hasCoordinates(b){return b&&Number.isFinite(Number(b.latitude))&&Number.isFinite(Number(b.longitude))&&b.latitude!=null&&b.longitude!=null;}
 function google(){
   if(window.google?.maps)return Promise.resolve(window.google.maps);
   if(sdk)return sdk;
   if(!cfg.googleMapsApiKey){return Promise.reject(Error('Google-Maps-Schlüssel fehlt in scripts/maps-config.js.'));}
   sdk=new Promise((resolve,reject)=>{
     const name='skMapsReady'+Date.now();
     window[name]=()=>{delete window[name];resolve(window.google.maps);};
     const script=document.createElement('script');script.src='https://maps.googleapis.com/maps/api/js?loading=async&key='+encodeURIComponent(cfg.googleMapsApiKey)+'&callback='+name;
     script.async=true;script.onerror=()=>{delete window[name];reject(Error('Google Maps konnte nicht geladen werden.'));};document.head.append(script);
   });return sdk;
 }
 function pin(maps,googleMap,pos,draggable,onDrag){
   const point={lat:Number(pos.latitude),lng:Number(pos.longitude)};
   const mark=new maps.Marker({position:point,map:googleMap,draggable:draggable,title:'Betriebsstandort'});
   if(onDrag)mark.addListener('dragend',e=>onDrag(e.latLng.lat(),e.latLng.lng()));
   return mark;
 }
 function redraw(){
   if(!map||!activeBusiness)return;
   if(marker){marker.setMap(null);marker=null;}
   if(hasCoordinates(activeBusiness)){
     const pos={lat:Number(activeBusiness.latitude),lng:Number(activeBusiness.longitude)};
     map.setCenter(pos);map.setZoom(activeBusiness.location_source==='manual'?16:activeBusiness.street?16:11);
     marker=pin(window.google.maps,map,activeBusiness,false,async(lat,lng)=>{
       const snapshot=current();
       try{say('Korrigierte Position wird gespeichert …');await window.SK_AUTH.saveMyLocation({p_latitude:lat,p_longitude:lng,p_source:'manual',p_address_key:key(snapshot)});
         activeBusiness={...activeBusiness,latitude:lat,longitude:lng,location_source:'manual',location_address_key:key(snapshot)};
         marker.setDraggable(false);updateReset();say('Manuell bestätigter Standort gespeichert ✓');
       }catch(e){say('Standort nicht gespeichert: '+e.message);redraw();}
     });
   }
 }
 async function initMap(){
   const maps=await google();
   if(!map){map=new maps.Map($('pr-map'),{center:{lat:47,lng:9},zoom:6,mapTypeControl:false,streetViewControl:false});}
   redraw();
 }
 async function geocode(force=false){
   if(!activeBusiness||!writable||locationBusy)return;
   const b=current(),aKey=key(b);
   if(!b.postal_code.trim()||!b.city.trim())return say('Land, PLZ und Ort werden für die Standortbestimmung benötigt.');
   if(activeBusiness.location_source==='manual')return say('Manuell bestätigte Position bleibt erhalten. Mit „Position automatisch neu ermitteln“ kannst du sie ausdrücklich ersetzen.');
   if(!force&&activeBusiness.location_address_key===aKey&&hasCoordinates(activeBusiness))return;
   const serial=++request;locationBusy=true;
   try{
     const maps=await google();
     const geocoder=new maps.Geocoder();say('Google ermittelt den Standort …');
     const {results}=await geocoder.geocode({address:address(b),componentRestrictions:{country:b.country}});
     if(serial!==request)return;
     const found=results?.[0];if(!found)throw Error('Keine eindeutige Position gefunden.');
     const position=found.geometry.location;
     // Die Standort-RPC lehnt Antworten für inzwischen geänderte Adressen ab.
     if(key(current())!==aKey)return;
     await window.SK_AUTH.saveMyLocation({p_latitude:position.lat(),p_longitude:position.lng(),p_source:'geocoded',p_address_key:aKey});
     activeBusiness={...activeBusiness,latitude:position.lat(),longitude:position.lng(),location_source:'geocoded',location_address_key:aKey};
     if(!map)await initMap();redraw();say(b.street?.trim()?'Standort aus Adresse ermittelt ✓':'Ungefährer Standort aus PLZ und Ort ✓');
   }catch(e){say('Standort konnte nicht ermittelt werden: '+e.message);}
   finally{locationBusy=false;updateReset();}
 }
 async function load(b,canEdit){
   activeBusiness={...b};writable=canEdit;lastAddress=key(b);request++;updateReset();
   $('pr-location-search').disabled=!writable;$('pr-location-correct').disabled=!writable;
   try{await initMap();
     if(activeBusiness.location_source==='manual')say('Manuell bestätigter Betriebsstandort. Du kannst ihn verschieben oder automatisch neu ermitteln.');
     else if(hasCoordinates(activeBusiness)&&activeBusiness.location_address_key===key(b))say(b.street?'Standort aus Adresse':'Ungefährer Standort aus PLZ und Ort');
     else if(writable)await geocode();
     else say('Noch kein Standort hinterlegt.');
   }catch(e){say(e.message+' Die Profilbearbeitung ist weiterhin möglich.');}
 }
 async function addressSaved(b,payload){
   if(!activeBusiness||!writable)return;
   const next={...activeBusiness,country:$('pr-country').value,company_name:payload.p_company_name,postal_code:payload.p_postal_code,city:payload.p_city,street:payload.p_street,house_number:payload.p_house_number};
   const now=key(next);activeBusiness={...activeBusiness,...next};
   if(now!==lastAddress){lastAddress=now;
     if(activeBusiness.location_source==='manual')say('Adresse geändert. Der manuell bestätigte Standort bleibt erhalten; bitte auf Richtigkeit prüfen.');
     else void geocode();
   }
 }
 async function showAdmin(b){
   const root=$('business-admin-map'),state=$('business-admin-map-status');if(!root)return;
   if(!hasCoordinates(b)){state.textContent='Standort noch nicht ermittelt.';root.textContent='Keine Kartenposition hinterlegt.';return;}
   try{const maps=await google();if(!root.isConnected)return;
     const center={lat:Number(b.latitude),lng:Number(b.longitude)};
     const instance=new maps.Map(root,{center,zoom:b.location_source==='manual'||b.street?16:11,mapTypeControl:false,streetViewControl:false});
     pin(maps,instance,b,false,null);
     state.textContent=b.location_source==='manual'?'Manuell bestätigte Position':b.street?'Standort aus Adresse':'Ungefährer Standort aus PLZ und Ort';
   }catch(e){state.textContent='Kartenanzeige nicht verfügbar: '+e.message;}
 }
 $('pr-location-search').addEventListener('click',()=>{void geocode(true);});
 // Neue automatische Ermittlung: Google muss zuerst eine neue Position liefern,
 // bevor die manuelle Position in Supabase aufgehoben wird.
 async function resetToGeocoded(){
   if(!writable||!activeBusiness||locationBusy)return;
   if(activeBusiness.location_source!=='manual')return void geocode(true);
   if(!confirm('Manuelle Position durch den automatisch ermittelten Standort aus der aktuellen Adresse ersetzen?'))return;
   const b=current(),addressKey=key(b);
   if(!b.postal_code.trim()||!b.city.trim())return say('Zuerst Land, PLZ und Ort ausfüllen.');
   // Offene Auto-Save-Eingaben vor der Geocodierung speichern.
   if(window.SK_PROFILE?.hasPending()&&!(await window.SK_PROFILE.beforeLeave()))return say('Bitte zuerst die Profiländerungen speichern.');
   if(key(current())!==addressKey)return say('Adresse wurde geändert; bitte erneut versuchen.');
   locationBusy=true;updateReset();++request;
   const old={...activeBusiness};let cleared=false;
   try{
     const maps=await google();
     say('Google ermittelt zuerst die neue Position …');
     const {results}=await new maps.Geocoder().geocode({address:address(b),componentRestrictions:{country:b.country}});
     if(!results?.[0])throw Error('Keine Position für diese Adresse gefunden.');
     if(key(current())!==addressKey)throw Error('Adresse wurde zwischenzeitlich geändert.');
     const point=results[0].geometry.location;
     // Die alte Position bleibt erhalten, wenn Google keine Position findet.
     say('Neue Position ermittelt; sie wird gespeichert …');
     await window.SK_AUTH.saveMyLocation({p_latitude:null,p_longitude:null,p_source:'reset',p_address_key:addressKey});cleared=true;
     await window.SK_AUTH.saveMyLocation({p_latitude:point.lat(),p_longitude:point.lng(),p_source:'geocoded',p_address_key:addressKey});
     activeBusiness={...activeBusiness,latitude:point.lat(),longitude:point.lng(),location_source:'geocoded',location_address_key:addressKey};
     redraw();say('Position automatisch neu ermittelt und gespeichert ✓');
   }catch(e){
     // Bei Fehler nach dem Reset die bestätigte Altposition bestmöglich wiederherstellen.
     if(cleared){
       try{await window.SK_AUTH.saveMyLocation({p_latitude:old.latitude,p_longitude:old.longitude,p_source:'manual',p_address_key:addressKey});}
       catch{say('Speicherfehler: Bitte Seite neu laden und Standort kontrollieren.');return;}
     }
     say('Neue Ermittlung fehlgeschlagen. Bisherige Position bleibt erhalten: '+e.message);
   }finally{locationBusy=false;updateReset();}
 }
 $('pr-location-reset').addEventListener('click',()=>{void resetToGeocoded();});
 $('pr-location-correct').addEventListener('click',async()=>{
   if(!writable)return;
   try{await initMap();if(!marker)return say('Zuerst Standort automatisch ermitteln.');
     marker.setDraggable(true);say('Marker verschieben. Beim Loslassen wird die Position gespeichert.');
   }catch(e){say(e.message);}
 });
 window.SK_LOCATION={load,addressSaved,showAdmin};
})();
// StaffKeeping 0.33.1.5 – wiederverwendbarer Karteneditor für betriebs-ID-basierte Formulare.
(function(){
  const existing=window.SK_LOCATION||{};
  let editor=null;
  const cfg=window.SK_MAPS_CONFIG||{};
  const norm=v=>String(v??'').trim();
  function addressKey(b){return [b.country,b.postal_code,b.city,b.street,b.house_number].map(v=>norm(v).toLowerCase()).join('|');}
  function fields(form){const v=n=>norm(form.elements.namedItem(n)?.value);return {country:v('country'),postal_code:v('postal_code'),city:v('city'),street:v('street'),house_number:v('house_number')};}
  function address(b){return [([b.street,b.house_number].filter(Boolean).join(' ')),[b.postal_code,b.city].filter(Boolean).join(' '),({CH:'Schweiz',DE:'Deutschland',AT:'Österreich'})[b.country]||b.country].filter(Boolean).join(', ');}
  async function mapsReady(){
    if(window.google?.maps?.Map)return window.google.maps;
    if(!cfg.googleMapsApiKey)throw Error('Google-Maps-Konfiguration fehlt.');
    if(!window.__skMapPromise)window.__skMapPromise=new Promise((resolve,reject)=>{
      const cb='skGoogleMaps'+Date.now();window[cb]=()=>{delete window[cb];resolve(window.google.maps);};
      const script=document.createElement('script');script.async=true;script.src='https://maps.googleapis.com/maps/api/js?loading=async&key='+encodeURIComponent(cfg.googleMapsApiKey)+'&callback='+cb;
      script.onerror=()=>reject(Error('Google Maps konnte nicht geladen werden.'));document.head.appendChild(script);
    });
    return window.__skMapPromise;
  }
  async function editBusiness(form,b={}){
    if(!form)return;
    const root=form.querySelector('#sk-edit-business-map'),status=form.querySelector('#sk-edit-location-status');
    if(!root||!status)return;
    const disabled=!form.querySelector('[type=submit]');
    const valid=(lat,lng)=>lat!==null&&lat!==undefined&&lng!==null&&lng!==undefined&&
      Number.isFinite(Number(lat))&&Number.isFinite(Number(lng))&&Math.abs(Number(lat))<=90&&Math.abs(Number(lng))<=180;
    const sameAddress=addressKey(fields(form))===addressKey(b);
    const state={form,root,status,map:null,marker:null,position:null,addressKey:null,source:null,businessId:b.id||null,
      initialKey:addressKey(b),serial:0,timer:null,manual:false,loading:false};
    if(editor?.timer)clearTimeout(editor.timer);
    editor=state;
    const live=()=>editor===state&&root.isConnected;
    const say=msg=>{if(live())status.textContent=msg;};
    const clear=()=>{state.position=null;state.addressKey=null;state.source=null;state.manual=false;
      if(state.marker)state.marker.setMap(null);state.marker=null;};
    async function markerAt(lat,lng,source,expectedKey){
      lat=Number(lat);lng=Number(lng);
      if(!valid(lat,lng))throw Error('Ungültige Standortkoordinaten. Bitte Adresse erneut ermitteln.');
      const maps=await mapsReady();if(!live()||(expectedKey&&expectedKey!==addressKey(fields(form))))return false;
      if(!state.map)state.map=new maps.Map(root,{center:{lat,lng},zoom:16,streetViewControl:false,mapTypeControl:false});
      if(state.marker)state.marker.setMap(null);
      state.position={lat,lng};state.source=source;state.addressKey=addressKey(fields(form));state.manual=source==='manual';
      state.map.setCenter({lat,lng});state.map.setZoom(16);
      state.marker=new maps.Marker({position:{lat,lng},map:state.map,draggable:false,title:'Betriebsstandort'});
      return true;
    }
    async function geo(force=false){
      if(!live()||disabled)return;
      const snapshot=fields(form),snapshotKey=addressKey(snapshot),serial=++state.serial;
      if(!snapshot.country||!snapshot.postal_code||!snapshot.city){
        say('Land, PLZ und Ort erfassen; die Standortermittlung startet danach automatisch.');return;
      }
      if(state.manual&&!force)return;
      if(state.position&&state.addressKey===snapshotKey&&!force)return;
      state.loading=true;say('Standort wird automatisch ermittelt …');
      try{
        const maps=await mapsReady();
        const {results}=await new maps.Geocoder().geocode({address:address(snapshot),componentRestrictions:{country:snapshot.country}});
        if(!live()||serial!==state.serial||snapshotKey!==addressKey(fields(form)))return;
        if(!results?.length)throw Error('Google hat die Adresse nicht gefunden.');
        const pos=results[0].geometry.location;
        if(await markerAt(pos.lat(),pos.lng(),'geocoded',snapshotKey))say('Standort automatisch ermittelt. Bitte Position prüfen und anschliessend speichern.');
      }catch(e){if(live()&&serial===state.serial)say('Standort konnte nicht ermittelt werden: '+e.message+' Du kannst die Ermittlung erneut starten.');}
      finally{if(live()&&serial===state.serial)state.loading=false;}
    }
    function scheduleGeo(){
      if(!live())return;
      ++state.serial;
      if(state.timer)clearTimeout(state.timer);
      const newKey=addressKey(fields(form));
      if(newKey===state.addressKey&&state.position)return;
      clear();say('Adresse geändert. Der Standort wird automatisch neu ermittelt …');
      state.timer=setTimeout(()=>{if(live())void geo();},700);
    }
    form.querySelectorAll('[name="country"],[name="postal_code"],[name="city"],[name="street"],[name="house_number"]').forEach(el=>{
      el.addEventListener('input',scheduleGeo);el.addEventListener('change',scheduleGeo);
    });
    form.querySelector('#sk-edit-location-search')?.addEventListener('click',()=>{
      if(state.timer)clearTimeout(state.timer);void geo(true);
    });
    form.querySelector('#sk-edit-location-correct')?.addEventListener('click',()=>{
      if(!live())return;
      if(!state.marker)return say('Zuerst Standort ermitteln.');
      state.marker.setDraggable(true);say('Marker auf der Karte an den richtigen Ort ziehen.');
      state.marker.addListener('dragend',e=>{
        if(!live())return;
        state.serial++;
        if(state.timer)clearTimeout(state.timer);
        state.position={lat:e.latLng.lat(),lng:e.latLng.lng()};state.source='manual';state.manual=true;
        state.addressKey=addressKey(fields(form));state.marker.setDraggable(false);
        say('Position manuell korrigiert. Diese Position bleibt bis zur nächsten Adressänderung erhalten. Bitte speichern.');
      });
    });
    if(valid(b.latitude,b.longitude)&&sameAddress){
      try{await markerAt(b.latitude,b.longitude,b.location_source||'geocoded');say('Gespeicherter Standort geladen.');}
      catch(e){say('Kartenanzeige nicht verfügbar: '+e.message);}
    }else if(!disabled){
      say('Noch kein gespeicherter Standort. Er wird aus der Adresse ermittelt.');
      scheduleGeo();
    }else say('Noch kein gespeicherter Standort. Während der Prüfung nur lesbar.');
    if(disabled&&state.position)say('Gespeicherter Standort (nur zur Ansicht).');
  }
  function editorPosition(form){
    if(!editor||editor.form!==form||!editor.root.isConnected)return null;
    if(!editor.position||editor.addressKey!==addressKey(fields(form)))return null;
    return {...editor.position,addressKey:editor.addressKey,source:editor.source};
  }
  async function adminPreview(b){
    const root=document.getElementById('business-admin-map'),status=document.getElementById('business-admin-map-status');
    if(!root)return;
    const same=()=>root.isConnected;
    try{
      const maps=await mapsReady();if(!same())return;
      let lat=Number(b.latitude),lng=Number(b.longitude),preview=false;
      if(b.latitude==null||b.longitude==null||!Number.isFinite(lat)||!Number.isFinite(lng)){
        const {results}=await new maps.Geocoder().geocode({address:address(b),componentRestrictions:{country:b.country}});
        if(!same())return;
        if(!results?.length)throw Error('Kein Standort hinterlegt; Adresse nicht gefunden.');
        lat=results[0].geometry.location.lat();lng=results[0].geometry.location.lng();preview=true;
      }
      const m=new maps.Map(root,{center:{lat,lng},zoom:b.street?16:11,streetViewControl:false,mapTypeControl:false});
      new maps.Marker({position:{lat,lng},map:m,title:preview?'Ungeprüfte Vorschau':'Gespeicherter Betriebsstandort'});
      status.textContent=preview?'Nur Karten-Vorschau aus der Adresse – keine gespeicherten oder freigegebenen Koordinaten.':b.location_source==='manual'?'Manuell bestätigter Standort':'Gespeicherter Standort';
    }catch(e){if(same()){status.textContent='Kartenanzeige nicht verfügbar: '+e.message;root.textContent='Standortkarte derzeit nicht verfügbar.';}}
  }
  window.SK_LOCATION={...existing,editBusiness,editorPosition,showAdmin:adminPreview};
})();
