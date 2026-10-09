# Testplan und Abnahme

## Stand 0.18
- [ ] In App Demo-Anmeldung durchführen → Admin → Projektdoku erreichbar.
- [ ] Alle neun Dokumentationskapitel umschalten, Copy-Funktion testen.
- [ ] Marketing-Inhalte nicht in die App aufgenommen.
- [ ] Kein Inline-CSS; CSS-Dateien richtig geladen; Farbpalette beibehalten.
- [ ] Navigation nach 0.17 in Safari/Desktop und Smartphone testen; Benutzer-Retest noch offen.
- [ ] Keine vertraulichen Originaldokumente im öffentlichen Pages-Pfad.

## Vor produktivem Betrieb
- [ ] Ohne Login: keine geschützten Daten über API.
- [ ] Registriert, aber nicht freigegeben: kein Marktplatz-/Chat-Zugriff.
- [ ] Zwei Firmen: fremde Datensätze und Chats nicht abrufbar.
- [ ] Administrator: Chat-Lesezugriff, keine unerlaubte Änderung.
- [ ] Konto gesperrt: geschützte Zugriffe sofort blockiert.
- [ ] Login, Reset, E-Mail-Verifikation, Registrierung, Adminfreigabe, Upload, Inseratsablauf und Mobilansicht vollständig testen.

Aktuelle Kästchen sind **ausstehende Tests**, keine bereits bestandenen Tests.

## Release 0.19 – Supabase (alle Tests ausstehend)
- [ ] SQL-Migration einmal im richtigen leeren StaffKeeping-Projekt ohne Fehler ausführen.
- [ ] Tabellen und RLS ON bestätigen; `sk_internal` nicht in exponierten Schemas.
- [ ] Anonyme API-Anfragen erhalten keine Daten und dürfen keine Registrierungs-RPC ausführen.
- [ ] Unbestätigter Auth-Benutzer kann kein Unternehmen registrieren.
- [ ] Bestätigter Benutzer darf eigenes Unternehmen einmal mit Status `Ausstehend` anlegen, aber keinen Status/Rolle ändern.
- [ ] Zwei Testfirmen: kein Querzugriff, keine fremden Mitgliedschaftsdaten.
- [ ] Admin allein darf Firmen freigeben/sperren; Änderungen protokolliert.
- [ ] Freigabe-Check liefert für ausstehende/gesperrte Firma false.

## Übergabe-/Domainwechseltests (geplant, nicht ausgeführt)
- [ ] Eigentum, Billing und Administratorrechte in GitHub, Supabase und Postmark nach der Übertragung bestätigen.
- [ ] GitHub Pages und neue Domain inkl. DNS, HTTPS und Link von der Marketingseite prüfen.
- [ ] Supabase Auth Site URL und Redirect-Allowlist, Mail-Bestätigung, Reset und Login auf finaler Domain testen.
- [ ] Postmark-Absender, SPF/DKIM/DMARC, Testmails und Zustellung validieren.
- [ ] Bestehenden Google-Maps-Key unter neuer App-Domain und API-Einschränkungen testen.
- [ ] RLS und Berechtigungen nach Transfer mit mehreren Firmen/Admins negativ testen.
- [ ] Testdatenbereinigung und Sicherung vor Produktivstart verifizieren.
Siehe `docs/uebergabe-annette.md`.


## Auth-Tests 0.20 (noch offen)
- Falsches Passwort abweisen; gültiger Admin login; Logout; erneutes Laden.
- Neues Testunternehmen registrieren, E-Mail bestätigen, Registrierung vervollständigen, Status Ausstehend.
- Kein Marktplatzzugang solange Ausstehend oder Gesperrt, auch per URL-Hash und API.
- Admin kann Freigeschaltet/Gesperrt via RPC ändern, Nichtadmin erhält Fehler.
- Passwort-Reset-Mail und neue Passwortvergabe testen.
- Bestätigung in anderem Browser/Gerät: Registrierung muss wiederaufgenommen werden (derzeit noch eingeschränkt).
- Browserkonsole, mobile Ansicht, öffentliche docs-Dateien und Berechtigungen prüfen.

