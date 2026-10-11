-- StaffKeeping 0.33.1.4: ZWEI Dokumentations-UPDATEs in Transaktion und EIN Kontroll-SELECT.
-- Supabase zeigt je nach Ansicht vor allem das letzte Resultset an.
BEGIN;
UPDATE sk_internal.project_doc_chapters
SET body=body||E'\n\n'||$note$
## StaffKeeping 0.33.1.4 – Google Maps im Mehrbetriebsprofil
Implementiert, live noch nicht getestet: Die einzelnen Betriebsprofile unter Profil → Meine Betriebe verwenden jetzt einen Kartenbereich mit Google-Geocoding und verschiebbarem Standortmarker. Adress- und Koordinatenänderung erfolgen atomar über sk_update_business_with_location: bestehende sk_update_business_by_id-Berechtigungen und die individuellen Freigabe-/Nachbesserungsregeln bleiben erhalten. Die serverseitige Speicherung bestätigt dieselbe Business-ID, Owner-Mitgliedschaft, gültige Benutzeridentität und den kanonischen Adressschlüssel. Ohne ermittelte Koordinaten kein stillschweigendes Beibehalten des alten Standorts nach einer Adressänderung; die Umkreissuche kennzeichnet Entfernung unbekannt. Nachbesserung kann Adresse und Koordinaten in einer Aktion einreichen. Admin → Betriebe zeigt gespeicherte Positionen oder bei fehlenden Koordinaten nur eine explizit nicht verifizierte Google-Adressvorschau (keine Speicherung). Der API-Schlüssel bleibt öffentliches Browser-Credential, Google-Cloud-Referrer/API-Beschränkungen mit Annette weiterhin als Sicherheits-TODO offen.
Teststatus 0.33.1.3: 17/23 erfolgreich, 6 offen. Zusätzlich Maps-Integration in mehreren Betriebsansichten als Fehler entdeckt. Zu testen 0.33.1.4: beide Betriebe, neue Adressen, Geocoder, Marker-Verschiebung, atomare Speicherung und Refresh, Nachbesserung, Admin-Karte, fehlende Koordinaten, fremde Business-ID, vorangegangene Daten erhalten, Umkreis-Radius und API-Key-Fehler. Technischer Ist-Zustand von 0.33.1.4 ist bis zum Live-Test nicht als erfolgreich zu kennzeichnen.
$note$,updated_at=now()
WHERE slug='concept' AND position('## StaffKeeping 0.33.1.4 – Google Maps im Mehrbetriebsprofil' IN body)=0;
UPDATE sk_internal.help_chapters
SET body=body||E'\n\n'||$note$
## Standort im Betriebsprofil · 0.33.1.4
Unter Profil → Meine Betriebe beim gewünschten Betrieb auf „Betriebsprofil bearbeiten“ klicken. Adresse ergänzen oder ändern, „Standort aus Adresse ermitteln“ auswählen, Marker bei Bedarf verschieben und Betriebsprofil speichern. Die Kartendaten werden nur für diesen Betrieb übernommen. Wenn keine Position ermittelt werden konnte, zuerst Google-Maps-Konfiguration prüfen; unbestätigte Koordinaten niemals als verifiziert darstellen. Bei Nachbesserung nach Annettes Aufforderung Adresse/Standort im selben Formular korrigieren und erneut einreichen. Admin → Betriebe → Details/Prüfen zeigt die gespeicherte Karte oder eine eindeutig als unverifiziert bezeichnete Google-Vorschau. Screenshot-Platzhalter: ![Betriebsstandort bearbeiten](screenshot:sk-business-location-03314) ![Admin Standort prüfen](screenshot:sk-admin-location-03314)
$note$,updated_at=now()
WHERE page_key='my-listings' AND position('## Standort im Betriebsprofil · 0.33.1.4' IN body)=0;
COMMIT;
SELECT '0.33.1.4 Dokumentation ergänzt' AS result;
