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
