# StaffKeeping – App-Designprototyp 0.16

## Inhalt
Reiner Frontend-Designprototyp (kein Supabase, keine echten Login- oder Datenbankfunktionen):

- Login, Passwort zurücksetzen, Unternehmensregistrierung und Freigabestatus
- Marktplatz mit Demo-Inseraten, Suche, Merkliste und Kartenplatzhalter
- Unternehmensprofil mit Feldern gemäss Migrationskonzept (Logo/Bilder als Platzhalter)
- Meine Inserate mit Tabs, Erstellen-/Bearbeiten-Popup, Status und Demo-Vergabe/Bewertung
- Inseratdetails mit Kontakt-Disclaimer
- Nachrichten mit Konversationsliste und lokalen Demo-Nachrichten
- Meine Bewertungen
- Administration: Betriebe, Inserate, Impact-Dashboard

**Wichtig:** Alle Handlungen sind ausschliesslich lokale Design-Demos und werden beim Neuladen verworfen. Die sichtbar gemachten Administrationsseiten haben noch keinerlei Sicherheitskontrolle! Erst nach Authentifizierung, RLS und Rollenprüfung produktiv verwenden. Die Admin-Navigation wird vor der produktiven Veröffentlichung nur für berechtigte Benutzer sichtbar gemacht.

## Dateien
- `index.html`: Alle Demo-Masken (ohne eingebettete Styles / Skripte)
- `styles/tokens.css`: CI-Farbwerte und zentrale Variablen, unverändert aus Version 0.14
- `styles/main.css`: gemeinsames Layout, responsive Komponenten, Version 0.17
- `scripts/app.js`: Demo-Navigation, Muster-Daten und Interaktionen, Version 0.17

## Installation
Das Update-ZIP im Wurzelverzeichnis des Git-Repositories entpacken. Alle Pfade beginnen mit `staffkeeping/`; nur die geänderten Dateien werden ausgeliefert. GitHub Pages: URL zu `/staffkeeping/` verwenden.

## Zu testen / Designabnahme mit Annette
1. Anmeldung und Registrierung; nach Demo-Login die horizontale App-Navigation prüfen.
2. Marktplatz: filtern, Merkliste markieren, „Details ansehen“ und Kontakt-Disclaimer öffnen.
3. Unternehmensprofil: Formularlayout und Platzhalter für Unternehmensmedien beurteilen.
4. Meine Inserate: Tabs, Neues Inserat, Bearbeiten, Aktiv/Inaktiv, Vergeben und Bewertungs-Popup.
5. Nachrichten: zwischen Gesprächen wechseln und eine Testnachricht eingeben (nur lokal).
6. Meine Bewertungen: Kennzahlen und Kommentare.
7. Admin: Betriebe/Freigaben, Inseratmoderation und Impact-Karten (alle Daten erfunden).
8. Desktop und Smartphone; lange Texte, Tabellen-Scrollen und Bedienbarkeit.

## Fachlich offen (nicht als Produktivregeln interpretieren)
- Endgültiges Original-Logo und Schriftart; CI-Blau `#159FD4` ist eine Annäherung.
- Datenmodell und tatsächliche erlaubte Felder/Rollen; Statusdefinitionen und die Zuordnung der Gesprächspartner sind im Konzept teilweise widersprüchlich.
- Technische Benachrichtigungen, Karten/Radius-Suche, Uploads, Zahlungen/Impact, echte Bewertungen sowie persistente Inserate und Nachrichten.

Beim Übergang zu Supabase werden alle Demo-Daten und die simulierten Schreibvorgänge durch authentifizierte API-Zugriffe mit RLS und administrativen Rollenchecks ersetzt.

## Navigation (Korrektur 0.17)

- Nach der Demo-Anmeldung öffnet sich einmalig der Marktplatz. Danach sind alle Ansichten über die App-Navigation erreichbar.
- Die aktuelle Ansicht steht im URL-Fragment (`#messages`, `#profile` usw.) und bleibt bei einem Reload erhalten.
- Die Demo-Anmeldung gilt nur für den aktuellen Browser-Tab (`sessionStorage`); Abmelden beendet sie. Keine echte Authentifizierung und keine Datenbankverbindung.
- Für CSS und JavaScript sind Versionsparameter angehängt, um veraltete Browser-Caches beim Update auszuschliessen.
- Das Logo führt im angemeldeten Zustand zum Marktplatz statt zur Login-Maske.
