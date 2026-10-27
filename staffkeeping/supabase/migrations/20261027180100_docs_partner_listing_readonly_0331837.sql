-- StaffKeeping 0.33.1.8.37 – zentrale Projektdokumentation.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$n$
## 0.33.1.8.37 – Partnerinserat schreibgeschützt
Nach Annahme der Vergabe sind Inserate für beide berechtigten beteiligten Betriebe über den Chat in einer Leseansicht verfügbar, auch wenn sie aus dem öffentlichen Marktplatz entfernt wurden. Bearbeitung, Statusänderung und Löschung sind für Status Vergeben/Abgeschlossen nicht zulässig. Serverseitiger UPDATE-Trigger verhindert Datenmanipulation ausserhalb des bestehenden Statuswechsels. Berechtigungsgeprüfte RPC sk_partnership_listing(p_thread_id) liefert nur die fachlich notwendigen Inseratfelder.
$n$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.8.37 – Partnerinserat schreibgeschützt' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$n$
## 0.33.1.8.37 – Stand
Chat-Direktlink nach angenommener Vergabe für Inserateigner und Interessent über sichere Lese-RPC korrigiert; Inserate nach Vergabe unveränderbar. Produktive Migration und Retests stehen noch aus.
$n$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.8.37 – Stand' IN body)=0;
COMMIT;
