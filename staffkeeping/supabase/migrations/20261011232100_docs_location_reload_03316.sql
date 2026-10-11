-- StaffKeeping 0.33.1.6: Teststand und Standortablauf dokumentieren.
-- Zwei UPDATE-Anweisungen innerhalb einer Transaktion; EIN Kontroll-SELECT.
-- Supabase zeigt ggf. nur das letzte Resultset.
BEGIN;
UPDATE sk_internal.project_doc_chapters
SET body=body||E'\n\n'||$note$
## StaffKeeping 0.33.1.6 – Standort beim Öffnen laden und Adresse automatisch bestimmen
Befund 0.33.1.5: Nach gespeicherter Kartenposition erscheint sie bei Annette, aber nicht beim erneuten Öffnen unter „Meine Betriebe“. Grund: listMyBusinesses selektierte latitude, longitude, location_source und location_address_key nicht. Ab 0.33.1.6 lädt die Betriebsübersicht diese vier Spalten. Der einheitliche Betriebs-Karteneditor zeigt gespeicherte Positionen, berechnet bei vollständiger bzw. geänderter Adresse verzögert automatisch neu und erhält manuell korrigierte Positionen bis zur erneuten Adressänderung. Im Formular „Weiteren Betrieb hinzufügen“ sind nun Strasse, Hausnummer, Karte und Standortermittlung vorhanden. Die serverseitige Funktion sk_add_business_with_location nutzt unverändert die Berechtigungs-/Freigabeprüfung von sk_add_business und legt neue Betriebe mit Standort atomar an. Keine automatische Freigabe, keine Abo-Zuordnung. Fehlende Standortdaten müssen deutlich angezeigt werden; Admin-Karten-Vorschau ist weiterhin keine Freigabe. Teststatus: Live-Test offen. Prüfen: gespeicherten Marker erneut öffnen; Adressänderung/Auto-Geocoding; manuelle Korrektur; neuer Betrieb samt Standort, Annette-Ansicht, fehlgeschlagenes Geocoding, Zugriff auf fremde Betriebs-IDs. Veraltete Marker-API und API-Key-Sicherheitsprüfung mit Annette bleiben offene Punkte.
$note$,updated_at=now()
WHERE slug='concept' AND position('## StaffKeeping 0.33.1.6 – Standort beim Öffnen laden' IN body)=0;
UPDATE sk_internal.help_chapters
SET body=body||E'\n\n'||$note$
## Betriebsstandorte (0.33.1.6)
Profil → Meine Betriebe → Betriebsprofil bearbeiten: Gespeicherte Standorte werden auf der Karte wieder angezeigt. Bei Eingabe einer vollständigen oder Änderung der Adresse ermittelt Google den Standort automatisch; der Button „Standort aus Adresse ermitteln“ bleibt zum Wiederholen. Nach Verschieben des Markers bleibt die manuelle Position bis zu einer Adressänderung erhalten und wird beim Speichern übernommen. Auch neue zusätzliche Betriebe haben eine Karte und können ihre Adresse mit Koordinaten zur Prüfung einreichen. Annette gibt jeden Betrieb weiterhin einzeln frei. Bei Problemen Statushinweis beachten; die Koordinaten müssen nach erneutem Öffnen kontrolliert werden.
$note$,updated_at=now()
WHERE page_key IN ('my-businesses','profile') AND position('## Betriebsstandorte (0.33.1.6)' IN body)=0;
COMMIT;
SELECT '0.33.1.6 Dokumentation ausgeführt' AS status;
