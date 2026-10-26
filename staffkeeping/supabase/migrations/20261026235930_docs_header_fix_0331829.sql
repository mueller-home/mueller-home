-- StaffKeeping 0.33.1.8.29 – Header Korrektur nach Browserprüfung
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$note$
## 0.33.1.8.29 – Korrektur responsiver Header
Nach Screenshot-Retest von 0.33.1.8.28: Navigationslinks kollidierten und wurden bei breiten Fenstern zu klein. Ursache war die Kombination aus einer auf 1200px beschränkten Header-Shell und einer dreispaltigen Navigation samt Kontobereich. Der Header erhält eine eigene maximale Breite (1600px), eine geordnete Hilfs-/Kontozeile ab 1450px und eine kompakte Menüansicht bis 980px. Das übrige Inhaltslayout und die Supabase-Berechtigungen bleiben unverändert. Die Betriebswahl ist weiterhin nur bei mehreren freigegebenen Betrieben sichtbar.
$note$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.8.29 – Korrektur responsiver Header' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$note$
## 0.33.1.8.29 – Status
Gezielter Header-Fix vorbereitet; produktiver Browser-Retest offen. Testen: breite Navigation ohne Überschneidungen, definierte zweite Zeile bei mittlerer Breite, Menüknopf bei schmaler Breite, aktiver Betrieb, Hilfelinks, Profil und Abmelden. Kein Eingriff in Fachfunktionen.
$note$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.8.29 – Status' IN body)=0;
COMMIT;
