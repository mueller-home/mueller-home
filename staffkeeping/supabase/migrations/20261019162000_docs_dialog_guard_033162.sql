-- StaffKeeping 0.33.1.6.2: nur Dokumentations-Updates, keine Schema- oder Betriebsdatenänderung.
-- Vier UPDATEs; bei Supabase wird nur das abschliessende SELECT-Resultset direkt angezeigt.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$sk$
## 0.33.1.6.2 – Popup-Stabilität und Verlustschutz (19.10.2026)
Dialogschliessen über X/Escape/Navigieren wird bei Änderungen durch „Weiter bearbeiten“ / „Änderungen verwerfen“ geschützt. Hintergrundklick schliesst Popup nicht mehr; laufende Speicherung verhindert Schliessen. Unerwartete close-Events werden in der Browserkonsole protokolliert und ein Programm-Schliessen ohne Freigabe wird soweit möglich wieder geöffnet. Es handelt sich ausdrücklich noch NICHT um Auto-Save.
$sk$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.6.2 – Popup-Stabilität und Verlustschutz' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$sk$
## 0.33.1.6.2 – Popup-Stabilität und Verlustschutz (19.10.2026)
Patch 0.33.1.6.2 erstellt, statische Tests ausstehend bzw. separat zu dokumentieren; Live-Abnahme offen. Auslöser des bisherigen spontanen Schliessens ohne Interaktion nicht bewiesen. 0.33.1.7 Auto-Save bleibt offen.
$sk$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.6.2 – Popup-Stabilität und Verlustschutz' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$sk$
## 0.33.1.6.2 – Popup-Stabilität und Verlustschutz (19.10.2026)
Live-Retest 0.33.1.6.2: Dialog einige Minuten offen lassen; Felder bearbeiten, X/Escape und Navigieren prüfen; beide Schaltflächen im Änderungsdialog prüfen; Speicherfehler und Speichervorgang kontrollieren; Konsole auf [SK dialog] Meldungen prüfen. Standorttest 7 Retest und Tests 8–10 weiterhin offen.
$sk$,updated_at=now() WHERE slug='tests' AND position('## 0.33.1.6.2 – Popup-Stabilität und Verlustschutz' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$sk$
## 0.33.1.6.2 – Popup-Stabilität und Verlustschutz (19.10.2026)
Gezielter Frontend-Patch zum Schutz von Popups bei Eingaben; kein Datenbank-Schema-Eingriff. Vorgang ist nicht als vollumfängliche Auto-Save-Implementierung zu verstehen.
$sk$,updated_at=now() WHERE slug='history' AND position('## 0.33.1.6.2 – Popup-Stabilität und Verlustschutz' IN body)=0;
COMMIT;
SELECT slug,updated_at FROM sk_internal.project_doc_chapters WHERE slug IN ('concept','status','tests','history') ORDER BY slug;
