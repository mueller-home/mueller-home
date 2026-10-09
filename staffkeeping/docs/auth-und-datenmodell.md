# Authentifizierung und Datenmodell · Entwurf 0.19

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
