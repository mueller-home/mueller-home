# Betrieb, Eigentümerschaft und Übergabe an Annette

**Stand: 09.10.2026 · Release 0.19.1 · Planungsstand, noch keine Übergabe ausgeführt.**

## Beschlossene Zielstruktur

Die **bestehenden Ressourcen** werden nach Entwicklung und Abnahme in Annettes Verantwortung übertragen; grundsätzlich kein paralleler Neuaufbau der Produktivumgebung. Der bisherige Entwickler bleibt mit **zusätzlichen administrativen Rechten** beteiligt. Eine spätere Neuanlage ist nur ein Fallback, falls ein Anbieter die gewünschte Übertragung technisch oder organisatorisch nicht zulässt. Eigentum, Verwaltung und Abrechnung sind pro Anbieter zu prüfen.

| Dienst | Ziel / Vorgabe | Status |
|---|---|---|
| GitHub | Bestehendes Repository an Annette oder vorzugsweise ihre Organisation übertragen; Entwickler behält Admin-Zugriff. Organisation und gewünschte Rollen prüfen. | Geplant |
| Supabase | Bestehendes StaffKeeping-Projekt in Annettes Organisation überführen; Entwickler behält benötigte Verwaltungsrolle. Projektverfügbarkeit, Datenbestand, Abrechnung und Zugriffsrechte prüfen. | Geplant |
| Postmark | Bestehendes Konto bzw. Server in Annettes Verantwortung übergeben, mit administrativem Zugriff für den Entwickler; konkreten Provider-Prozess vorab verifizieren. | Geplant |
| Google Maps | Google-Maps-Schlüssel gehört bereits Annette und ist korrekt eingerichtet; keinen unnötigen Schlüsselwechsel vorsehen, API-/Referrer-Beschränkungen nach Domainwechsel kontrollieren. | Vorhanden, Funktionstest offen |
| App-Domain | App auf die von Annette bestimmte Domain/Subdomain umstellen; bestehende Marketing-Website bleibt separat und verlinkt auf App. | Geplant; Domainname noch offen |
| E-Mail-Absender | Produktive Absenderadresse und eigene Domain-Authentifizierung unter Annettes Domain; Postmark/SMTP und Templates prüfen. | Geplant; konkrete Adresse offen |

## Verbindliche Übergabe-Checkliste (offen)

- [ ] Rechtlich und organisatorisch klären, ob Annette persönlich oder eine GitHub-/Supabase-Organisation Eigentümerin wird; Einladungen/Rollen für beide Administratoren prüfen.
- [ ] GitHub-Repository-Eigentum übertragen; GitHub Pages, Branch, Actions, Deployments, Webhooks und Adminberechtigungen prüfen.
- [ ] Supabase-Projekttransfer, Organisationsrolle, Billing, Backups, Auth, Datenbank- und Storage-Zugriffsrechte prüfen. Vor Transfer verifiziertes Backup/Restore-Verfahren und Wartungsfenster festlegen.
- [ ] Testdaten vor produktivem Betrieb geplant bereinigen, ohne SQL-Migrationshistorie oder notwendige Stammdaten zu verlieren. Keine alten Bubble-Unternehmensdaten übernehmen.
- [ ] Postmark-Account/Server-Verwaltung und Billing an Annette übergeben; Sender Signature, SPF, DKIM, DMARC und SMTP-Senden testen.
- [ ] DNS, Custom Domain, HTTPS/TLS-Zertifikate, App-Link von bestehender Website und Weiterleitungen einrichten.
- [ ] Supabase Auth: Site URL, Redirect-Allowlist, Bestätigungs-/Reset-Mails, Session-/Cookie-Verhalten und E-Mail-Links auf neuer Domain testen.
- [ ] Zentrale Frontend-Konfiguration für Projekt-URL, Publishable Key, App-URL aktualisieren; keine Geheimnisse in GitHub Pages.
- [ ] Maps-Key behalten, aber Google-API-Einschränkungen/HTTP-Referrer für neue App-Domain aktualisieren und Karten-/Umkreissuche prüfen.
- [ ] Backend- und Postmark-Secrets nach Eigentumswechsel inventarisieren und bei Bedarf rotieren; Zugriffsrechte, Logs und Abrechnungsverantwortung dokumentieren, **keine geheimen Werte** in Repo/Projektdoku speichern.
- [ ] End-to-End-Abnahme auf finaler Domain: Registrierung, E-Mail-Verifikation, Adminfreigabe, Login, Reset, Logout, gesperrte Firmen, RLS-Negativtests, Chats, Mail, Maps, Mobilansicht.
- [ ] Eigentümer-/Administratorkonten, Recovery-/Notfallzugang, Betriebsverantwortliche und Supportprozess schriftlich bestätigen.

## Wichtige Einschränkungen

- Eine Repo-Übertragung überträgt nicht automatisch Domain, Postmark, Supabase-Projekt oder Zahlungsdaten.
- Die konkrete Möglichkeit eines Eigentums-/Projekttransfers ist vor der Übergabe **beim jeweiligen Anbieter** zu verifizieren; Annahmen nicht als erledigt markieren.
- Das Supabase-Projekt ist aktuell noch nicht verifiziert; die SQL-Migration 0.19 gilt weiterhin als **vorbereitet, nicht ausgeführt**.
- Bis zur echten Auth- und Admin-Berechtigung ist die Admin-Projektdoku in GitHub Pages **öffentlich zugänglicher Demoinhalt**. Deshalb keine internen Credentials oder geheimen Übergabeunterlagen einfügen.

## Weiterentwicklung und Releasepflicht

Dieses Kapitel sowie `entwicklungsstand.md`, `entscheidungen.md`, `aufgaben-und-fragen.md`, `testplan.md`, `versionshistorie.md` und `chat-uebergabe.md` werden bei betroffenen Releases synchron aktualisiert. Ergänzungen in der öffentlichen Demoansicht müssen denselben Status wiedergeben.
