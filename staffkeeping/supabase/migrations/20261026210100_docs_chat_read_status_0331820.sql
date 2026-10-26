-- StaffKeeping 0.33.1.8.20: Zentrale Dokumentation
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$doc$
## 0.33.1.8.20 – Ungelesene Chatnachrichten
Privater Lesestatus je Unterhaltung, Benutzer und Absender-/Empfängerbetrieb in sk_internal.chat_read_states ohne direkte Rechte für anon/authenticated. Berechtigungsgeprüfte RPCs sk_chat_unread_counts und sk_chat_mark_read; Markierung nur für angezeigte Nachrichten, niemals für fremde Threads. In der Nachrichtenliste Anzahl ungelesener Nachrichten, im persönlichen Dashboard gesamter Zähler und Direktzugriff. Bestehende Chat-Aktualisierung alle zwei Sekunden bleibt erhalten. Vor produktiver Abnahme Negativtests mit fremden Thread-IDs durchführen.
$doc$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.8.20 – Ungelesene Chatnachrichten' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$doc$
## 0.33.1.8.20 – Status
SQL-Migrationen für private Lesestände und Projektdokumentation, Website-Dateien index.html, scripts/app.js, scripts/auth.js. Lokale Syntaxprüfung erfolgt, Live- und Sicherheitstests stehen aus. Weiter offen: gespeicherte Suchen, zweimal tägliche Trefferbenachrichtigung, Kartenansicht und Mitgliedschaftsablaufanzeige.
$doc$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.8.20 – Status' IN body)=0;
COMMIT;