## Auth-Recovery Version 0.21 – verpflichtender Retest
- [ ] Custom SMTP Postmark: Testmail an berechtigte Adresse tatsächlich angekommen.
- [ ] Ein Recovery-Link öffnet die Ansicht „Neues Passwort“ und NICHT den Marktplatz, trotz authentifizierter Recovery-Sitzung.
- [ ] Zwei unterschiedliche Passwörter werden vor dem Update abgewiesen.
- [ ] Zwei identische gültige Passwörter werden gespeichert; danach Abmeldung und reguläre Anmeldung mit neuem Passwort.
- [ ] Seitenreload während Recovery zeigt weiterhin Passwortformular.
- [ ] Ungültiger/abgelaufener Recovery-Link ergibt klare Fehlermeldung; kein unbeabsichtigter Zugang zum Marktplatz.
- [ ] Nach explizitem Zurück zur Anmeldung wird der Recovery-Modus beendet.
- [ ] Adminfreigabe und RLS-Negativtests bleiben ausstehend und sind separat durchzuführen.

## Version 0.22 – Rücksprung-URLs / Regression
- [x] 0.21: Recovery-Mail erhalten, Passwort gesetzt, Logout und erneuter Login mit neuem Passwort – vom Benutzer live bestätigt.
- [ ] Signup in StaffKeeping unter `/staffkeeping/` beginnen; frisch empfangenen Link kontrollieren: `redirect_to` muss `/staffkeeping/` enthalten. **Nur Redirect-Parameter ansehen, niemals Token weitergeben.**
- [ ] Link bestätigen; korrekter Aufruf der App statt Root-Homepage; Firma im richtigen Browser anlegen; Status `Ausstehend` prüfen.
- [ ] Passwort-Reset-Link erneut auf `/staffkeeping/` überprüfen (nur falls nötig; keine unnötigen zusätzlichen Mails).
- [ ] Adminfreigabe und Berechtigung mit zwei Firmen; Browserwechsel bei Signup als bekannter offener Fall.
- [ ] Spam-Zustellung bei Postmark/Gmail prüfen; nicht als behoben markieren.

## Version 0.23 – Fortsetzung der Registrierung (vor Ort zu testen)
- [ ] Bereits bestätigter Testbenutzer ohne Mitgliedschaft meldet sich an und gelangt zu „Unternehmensregistrierung abschliessen“, nicht zu „Prüfung ausstehend“.
- [ ] Das Formular enthält keine Passwortpflicht; E-Mail entspricht dem bestehenden Auth-Konto.
- [ ] Firmenangaben vervollständigen, speichern, keine weitere Auth-Mail / kein zweiter Auth-User.
- [ ] SQL: genau eine Firma und eine Mitgliedschaft; Status `Ausstehend`.
- [ ] Ausstehender Benutzer bleibt von Marktplatz und Administrations-API ausgeschlossen.
- [ ] Admin sieht neue Firma, gibt sie frei; Benutzer kann danach zugreifen.
- [ ] Negativ: Benutzer mit vorhandener Firma darf keine zweite anlegen; falsche Session/E-Mail darf fremde Registrierungsdaten nicht nutzen.
- [ ] Neue Registrierung inklusive Bestätigungslink sowie Login nach Browser-/Gerätewechsel separat testen.

