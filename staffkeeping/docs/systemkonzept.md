# System- und Migrationskonzept

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
Registrierungsfelder liegen in `public.sk_businesses`; Admin kann diese über die vorhandene SELECT-Policy lesen. Für Details inklusive Statushistorie (`sk_internal.business_status_audit`) und Notizen (`sk_internal.business_admin_notes`) stellt die DB zwei `SECURITY DEFINER`-RPCs mit `sk_is_admin()`-Prüfung bereit. Beide Funktionen verwenden `search_path=''`, `anon` hat kein EXECUTE, interne Tabellen bleiben nicht exponiert. Keine direkten Schreibrechte für normale Browserrollen. Das öffentlich ausgelieferte Frontend ist nie die Sicherheitsgrenze.
