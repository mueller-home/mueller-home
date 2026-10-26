-- StaffKeeping 0.33.1.8.25 – Marktplatzdaten ohne Seiten-Reload aktualisieren.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$doc$
## 0.33.1.8.25 – Marktplatzaktualisierung
Marktplatz-Karte und Liste laden Inserate, Entfernungen und datenschutzgerecht gerundete Kartenkoordinaten erneut aus Supabase: bei Filteränderung (450 ms entprellt), beim Umschalten Liste/Karte, beim Wiederöffnen des Browser-Tabs und während sichtbarem Marktplatz spätestens nach ca. 30 Sekunden. Bereits geladene Ergebnisse bleiben während Hintergrundabfragen sichtbar; fehlgeschlagene Hintergrundabfragen leeren den letzten gültigen Stand nicht. Keine Änderung der vorhandenen Datenbank-RPCs und Berechtigungen. Produktiven Browser-Retest mit neu freigeschaltetem Inserat erforderlich.
$doc$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.8.25 – Marktplatzaktualisierung' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$doc$
## 0.33.1.8.25 – Status
Frontend-Patch für automatische Marktplatz-Aktualisierung vorbereitet. JavaScript-Syntax geprüft. Produktive Ausführung und Browser-Retest ausstehend. Voraussetzung 0.33.1.8.24. Offener Punkt Annette/Patrick: eigene produktive Google-Maps-Karten-ID anlegen und DEMO_MAP_ID ersetzen.
$doc$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.8.25 – Status' IN body)=0;
COMMIT;
