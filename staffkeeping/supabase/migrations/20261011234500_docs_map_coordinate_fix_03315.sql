-- StaffKeeping 0.33.1.5: ZWEI UPDATE-Anweisungen innerhalb einer Transaktion; danach EIN Kontroll-SELECT.
-- Supabase zeigt möglicherweise hauptsächlich das letzte Resultset.
BEGIN;
UPDATE sk_internal.project_doc_chapters
SET body=body||E'\n\n'||$note$
## StaffKeeping 0.33.1.5 – Google-Maps-Koordinatenkorrektur
Fehler bei Live-Test von 0.33.1.4: Google Maps blieb leer mit InvalidValueError setCenter/setPosition (lng is not a number), obwohl die Adresse gefunden wurde. Ursache: Übergabe von pos.lng statt pos.lng() in scripts/location.js. Korrigiert in 0.33.1.5; zusätzliche Validierung auf endliche geografisch gültige Zahlen vor Karteninitialisierung. Keine DB-Schemaänderung; Google-Maps-API-Schlüssel bleibt unverändert. Teststatus: Kartenrendering, verschiebbarer Marker, Speicherung beim richtigen Betrieb, Reload und Admin-Anzeige noch erneut live zu bestätigen. Altlast: google.maps.Marker veraltet; Migration zu AdvancedMarkerElement weiterhin offen. Sicherheitsprüfung des Browser-API-Schlüssels mit Annette ebenfalls offen.
$note$, updated_at=now()
WHERE slug='concept' AND position('## StaffKeeping 0.33.1.5 – Google-Maps-Koordinatenkorrektur' IN body)=0;
UPDATE sk_internal.help_chapters
SET body=body||E'\n\n'||$note$
## Standortkarte: Koordinatenfehler korrigiert (0.33.1.5)
Wenn bei „Standort aus Adresse ermitteln“ früher eine leere Karte erschien, war dies in 0.33.1.4 durch einen falschen Longitude-Wert verursacht. Ab 0.33.1.5 werden Breite und Länge als Zahlen geprüft. Test: Adresse ermitteln, Kartenmarker prüfen, gegebenenfalls verschieben, Betriebsprofil speichern und nach Reload erneut kontrollieren.
$note$,updated_at=now()
WHERE page_key='my-listings' AND position('## Standortkarte: Koordinatenfehler korrigiert (0.33.1.5)' IN body)=0;
COMMIT;
SELECT '0.33.1.5 Dokumentation ergänzt' AS result;
