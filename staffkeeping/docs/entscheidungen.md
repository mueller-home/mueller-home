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
