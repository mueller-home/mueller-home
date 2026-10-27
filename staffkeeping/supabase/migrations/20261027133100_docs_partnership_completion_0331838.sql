-- StaffKeeping 0.33.1.8.38 – zentrale Projektdokumentation.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$n$
## 0.33.1.8.38 – Abschluss und Bewertung
Dashboard: «Zusammenarbeit läuft · Abschluss bestätigen» wird erst ab dem Inserat-Enddatum (Schweizer Kalenderdatum) angeboten. Das Enddatum wird über die berechtigungsgeprüfte Funktion sk_partnership_end_dates gelesen; ohne Enddatum-Abfrage keine vorzeitige Abschlussaufgabe. Nach der zweiten Abschlussbestätigung führt der Chat direkt zum passenden Bewertungsformular. Nach der ersten Bestätigung wird weiterhin auf die Bestätigung der Gegenseite hingewiesen.
$n$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.8.38 – Abschluss und Bewertung' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$n$
## 0.33.1.8.38 – Teststand
Dashboard-Fristlogik und Navigation zum Bewertungsformular implementiert. SQL-Migration, produktiver Funktionstest und Berechtigungs-Negativtests noch offen.
$n$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.8.38 – Teststand' IN body)=0;
COMMIT;
