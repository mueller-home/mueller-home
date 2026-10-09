-- StaffKeeping 0.27 – Führende Admin-Projektdokumentation (einmalige Initialisierung)
-- Nach Migration 0.26. Eine Transaktion; mehrere DDL-/INSERT-Anweisungen, KEINE SELECT-Resultsets.
-- Bestehendes Original (v2.2) unverändert in privatem Storage; KEINE Kopie in SQL oder GitHub.
BEGIN;
CREATE TABLE IF NOT EXISTS sk_internal.project_doc_chapters (
  slug text PRIMARY KEY CHECK (slug ~ '^[a-z0-9-]{2,40}$'),
  title text NOT NULL CHECK (char_length(title) BETWEEN 2 AND 160),
  body text NOT NULL DEFAULT '',
  position integer NOT NULL DEFAULT 100,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL
);
REVOKE ALL ON sk_internal.project_doc_chapters FROM PUBLIC, anon, authenticated;
ALTER TABLE sk_internal.project_doc_chapters ENABLE ROW LEVEL SECURITY;
-- Admin only: SECURITY DEFINER mit serverseitiger Rollenprüfung; nie direkte Schemaexposition.
CREATE OR REPLACE FUNCTION public.sk_admin_list_project_docs()
RETURNS TABLE(slug text,title text,body text,"position" integer,updated_at timestamptz)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $fn$
BEGIN
 IF NOT public.sk_is_admin() THEN RAISE EXCEPTION 'Administratorberechtigung erforderlich' USING ERRCODE='42501'; END IF;
 RETURN QUERY SELECT d.slug,d.title,d.body,d.position,d.updated_at
 FROM sk_internal.project_doc_chapters d ORDER BY d.position,d.slug;
