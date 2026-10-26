-- StaffKeeping 0.33.1.8.28 – Headerstruktur und responsives Menü
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'

'||$note$
## 0.33.1.8.28 – Header und Navigation
Designvorlage vom 26.10.2026: Logo links, zentrale Hauptnavigation mit Übersicht, Marktplatz, Meine Inserate, Nachrichten, Bewertungen und Admin (nur Berechtigte). Rechts folgen Hilfe und Hilfe zur Seite, aktiver Betrieb (nur sichtbar bei mehreren freigegebenen Betrieben), Profil und Abmelden. Der aktive Betrieb bleibt bei genau einem Betrieb unsichtbar aktiv. Desktop: geordnete einzeilige Navigation bei ausreichender Breite; mittlere Fenster: definierte zweite Zeile statt zufälliger Umbrüche; schmale Fenster: Menüschalter mit ausklappbarer Hauptnavigation. Bestehende data-view-Ziele, Rechte und Geschäftslogik bleiben erhalten.
$note$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.8.28 – Header und Navigation' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'

'||$note$
## 0.33.1.8.28 – Status
Header-Patch zur Installation vorbereitet; Browser-Retest noch offen. Prüfen: breite/mittlere/schmale Fenster, Navigation, Hilfefunktionen, Kontofunktionen, Betriebswechsel, sichtbare Menüpunkte nach Berechtigungen. Kein Eingriff in Datenbanktabellen.
$note$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.8.28 – Status' IN body)=0;
COMMIT;
