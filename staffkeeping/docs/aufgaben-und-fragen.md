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

## Version 0.22 – Prioritäten
- **P0 / Test ausstehend:** Nach Veröffentlichung von 0.22 neue Signup-Mail generieren und **nur** den `redirect_to`-Wert prüfen (`https://www.mueller-home.me/staffkeeping/`); vollständigen Link/Token niemals in Chat/Issues teilen.
- **P0:** Mail bestätigen, Firmen-Eintrag und Status `Ausstehend` prüfen; Registrierung kann bei browserübergreifendem Bestätigen noch am lokal gehaltenen Registrierungsentwurf scheitern.
- **P0:** Adminfreigabe, Firmenstatus und RLS-Negativtest mit zwei neuen Konten.
- **P1:** Spam-Einstufung prüfen (Postmark-Berichte, SPF/DMARC, Vorlage); das SMTP-Setup ist bereits erfolgreich durchgeführt.
- **Erledigt und live bestätigt:** Version 0.21 Passwort-Reset, Logout und anschliessender Login mit neuem Passwort.

## Version 0.23 – P0 Test und Folgearbeiten
- [ ] Mit bestehendem, bestätigtem Testkonto **ohne** Unternehmensdatensatz anmelden: Firmenformular erscheint statt allgemeiner Warteseite.
- [ ] Bereits ausgefüllte Felder falls vorhanden vorgefüllt; fehlende Werte manuell ergänzen; Abschluss ohne erneute Registrierungsmail.
- [ ] `sk_businesses` und `sk_business_members` prüfen: genau eine Firma, Rolle `owner`, Status `Ausstehend`.
- [ ] Benutzer ohne Freigabe sieht Marktplatz nicht; Administrator kann Firma freigeben; danach Login und Zugriff prüfen.
- [ ] Negativtests mit zwei verschiedenen Unternehmen und direkten API-Anfragen; Spamzustellung separat behandeln.
- [ ] Langfristig serverseitigen, geräteübergreifenden Registrierungsentwurf erwägen, nicht als bereits implementiert markieren.

## Priorität 0 – 0.24 testen
- SQL-Migration `20261009153000_admin_business_review.sql` in StaffKeeping einmalig ausführen und Rechte überprüfen.
- Admin sieht vollständige Registrierungs-/Kontaktdaten, kann Notiz speichern, Freigabehistorie prüfen und Betrieb freischalten.
- Negativtest: normales freigeschaltetes sowie ausstehendes Konto darf die Detail-/Notiz-RPCs nicht ausführen; direkte `sk_internal`-Tabellenabfragen müssen verweigert werden.
- Freigabe von Hotel chris.login erst nach Detailprüfung durchführen.
- Spam-Einstufung von Supabase/Postmark-Mails untersuchen; künftig Statusanzeigen der Registrierungs-Warteseite präzisieren.
- Altbetrieb ohne Benutzerzuordnung nach Bestätigung löschen (noch nicht als erledigt markieren).


## Stand 0.25 – aktuelle Prioritäten
- **P0:** SQL-Migration `20261009160500_business_profile_media.sql` im bestehenden Supabase-Projekt installieren, danach App 0.25 deployen.
- **P0:** Profil-Lade-/Speichertest mit genehmigtem Testbetrieb; nach Browserneustart gespeicherte Beschreibung und Kontaktdaten prüfen. Land, USt-ID und Firmenfreigabe dürfen nicht eigenständig geändert werden.
- **P0:** Logo hochladen/ersetzen/löschen, Bilder 1–5 hochladen/ersetzen/löschen; Admin-Detailansicht kontrollieren. Versuche ohne/mit fremdem Konto und direkte Storage-API-RLS-Negativtests durchführen.
- **P0:** Prüfen, ob Admin-Notizen und Freigabehistorie nach Reload bleiben.
- **P1:** Postmark-Zustellung beim iCloud-Testaccount im Spam analysieren (DMARC, Header und Postmark Activity).
- **P1:** Verwaiste Testunternehmen kontrolliert bereinigen; Löschen eines Auth-Users darf produktive Unternehmen nicht automatisch entfernen.
- **P1:** Registrierung und Freigabe mit zweitem unabhängigem Testbetrieb sowie anderem Browser/Gerät testen; Nutzungsbedingungen finalisieren.
- **P2:** E-Mail-Benachrichtigungsvorliebe bei Implementierung von Nachrichten-/Inseratsmodulen für tatsächlichen Versand auswerten.


## Priorisierte offenen Tests und Arbeiten 0.26
- **P0:** Migration `20261009163000_private_project_docs.sql` ausführen; Bucket privat bestätigen; HTML-Original per Admin hochladen; Lesetest und **anonym/nicht-Admin Negativtest**.
- **P0:** Profil 0.25-Migration/Medien live prüfen; anschließend 0.26 Auto-Save auf Texte, Auswahllisten, Benachrichtigung, Navigationswechsel, Back/Forward, Netzfehler, Reload/Tab-Schliessen testen.
- **P1:** E-Mail-Postmark landet bei iCloud im Spam; Zustellbarkeit / Postmark-Aktivität und DMARC prüfen.
- **P1:** Admin-Dokumentationsinhalte mit tatsächlichem Versionsstand konsistent halten; zukünftige Versionen nie ohne Docs aktualisieren.
- **P1:** Mehrtab-/Mehrbenutzer-Konflikte: aktiver RPC überschreibt ein ganzes Profil, noch keine feldweise serverseitige Konfliktkontrolle.
- **P2:** Inserate, Chat, Bewertungen aus Demo in echte Fachmodule überführen, Mailbenachrichtigungsversand erst mit Fachmodulen aktivieren.
