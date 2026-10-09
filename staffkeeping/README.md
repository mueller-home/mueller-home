# StaffKeeping – App-Prototyp 0.18

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
