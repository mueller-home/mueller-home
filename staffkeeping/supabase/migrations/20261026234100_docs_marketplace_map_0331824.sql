-- StaffKeeping 0.33.1.8.24 – Marktplatzkarte und moderne Marker.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$doc$
## 0.33.1.8.24 – Marktplatzkartenansicht und Google Maps
Marktplatz erhält einen Umschalter Liste/Karte mit identischen Filtern. Marker verlinken zu Inseratdetails. Nicht kartierbare Inserate bleiben separat erreichbar. Neue RPC sk_marketplace_map_locations liefert nur veröffentlichte, fremde Inserate freigegebener Betriebe mit bestätigten Koordinaten; Positionen auf zwei Dezimalstellen gerundet, keine exakte Betriebsadresse. Marker in allen vorhandenen Standortkomponenten werden auf AdvancedMarkerElement umgestellt (Google-Maps-Karten-ID erforderlich). maps-config.js kann optional googleMapsMapId enthalten; ohne ID DEMO_MAP_ID nur für Tests. Standortbearbeitung / manuelle Markerbestätigung ist gegen Regressionen zu prüfen.
$doc$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.8.24 – Marktplatzkartenansicht und Google Maps' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$doc$
## 0.33.1.8.24 – Status
Marktplatzkarte, gerundete Koordinaten-RPC und AdvancedMarkerElement vorbereitet. JavaScript-Syntax und ZIP-Aufbau lokal geprüft; produktive SQL-/Browser-/Berechtigungstests ausstehend. Voraussetzung Version 0.33.1.8.23. Eigene Google-Maps-Karten-ID für Produktivbetrieb eintragen.
$doc$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.8.24 – Status' IN body)=0;
COMMIT;
