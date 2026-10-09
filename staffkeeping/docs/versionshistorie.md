# Versionshistorie (Designphase)

- 0.10 – erste Startseiten-Demo; Marketingausrichtung später verworfen.
- 0.11 – App-Login/Registrierung/Marktplatz.
- 0.12 – temporärer Inline-CSS-Workaround; später verworfen.
- 0.13 – zentrale CSS-/JS-Dateien wiederhergestellt.
- 0.14 – Akzentfarbe `#159FD4`.
- 0.15 – Demo-/Hero-Balken hellblau.
- 0.16 – zusätzliche Fach- und Admin-Masken.
- 0.17 – Demo-Navigation und Reload-Verhalten korrigiert (statischer Check, Benutzer-Retest offen).
- 0.18 – Admin-Projektdokumentation, Status/Regeln/TODO/Entscheidungen, Chat-Übergabe; vollständige Originalquelle bleibt bewusst lokal.

Ausstehend: echte Authentifizierung und backendgeschützter Originaldokument-Zugriff.

- **0.19 – vorbereitet:** Neues versioniertes SQL-Basisschema (Unternehmen/Mitgliedschaften/Admin/Audit, RLS, RPC), DB-/Auth-Installationsanleitung und Dokumentationsaktualisierung. Kein Deployment und keine Funktionstests nachgewiesen.

- **0.19.1 – Dokumentation/Übergabeplanung:** GitHub/Supabase/Postmark an Annette, zusätzlicher Adminzugang für Entwickler, vorhandener Google-Maps-Key, Domain/Mail-Umstellung; Checkliste und Demo-Admin-Kapitel. **Keine** echten Transfers, keine SQL-Ausführung, keine Auth-Anbindung.


## 0.20 – Auth-Integrationsstand (09.10.2026)
Echte Auth- und Freigabeaufrufe programmiert. scripts/config.js muss noch ergänzt werden; SMTP und E2E-Tests stehen aus. Kein vollständig produktiver Stand.

## 0.21 – 09.10.2026
Passwort-Recovery stabilisiert: Recovery-Modus gegenüber automatischer Sitzungs-/Rollenbewertung priorisiert; doppelte Passworteingabe, Plausibilitätsprüfung, Statusmeldungen, Sign-out nach erfolgreicher Passwortänderung, Abbruchmöglichkeit. Admin-Doku auf aktuellen Supabase-/Postmark-Stand gebracht. **Statischer Code-Test; Live-Browsertest und Versandtest ausstehend.**

## 0.22 – 09.10.2026
- Signup- und Passwort-Reset-Redirect werden aus dem Pfad von `scripts/auth.js` abgeleitet; `/staffkeeping/` wird explizit validiert.
- Versionsanzeige in Hinweisbalken, Footer und Admin-Projektdoku synchronisiert; öffentliche Dokumentation / Übergabetext aktualisiert.
- Kein SQL- oder Secret-Wechsel; User-Konfiguration bleibt unverändert. Live-Bestätigung der neuen Registrierungslinks ausstehend.
- Nachgetragen: Passwort-Reset 0.21 einschliesslich Logout und erneutem Login wurde live erfolgreich getestet.

## 0.23 – 09.10.2026
- Bestätigte Test-E-Mail hatte noch keine Firma; 0.22 zeigte trotzdem nur den Wartestatus.
- 0.23: Nach Login ohne Firmenzuordnung Formular zum Vervollständigen der Firma; keine zweite Auth-Registrierung/kein Mailversand.
- Pending erst nach Anlage von `sk_businesses` und `sk_business_members`; SQL unverändert, Live-Test offen.
- App-/Admin-Versionsanzeigen und Dokumentation aktualisiert.

## 0.24 – 09.10.2026
Admin → Betriebe: Detailprüfung vor Freigabe, Kontaktdaten und Benutzerzuordnung; interne, nur administrativ abrufbare Notizen; vorhandenes Audit als Freigabehistorie. Neue versionierte Supabase-Migration. Umsetzung/statische Tests erfolgt, Live-Test offen.


## 0.25 – Profilverwaltung und private Bilder (09.10.2026)
Neue Migration für Beschreibung/Benachrichtigungsvorliebe, zwei private Storage-Buckets mit RLS und serverseitige Profil-RPCs. Profilmaske liest/speichert echte Unternehmensdaten; Admin-Details zeigen Profilbeschreibung und Medien. Freigabe-Warteseite weist bestätigte E-Mail und bereits erfasste Firma getrennt aus. Live-Test der 0.25-Migration und Funktionen steht aus.


## 0.26 – 09.10.2026
- Auto-Save im Firmenprofil (Debounce, Blur, sofort bei Auswahländerung, Flush vor Navigation, Fehleranzeige/Retry und Browser-Unload-Warnung).
- Geschützter Original-Migrationskonzept-Viewer und Upload auf private Supabase Storage; SQL-Migration 20261009163000. Originaldatei nicht im öffentlichen Update-ZIP.
- Projektdokumentation, Testfälle und Chat-Übergabe überarbeitet.
- Status: **implementiert / statisch geprüft**, Supabase-Migration und Live-Sicherheitsabnahme **noch offen**.
