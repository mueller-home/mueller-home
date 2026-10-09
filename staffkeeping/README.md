# StaffKeeping – App-Designprototyp 0.13

Korrektur der Version 0.12: CSS und JavaScript wieder in zentralen Dateien.

## Dateien
- `index.html`: Seitenstruktur und relative Dateiverweise, ohne Inline-CSS/JS
- `styles/tokens.css`: CI-Farben, Schrift-Platzhalter und globale Designvariablen
- `styles/main.css`: sämtliche Layout- und Komponentenstile
- `scripts/app.js`: Demo-Navigation, Filter und Musteransichten

## Installation
ZIP im Wurzelverzeichnis des Repositories entpacken, bestehende Dateien ersetzen. Alle Pfade beginnen mit `staffkeeping/`. Bei GitHub Pages die URL zur **App** (`.../staffkeeping/`) öffnen; nicht die separate Repository-Startseite.

## Prüfungen
1. `staffkeeping/index.html` lokal öffnen: zweispaltige Login-Ansicht und formatierte Navigation.
2. Zwischen Login, Registrierung, Freigabestatus und Marktplatz wechseln.
3. Im Marktplatz Filter und Merkliste prüfen.
4. Nach GitHub-Push Browser hart neu laden (Mac Safari: ⌥⌘R); im Netzwerk-Tab müssen `styles/tokens.css`, `styles/main.css` und `scripts/app.js` ohne 404 geladen werden.

**Hinweis:** Nur Designprototyp, keine Authentifizierung, Datenspeicherung oder echte Freigabe. Keine neuen geheimen Schlüssel oder API-Zugänge in die Dateien schreiben.
