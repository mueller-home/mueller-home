-- StaffKeeping 0.33.1.8.23 – Projektdokumentation: getrennte inaktive Inserate
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$doc$
## 0.33.1.8.23 – Inaktive Inserate in eigener Gruppe
In «Meine Inserate» werden Inserate mit dem gespeicherten Status «Inaktiv» nicht mehr in der regulären Liste angezeigt, sondern in einer eigenen Gruppe «Inaktive Inserate» unterhalb der privaten Entwürfe. Die Gruppe erscheint nur, wenn entsprechende Inserate existieren. Bestehende Aktionen (Bearbeiten, Aktivieren, Entfernen und Chatverknüpfungen) bleiben unverändert. Abgelaufene Inserate bleiben in der regulären Liste; sie gelten nicht automatisch als ausdrücklich inaktiv. Keine Schema- oder Rechteänderung.
$doc$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.8.23 – Inaktive Inserate in eigener Gruppe' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$doc$
## 0.33.1.8.23 – Status
Darstellung von «Meine Inserate» angepasst: inaktive Inserate separat unter privaten Entwürfen. JavaScript-Syntax und ZIP-Struktur lokal geprüft; produktiver Browsertest offen. Vorgängerversion 0.33.1.8.22 ist Voraussetzung.
$doc$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.8.23 – Status' IN body)=0;
COMMIT;
