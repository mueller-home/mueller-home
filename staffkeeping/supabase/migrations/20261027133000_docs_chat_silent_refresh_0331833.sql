-- StaffKeeping 0.33.1.8.33 – Sichtbar flackerfreie Chat-Aktualisierung
-- Ausschliesslich zentrale Dokumentation, keine DB-/Berechtigungsänderungen.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$note$
## 0.33.1.8.33 – Chat-Hintergrundabgleich ohne Flackern
Die Zwei-Sekunden-Abfrage für Chats bleibt bestehen. Kein Status «Unterhaltungen werden geladen» und kein Platzhalter «Nachrichten werden geladen» bei automatischen Updates. Unterhaltungs-, Nachrichten- und Kopfbereich werden nur bei tatsächlicher Änderung neu aufgebaut; die Ansicht wird nicht bei jedem Poll geleert. Der Änderungsvergleich wurde korrigiert, damit unnötige Voll-Renderings vermieden werden. Beim Lesen älterer Nachrichten bleibt die Scrollposition erhalten; nur bei bereits unten positionierter Ansicht wird zu neuen Nachrichten gescrollt. Fehler beim automatischen Abgleich erscheinen nur in der Browserkonsole; die sichtbaren Nachrichten bleiben bestehen. Manuelle Aktionen behalten ihre Fehlermeldungen. Berechtigungs-RPCs unverändert.
$note$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.8.33 – Chat-Hintergrundabgleich' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$note$
## 0.33.1.8.33 – Entwicklungsstand
ZIP mit app.js, index.html und dieser Dokumentationsmigration vorbereitet. Testen: zwei Browser und geöffnete Unterhaltungen, neue Nachrichten erscheinen ohne sichtbare Ladeanzeige oder Flackern; längeren Chat nach oben scrollen, Scrollposition bleibt beim Poll erhalten; neue Chats und Archivstatus werden weiterhin übernommen; manuelle Filter-/Chatwahl funktionieren. Keine produktive Browserabnahme und keine neuen SQL-Funktionen. Die noch offenen Funktionstests der Vergabe und Bewertungen 0.33.1.8.32 bleiben bestehen.
$note$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.8.33 – Entwicklungsstand' IN body)=0;
COMMIT;
