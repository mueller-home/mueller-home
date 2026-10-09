-- StaffKeeping 0.29: bestehende zentrale Kapitel gezielt ergänzen; keine neuen Kapitel
-- Eine Transaktion, zwei UPDATEs, keine SELECT-Resultsets.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||$note$

## StaffKeeping 0.29 – Betriebsstandort und Google Maps
- In `sk_businesses` optionale Strasse, Hausnummer und Adresszusatz; Land/PLZ/Ort bleiben Pflicht.
- Auto-Save im bestehenden Profil, Google Maps Geocoding nach erfolgreichem Speichern; ungefähre Position bei Ort/PLZ und genauere bei Strasse.
- Koordinaten und Positionsherkunft in Supabase, manuell korrigierter Marker wird nicht ohne ausdrückliches Zurücksetzen überschrieben.
- Standortkarte und alle Adressfelder in der geschützten Admin-Betriebsdetailansicht. Öffentliche Strassenadresse standardmässig deaktiviert.
- Schlüssel separat in `scripts/config.js` hinterlegen und in Google Cloud auf StaffKeeping-Domain/API beschränken. Google Maps Platform Billing und API-Freischaltung erforderlich; Kosten verbrauchsabhängig. Google-Nutzungsregeln für Geocoding und Speicherung beachten.
- **Umgesetzt, noch nicht live getestet:** SQL-Migration, Kartenaufruf, Geocoding/Standort-RPC, Marker, Adminansicht, Berechtigungen.
$note$,updated_at=now() WHERE slug='concept' AND strpos(body,'## StaffKeeping 0.29 – Betriebsstandort und Google Maps')=0;
UPDATE sk_internal.project_doc_chapters SET body=body||$note$

## Version 0.29 – Standortverwaltung (09.10.2026)
- Profil und Admin-Betriebsdetails um Google-Maps-Standort erweitert; optionale Strassenadresse, Standortermittlung aus PLZ/Ort, manuelle Markerkorrektur, Auto-Save.
- Datenbankmigration `20261009171000_business_location.sql`; Google-API-Schlüssel wird bewusst **nicht** mitgeliefert.
- **Teststatus: Code statisch geprüft, Live-Supabase/Google/API/Billing noch offen.**
$note$,updated_at=now() WHERE slug='history' AND strpos(body,'## Version 0.29 – Standortverwaltung')=0;
UPDATE sk_internal.project_doc_chapters SET body=body||$note$

## Testplan 0.29 – Betriebsstandort
1. Ohne Strasse: Land/PLZ/Ort speichern, ungefähre Position prüfen.
2. Strasse/Hausnummer ergänzen: Auto-Save und genauere Position sowie Neuladen prüfen.
3. Marker verschieben, neu laden, manuelle Position muss bleiben; Rücksetzen bewusst testen.
4. Administrator: Adresse und Standort desselben Betriebs prüfen.
5. Zweites Unternehmen: fremde Koordinaten-/Adressänderung über RPC muss scheitern.
6. Google-Schlüssel falsch oder API deaktiviert: verständliche Meldung, Profil weiterhin nutzbar.
7. Fehlgeschlagenes Geocoding darf Speichern der Firmendaten nicht verhindern.
**Bisher nicht live ausgeführt.**
$note$,updated_at=now() WHERE slug='tests' AND strpos(body,'## Testplan 0.29 – Betriebsstandort')=0;
COMMIT;
