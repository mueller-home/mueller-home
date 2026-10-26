-- StaffKeeping 0.33.1.8.17: Dokumentation Inseratlink im Chat.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$doc$
## 0.33.1.8.17 – Inseratlink in Unterhaltungen
Im Kopf jeder Chat-Unterhaltung führt «Zum Inserat» zur Detailansicht des verknüpften Inserats. Die Navigationsfunktion nutzt die bestehende Inserat-ID aus sk_chat_threads und die vorhandene berechtigungsgeschützte Marktplatzabfrage. Ist ein Inserat nicht mehr im Marktplatz verfügbar, wird dies angezeigt, ohne eine falsche Detailansicht zu öffnen. Keine neue Datenbankberechtigung und keine Änderung an Chat-RPCs.
$doc$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.8.17 – Inseratlink in Unterhaltungen' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$doc$
## 0.33.1.8.17 – Status
Browser-Rückmeldung: automatische Nachrichtenaktualisierung aus 0.33.1.8.16 funktioniert. Inseratlink im Chat ergänzt; produktiver Browser-Kurztest noch offen.
$doc$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.8.17 – Status' IN body)=0;
COMMIT;
