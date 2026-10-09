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
