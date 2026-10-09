# Entwicklungsstand

**Version 0.18 – 09.10.2026:** Designprototyp, ohne echte Datenbank/Authentifizierung.

## Demonstrierbare UI-Masken
Login, Registrierung, Passwort-Reset, Freigabe ausstehend, Marktplatz, Profil, Meine Inserate, Inseratdetails, Nachrichten, Bewertungen, Admin-Betriebe, Admin-Inserate, Impact-Dashboard, Admin-Projektdokumentation.

## Nicht implementiert
Supabase-Projekt und Schema, Auth und Freigabe, serverseitige Rollen/RLS, sichere Originaldokumentauslieferung, Datenspeicherung, Mail, Maps, Zahlungen, reale Admin-Aktionen. Demo-Daten und Demo-Aktionen nicht produktiv.

## Nächste Etappe
Design und App-Navigation mit Annette abnehmen; Bubble-Daten-/Workflow-Audit; Datenmodell und Berechtigungen definieren; Supabase-Sicherheitsgrundlage erstellen.

## Zuletzt bekannte Einschränkungen
Navigationskorrektur 0.17 statisch geprüft, Benutzer-Retest noch nicht bestätigt. In 0.18 ist die Projektdokumentation öffentlichkeitsfähig gekürzt, die vollständige Originaldatei bleibt lokal bis geschütztes Backend existiert.

## Version 0.19 – vorbereitet, NICHT ausgeführt
SQL-Basismigration für Unternehmen, Firmenmitgliedschaften, Backend-Administratoren, Auditlog, RLS und definierte RPCs erstellt. Kein Supabase-Deployment nachgewiesen; GitHub-Pages-Anwendung bleibt Demo. Installation und Sicherheitsprüfung stehen aus. Nächste Stufe 0.20: echte Auth-Verbindung und Registrierung erst nach erfolgreich verifiziertem Schema.

## Version 0.19.1 – dokumentiert (09.10.2026)
Übergabeplanung für Annette in `docs/uebergabe-annette.md` aufgenommen und in der Demo-Admin-Ansicht ergänzt. Keine Datenbankänderung, keine echte Auth-Anbindung, kein Infrastrukturtransfer. SQL-Stand 0.19 unverändert: **vorbereitet, nicht ausgeführt**. Nächster technischer Schritt: Supabase-Schema im richtigen Projekt kontrolliert installieren und RLS testen; danach echte Registrierung/Login.


## Stand 0.20 (Auth-Integration vorbereitet)
- Das Supabase-Schema 0.19 wurde vom Benutzer in StaffKeeping ausgeführt; RLS, Policies, RPC-Ausführungsrechte und interne Adminrechte durch SQL-Abfragen überprüft.
- Erster Administrator in sk_internal.staff_admins angelegt.
- 0.20: echte E-Mail/Passwort-Anmeldung, Signup, Bestätigung/Registrierungs-RPC, Session und Admin-Betriebsstatus in JavaScript implementiert. **Live-End-to-End-Test ausstehend; Konfiguration noch leer.**
- Inserate, Nachrichten, Profiländerungen und Bewertungen weiterhin Demo. Original-Projektdokumente noch nicht geschützt online eingebunden.

## Version 0.21 – Passwort-Recovery-Reparatur (Code fertig, Live-Test ausstehend)
- Tatsächlicher Stand: Supabase Auth ist unter der Testdomain konfiguriert; erster Administrator ist angelegt, jedoch war der Passwort-Login bislang nicht erfolgreich.
- Der Recovery-Link führte zu einer angemeldeten Sitzung ohne sichtbares Passwortformular; 0.21 priorisiert den Recovery-Modus vor der normalen Session-/Rollenprüfung und ergänzt eine Passwortbestätigung.
- Bei erfolgreicher Passwortänderung wird die Sitzung beendet und der Nutzer zur normalen Anmeldung geführt.
- Postmark: DKIM und Return-Path für `mueller-home.me` bestätigt; Postmark-Konto freigegeben; Supabase Custom SMTP nach Rückmeldung erfolgreich konfiguriert. Tatsächliche Zustellung und Reset-End-to-End **noch nicht getestet**.
- Es werden keine neuen SQL-Migrationen benötigt. Inserate, Nachrichten und andere Fachmasken bleiben Demo.

## Version 0.22 – Auth-Weiterleitungsadresse (Code erstellt, Live-Retest ausstehend)
- **Live bestätigt durch Anwender:** Passwort-Recovery über Postmark, neues Passwort festlegen, abmelden und mit neuem Passwort anmelden funktionieren in Version 0.21.
- **Fehler aus Signup-Test:** versendeter Bestätigungslink enthielt `redirect_to=https://www.mueller-home.me/` statt `/staffkeeping/`. Supabase Site URL und Redirect-Allowlist sowie Mail-Vorlage wurden im Dashboard kontrolliert und waren richtig.
- **Korrektur 0.22:** `emailRedirectTo` und `redirectTo` werden aus der URL der tatsächlich geladenen Datei `scripts/auth.js` hergeleitet (`/staffkeeping/`), nicht mehr aus `location.pathname`. Kein Supabase-SQL, keine Änderung an der öffentlichen `scripts/config.js` nötig.
- Die alte Bestätigungsmail bleibt unverändert; eine neue Mail und der komplette Firmen-Flow sind **noch zu testen**. Bereits geteilter Bestätigungslink enthält einen Auth-Token und sollte nicht wiederverwendet werden.
- Postmark zugestellt, aber Bestätigungsmail im Spam: Zustellbarkeit separat prüfen. Weiterhin Demo: Inserate, Chats, Profiländerungen, Bewertungen.

## Version 0.23 – Unterbrochene Unternehmensregistrierung (Code erstellt, Live-Test offen)
- Beim Live-Test ist das zweite Supabase-Auth-Konto per E-Mail **bestätigt**; die SQL-Abfrage auf `sk_businesses` + Mitgliedschaften lieferte **keine Zeilen**. Die App zeigte fälschlich „Prüfung ausstehend“.
- Ab 0.23 wird nach `getUser`/`sk_is_admin`/Mitgliedschaft geprüft: Ein bestätigter Benutzer ohne Unternehmenszuordnung sieht das Formular „Unternehmensregistrierung abschliessen“. Bereits vorhandene Daten aus dem lokalen Entwurf werden für die gleiche E-Mail vorgefüllt; sonst kann der Benutzer die Angaben neu erfassen. **Es erfolgt kein erneutes `signUp` und keine neue Bestätigungsmail.**
- `sk_register_business` bleibt die einzige Anlagefunktion; Status `Ausstehend` wird in der Datenbank gesetzt. Bestehende bestätigte Test-Auth-Konten bleiben erhalten.
- Live-Prüfung der Firma, Admin-Freigabe, Marktplatz-Sperre und RLS-Zugriffe stehen weiterhin aus. Ohne serverseitigen Registrierungsentwurf werden Daten bei Browser-/Gerätewechsel nur durch neue Formulareingabe ergänzt.
