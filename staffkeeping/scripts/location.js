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
