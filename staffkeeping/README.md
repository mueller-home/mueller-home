# StaffKeeping – Designprototyp 0.11

Ziel: ausschliesslich **Applikation**, keine Marketing-Website. Die separate StaffKeeping-Homepage verlinkt später auf diese App.

## Bestandteil
- `index.html`: Login, Registrierung, Passwort-Reset-Platzhalter, Freigabe-Warteseite und Marktplatz.
- `styles/tokens.css`: CI-Farbdefinitionen (gegenüber 0.10 unverändert; wird **nicht** im Update-ZIP mitgeliefert).
- `styles/main.css`: App-Layout, Responsive-Design.
- `scripts/app.js`: ausschliesslich lokale Demo-Interaktionen (keine Supabase-Verbindung).

## Wichtige Einschränkungen
- **Keine echte Authentifizierung.** Jedes formal gültig ausgefüllte Login-Formular öffnet die Demo-Marktplatzansicht.
- **Keine Speicherung, kein Versand.** Registrierung, Passwort-Rücksetzung, Merkliste und Suche sind ausschliesslich Demo-Funktionen.
- **Kein realer Datenzugriff.** Inserate sind vollständig fiktiv. Länder-/Radiusregeln sind noch nicht serverseitig umgesetzt.
- Registrierungsfelder sind eine Design-Musteransicht; Abgleich mit Kapitel 5 des Migrationskonzepts vor tatsächlicher Supabase-Implementierung erforderlich.
- Eine endgültige Schriftart ist laut Migrationskonzept noch offen; bis dahin Systemschrift.
- Schirmmarke als gezeichneter Platzhalter, originale Logo-Datei fehlt weiterhin.
- Impressum/Datenschutz/Nutzungsbedingungen werden später über die bestehende Homepage bzw. verbindliche Rechtstexte verlinkt; keine unbestätigten URLs hinterlegt.

## Testablauf
1. `index.html` im Browser öffnen.
2. Login mit beliebiger syntaktisch gültiger E-Mail und Passwort probieren → Demo-Marktplatz.
3. Ausloggen → Unternehmen registrieren → Freigabestatus.
4. Zurück zum Login → Passwort vergessen → Demo-Meldung (keine E-Mail versendet).
5. Im Marktplatz Suchfilter und Merkliste testen; Karte ist bewusst ein Platzhalter.
6. Desktop und Mobilansicht mit Annette beurteilen.

## Update-Regeln
ZIP `sk-update-<Version>-<YYYYMMDD-HHMMSS>.zip`; alle Dateien unter `staffkeeping/`; nur neue/geänderte Dateien. `styles/tokens.css` ist aus 0.10 unverändert, und die bisherige `assets/illustrations.svg` wird von der App nicht mehr verwendet (kann im Projekt gelöscht werden). Eine ZIP-Datei löscht vorhandene Altdateien nicht automatisch.
