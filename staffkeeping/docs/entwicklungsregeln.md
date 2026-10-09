# Verbindliche Entwicklungsregeln

1. **Vor Änderungen:** Migrationskonzept, diese Regeln, Systemübersicht, Entwicklungsstand und betroffene Fachvorgaben lesen. Zuerst prüfen/analysieren; Umsetzung nach explizitem **LOS**.
2. **Projektumfang:** nur StaffKeeping-Applikation, keine neue Marketingseite. Die externe Homepage bleibt separat.
3. **Styling:** alle Regeln in `styles/tokens.css` und `styles/main.css`. Keine Inline-Styles oder `<style>`-Blöcke; JS in `scripts/app.js`.
4. **ZIP-Namensschema:** `sk-update-<Version>-<YYYYMMDD-HHMMSS>.zip`; echte lokale Versions-/Erstellzeit verwenden.
5. **ZIP-Inhalt:** ausschließlich neue/geänderte Dateien; alle ZIP-Einträge beginnen mit `staffkeeping/`. Keine Root-Dateien im Archiv.
6. **Private Bubble-Unterlagen:** `staffkeeping/_bubble/` bleibt lokal, per `.gitignore` ausgeschlossen, nicht synchronisieren. Alte Commit-Kopien werden dadurch nicht aus der Git-Historie gelöscht.
7. **Sicherheit:** GitHub Pages ist öffentlich. Keine Geheimnisse, Admin-Keys, echten Login-Daten oder internen Dokumente in öffentlich ausgelieferten Assets. Supabase RLS für jede browserseitig zugreifbare Tabelle, Adminrechte serverseitig prüfen.
8. **Freigaben:** Selbstregistrierung erlaubt, aber geschützte Inhalte nur nach Adminfreigabe. Administratoren dürfen Chats lesend einsehen.
9. **Datenübernahme:** nur ausgewählte Stammdaten; keine Bubble-Testdaten.
10. **Jedes Release:** Architektur/Stand, Aufgaben, Entscheidungen, Tests, Historie und Chat-Übergabe **mit der Implementierung** aktualisieren; keinen fertigen Status ohne Test behaupten.
11. **Deployment:** bestehende Pfade beibehalten; CSS/JS-Cacheversionen und tatsächliche ZIP-Verzeichnisstruktur prüfen.
12. **Datenschutz/Original:** vollständiges Migrationskonzept darf erst nach echtem Adminschutz online ausgeliefert werden. Eine Demo-Anmeldung ist keine Zugriffskontrolle.
