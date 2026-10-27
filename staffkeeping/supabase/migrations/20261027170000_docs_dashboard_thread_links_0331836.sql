-- StaffKeeping 0.33.1.8.36: gezielte Links aus Dashboard-Aufgaben auf Chatunterhaltungen.
-- Keine Tabellen- oder RPC-Änderungen; ausschliesslich zentrale Projektdokumentation.
BEGIN;
UPDATE sk_internal.project_doc_chapters
SET body = body || E'\n\n' || $note$
## 0.33.1.8.36 – Dashboard-Direktlinks
Hinweise «Vergabeangebot wartet auf Antwort» und «Zusammenarbeit läuft» verlinken nicht nur zur Nachrichtenübersicht, sondern öffnen die konkrete Unterhaltung anhand der in der Partnerschaft gespeicherten thread_id. Vor dem Öffnen wird die Berechtigung über sk_chat_threads geprüft. Archivierte beziehungsweise abgeschlossene Unterhaltungen werden gezielt in der Archivansicht geöffnet. Der normale Menüeinstieg «Nachrichten» öffnet weiterhin ausschliesslich die aktiven Unterhaltungen als Standard. Keine Schemaänderungen.
$note$, updated_at=now()
WHERE slug='concept' AND position('## 0.33.1.8.36 – Dashboard-Direktlinks' IN body)=0;
UPDATE sk_internal.project_doc_chapters
SET body = body || E'\n\n' || $note$
## 0.33.1.8.36 – Entwicklungsstand
Dashboard-Einträge zu Vergabeangeboten und laufenden Partnerschaften besitzen jetzt einen gezielten Chat-Direktlink. JavaScript-Syntax geprüft, produktiver Funktionstest offen.
$note$, updated_at=now()
WHERE slug='status' AND position('## 0.33.1.8.36 – Entwicklungsstand' IN body)=0;
COMMIT;
