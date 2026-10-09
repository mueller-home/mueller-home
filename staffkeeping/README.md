# StaffKeeping – App-Prototyp 0.18

Öffne `index.html` für die lokale Demo oder veröffentliche **nur die freigabefähigen App-Dateien** auf GitHub Pages. Der Demo-Login besitzt keine echte Berechtigungsprüfung.

### Neu in 0.18
Admin-Navigation → **Projektdoku**, Kapitel Briefing, Systemkonzept, Stand, Aufgaben, Regeln, Tests, Versionen, Chat-Übergabe sowie Hinweise zum Originalkonzept.

### Dokumentation
- `docs/`: versionierte **öffentlichkeitsfähige** Projektdokumentation.
- `_bubble/staffkeeping_migrationskonzept.html`: vollständige Originalquelle (v2.2) inkl. eingebetteter Screenshots, **nur lokal**, von Git ausgeschlossen. Nicht im GitHub-Pages-Pfad veröffentlichen; `.gitignore` prüfen.
- Ein geschützter Zugriff auf das vollständige Konzept im Adminbereich erfordert die spätere Supabase-Authentifizierung und serverseitige Rollenprüfung. Nicht als bereits implementiert betrachten.

### Dateien
Zentrale CSS-Dateien `styles/tokens.css`, `styles/main.css`; Interaktion `scripts/app.js`. Keine realen Daten oder Verbindungen.

### Aktualisierungsregel
Mit jeder neuen Version `docs/` und die Demo-Inhalte der Projektdoku konsistent anpassen. ZIP `sk-update-<Version>-<YYYYMMDD-HHMMSS>.zip`, ausschliesslich geänderte/neue Dateien unter `staffkeeping/`.


## 0.20 Supabase Auth (Konfiguration erforderlich)

In `scripts/config.js` **nur** die Project URL und den Publishable Key eintragen. Keine geheimen Schlüssel. Supabase Auth: Site URL und Redirect URL auf die verwendete App-Adresse setzen. Custom SMTP/Postmark vor breiten Registrierungstests konfigurieren. Erst danach mit Admin und Testfirma testen. Registrierung wird erst nach bestätigter E-Mail abgeschlossen; der Zwischenentwurf verbleibt bis dahin lokal im gleichen Browser (nicht in Supabase). Bei Browserwechsel den Vorgang ggf. neu starten – vor Produktivstart zu verbessern. Inserate und Chats bleiben Beispiele.

## Version 0.21 – Recovery-Korrektur
Postmark-SMTP für `mueller-home.me` ist laut Einrichtung bestätigt, Versand muss noch live getestet werden. Recovery-Links zeigen nun vorrangig das Formular für ein neues Passwort. Die App sollte nach Änderung abmelden und mit dem neuen Passwort erneut anmelden lassen. Siehe `docs/testplan.md`; vollständiger Browsertest noch offen. `scripts/config.js` bleibt unverändert und enthält ausschliesslich öffentliche Supabase-Verbindungsdaten.

## Update 0.23 – Firmenregistrierung fortsetzen
Bereits bestätigte Supabase-Benutzer ohne Firmenmitgliedschaft sehen das Formular zum Abschluss der Registrierung ohne erneute Auth-E-Mail. Nach Anlage der Firma zeigt die Anwendung den Freigabestatus. Kein SQL-Update. Siehe docs/testplan.md.

## 0.24 – Inbetriebnahme
1. Zuerst `supabase/migrations/20261009153000_admin_business_review.sql` einmalig im richtigen Supabase-Projekt ausführen (SQL enthält eine Transaktion, keine SELECT-Resultsets).
2. Erst danach Update-Dateien veröffentlichen.
3. Admin → Betriebe → Details / Prüfen; Kontaktdaten, Notizen, Audit und Freigabe testen.
4. Negativtests gegen die Admin-RPCs mit normalen Benutzerkonten durchführen.
