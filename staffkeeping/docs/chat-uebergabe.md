# Übergabe an neuen Chat – StaffKeeping

**Stand 09.10.2026 / Version 0.18**

Es wird ausschließlich die App entwickelt; Marketing-Homepage existiert separat. Frontend aktuell Demo HTML/CSS/JS, GitHub Pages; Supabase noch nicht angebunden. UI-Masken: Login, Registrieren, Reset, Freigabe, Marktplatz, Profil, eigene Inserate, Details, Nachrichten, Reviews, Admin-Betriebe/Inserate/Impact/Projektdoku.

**Nächste Arbeit:** UI mit Annette abnehmen; ursprüngliches Migrationskonzept v2.2 lesen und mit neuen Entscheidungen abgleichen; Bubble-Audit durchführen; danach Datenmodell/RLS/Auth planen und erst auf LOS implementieren.

**Sicherheit:** Demo-Login ist kein Schutz. Originalkonzept nur lokal `_bubble`, nicht als GitHub-Pages-Asset. Admin-Dokumente im `docs/`-Ordner enthalten nur freigabefähige Zusammenfassungen.

**Regeln:** `docs/entwicklungsregeln.md` vollständig lesen. ZIP `sk-update-<Version>-<YYYYMMDD-HHMMSS>.zip`; nur neue/geänderte Dateien unter `staffkeeping/`; zentrales CSS; nach jedem Release Dokumentation aktualisieren.

**Offene Punkte:** `docs/aufgaben-und-fragen.md`, Systemstand `docs/entwicklungsstand.md`, Entscheidungen `docs/entscheidungen.md`, Tests `docs/testplan.md`.

**Erforderliche Referenz:** Original `staffkeeping_migrationskonzept.html` v2.2 im lokalen gitignorierten `_bubble`-Ordner (im nächsten Chat erneut bereitstellen, bis sichere Dokumentenanbindung existiert).