END; $fn$;
CREATE OR REPLACE FUNCTION public.sk_admin_save_project_doc(p_slug text,p_body text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $fn$
BEGIN
 IF NOT public.sk_is_admin() THEN RAISE EXCEPTION 'Administratorberechtigung erforderlich' USING ERRCODE='42501'; END IF;
 IF p_body IS NULL OR char_length(p_body)>250000 THEN RAISE EXCEPTION 'Ungültige Kapitellänge'; END IF;
 UPDATE sk_internal.project_doc_chapters d SET body=p_body,updated_at=now(),updated_by=auth.uid()
 WHERE d.slug=p_slug;
 IF NOT FOUND THEN RAISE EXCEPTION 'Kapitel nicht vorhanden'; END IF;
END; $fn$;
REVOKE ALL ON FUNCTION public.sk_admin_list_project_docs() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.sk_admin_save_project_doc(text,text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.sk_admin_list_project_docs() TO authenticated;
GRANT EXECUTE ON FUNCTION public.sk_admin_save_project_doc(text,text) TO authenticated;
-- Initialseed wird bei wiederholter Ausführung NICHT über bereits bearbeitete Kapitel geschrieben.
INSERT INTO sk_internal.project_doc_chapters(slug,title,body,position) VALUES('briefing','Projektbriefing','# StaffKeeping – App-Prototyp 0.18

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


## Version 0.25 – Profil/Medien
Vor Veröffentlichung die neue Supabase-Migration `supabase/migrations/20261009160500_business_profile_media.sql` einmal ausführen. Profilwerte sind danach echt und werden gespeichert, Fotos im privaten Storage. Admin sieht sie in der Betriebsprüfung. Die E-Mail-Benachrichtigungsvorliebe wird nur gespeichert; Versand von Fachmails ist noch nicht implementiert.


## Release 0.26
- Auto-Save im Firmenprofil: verzögert bei Eingabe; Flush vor Navigation; Browser-Warnung bei ausstehenden Eingaben. Kritische Statusaktionen erfordern weiterhin bewusste Bestätigung.
- Admin → Projektdoku → **Originalkonzept hochladen / anzeigen**: nur nach Migration `supabase/migrations/20261009163000_private_project_docs.sql`. HTML-Datei aus lokalem `_bubble`-Archiv wählen; **nicht** in das öffentliche Repo legen.
- Die bestehenden `docs/*.md` bleiben bewusst öffentlich lesbar; nur das vollständige Originalkonzept mit Screenshots ist geschützt in Supabase Storage.
- Kein Supabase-Livetest/Storage-Negativtest in dieser Entwicklungsumgebung erfolgt; Tests siehe `docs/testplan.md`.
',10) ON CONFLICT (slug) DO NOTHING;
INSERT INTO sk_internal.project_doc_chapters(slug,title,body,position) VALUES('concept','Systemkonzept / Architektur','# System- und Migrationskonzept

**Quellenstatus:** Dieses Dokument ist eine aktualisierte Kurzfassung, **nicht** das vollständige Migrationskonzept. Ursprungsdokument: `staffkeeping_migrationskonzept.html`, Version 2.2 vom 14.09.2026 mit allen Kapiteln, UI-Masken, Tabellen, Workflows und eingebetteten Screenshots; liegt lokal im gitignorierten `_bubble`-Archiv.

## Ziel
B2B-Applikation für Personalaustausch zwischen Betrieben der Hotellerie, Gastronomie und Campingbranche in der DACH-Region. Die externe StaffKeeping-Landingpage existiert bereits; **hier entsteht nur die Anwendung**. Bubble liefert Anforderungen, nicht das Layout.

## Zielarchitektur (geplant, noch nicht implementiert)
- GitHub Pages: öffentliche Hülle mit Login / Registrierung; Quellcode öffentlich.
- Supabase: Auth, PostgreSQL, RLS, Storage, Edge Functions, serverseitige Zugriffsentscheidungen.
- Unternehmen registrieren sich selbst; Freigabe durch Administrator vor Marktplatzzugriff.
- Chat nur für Gesprächsteilnehmer und Administratoren lesbar; Administratoren dürfen alle Chats einsehen, aber keine fremden Inhalte stillschweigend bearbeiten.
- Normale Datenbankverschlüsselung bei Supabase; keine zusätzliche Feldverschlüsselung geplant.
- Google Maps, Benachrichtigungs-E-Mail später; Stripe/Abos fachlich noch zu klären.
- Datenmigration nur selektierte Stammdaten, keine Bubble-Testdaten oder Testnutzer.

## Design
CI aus Kapitel 13 des Originals. Navy `#1B263B`, Silver `#E0E1DD`, White `#FFFFFF`, Steel `#415A77`; vorläufiges Hero-Blau `#159FD4` nach Nutzerangabe. Original-Logo und Schrift noch zu liefern. Styles nur zentral in CSS-Dateien.

## Noch nicht geklärt
Relevante Widersprüche und Entscheidungen des Originals (Kapitel 21) müssen vor DB-Implementierung anhand des Bubble-Editors geprüft werden. Keine Vermutungen als Ist-Zustand ausgeben.

## Auth-Fundament 0.19 (vorbereitet, nicht deployt)
- `public.sk_businesses` und `public.sk_business_members`: Unternehmen getrennt von Auth-Benutzern; zunächst ein Unternehmen je Benutzer.
- `sk_internal.staff_admins`, `sk_internal.business_status_audit`: Backend-only, nicht über Data API exponieren.
- RLS auf browserseitigen Tabellen und explizite SELECT-Policies; Schreibvorgänge ausschliesslich über autorisierte `SECURITY DEFINER`-RPCs.
- E-Mail-Bestätigung und Adminfreigabe erforderlich.
- Keine Migration existierender Bubble-Unternehmen oder -Benutzer; alle Testkonten werden frisch registriert.
- Offen: fachliche Abnahme der Mehrbenutzer-/Mehrbetriebszuordnung und Rollen.

## Eigentümerschaft und Betriebsübergabe (Beschluss 09.10.2026)
Bestehendes Repository, Supabase-Projekt und Postmark-Verwaltung nach Entwicklung an Annette übertragen; Entwickler behält zusätzliche Adminrechte. Google-Maps-Key gehört bereits Annette. Die App-Domain und E-Mail-Absender werden auf ihre Domain/Konten umgestellt. Getrennte Neuinstallation ist **nicht** der bevorzugte Weg. Technische Provider-Voraussetzungen vor Übergabe verifizieren. Vollständige Checkliste: `docs/uebergabe-annette.md`.


## Auth-Implementierung 0.20
Supabase Auth E-Mail/Passwort; nach E-Mail-Bestätigung wird sk_register_business aufgerufen. Status Ausstehend; nur Freigeschaltet oder sk_is_admin erlaubt App-Zugang. Adminstatus aus sk_internal.staff_admins, kein clientseitig gesetztes Flag als Zugriffsquelle. Firmenfreigabe per sk_admin_set_business_status. Client nutzt ausschliesslich Publishable Key; serverseitige RLS/RPC-Prüfung bleibt maßgeblich. Konfiguration in scripts/config.js (öffentlich).

## Ergänzung 0.23 – Registrierung und getrennte Zustände
Auth-Benutzer, Unternehmensdatensatz und dessen Freigabe sind verschiedene Zustände. Ein bestätigter Benutzer ohne Firmenmitgliedschaft muss vorhandene Test-Firmendaten nacherfassen können (über `sk_register_business`, kein zweites `signUp`). Nur für tatsächlich angelegte Unternehmen ist der Status `Ausstehend` im Sinne der Admin-Freigabe relevant. Bestätigte Test-Auth-Konten werden nicht gelöscht. Die Anwendung wird im Live-Test noch validiert.

## 0.24 – Betriebsprüfung und Administration
Registrierungsfelder liegen in `public.sk_businesses`; Admin kann diese über die vorhandene SELECT-Policy lesen. Für Details inklusive Statushistorie (`sk_internal.business_status_audit`) und Notizen (`sk_internal.business_admin_notes`) stellt die DB zwei `SECURITY DEFINER`-RPCs mit `sk_is_admin()`-Prüfung bereit. Beide Funktionen verwenden `search_path=''''`, `anon` hat kein EXECUTE, interne Tabellen bleiben nicht exponiert. Keine direkten Schreibrechte für normale Browserrollen. Das öffentlich ausgelieferte Frontend ist nie die Sicherheitsgrenze.


## Erweiterung 0.25: Reales Unternehmensprofil und Medien
`public.sk_businesses` erhält `description` (max. 1000) und `email_notifications_enabled` (Standard true). Profile lesen über `sk_get_my_business_profile`, Änderungen ausschliesslich über `sk_update_my_business_profile` (freigegebener owner, begrenzte Felder). Bestehende Fremddatenkontrollen über RLS; keine allgemeinen UPDATE-Rechte auf `sk_businesses`.
Zwei private Storage-Buckets: `sk-business-logos` (2 MB), `sk-business-photos` (5 MB), nur JPG/PNG/WebP; UUID-Verzeichnis und jeweils `logo.*` bzw. 1–5.*. Admin/zugehörige Mitglieder können lesen, upload/delete nur freigegebener owner. Temporäre signierte URLs, keine öffentlichen Dateipfade. Admin-Details über bisherige admin-only-RPC plus private Mediensuche.
`email_notifications_enabled` ist lediglich eine Präferenz, kein automatischer Versand.


## Dokumentenschutz und Auto-Save (Stand 0.26)
- Öffentliche GitHub-Pages-App, private Originaldokumente ausschliesslich in `sk-project-docs`, Supabase Storage (`public=false`), serverseitige RLS-Policies prüfen `public.sk_is_admin()`.
- Originalmigration 2.2 bleibt historische Quelle, aktuelle Beschlüsse stehen getrennt in den versionierten `.md`-Dokumenten und in der Projektübersicht. Kein stillschweigendes Umschreiben des Originals.
- HTML-Original im Browser nur im isolierten, skriptlosen, fremd-originären iframe mit CSP angezeigt. Kein öffentliches Asset.
- Auto-Save im Unternehmensprofil (debounce, Flush bei Navigation, Fehler blockiert interne Navigation, Browser-Unload-Warnung). Das Backend bietet derzeit einen **gesamten Profilupdate-RPC**: Feldgranulare Konfliktsicherheit bei zwei parallelen Sessions ist noch nicht gewährleistet und bleibt ein offener Punkt.
',20) ON CONFLICT (slug) DO NOTHING;
INSERT INTO sk_internal.project_doc_chapters(slug,title,body,position) VALUES('status','Entwicklungsstand','# Entwicklungsstand

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

## Release 0.24 – Betriebsprüfung
Implementiert (Live-Test ausstehend): Admin-Detailansicht mit Firmen-/Kontaktfeldern, Benutzerzuordnung, Nutzungsbedingungen, Notizen, Freigabehistorie. Abfrage und Notiz-Anlage per abgesicherten RPCs; SQL-Migration muss zuerst ausgeführt werden. Tabelle zeigt alle Betriebe, der Detailbereich ermöglicht Freischalten/Sperren nach Prüfung.
Live festgestellt: Testunternehmen Hotel chris.login wurde am 09.10.2026 erfolgreich mit Status Ausstehend erstellt; ein verwaister Alt-Testbetrieb wurde identifiziert. Ob dieser entfernt wurde, ist nicht bestätigt.


## Version 0.25 – Unternehmen, Profil und Medien (Implementiert; Live-Abnahme offen)
- Auth-Login, Logout und Passwort-Recovery wurden vom Benutzer live erfolgreich geprüft; Bestätigungsmail, Firma `Hotel chris.login` und Freigabe ebenfalls. Unternehmensstatus `Freigeschaltet` und Marktplatzlogin mit Testnutzer bestätigt.
- In Version 0.24 wurden Betriebsprüfung/Notizen implementiert; Admin-Freigabe funktionierte live.
- Die Profilmaske war noch eine Demo und zeigte `Demo-Unternehmen`. 0.25 bindet Laden/Speichern an reale Supabase-Daten an, ergänzt Beschreibung (max. 1000 Zeichen), Kontakt-E-Mail, PLZ/Ort und Benachrichtigungsvorliebe.
- Firmenlogo und fünf Bilder erhalten private Storage-Buckets mit RLS, limitierter Dateigrösse und signierten temporären URLs. Admin kann Medien und Beschreibung einsehen.
- Noch erforderlich: SQL-Migration 20261009160500 ausführen, dann App veröffentlichen und mit Admin-/Testkonto testen. Bis dahin NICHT live einsatzbereit.
- E-Mail-Benachrichtigungsschalter: Preference gespeichert, **kein Versand** für neue Nachrichten/Inserate, bis Fachmodule real angebunden sind.
- Weitere Module Inserate, Chat, Bewertungen und Karten bleiben Demo. Spam-Einstufung iCloud separat offen.


## 0.26 – Auto-Save + geschütztes Originalkonzept (implementiert, Live-Abnahme offen)
- Im Unternehmensprofil kein Speichern-Button mehr: nach Eingabepause, Auswahländerung, Blur und vor interner Navigation speichern; bei Fehler Navigation stoppen und Retry anbieten. Vor Reload/Schliessen Browser-Warnung bei ungesicherten Änderungen; keine Garantie, dass ein Browser beim Schliessen noch einen Request abschliesst.
- Privater Bucket `sk-project-docs` mit Admin-Storage-Policies; Originalkonzept wird nach einmaligem **manuellem Admin-Upload** über geschützten Download angezeigt. Keine Originaldatei in öffentliches GitHub Pages.
- Das vollständige v2.2-Migrationskonzept ist dadurch **nicht automatisch bereits hochgeladen**. SQL-Ausführung, Upload und Negativtests noch ausstehend.
- Profil 0.25 / Medienmigration und Live-Tests ebenfalls vor Abschluss kontrollieren. Inserate/Chats/Bewertungen weiterhin Demo.


## Release 0.27
Implementiert: Zentrale, geschützte Admin-Kapitelverwaltung über Supabase; Live-Test noch offen. Profil Auto-Save 0.26 und private Dokumente weiterhin live zu verifizieren.
',30) ON CONFLICT (slug) DO NOTHING;
INSERT INTO sk_internal.project_doc_chapters(slug,title,body,position) VALUES('issues','Aufgaben & offene Fragen','# Aufgaben und Klärungsbedarf

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


## Priorität 0 – Version 0.27 testen
- SQL-Migration installieren und Admin-Kapitel laden.
- Text ändern, speichern, Seite neu laden, identischen Stand prüfen.
- Andere Unternehmenssession: RPC für Lesen/Schreiben muss fehlschlagen.
- Privates Original (v2.2) laden und Kapitel/Bilder prüfen; Upload nur einmal.
- 0.25/0.26 Profil, Medien, Auto-Save und Navigationsschutz im Browser testen.
',40) ON CONFLICT (slug) DO NOTHING;
INSERT INTO sk_internal.project_doc_chapters(slug,title,body,position) VALUES('rules','Entwicklungsregeln','# Verbindliche Entwicklungsregeln

1. **Vor Änderungen:** Migrationskonzept, diese Regeln, Systemübersicht, Entwicklungsstand und betroffene Fachvorgaben lesen. Zuerst prüfen/analysieren; Umsetzung nach explizitem **LOS**.
2. **Projektumfang:** nur StaffKeeping-Applikation, keine neue Marketingseite. Die externe Homepage bleibt separat.
3. **Styling:** alle Regeln in `styles/tokens.css` und `styles/main.css`. Keine Inline-Styles oder `<style>`-Blöcke; JS in `scripts/app.js`.
4. **ZIP-Namensschema:** `sk-update-<Version>-<YYYYMMDD-HHMMSS>.zip`; echte lokale Versions-/Erstellzeit verwenden.
5. **ZIP-Inhalt:** ausschließlich neue/geänderte Dateien; alle ZIP-Einträge beginnen mit `staffkeeping/`. Keine Root-Dateien im Archiv.
6. **Private Bubble-Unterlagen:** `staffkeeping/_bubble/` bleibt lokal, per `.gitignore` ausgeschlossen, nicht synchronisieren. Alte Commit-Kopien werden dadurch nicht aus der Git-Historie gelöscht.
7. **Sicherheit:** GitHub Pages ist öffentlich. Keine Geheimnisse, Admin-Keys, echten Login-Daten oder internen Dokumente in öffentlich ausgelieferten Assets. Supabase RLS für jede browserseitig zugreifbare Tabelle, Adminrechte serverseitig prüfen.
8. **Freigaben:** Selbstregistrierung erlaubt, aber geschützte Inhalte nur nach Adminfreigabe. Administratoren dürfen Chats lesend einsehen.
9. **Datenübernahme:** nur ausgewählte Stammdaten; keine Bubble-Testdaten.
10. **Jedes Release:** Architektur/Stand, Aufgaben, Entscheidungen, Tests, Historie und Chat-Übergabe **mit der Implementierung** aktualisieren; keinen fertigen Status ohne Test behaupten.
11. **Deployment:** bestehende Pfade beibehalten; CSS/JS-Cacheversionen und tatsächliche ZIP-Verzeichnisstruktur prüfen.
12. **Datenschutz/Original:** vollständiges Migrationskonzept darf erst nach echtem Adminschutz online ausgeliefert werden. Eine Demo-Anmeldung ist keine Zugriffskontrolle.

13. **Supabase-Migrationen:** Jede Schemaänderung als dauerhaft versionierte SQL-Migration. In `public` nur Tabellen mit begründetem Browserbedarf; interne Admin-/Audit-/Backendtabellen in nicht exponiertem Schema. Exposition, Grants und RLS explizit prüfen.
14. **SQL-Bedienung:** Anzahl/Art separater Resultsets vor SQL-Ausführung erklären; mehrere SELECTs können im SQL-Editor nicht gleichzeitig sichtbar sein. Niemals Migrationserfolg ohne Test behaupten.
15. **Testdaten:** Keine bestehenden Unternehmen/Benutzer aus Bubble übernehmen; neue Testkonten in StaffKeeping/Supabase registrieren.

16. **Eigentümerschaft/Übergabe:** Bestehende GitHub-, Supabase- und Postmark-Ressourcen werden für die Übergabe an Annette vorbereitet; sie übernimmt Eigentum/Verwaltung/Billing, bisheriger Entwickler behält zusätzliche Adminrechte. Bestehenden Google Maps Key von Annette verwenden; Domain, Auth-Redirects und Mail-Domain umstellen. Transfermöglichkeiten je Provider vorab prüfen. Checkliste `docs/uebergabe-annette.md` bei relevanten Releases nachführen.

17. **Browser-Konfiguration:** Ausschliesslich Project URL + Publishable Key in scripts/config.js; keine Secret-/Service-Role-Keys. Kein echtes Login durch lokalen Demo-Flag ersetzen.
18. **Auth-Tests:** Änderungen erst als produktiv deklarieren, wenn bestätigte Testkonten, Adminfreigabe, RLS-Negativtests und Passwort-Reset mit SMTP validiert sind.

## Authentifizierungsregel ab 0.21
- Passwort-Recovery darf nicht durch Session-Initialisierung oder Rollenprüfung überschrieben werden.
- Keine Recovery-/SMTP-Schlüssel, Zugangstokens oder Passwörter in Frontend-Konfiguration, Projektdateien oder Dokumentation.
- Auth-Release erst nach echten Tests als funktionsfähig deklarieren.

19. **Auth-Redirects:** Für Signup und Passwort-Reset die kanonische StaffKeeping-App-URL verwenden, nicht die zufällige aktuelle Seite (`location.pathname`). Nach Domain-/Pfadwechsel die URL-Ermittlung, Supabase Site URL und Redirect-Allowlist gemeinsam testen. Niemals vollständige Bestätigungs- oder Recovery-Links mit Tokens protokollieren oder veröffentlichen.

20. **Registrierungszustände strikt trennen:** nicht bestätigtes Auth-Konto, bestätigtes Konto ohne Firma, Firma `Ausstehend`, genehmigte Firma und gesperrte Firma sind fachlich verschieden. Nach bestätigtem Login ohne Firmenzuordnung darf kein erneutes `signUp` verlangt werden. Die Firmenanlage erfolgt über `sk_register_business`, nicht über Browserflags.

21. **Admin-Betriebsprüfung:** Kein Freischalten ohne einsehbare Firmen-/Kontaktdetails. Interne Notizen nie in öffentlich ausgelieferten Dateien, LocalStorage oder direkt exponierten Tabellen ablegen; Zugriff ausschliesslich serverseitig als Admin verifizieren. Jede Schemaerweiterung als separate persistente Migration.


22. **Unternehmensprofil:** Der User bearbeitet nur eigene Daten als freigeschalteter `owner`; Land, USt-ID und Status bleiben unveränderbar durch normale Nutzer. `contact_email` ist nicht die Auth-Login-E-Mail.
23. **Medien:** Supabase Storage private Buckets und RLS nach Unternehmens-ID; keine public URLs; nur kurzlebige Signed URLs, Dateityp/Grösse und erlaubte Slots serverseitig durch Bucket und Policies einschränken. Keine Fotos/Anhänge in GitHub.
24. **Mail-Einstellungen:** Schalter für Fachbenachrichtigungen darf nicht als aktiver Versand ausgegeben werden, solange kein sicherer serverseitiger Benachrichtigungsjob existiert. Auth-Mails sind davon unabhängig.


25. **Auto-Save:** Normale Eingaben ohne Speichern-Button, entprellt speichern; bei Navigation/Tabwechsel sowie Back/Forward vor Ansichtswechsel flushen; bei Fehler nicht navigieren, Wiederholen zeigen. Bevorstehendes Browser-Schliessen/Reload mit ungespeicherten Daten muss Warnung auslösen; Speichern beim Schliessen nicht garantieren. Kritische Freigaben/Löschungen weiterhin explizit bestätigen.
26. **Vollständiges Originalkonzept:** nie unter GitHub Pages oder im ZIP ausserhalb des per `.gitignore` ausgeschlossenen `_bubble`-Archivs ausliefern. Nur privater Bucket `sk-project-docs` und serverseitige Admin-Security-Policies; HTML im Admin-Browser isoliert und ohne Skriptberechtigung rendern. Separate historische v2.2-Quelle und aktuelle versionierte Projektunterlagen halten.
27. **Upload/Migration:** SQL erst kontrolliert installieren, dann bewusst Admin-Upload durchführen; keinen bereits durchgeführten Live-Test behaupten, bevor SQL, Storage-Zugriff und Browseranzeige verifiziert sind.


25. **Führende Dokumentation ab 0.27:** Nach erfolgreicher Migration ist Admin → Projektdoku (Supabase `sk_internal.project_doc_chapters`) die einzige aktuelle Arbeitsdokumentation. Bestehende Repo-Dateien sind bis zur Bereinigung nur Migrationseingang/Archiv und dürfen nicht unabhängig fortgeschrieben werden. SQL-Migrationen und Quellcode bleiben versionierte technische Artefakte. Bei Releases betroffene Admin-Kapitel aktualisieren, nicht neue parallele Projektdateien anlegen.
',50) ON CONFLICT (slug) DO NOTHING;
INSERT INTO sk_internal.project_doc_chapters(slug,title,body,position) VALUES('tests','Tests & Abnahme','# Testplan und Abnahme

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

## Test 0.24 – Admin-Betriebsprüfung (noch ausstehend)
1. SQL-Datei als eine Transaktion ausführen; danach Berechtigungen/RPCs prüfen.
2. Admin → Betriebe → Details / Prüfen: Firmenname, UID, Branche, Adresse, Kontakt, E-Mail, Telefon, Registrierungs-/AGB-Zeitpunkt mit Supabase vergleichen.
3. E-Mail-Link öffnet Mail-Programm, Telefon-Link entsprechend Client.
4. Admin-Notiz speichern; neu laden, Notiz mit Zeit und Adminautor sichtbar.
5. Erst danach Freischalten; Statuswechsel in Admin-Tabelle und Audit-Historie prüfen.
6. Als normaler Benutzer RPC sk_admin_get_business_details und sk_admin_add_business_note direkt versuchen: muss scheitern.
7. Direkter Zugriff auf sk_internal.business_admin_notes / business_status_audit für authenticated/anon: verweigert.
8. Login, Registrierung, Reset und Navigation auf Regression prüfen.


## Abnahme 0.25 – Unternehmensprofil und Freigabe
- [x] Live bestätigt vom User: Administrator-Login, Passwort-Recovery, neu registriertes Unternehmen mit E-Mail-Bestätigung, Status Ausstehend; erster Testbetrieb freigeschaltet und Testnutzer kann sich anmelden.
- [ ] SQL-Migration 0.25 erfolgreich ausgeführt (keine Live-Bestätigung).
- [ ] Testnutzer öffnet Profil: Firma, Branche, Land, UID, PLZ/Ort, Ansprechpartner und Kontakt-E-Mail/Telefon entsprechen Supabase.
- [ ] Beschreibung ändern, speichern, neu laden und in Admin-Betriebsdetails kontrollieren.
- [ ] Präferenz E-Mail-Benachrichtigungen speichern und nach Neuanmeldung kontrollieren; kein Versand für Fachmeldungen behaupten.
- [ ] Land und USt-ID nicht editierbar, direkter Änderungsversuch über Supabase scheitert.
- [ ] Logo JPG/PNG/WebP bis 2 MB sowie Betriebsbilder in 5 Slots bis je 5 MB hochladen, ersetzen, entfernen, neu laden. Ungültiger Dateityp/Grösse wird abgewiesen.
- [ ] Admin sieht Beschreibung und Medien, nicht angemeldeter/fremder Nutzer erhält bei Storage/RPC keinen Zugriff.
- [ ] Nach Freigabe Testnutzer Marktplatz, nach Sperrung kein Marktplatz.
- [ ] Auf Desktop/Mobile Layout prüfen; Registrierung, Reset und Admin-Notizen auf Regression testen.


## 0.26 – Tests zur Abnahme (noch nicht live durchgeführt)
1. SQL-Installation erfolgreich, private Bucket-Einstellung und Policies prüfen.
2. Admin lädt HTML-Original aus lokalem Archiv hoch; im isolierten Dokument-Viewer mit Screenshots vollständig lesbar.
3. Als `anon` und gewöhnlicher freigeschalteter Nutzer: Download, List, Upload, URL-Zugriff auf `sk-project-docs` verweigert.
4. Profil-Beschreibung ändern, 1 s warten: `Gespeichert`; Reload zeigt Wert.
5. Profilfeld ändern und sofort Marktplatz anklicken: vorher erfolgreich speichern.
6. Profilfeld ändern und Browser Zurück/Vorwärts: vorher speichern; bei Fehler Navigationsverlust verhindern.
7. Netzfehler simulieren: `Nicht gespeichert`, Eingabe bleibt sichtbar, Retry kann wiederholen.
8. Ungültiges Formular verhindert Navigation; Browser-Schliessen/Reload mit ungespeicherten Daten löst Warnung aus.
9. Dropdown und Benachrichtigungs-Schalter speichern ohne Klick auf Save; Medienänderungen gesondert prüfen.
10. Wiederholten Admin-Upload nur für Original-Datei prüfen; keine anderen Dateinamen/Buckets oder Nutzerrechte zulassen.
11. Bestehenden Login/Recovery/Freigabe/Profil/Medien und alle übrigen Navigationen auf Regression prüfen.
',60) ON CONFLICT (slug) DO NOTHING;
INSERT INTO sk_internal.project_doc_chapters(slug,title,body,position) VALUES('history','Versionshistorie','# Versionshistorie (Designphase)

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


## 0.27 (09.10.2026)
Zentrale, in Supabase gesicherte Admin-Projektdokumentation mit Kapitelsuche, Bearbeitung und Sicherung. Initialer Bestand aus vorhandenen Projektdateien übernommen; keine zweite statische Admin-Zusammenfassung. Das private historische Original bleibt unangetastet. Implementiert, Live-Test offen.
',70) ON CONFLICT (slug) DO NOTHING;
INSERT INTO sk_internal.project_doc_chapters(slug,title,body,position) VALUES('decisions','Entscheidungen','# Beschlossene Architektur- und Produktentscheidungen

- StaffKeeping ist ausschließlich die App; bestehende Landingpage separat.
- GitHub Pages ist öffentlich erreichbar; geschützte Inhalte erfordern echte Supabase-Berechtigungen.
- Unternehmen registrieren sich selbst und warten auf Adminfreigabe.
- Admin darf Chatverläufe vollständig lesen und gegebenenfalls außerhalb der App eingreifen.
- Keine Ende-zu-Ende- oder zusätzliche Feldverschlüsselung geplant; Standardverschlüsselung, Supabase Auth, serverseitige Berechtigungen und RLS.
- Nur benötigte Stammdaten aus Bubble migrieren; übrige Einträge sind Testdaten.
- Corporate Design aus Migrationskonzept, Hellblau vorläufig `#159FD4`; Original-Logo/Schrift noch offen.
- Styles ausschließlich zentrale CSS-Dateien.
- Projektübergabe und Dokumentation werden mit jedem Release gepflegt.
- ZIP-Regeln gelten verbindlich; `_bubble` bleibt Git-ignoriert.

- **Präzisierung 0.19:** Aus Bubble werden **keinerlei bestehende Unternehmen oder Benutzer** übernommen; neue Daten werden ausschliesslich als frische Testdaten erzeugt. Optionale allgemeine Stammdaten bleiben gesondert zu beurteilen.
- Erstes Schema trennt Unternehmen von `auth.users`; aktive Firma muss von Administrator freigegeben sein.
- Interne Administrator- und Auditdaten im nicht exponierten Schema `sk_internal`. Keine frei wählbaren Admin-Rollen im Frontend.

- **Übergabe an Annette (09.10.2026):** Bestehendes GitHub-Repository, Supabase-Projekt und Postmark-Verwaltung in Annettes Verantwortung übertragen; bisheriger Entwickler bleibt zusätzlicher Admin. Google-Maps-Key ist bereits über Annette eingerichtet. App-Domain und Mail-Absender später auf Annettes Vorgaben umstellen. Transferfähigkeit und Providerrollen erst noch überprüfen; keine Durchführung behaupten.


## 0.20
Kein Magic-Link-Zwang beim Login, sondern E-Mail/Passwort. Registrierungen mit Bestätigung und anschliessendem RPC; Status Ausstehend. Mailversand produktiv mit eigenem SMTP/Postmark; bestehender Administrator über auth.users-ID kontrolliert vergeben.

## Postmark und Recovery (09.10.2026)
- Entwicklungs-Senderdomain `mueller-home.me` (Postmark DKIM und Return-Path verifiziert); bei Übergabe Umstellung auf Annettes Domain. Kein privater SMTP-Schlüssel in Git oder Dokumentation.
- Normales Login erfolgt weiterhin per E-Mail/Passwort. Recovery-Link öffnet ausschliesslich die Passwortneuvergabe; erst nach erfolgreicher Änderung erfolgt neue Anmeldung.

## 09.10.2026 – Auth-Callback-URL
Bei GitHub Pages liegt die App unter `/staffkeeping/`, die Marketing-Homepage auf `/`. Signup- und Passwort-Reset-E-Mails müssen immer die App als Rücksprungadresse verwenden. Die App-Basis wird aus der geladenen Datei `scripts/auth.js` ermittelt; abweichende Domains/Pfade werden abgewiesen statt stillschweigend zur Homepage umzuleiten. Beim geplanten Wechsel zur Domain von Annette muss dieser harte Pfadtest überprüft bzw. bewusst angepasst werden. Supabase Site URL und Redirect-Allowlist zusätzlich auf die neue Domain umstellen.

## Ergänzung 0.23 – Registrierung unterbrechen und fortsetzen
Ein bestätigtes Auth-Konto ohne Firmenmitgliedschaft ist **nicht** gleichbedeutend mit einem Unternehmen im Status `Ausstehend`. Die Anwendung muss das Formular zur Unternehmensregistrierung anbieten, ohne eine neue Auth-Registrierung/E-Mail anzustossen. Die tatsächliche Firmenanlage erfolgt ausschließlich über `public.sk_register_business`; erst dann gilt die Adminfreigabe als ausstehend.

## 0.24 – Admin-Freigabe nach Detailprüfung
Die Unternehmensfreigabe soll aus der Detailansicht erfolgen. Kontaktaufnahme per E-Mail/Telefon ausserhalb der App. Admin-Notizen sind ausschliesslich für StaffKeeping-Administratoren bestimmt und liegen in `sk_internal`; kein öffentlicher Tabellenzugriff. Statusänderungen bleiben in der bestehenden Audit-Tabelle dokumentiert.


## 0.25 – Profil und Medien
- Unternehmensprofil (Firma, Branche, PLZ/Ort, Ansprechpartner, Kontakt-E-Mail/Telefon, Beschreibung) ist nach Adminfreigabe durch den Firmeninhaber bearbeitbar. Land und UID/USt-ID sowie Freigabestatus bleiben admin-/backendkontrolliert.
- Login-E-Mail gehört zu Supabase Auth; Kontakt-E-Mail darf abweichen und ist nicht gleichzeitig Login-Änderung.
- Logo (2 MB) und fünf Betriebsbilder (je 5 MB), JPG/PNG/WebP, in zwei PRIVATEN Buckets mit RLS und signierten Lese-URLs; kein öffentliches Bucket.
- System-Admin darf Beschreibung und private Medien im Betriebsprüfungsfenster einsehen.
- E-Mail-Benachrichtigungen als gespeicherte Vorliebe, **ohne aktiven Versand**, bis Chat-/Inseratsmodul technisch angebunden ist.


## Beschlüsse 0.26
- Unternehmensprofil: Auto-Save statt Speichern-Button, auch vor interner Navigation/Browser-Historienwechsel; sichtbar gespeicherter/ungespeicherter Status. Browser-Reload kann nur warnen.
- Vollständiges historisches Migrationskonzept v2.2 mit Screenshots zentral im Admin-Bereich, aber nicht öffentlich zugänglich; privater Supabase Storage und explizite Admin-only Policies.
- Aktuelle Projektunterlagen getrennt vom unveränderten Original und bei jedem Release pflegen.
',80) ON CONFLICT (slug) DO NOTHING;
INSERT INTO sk_internal.project_doc_chapters(slug,title,body,position) VALUES('handoff','Chat-Übergabe','# Übergabe an neuen Chat – StaffKeeping

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

## Aktueller Übergabestand 0.24
Supabase Auth + Postmark laufen; Passwort-Reset und neuer Login live bestätigt. Testfirma `Hotel chris.login` (`chris.login@icloud.com`) ist als `Ausstehend` gespeichert. Der Admin sah zusätzlich eine verwaiste ältere Testfirma, gezielte Löschung empfohlen, Abschluss noch nicht bestätigt. 0.24 ergänzt Admin-Detailprüfung, Kontaktlinks, Notizen und Audit-Historie; **vor Frontend-Rollout muss** die SQL-Migration `20261009153000_admin_business_review.sql` installiert und geprüft werden. Danach Testbetrieb nach Detailprüfung freischalten, Benutzerzugriff prüfen. Offene Punkte: Mail im Spam, vollständige RLS-Negativtests, genaue Registrierungsstatusanzeige. ZIP nur geänderte Dateien unter `staffkeeping/`, CSS nur zentral.


## Fortschreibung für nächsten Chat · 09.10.2026 · v0.25
Version 0.25 ist als Update ausgearbeitet; SQL `staffkeeping/supabase/migrations/20261009160500_business_profile_media.sql` MUSS zuerst ausgeführt werden, DANN Frontend aktualisieren. Keine Live-Ausführung durch ChatGPT.
Live bestätigt: Supabase-Login, Passwort-Recovery, Postmark Auth-E-Mails, Testfirma `Hotel chris.login` angelegt und genehmigt, Testnutzer kann sich anmelden. Vorheriger `Hotel Chris.login` war verwaister Testdatensatz (Löschung nicht durch SQL-Ergebnis bestätigt).
0.25: Profil lädt/speichert echte Angaben; Admin sieht Beschreibung/Bilder; private Storage-Buckets; `email_notifications_enabled` als Preference, Fachmail-Versand noch nicht implementiert. Vollständiger 0.25-End-to-End- und RLS-Test offen. Nächste Arbeit: Migration + Profil-/Medien-Tests, dann Inserate/Chats.


## Projektstand für neuen Chat – 0.26
StaffKeeping ist ausschliesslich die Web-Applikation; öffentliche externe Marketing-Seite ist separat. Frontend: GitHub Pages unter `/staffkeeping/`; Supabase Auth/Postgres/RLS/Storage; Postmark über `mueller-home.me` bis zur Übertragung an Annette. Admin-User eingerichtet; Registrierung/Freigabe/Password-Recovery live getestet; Firmenprofil samt Bildern 0.25 implementiert. Inserate, Chats, Bewertungen noch Demo.
**0.26:** Firmenprofil mit Auto-Save und blockiertem internen Seitenwechsel bei Fehler (erst Live-Test offen); vollständiges Migrationskonzept v2.2 soll privat im Admin-Bereich abrufbar sein: zuerst SQL `20261009163000_private_project_docs.sql` installieren, dann per Admin die lokale HTML-Originaldatei in `sk-project-docs` hochladen, Sicherheits-/Lesetests durchführen. Die Originaldatei ist NICHT im öffentlichen ZIP!
Verbindliche ZIP-Regel: `sk-update-<Version>-<YYYYMMDD-HHMMSS>.zip`, nur neue/geänderte Dateien, alles unter `staffkeeping/`. Projekt- und Testdoku mit jedem Release aktualisieren. CSS nur zentral. `_bubble` bleibt lokal via `.gitignore`. Admin liest Chats, reguläre Anwender nur eigene; neue Firmen brauchen Freigabe.
Offen: Profil-/Storage-Livetests, Spam-Zustellbarkeit, Multi-Tab-Profilkonflikte, nächste Fachmodule. Übergabe: bestehendes GitHub/Supabase/Postmark an Annette, ursprünglicher Entwickler weiterhin Admin; bestehender Google-Maps-Key gehört Annette; Domain später umstellen.
',90) ON CONFLICT (slug) DO NOTHING;
INSERT INTO sk_internal.project_doc_chapters(slug,title,body,position) VALUES('ownership','Übergabe Annette','Noch nicht dokumentiert – siehe ursprüngliches Migrationskonzept und offene Aufgaben.',100) ON CONFLICT (slug) DO NOTHING;
INSERT INTO sk_internal.project_doc_chapters(slug,title,body,position) VALUES('auth','Auth & Datenmodell','# Authentifizierung und Datenmodell · Entwurf 0.19

**Status:** SQL-Datei vorbereitet, nicht ausgeführt. UI weiterhin Demo; reale Authentifizierung erfolgt erst im nächsten Release nach Tests.

## Bezug zum ursprünglichen Migrationskonzept

Kapitel 3–5 beschreiben Bubble Data Types, Tabellen, RLS und Supabase Auth. Die dortige Tabelle `businesses` nutzt die User-UUID zugleich als Business-ID. Wir **weichen bewusst davon ab**: Betriebe und Login-Benutzer werden getrennt; spätere mehrere Benutzer pro Betrieb sind damit möglich. Die endgültige Ausgestaltung von Mitarbeiterkonten (Einladung, Rechte, Entfernung) ist noch offen. Die ursprünglichen Statuswerte `Ausstehend`, `Freigeschaltet`, `Gesperrt` bleiben vorerst erhalten. **Ablehnung** als separater Status ist im Original nicht verbindlich spezifiziert und wird nicht erfunden.

## Datenmodell

- `auth.users`: E-Mail/Passwort und Identität, von Supabase verwaltet.
- `public.sk_businesses`: Betriebsidentität, Land, Branche, Ansprechpartner, Zustimmungszeitpunkt, Freigabestatus.
- `public.sk_business_members`: Bindung Benutzer↔Firma; ein Betrieb kann mehrere Mitglieder haben, aber die erste Migration gestattet einem Benutzer nur eine Firma.
- `sk_internal.staff_admins`: ausdrücklich vom DB-Verantwortlichen vergebene globale Systemadministratorrolle.
- `sk_internal.business_status_audit`: Statusänderungen inklusive handelndem Administrator.

## Registrierungsfolge (geplant)

1. Supabase `signUp` und E-Mail-Bestätigung.
2. Authentifizierter, bestätigter Benutzer ruft `sk_register_business(...)` auf.
3. DB erzeugt Firma mit Status `Ausstehend` und ordnet Benutzer als `owner` zu.
4. Admin sieht Firma über geschützte Abfrage und ändert Status über `sk_admin_set_business_status`.
5. Marktplatzberechtigung wird **künftig auf jedem Backend-Zugriff** über aktive Firmenmitgliedschaft, Status und Datenberechtigung geprüft. Derzeit gibt es noch keine Marktplatztabellen oder RLS dafür.

## Sicherheitsgrenzen

- Browser darf auf Business-/Mitgliedschaftstabellen lediglich lesend zugreifen und sieht nur eigene Zeilen; Systemadmin darf alle Businesses und Mitgliedschaften lesen.
- Status und Zuordnungen sind nicht direkt via Data API schreibbar, sondern nur über definierte RPCs.
- Normale Anwender können sich nicht zum Systemadministrator erklären.
- Systemadmin-Rollenwechsel erfolgt ausschliesslich über privilegierten SQL-Zugriff.
- Interne Tabellen liegen im nicht exponierten Schema `sk_internal`.
- Keine eigenen Passworttabellen und keine Tokens/Secrets im Git.

## Vorläufige offene Fachentscheidungen

- Mehrere Nutzer pro Firma: Einladungen und Rechte noch nicht spezifiziert.
- Ansprechpartner-E-Mail und Auth-E-Mail können abweichen; Verifikations-/Abuse-Regel vor Produktivbetrieb klären.
- Betreiberfreigabe der Datenbankmigration und EU-Region durch Projektverantwortliche.
- Mögliche abgelehnte Registrierung: eigener Status und Umgang mit erneuter Antragstellung.
- Schreibrechte für eigene Firmendaten: separates, streng validiertes Update-RPC im späteren Profil-Release.


## Nachtrag 0.20
Backend 0.19 ist in Supabase installiert. Frontend 0.20 verwendet signInWithPassword, signUp, resetPasswordForEmail und sk_register_business / sk_is_admin / sk_is_approved_member / sk_admin_set_business_status. Keine Key-Werte in Doku speichern. Teststatus: noch nicht live geprüft.

## Ergänzung 0.21: Passwort-Recovery
Recovery über `resetPasswordForEmail` und `PASSWORD_RECOVERY`-Ereignis. Der Recovery-Zustand muss vor normaler Auth-Sitzungsprüfung UI-priorisiert werden. Nach geprüftem `updateUser({password})` erfolgt `signOut` und erneuter E-Mail-/Passwort-Login. Postmark SMTP vom Anwender konfiguriert, tatsächlicher End-to-End-Test weiterhin offen.

## 0.23 – Bestätigter Benutzer ohne Firma
Supabase Auth und Unternehmen sind getrennte Lebenszyklen. `auth.users` mit bestätigter E-Mail, aber ohne `sk_business_members`, darf nicht als Firma im Freigabestatus behandelt werden. Die App zeigt die Firmenregistrierung mit gesperrter Login-E-Mail und ohne erneutes Passwortfeld. Nach erfolgreicher RPC `public.sk_register_business` entsteht der Datensatz in `sk_businesses` (Default `Ausstehend`) sowie die Mitgliedschaft als `owner`. Ein erneutes Auth-`signUp` wird in diesem Pfad nicht ausgeführt. Fachliche Rechte bleiben durch Datenbank-RLS und RPC zu sichern; der Anzeigestatus allein ist kein Sicherheitsbeweis. Live-Test offen.

## Schema-Erweiterung 0.24
Migration `20261009153000_admin_business_review.sql`: interne Tabelle `sk_internal.business_admin_notes` (PK, Unternehmen, Autor, Text 1–3000 Zeichen, Erstellzeit). Admin-only RPCs `sk_admin_get_business_details(uuid) -> jsonb` (Betrieb, Mitglieder, Notizen, Audit) und `sk_admin_add_business_note(uuid,text) -> void`. Prozedur und SQL-Sicherheit vor Live-Freigabe testen.


## V0.25 (nur nach SQL-Installation)
`sk_businesses.description` (Text, 0–1000 Zeichen) und `email_notifications_enabled` (Boolean). Backendfunktionen `sk_get_my_business_profile()` und `sk_update_my_business_profile(...)` mit serverseitiger Eigentümer-, Status- und Datenprüfung; Datenbankstatus und USt-ID durch normale Nutzer nicht änderbar. Medien in privaten Storage-Buckets; Auth-/RLS-Verifikation mit zweitem Konto erforderlich.
',110) ON CONFLICT (slug) DO NOTHING;
INSERT INTO sk_internal.project_doc_chapters(slug,title,body,position) VALUES('security','Geschützte Projektdokumentation','# Geschützte Projektdokumentation · StaffKeeping 0.26

## Technische Trennung
- `staffkeeping/docs/*.md` sind versionierte, **öffentlich lesbare** Projektzusammenfassungen; dort keine vertraulichen Angaben einfügen.
- Das **vollständige** historische `staffkeeping_migrationskonzept.html` (v2.2, inklusive Screenshots) bleibt als Original erhalten. Es darf **nicht** unter einem öffentlich ausgelieferten GitHub-Pages-Pfad liegen.
- Upload über den Admin-Bereich in Supabase Storage Bucket `sk-project-docs`, Objektpfad `original/staffkeeping_migrationskonzept_v2.2.html`; Bucket `public=false`.
- SQL-Migration `20261009163000_private_project_docs.sql` muss VOR dem ersten Upload ausgeführt werden. Authentifizierte Administratoren lesen/überschreiben; normale Benutzer und anonyme Nutzer nicht.
- Im Browser wird das heruntergeladene HTML in einem `iframe` ohne `allow-scripts` und ohne `allow-same-origin` sowie zusätzlich eingeschränkter CSP isoliert. Es ist **nicht** öffentlich über GitHub Pages erhältlich.
- Sicherheitskontrolle: Anonymen und freigeschalteten Nicht-Admin über Storage-API muss das Abrufen/Schreiben verweigert werden. Direkten Dateilink ohne Token prüfen. Anzeige als Admin bestätigen.
- Originalversion **nicht stillschweigend ändern**. Künftige Entscheidungen und Abweichungen bleiben separat im versionierten aktuellen Systemkonzept dokumentiert.

## Einmalige Einrichtung
1. Supabase SQL-Migration für 0.26 ausführen; Erfolg und Bucket-Privatsphäre kontrollieren.
2. Unter `Admin → Projektdoku` die Schaltfläche `Originalkonzept hochladen` betätigen und die **lokale** HTML-Datei aus `_bubble` auswählen (oder die ursprüngliche HTML-Datei). Originaldatei bleibt unverändert erhalten.
3. `Originalkonzept anzeigen` wählen; Vollständigkeit der Screenshots prüfen.
4. Als nicht freigeschalteter Benutzer / Fremdunternehmen / ohne Anmeldung den Objektabruf negativ testen.

## Einschränkungen
- Die zusätzlichen `docs/*.md` sind weiterhin **nicht** dynamisch aus Supabase geladen; die statische Projektübersicht in `scripts/app.js` ist weiterhin als öffentlich zugängliche Zusammenfassung implementiert und muss pro Release aktualisiert werden.
- Das Hochladen der Originaldatei ist ein bewusster separater Administrationsschritt, nicht Teil des GitHub-ZIP.
- Ein Backend kann vollständig privilegierte Administratorzugriffe grundsätzlich ermöglichen; Schutz ist hier gegen Fremdbenutzer und anonyme Zugriffe gerichtet.
',120) ON CONFLICT (slug) DO NOTHING;
COMMIT;
