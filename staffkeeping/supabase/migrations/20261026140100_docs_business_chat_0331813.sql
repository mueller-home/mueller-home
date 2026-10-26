BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$doc$
## 0.33.1.8.13 – Kontaktaufnahme und betriebsbezogener Chat
Private Chat-Threads und Nachrichten in sk_internal, kein direkter Client-Tabellenzugriff. RPCs sk_chat_start, sk_chat_threads, sk_chat_messages, sk_chat_send prüfen die authentifizierte, freigegebene Betriebsmitgliedschaft serverseitig. Kontaktaufnahme nur zu aktiven, nicht abgelaufenen Inseraten freigegebener anderer Betriebe. Mehrbetriebs-Benutzer wählen ihren Absenderbetrieb. Nachrichten bleiben auf beide beteiligten Betriebe beschränkt. Noch ohne E-Mail-Alarm, Anhänge, Lesebestätigung und Echtzeit-Push. Oberfläche verwendet nach Installation echte Nachrichten statt Demo-Unterhaltungen.
$doc$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.8.13 – Kontaktaufnahme' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$doc$
## 0.33.1.8.13 – Status
0.33.1.8.12: Nutzer-Retest 10/10 erfolgreich, funktionaler Umfang abgenommen. 0.33.1.8.13: Chat-SQL und Frontend bereit zur Installation, produktiver Browser- und Berechtigungstest offen. Prüfen: Kontakt A an B, Antwort B, Mehrbetrieb-Auswahl, fremder Thread nicht zugänglich, inaktives/abgelaufenes Inserat nicht kontaktierbar; mehrere Benutzer desselben freigegebenen Betriebs. Weitere offene Punkte: 0.33.1.8.11-Retests, Kartenansicht, gespeicherte Suchen und E-Mail-Trefferprüfungen, alte Profilseite, Auto-Save-Timeout und Rechtschreibprüfung.
$doc$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.8.13 – Status' IN body)=0;
COMMIT;
SELECT slug,updated_at FROM sk_internal.project_doc_chapters WHERE slug IN ('concept','status') ORDER BY slug;
