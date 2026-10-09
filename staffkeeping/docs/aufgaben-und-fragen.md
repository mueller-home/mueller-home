# Aufgaben und Klärungsbedarf

| Priorität | Status | Thema |
|---|---|---|
| P0 | Offen | Vollständiges Migrationskonzept künftig geschützt in Admin-Oberfläche bereitstellen (Supabase Admin-Rolle). |
| P0 | Offen | Supabase Datenmodell, RLS, Freigabe- und Sperrlogik, Zugriffstests. |
| P1 | Offen | Designabnahme mit Annette; Logo, Schrift, genauer Blauwert. |
| P1 | Offen | Bubble-Audit Data Types, Privacy Rules, Workflows, Option Sets. |
| P1 | Offen | Firmen-/Benutzerbeziehung, Rollen und Chat-Zugriff klären. |
| P1 | Offen | Abweichende Inseratestatus und Chatfeld-Bezeichnungen im Konzept bereinigen. |
| P2 | Geplant | E-Mail, Karten/Umkreissuche, Storage. |
| Später | Geplant | Stripe, Mitgliedschaft, Währungen, Talent-Fonds. |

Weitere offene Vorgaben laut Original: BusinessImage-Struktur, Bewertungsvalidierung, Mehrsprachigkeit, Impact-Sichtbarkeit, Freischaltungsdauer. Nicht als entschieden behandeln.

## Arbeitspaket 0.19 / 0.20
- **P0 – Vorbereitet, offen:** SQL-Migration 0.19 im korrekten Supabase-Projekt kontrolliert ausführen; RLS, Schemaexposition und Funktions-Eigentümer prüfen.
- **P0 – Offen:** Erstes verifiziertes Admin-Auth-Konto anlegen, seine UUID nur über privilegierte SQL-Verwaltung eintragen.
- **P0 – Offen:** RLS/RPC-Negativtests mit mindestens zwei frischen Testunternehmen durchführen.
- **P0 – Geplant (0.20):** Demo-Login durch Supabase Auth, E-Mail-Verifikation, Passwort-Reset und serverseitige Statusprüfung ersetzen.
- **P1 – Zu klären:** Mehrere Mitarbeiter je Unternehmen, mehrere Firmen je Benutzer und weitere Statuswerte (z. B. abgelehnt).
- **P1 – Offen:** Original-Migrationskonzept erst nach echtem Adminschutz ausliefern.

## Übergabe an Annette (neuer Beschluss)
- **P1 – Offen:** GitHub-Übertragung an Annettes Konto/Organisation und zusätzliche Admin-Rolle des bisherigen Entwicklers prüfen.
- **P1 – Offen:** Supabase-Projekttransfer, Organisationsrollen, Billing und Backups prüfen.
- **P1 – Offen:** Postmark-Konto-/Server-Verwaltung und E-Mail-Domain auf Annette überführen.
- **P1 – Offen:** Ziel-App-Domain, Supabase Auth Redirects, DNS/HTTPS, Mail-Absender und bestehende Google Maps Referrer-Beschränkungen klären.
- **P0 – Vor Livegang:** finale Domain und vollständige Zugriffstests durchführen.
- Referenzcheckliste: `docs/uebergabe-annette.md`. Die Providertransfers sind **geplant, nicht ausgeführt**.


## Aktuell prioritär (0.20)
1. Project URL und Publishable Key in scripts/config.js konfigurieren; keine Secrets eintragen.
2. Auth Redirect URLs, Site URL und Postmark/SMTP prüfen.
3. Signup/Testfirma inkl. E-Mail-Bestätigung, Pending, Adminfreigabe, Session und Passwort-Reset LIVE testen.
4. Test über fremden Benutzer und direkte REST/RPC-Anfragen, keinen ungeprüften Marktplatz-Zugang.
5. Registrierung über mehrere Geräte: noch kein langlebiger serverseitiger Registrierungsentwurf; lokale Entwurfsdaten nur im gleichen Browser. Für produktive Nutzung verbessern.
6. Fehlende rechtsverbindliche Nutzungsbedingungen vor Produktivregistrierung ergänzen.

## Neu: P0 nach 0.21
1. Recovery-Link live öffnen: Passwortformular statt Marktplatz; neues Passwort zweimal setzen und danach regulären Login nach Logout prüfen. Bei E-Mail-Ratelimits keine wiederholten Testversuche starten.
2. Postmark-Transactional-Zustellung nachweisen, einschließlich From-Adresse und Supabase-Redirect.
3. Falsche Bestätigung, ungültige/verbrauchte Links, Browserreload und anderer Browser testen.
4. Bereits angelegtes Administratorkonto behalten, keine neuen Admin-UUIDs erzeugen.
5. Anmeldung, Registrierung, Adminfreigabe und negative RLS-Tests mit zwei Firmen nachholen.
