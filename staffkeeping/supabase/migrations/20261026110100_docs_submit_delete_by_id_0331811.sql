-- StaffKeeping 0.33.1.8.11 – zentrale Projektdokumentation.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$doc$
## 0.33.1.8.11 – Freischaltung und Löschung mit Betriebs-ID
Neue RPCs sk_submit_business_by_id(uuid), sk_business_deletion_status_by_id(uuid), sk_request_business_deletion_by_id(uuid,text,text) prüfen Authentifizierung und Eigentümerbezug zum ausgewählten Betrieb. Freischaltung bleibt bei Annette. Bereits freigegebene Betriebe erfordern bei Löschung eine Admin-Prüfung. Der Abbruch noch nicht eingereichter Registrierungen erzeugt einen genehmigten Löschvorgang und sperrt den Betrieb, löscht jedoch weder das Login noch andere Betriebe automatisch. Die endgültige Löschung läuft ausschliesslich im kontrollierten Admin-Prozess. Die Legacy-RPCs und Legacy-Ansicht bleiben vorerst kompatibel, bis Regressionstests erfolgreich abgeschlossen sind. UI-Texte Deutsch (Schweiz).
$doc$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.8.11 – Freischaltung' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$doc$
## 0.33.1.8.11 – Status
Version erstellt, produktive SQL-Ausführung und Browser-Retest noch offen. 0.33.1.8.9 6/6 bestätigt. 0.33.1.8.10 Sprachkorrektur noch separat zu kontrollieren. Keine Entfernung der alten RPCs oder endgültige automatische Betriebslöschung in dieser Version.
$doc$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.8.11 – Status' IN body)=0;
COMMIT;
SELECT slug,updated_at FROM sk_internal.project_doc_chapters WHERE slug IN ('concept','status') ORDER BY slug;
