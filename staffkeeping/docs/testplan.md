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
