# Übergabe an neuen Chat – StaffKeeping

**Stand 09.10.2026 / Version 0.18**

Es wird ausschließlich die App entwickelt; Marketing-Homepage existiert separat. Frontend aktuell Demo HTML/CSS/JS, GitHub Pages; Supabase noch nicht angebunden. UI-Masken: Login, Registrieren, Reset, Freigabe, Marktplatz, Profil, eigene Inserate, Details, Nachrichten, Reviews, Admin-Betriebe/Inserate/Impact/Projektdoku.

**Nächste Arbeit:** UI mit Annette abnehmen; ursprüngliches Migrationskonzept v2.2 lesen und mit neuen Entscheidungen abgleichen; Bubble-Audit durchführen; danach Datenmodell/RLS/Auth planen und erst auf LOS implementieren.

**Sicherheit:** Demo-Login ist kein Schutz. Originalkonzept nur lokal `_bubble`, nicht als GitHub-Pages-Asset. Admin-Dokumente im `docs/`-Ordner enthalten nur freigabefähige Zusammenfassungen.

**Regeln:** `docs/entwicklungsregeln.md` vollständig lesen. ZIP `sk-update-<Version>-<YYYYMMDD-HHMMSS>.zip`; nur neue/geänderte Dateien unter `staffkeeping/`; zentrales CSS; nach jedem Release Dokumentation aktualisieren.

**Offene Punkte:** `docs/aufgaben-und-fragen.md`, Systemstand `docs/entwicklungsstand.md`, Entscheidungen `docs/entscheidungen.md`, Tests `docs/testplan.md`.

**Erforderliche Referenz:** Original `staffkeeping_migrationskonzept.html` v2.2 im lokalen gitignorierten `_bubble`-Ordner (im nächsten Chat erneut bereitstellen, bis sichere Dokumentenanbindung existiert).

## Nachtrag Version 0.19
SQL-Fundament liegt in `supabase/migrations/20261009120000_auth_foundation.sql` (noch **nicht ausgeführt**, keine Live-Verifikation). Erklärung: `docs/auth-und-datenmodell.md` und `supabase/README.md`. Zuerst Migration mit Prüfplan installieren, Admin-UUID sicher bootstrappen und RLS-Negativtests; erst danach 0.20 Login/Registrierung. Alle Firmen/Benutzer komplett neue Testdaten, **keine Migration alter Bubble-Konten**.

## Aktueller Nachtrag 0.19.1 – Übergabe an Annette
Bitte `docs/uebergabe-annette.md` lesen: Bestehende GitHub-, Supabase- und Postmark-Ressourcen werden nach Abnahme an Annette übergeben, Entwickler bleibt zusätzlicher Administrator. Der Google-Maps-Key gehört bereits Annette. Neue App-Domain sowie Mail-Absender/SMTP/Redirect-URLs müssen zur Übergabe geändert werden. Noch nichts übertragen oder produktiv umgestellt. Die Docs-Version 0.19.1 aktualisiert nur Doku und Admin-Demo. SQL 0.19 weiterhin **nicht nachgewiesen ausgeführt**. Nächste technische Arbeit: Migration kontrolliert installieren, RLS/Nicht-Exposition testen, dann Auth 0.20. ZIP unter `staffkeeping/`, nur neue/geänderte Dateien. Die Demo-Adminansicht ist öffentlich abrufbar, daher dort keine Geheimnisse.


## Übergabe-Update 0.20
Supabase-Schema 0.19 installiert und geprüft; erster DB-Administrator angelegt. Code 0.20 für Auth/RPC vorbereitet, aber Projekt-URL/Publishable Key fehlen noch; End-to-End-Tests ausstehend. Vor Produktivnutzung Nutzungsbedingungen, zuverlässiger SMTP-Versand, Registrierungsfortsetzung über Geräte, RLS- und Rollen-Negativtests. Keine Produktivfähigkeit behaupten.

## Übergabe-Update 0.21 (09.10.2026)
Supabase 0.19 Schema und Admin-Konto sind installiert; Auth 0.20 ist mit Public URL/Publishable Key und Weiterleitungsadressen konfiguriert. Login schlug bisher mit `Invalid login credentials` fehl. Recovery-Mail meldete zwar eine Sitzung an, zeigte aber nicht das Formular zum Setzen eines Passworts. Postmark für `mueller-home.me` wurde mit DKIM, Return-Path, Freigabe und Supabase SMTP konfiguriert; ein echter Zustelltest fehlt. 0.21 behebt die UI-/State-Kollision des Recovery-Modus und ergänzt Passwortbestätigung; **echten Retest noch durchführen**. Fachfunktionen sind weiterhin Demo. ZIP-/CSS-/Dokumentationsregeln gelten fort.

## Übergabestand 0.22 – 09.10.2026
Die Test-App läuft unter `https://www.mueller-home.me/staffkeeping/`. Auth ist mit Supabase konfiguriert, Postmark ist genehmigt, Domain `mueller-home.me` DKIM/Return-Path bestätigt und SMTP aktiv. Passwort-Recovery 0.21 inklusive Ab-/Neuanmeldung wurde live erfolgreich getestet. Ein Signup-Bestätigungslink verwies wegen `redirect_to=https://www.mueller-home.me/` auf die Root-Homepage, obwohl Supabase Site URL und Mailvorlage korrekt waren. 0.22 leitet beide Auth-Redirects robust aus dem Auth-Skriptpfad `/staffkeeping/` ab; Retest mit **neuem** Bestätigungslink steht aus. Auth-Tokens nicht in Chat kopieren. Firmenfreigabe und Zwei-Konto-RLS sind noch ungetestet, Inserate/Chats Demo. Alle Dateien/Entscheidungen unter `docs/`, ZIP-Regeln beachten. Die originale Bubble-Dokumentation bleibt lokal.

## Übergabestand 0.23 – 09.10.2026
Nach Installation 0.22 bestätigte der Benutzer: Test-E-Mail bestätigt, SQL-Abfrage auf Unternehmen/Mitgliedschaften: `Success. No rows returned`. Login zeigte dennoch eine allgemeine Warteseite. Ursache: auth.js behandelte fehlende Mitgliedschaft wie ausstehende Freigabe und verlangte für die Registrierung immer ein neues Auth-Konto.
0.23 (Code bereitgestellt; Live-Test noch offen): bestätigtes Auth-Konto ohne Firmenzuordnung wird zur vervollständigbaren Registrierung geleitet. E-Mail bleibt gebunden, Passwort-Neuanlage entfällt; RPC `sk_register_business` legt die Firma an, anschliessend Wartestatus. Kein neues SQL. Test: bestehendes Testkonto anmelden → Firma erfassen → SQL Status `Ausstehend` prüfen → Adminfreigabe → RLS-Negativtests. V0.21 Recovery erfolgreich live, V0.22 Redirect-Korrektur noch nicht abschliessend live bestätigt.
