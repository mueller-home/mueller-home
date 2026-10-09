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

13. **Supabase-Migrationen:** Jede Schemaänderung als dauerhaft versionierte SQL-Migration. In `public` nur Tabellen mit begründetem Browserbedarf; interne Admin-/Audit-/Backendtabellen in nicht exponiertem Schema. Exposition, Grants und RLS explizit prüfen.
14. **SQL-Bedienung:** Anzahl/Art separater Resultsets vor SQL-Ausführung erklären; mehrere SELECTs können im SQL-Editor nicht gleichzeitig sichtbar sein. Niemals Migrationserfolg ohne Test behaupten.
15. **Testdaten:** Keine bestehenden Unternehmen/Benutzer aus Bubble übernehmen; neue Testkonten in StaffKeeping/Supabase registrieren.

16. **Eigentümerschaft/Übergabe:** Bestehende GitHub-, Supabase- und Postmark-Ressourcen werden für die Übergabe an Annette vorbereitet; sie übernimmt Eigentum/Verwaltung/Billing, bisheriger Entwickler behält zusätzliche Adminrechte. Bestehenden Google Maps Key von Annette verwenden; Domain, Auth-Redirects und Mail-Domain umstellen. Transfermöglichkeiten je Provider vorab prüfen. Checkliste `docs/uebergabe-annette.md` bei relevanten Releases nachführen.

17. **Browser-Konfiguration:** Ausschliesslich Project URL + Publishable Key in scripts/config.js; keine Secret-/Service-Role-Keys. Kein echtes Login durch lokalen Demo-Flag ersetzen.
18. **Auth-Tests:** Änderungen erst als produktiv deklarieren, wenn bestätigte Testkonten, Adminfreigabe, RLS-Negativtests und Passwort-Reset mit SMTP validiert sind.

## Authentifizierungsregel ab 0.21
- Passwort-Recovery darf nicht durch Session-Initialisierung oder Rollenprüfung überschrieben werden.
- Keine Recovery-/SMTP-Schlüssel, Zugangstokens oder Passwörter in Frontend-Konfiguration, Projektdateien oder Dokumentation.
- Auth-Release erst nach echten Tests als funktionsfähig deklarieren.

19. **Auth-Redirects:** Für Signup und Passwort-Reset die kanonische StaffKeeping-App-URL verwenden, nicht die zufällige aktuelle Seite (`location.pathname`). Nach Domain-/Pfadwechsel die URL-Ermittlung, Supabase Site URL und Redirect-Allowlist gemeinsam testen. Niemals vollständige Bestätigungs- oder Recovery-Links mit Tokens protokollieren oder veröffentlichen.

20. **Registrierungszustände strikt trennen:** nicht bestätigtes Auth-Konto, bestätigtes Konto ohne Firma, Firma `Ausstehend`, genehmigte Firma und gesperrte Firma sind fachlich verschieden. Nach bestätigtem Login ohne Firmenzuordnung darf kein erneutes `signUp` verlangt werden. Die Firmenanlage erfolgt über `sk_register_business`, nicht über Browserflags.

21. **Admin-Betriebsprüfung:** Kein Freischalten ohne einsehbare Firmen-/Kontaktdetails. Interne Notizen nie in öffentlich ausgelieferten Dateien, LocalStorage oder direkt exponierten Tabellen ablegen; Zugriff ausschliesslich serverseitig als Admin verifizieren. Jede Schemaerweiterung als separate persistente Migration.


22. **Unternehmensprofil:** Der User bearbeitet nur eigene Daten als freigeschalteter `owner`; Land, USt-ID und Status bleiben unveränderbar durch normale Nutzer. `contact_email` ist nicht die Auth-Login-E-Mail.
23. **Medien:** Supabase Storage private Buckets und RLS nach Unternehmens-ID; keine public URLs; nur kurzlebige Signed URLs, Dateityp/Grösse und erlaubte Slots serverseitig durch Bucket und Policies einschränken. Keine Fotos/Anhänge in GitHub.
24. **Mail-Einstellungen:** Schalter für Fachbenachrichtigungen darf nicht als aktiver Versand ausgegeben werden, solange kein sicherer serverseitiger Benachrichtigungsjob existiert. Auth-Mails sind davon unabhängig.


25. **Auto-Save:** Normale Eingaben ohne Speichern-Button, entprellt speichern; bei Navigation/Tabwechsel sowie Back/Forward vor Ansichtswechsel flushen; bei Fehler nicht navigieren, Wiederholen zeigen. Bevorstehendes Browser-Schliessen/Reload mit ungespeicherten Daten muss Warnung auslösen; Speichern beim Schliessen nicht garantieren. Kritische Freigaben/Löschungen weiterhin explizit bestätigen.
26. **Vollständiges Originalkonzept:** nie unter GitHub Pages oder im ZIP ausserhalb des per `.gitignore` ausgeschlossenen `_bubble`-Archivs ausliefern. Nur privater Bucket `sk-project-docs` und serverseitige Admin-Security-Policies; HTML im Admin-Browser isoliert und ohne Skriptberechtigung rendern. Separate historische v2.2-Quelle und aktuelle versionierte Projektunterlagen halten.
27. **Upload/Migration:** SQL erst kontrolliert installieren, dann bewusst Admin-Upload durchführen; keinen bereits durchgeführten Live-Test behaupten, bevor SQL, Storage-Zugriff und Browseranzeige verifiziert sind.
