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
