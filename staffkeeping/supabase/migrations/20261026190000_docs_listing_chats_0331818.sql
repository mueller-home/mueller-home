-- StaffKeeping 0.33.1.8.18: Verknüpfung von Inseraten und berechtigten Chats.
-- Dokumentation, keine Schema- oder Berechtigungsänderungen.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$doc$
## 0.33.1.8.18 – Inseratsbezogene Chats
Die Inseratdetailseite zeigt «Zum Chat» statt «Kontakt aufnehmen», sobald zu diesem Inserat eine für das Mitglied zugängliche Unterhaltung vorhanden ist. Unter «Meine Inserate» zeigen veröffentlichte Inserate vorhandene Chat-Unterhaltungen samt Anzahl und führen zur nach Inserat gefilterten Nachrichtenansicht. Mehrere Unterhaltungen zu einem Inserat bleiben auswählbar; der Filter kann zurückgesetzt werden. Die Daten werden ausschliesslich mit den bestehenden serverseitig berechtigungsgeprüften Chat-RPCs abgefragt. Ein Chat-Indexfehler darf keine fremden Daten zeigen.
$doc$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.8.18 – Inseratsbezogene Chats' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$doc$
## 0.33.1.8.18 – Status
ZIP mit index.html, scripts/app.js sowie dieser Dokumentationsmigration. JavaScript-Syntax und ZIP-Struktur geprüft; produktive Tests ausstehend. Geplant: Persönliches Dashboard als Startseite mit echten Daten für ungelesene Nachrichten, Inseratstatus, Betriebsfreigaben, Suchtreffer und Mitgliedschaft. Datenstruktur für Lesestatus, Suchabonnements und Mitgliedschaftsablauf vor Anzeige entsprechender Zahlen prüfen.
$doc$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.8.18 – Status' IN body)=0;
COMMIT;
