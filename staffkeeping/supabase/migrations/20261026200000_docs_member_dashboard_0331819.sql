-- StaffKeeping 0.33.1.8.19 – persönliches Mitgliederdashboard
-- Nur zentrale Projektdokumentation; keine Tabellen- oder RPC-Änderung.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$doc$
## 0.33.1.8.19 – Persönliches Dashboard
Für angemeldete freigeschaltete Mitglieder ist «Meine Übersicht» die Startseite. Das bestehende Admin-Dashboard bleibt für Administratoren erhalten. Angezeigt werden echte Werte aus den vorhandenen berechtigungsgeprüften Aufrufen für eigene Inserate, Unterhaltungen, Betriebsprüfstatus und private Entwürfe. Hinweise zu abgelaufenen sowie innerhalb von 7 Tagen auslaufenden Inseraten verlinken auf die Inseratverwaltung. Die wichtigsten Bereiche sind über Schnellaktionen direkt erreichbar. Nicht verfügbare Daten werden nicht durch erfundene Zahlen ersetzt. Ungelesen-Status, gespeicherte Suchen, Trefferbenachrichtigung und Mitgliedschaftslaufzeiten bleiben offen und werden nicht als bereits implementiert dargestellt.
$doc$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.8.19 – Persönliches Dashboard' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$doc$
## 0.33.1.8.19 – Status
Persönliches Dashboard implementiert; kleine ZIP-Aktualisierung mit index.html, scripts/app.js und Dokumentationsmigration. Browser- und Supabase-Livetest ausstehend. Keine Tabellenmigration erforderlich. Nächste Aufgaben: serverseitiger Lesestatus und Dashboard-Nachrichtenhinweise, gespeicherte Suchen mit Trefferprüfung zweimal täglich, Mitgliedschaftslaufzeitdaten und Kartenansicht.
$doc$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.8.19 – Status' IN body)=0;
COMMIT;
