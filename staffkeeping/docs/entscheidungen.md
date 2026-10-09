# Beschlossene Architektur- und Produktentscheidungen

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
