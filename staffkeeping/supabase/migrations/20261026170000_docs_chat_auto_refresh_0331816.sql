-- StaffKeeping 0.33.1.8.16: Dokumentation automatische Nachrichtenaktualisierung.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$doc$
## 0.33.1.8.16 – Automatische Nachrichtenaktualisierung
Während die Nachrichtenansicht sichtbar ist, prüft die Oberfläche alle zwei Sekunden über die vorhandenen berechtigungsgeschützten RPCs auf neue Unterhaltungen und Nachrichten. Bei Änderungen aktualisiert sie die Ansicht ohne manuelles Neuladen. In anderen Ansichten und bei Hintergrund-Tabs wird nicht abgefragt. Keine Freigabe der privaten Chat-Tabellen, keine zusätzlichen Datenbankrechte. Technisch handelt es sich um Intervallabfragen, nicht um Push-Echtzeit. Browser-Retest offen.
$doc$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.8.16 – Automatische Nachrichtenaktualisierung' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$doc$
## 0.33.1.8.16 – Status
Automatische Chat-Aktualisierung im Abstand von zwei Sekunden implementiert. Änderungserkennung vermeidet unnötiges Neuzeichnen. Datenzugriff nur über bestehende RPC-Berechtigungen. Produktiver Browser-Retest offen.
$doc$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.8.16 – Status' IN body)=0;
COMMIT;
