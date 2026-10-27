-- StaffKeeping 0.33.1.8.30 – Responsive Header, ausschliesslich Projektdokumentation
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$note$
## 0.33.1.8.30 – Kontrolliertes Header-Layout
Responsives Header-Layout von 0.33.1.8.29 überarbeitet: bei breiten Fenstern eine Navigationszeile mit grosszügigeren Abständen; bei mittleren Breiten bleiben die Hauptlinks innerhalb der zentrierten Hauptnavigation, die bei Platzmangel maximal in mehrere saubere Zeilen umbrechen darf. Hilfe/Hilfe zur Seite bleiben bei der rechts angeordneten Betriebs- und Kontogruppe statt isoliert links. Bei engeren Desktopfenstern wird die Navigation in einer eigenen zentrierten Zeile geführt; erst bis 700 px erscheint das kompakte Menü. Betriebswahl weiterhin nur bei mehreren berechtigten Betrieben sichtbar. Keine Änderungen an Chat, Inseraten, Filtern oder Datenbankberechtigungen.
$note$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.8.30 – Kontrolliertes Header-Layout' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$note$
## 0.33.1.8.30 – Status
Header-Korrektur vorbereitet, noch kein produktiver Browser-Retest. Prüfen bei ca. 1920, 1500, 1280, 1024, 850 und 600 px; keine Überschneidungen, zentrierte Navigation, Hilfe und Konto gruppiert, Menüzustand und Betriebswahl. Frühere Header-Patches 0.33.1.8.28/.29 optisch nicht abgenommen.
$note$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.8.30 – Status' IN body)=0;
COMMIT;