## Test 0.24 – Admin-Betriebsprüfung (noch ausstehend)
1. SQL-Datei als eine Transaktion ausführen; danach Berechtigungen/RPCs prüfen.
2. Admin → Betriebe → Details / Prüfen: Firmenname, UID, Branche, Adresse, Kontakt, E-Mail, Telefon, Registrierungs-/AGB-Zeitpunkt mit Supabase vergleichen.
3. E-Mail-Link öffnet Mail-Programm, Telefon-Link entsprechend Client.
4. Admin-Notiz speichern; neu laden, Notiz mit Zeit und Adminautor sichtbar.
5. Erst danach Freischalten; Statuswechsel in Admin-Tabelle und Audit-Historie prüfen.
6. Als normaler Benutzer RPC sk_admin_get_business_details und sk_admin_add_business_note direkt versuchen: muss scheitern.
7. Direkter Zugriff auf sk_internal.business_admin_notes / business_status_audit für authenticated/anon: verweigert.
8. Login, Registrierung, Reset und Navigation auf Regression prüfen.


## Abnahme 0.25 – Unternehmensprofil und Freigabe
- [x] Live bestätigt vom User: Administrator-Login, Passwort-Recovery, neu registriertes Unternehmen mit E-Mail-Bestätigung, Status Ausstehend; erster Testbetrieb freigeschaltet und Testnutzer kann sich anmelden.
- [ ] SQL-Migration 0.25 erfolgreich ausgeführt (keine Live-Bestätigung).
- [ ] Testnutzer öffnet Profil: Firma, Branche, Land, UID, PLZ/Ort, Ansprechpartner und Kontakt-E-Mail/Telefon entsprechen Supabase.
- [ ] Beschreibung ändern, speichern, neu laden und in Admin-Betriebsdetails kontrollieren.
- [ ] Präferenz E-Mail-Benachrichtigungen speichern und nach Neuanmeldung kontrollieren; kein Versand für Fachmeldungen behaupten.
- [ ] Land und USt-ID nicht editierbar, direkter Änderungsversuch über Supabase scheitert.
- [ ] Logo JPG/PNG/WebP bis 2 MB sowie Betriebsbilder in 5 Slots bis je 5 MB hochladen, ersetzen, entfernen, neu laden. Ungültiger Dateityp/Grösse wird abgewiesen.
- [ ] Admin sieht Beschreibung und Medien, nicht angemeldeter/fremder Nutzer erhält bei Storage/RPC keinen Zugriff.
- [ ] Nach Freigabe Testnutzer Marktplatz, nach Sperrung kein Marktplatz.
- [ ] Auf Desktop/Mobile Layout prüfen; Registrierung, Reset und Admin-Notizen auf Regression testen.


## 0.26 – Tests zur Abnahme (noch nicht live durchgeführt)
1. SQL-Installation erfolgreich, private Bucket-Einstellung und Policies prüfen.
2. Admin lädt HTML-Original aus lokalem Archiv hoch; im isolierten Dokument-Viewer mit Screenshots vollständig lesbar.
3. Als `anon` und gewöhnlicher freigeschalteter Nutzer: Download, List, Upload, URL-Zugriff auf `sk-project-docs` verweigert.
4. Profil-Beschreibung ändern, 1 s warten: `Gespeichert`; Reload zeigt Wert.
5. Profilfeld ändern und sofort Marktplatz anklicken: vorher erfolgreich speichern.
6. Profilfeld ändern und Browser Zurück/Vorwärts: vorher speichern; bei Fehler Navigationsverlust verhindern.
7. Netzfehler simulieren: `Nicht gespeichert`, Eingabe bleibt sichtbar, Retry kann wiederholen.
8. Ungültiges Formular verhindert Navigation; Browser-Schliessen/Reload mit ungespeicherten Daten löst Warnung aus.
9. Dropdown und Benachrichtigungs-Schalter speichern ohne Klick auf Save; Medienänderungen gesondert prüfen.
10. Wiederholten Admin-Upload nur für Original-Datei prüfen; keine anderen Dateinamen/Buckets oder Nutzerrechte zulassen.
11. Bestehenden Login/Recovery/Freigabe/Profil/Medien und alle übrigen Navigationen auf Regression prüfen.
