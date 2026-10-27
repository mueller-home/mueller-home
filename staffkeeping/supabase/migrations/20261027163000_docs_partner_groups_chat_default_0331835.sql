-- StaffKeeping 0.33.1.8.35: UI-Änderungen an Partnerliste und Nachrichtenstandard.
-- Keine neuen Tabellen oder RPCs. Nur zentrale Projektkapitel aktualisieren.
BEGIN;
UPDATE sk_internal.project_doc_chapters
SET body = body || E'\n\n' || $note$
## 0.33.1.8.35 – Partnerliste und Nachrichtenstandard
«Meine Inserate / Als Partner» zeigt zwei separate Gruppen in dieser Reihenfolge: «Zusammenarbeit läuft» (angenommene Vergaben) und darunter «Zusammenarbeit abgeschlossen». Offene Vergabeangebote bleiben getrennt unterhalb der beiden Gruppen. In laufenden Fällen wird der Status kurz als «Zusammenarbeit läuft» bezeichnet. Der Chat-Direktzugriff bleibt in allen Gruppen erhalten.
Beim normalen Navigieren zu «Nachrichten» erscheint immer zuerst die Ansicht «Aktive Unterhaltungen» und ein zuvor gesetzter Inseratefilter wird zurückgesetzt. Ein ausdrücklicher Direktlink zu einem Chat oder zu den Chats eines Inserats darf weiterhin gezielt einen archivierten Verlauf öffnen. Die Archivansicht ist über den manuellen Umschalter erreichbar. Keine Änderung an der Berechtigungslogik oder den Chatdaten.
$note$, updated_at=now()
WHERE slug='concept' AND position('## 0.33.1.8.35 – Partnerliste und Nachrichtenstandard' IN body)=0;
UPDATE sk_internal.project_doc_chapters
SET body = body || E'\n\n' || $note$
## 0.33.1.8.35 – Entwicklungsstand
Partnerliste nach laufenden und abgeschlossenen Zusammenarbeiten getrennt; offene Vergabeangebote separat. Normaler Einstieg in die Nachrichten setzt Archivansicht und Inseratefilter zurück. Gezielte Chat-Direktlinks dürfen Archivansichten öffnen. Produktiver Browser-Retest offen. Keine neue SQL-Datenstruktur.
$note$, updated_at=now()
WHERE slug='status' AND position('## 0.33.1.8.35 – Entwicklungsstand' IN body)=0;
COMMIT;
