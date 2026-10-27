-- StaffKeeping 0.33.1.8.34: Angenommene Vergaben unter «Meine Inserate / Als Partner» anzeigen.
-- Keine neue Datenbankstruktur; bestehende berechtigungsgeschützte RPCs werden verwendet.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$note$
## 0.33.1.8.34 – Partner-Inserate
Unter «Meine Inserate / Als Partner» werden angenommene Vergaben und abgeschlossene Zusammenarbeiten des eigenen Interessentenbetriebs angezeigt. Offene Vergabeangebote werden getrennt ausgewiesen. Die Liste basiert auf der bestehenden berechtigungsgeschützten RPC sk_partnership_overview und zeigt den Inseratetitel, den eigenen Betrieb, den Vergabestatus und den direkten Link zur zugehörigen Unterhaltung. Inserate bleiben dort auch dann auffindbar, wenn sie wegen einer angenommenen Vergabe aus dem öffentlichen Marktplatz verschwunden sind. Die Daten werden beim Öffnen der Ansicht neu geladen. Kein neues Tabellenrecht.
$note$, updated_at=now() WHERE slug='concept' AND position('## 0.33.1.8.34 – Partner-Inserate' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$note$
## 0.33.1.8.34 – Entwicklungsstand
Partnerreiter bisher nur Platzhalter, nun echte Annahmen/Abschlüsse und offene Angebote mit Chat-Direktzugriff. Browser-Retest mit zwei Betrieben noch offen. Der gesonderte Fehler «Zum Inserat» nach Vergabe ist damit nicht automatisch behoben und bleibt offen. Benutzerhandbuch und kontextbezogene Hilfe sind weiterhin separat zu aktualisieren.
$note$, updated_at=now() WHERE slug='status' AND position('## 0.33.1.8.34 – Entwicklungsstand' IN body)=0;
COMMIT;
