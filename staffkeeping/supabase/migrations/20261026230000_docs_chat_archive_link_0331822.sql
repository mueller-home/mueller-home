-- StaffKeeping 0.33.1.8.22 – Projektdokumentation: dezenter Archiv-Link
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$doc$
## 0.33.1.8.22 – Nachrichten: Archivnavigation
Der bisher grosse Button für archivierte und abgeschlossene Unterhaltungen wird durch einen dezenten Textlink unter der aktiven Unterhaltungsliste ersetzt. Der Link wird in der aktiven Ansicht ausschliesslich angezeigt, wenn im aktuellen Betriebs-/Inseratefilter tatsächlich abgeschlossene oder archivierte Gespräche existieren, und zeigt deren Anzahl. In der Archivansicht führt ein Textlink zu den aktiven Unterhaltungen zurück. Die manuelle Schaltfläche «Aktualisieren» entfällt; die automatische Zwei-Sekunden-Aktualisierung bleibt unverändert. Keine Änderungen der Datenbankfunktionen oder Zugriffsrechte.
$doc$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.8.22 – Nachrichten: Archivnavigation' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$doc$
## 0.33.1.8.22 – Status
Oberflächenupdate für schlanke Archivnavigation und Entfernung der manuellen Aktualisierung. JavaScript-Syntax und ZIP-Struktur lokal geprüft; produktiver Browsertest ausstehend. 0.33.1.8.21 bleibt Voraussetzung.
$doc$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.8.22 – Status' IN body)=0;
COMMIT;
