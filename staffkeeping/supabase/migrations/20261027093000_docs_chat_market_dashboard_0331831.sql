-- StaffKeeping 0.33.1.8.31 – Chat-Hinweise, Dashboard-Zähler, Inseratnavigation.
-- Nur zentrale Projektdokumentation; keine Berechtigungs- oder Tabellenänderungen.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$note$
## 0.33.1.8.31 – Chat-Zuordnung und aktuelle Nachrichten
Marktplatz-Inseratekarten zeigen bei vorhandenen, für den Benutzer berechtigten Unterhaltungen einen Hinweis mit Anzahl und direktem Chat-Einstieg. Die Chat-Zuordnung wird mit der Marktplatz-Hintergrundaktualisierung geladen; ein Fehler bei der Chat-Abfrage blockiert den Marktplatz nicht. Im persönlichen Dashboard wird die Anzahl ungelesener Nachrichten bei geöffnetem Dashboard alle fünf Sekunden sowie bei Tab-/Fenster-Rückkehr aktualisiert, ohne die übrigen Karten neu aufzubauen. Der Link «Zum Inserat» in Nachrichten prüft zuerst die eigenen verwaltbaren Inserate: Inserateigner gelangen zur eigenen Inseratbearbeitung (auch bei inaktiven Inseraten), andere Beteiligte zur berechtigten Marktplatzdetailansicht. Keine neuen Berechtigungen oder RPCs.
$note$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.8.31 – Chat-Zuordnung' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$note$
## 0.33.1.8.31 – Status und Kurztest
Korrektur-Patch erstellt; produktiver Browser-Retest offen. Testen: 1. vorhandene Unterhaltungen als Link auf Marktplatzkarten (nur eigene berechtigte Chats), 2. neue ungelesene Chatnachricht erscheint ohne Neuladen im geöffneten Dashboard und verschwindet nach Lesen, 3. Chatlink beim Inserateigner öffnet das eigene Inserat auch bei inaktivem Status, beim Interessenten die berechtigte Marktplatzdetailseite. Keine Änderungen der Chat-/Inserate-Datenbankstruktur. Offene Punkte: Bewertungen, automatische Treffer-E-Mails, Mitgliedschaft, Google Maps Produktions-Karten-ID (Annette/Patrick) und Sicherheitstests.
$note$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.8.31 – Status' IN body)=0;
COMMIT;
