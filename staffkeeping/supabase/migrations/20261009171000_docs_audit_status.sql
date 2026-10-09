-- StaffKeeping 0.28: fachliche Quellenprüfung; keine neue Kapitelstruktur.
-- Eine Transaktion mit 2 UPDATEs, KEINE SELECT-Resultsets.
-- Voraussetzung: 0.27 und 0.27.1 erfolgreich ausgeführt.
BEGIN;
DO $sk$
BEGIN
 IF (SELECT count(*) FROM sk_internal.project_doc_chapters WHERE slug IN ('concept','issues')) <> 2 THEN
  RAISE EXCEPTION 'Zentrale Kapitel fehlen; zuerst Migration 0.27/0.27.1 prüfen';
 END IF;
END $sk$;
UPDATE sk_internal.project_doc_chapters
 SET body = body || $txt$

## Quellenprüfung und Abnahmegrenze – Version 0.28
**Quelle:** unverändertes Bubble-Migrationskonzept v2.2 vom 14.09.2026 (HTML mit eingebetteten Screenshots). **Status: Kapitelstruktur geprüft, keine vollständige inhaltliche Abnahme.**
Das Original enthält die Abschnitte 01–13 zu Architektur, Tabellen, Privacy/RLS, Auth, Workflows, Postmark, Karten, Stripe, Hosting, Migration, Phasen und Design; dazu die sieben Maskenbereiche Login/Marktplatz, Profil, Inserate, Inseratdetails, Nachrichten, Bewertungen und Administration sowie Bubble-Muster und Kapitel 21 Diskrepanzen.
**Verbindliche Trennung:** Historische Bubble-Ausführungen sind keine aktuelle Implementierungszusage. Aktuelle Supabase-Registrierung/Freigabe ist separat live bestätigt; Profil/Medien, Navigation, RLS-Negativtests und Original-Viewer bleiben bis zu echtem Test unbestätigt.
Die Unterschiede in den Tabellen- und Feldnamen sowie Statuswerten sind noch einzeln fachlich zu entscheiden, bevor Inserate/Chat/Bewertungen umgesetzt werden. Das Original ist Referenz, **diese Kapitel sind die einzige fortlaufend bearbeitete Projektdokumentation**.
$txt$,updated_at=now()
 WHERE slug='concept' AND strpos(body,'## Quellenprüfung und Abnahmegrenze – Version 0.28')=0;
UPDATE sk_internal.project_doc_chapters
 SET body = body || $txt$

## Prüfschritte bis zum Abschluss Registrierung / Profil und öffentliche Dokumentation (0.28)
- [ ] Mit freigegebenem Testbetrieb Unternehmensdaten aus Supabase laden: Name, Branche, Land, USt-ID, Kontakt, Beschreibung.
- [ ] Auto-Save nach Eingabepause, Feldwechsel, Tab-/Menüwechsel und Browser Zurück/Vorwärts live prüfen; Netzwerkfehler/Reload ohne Datenverlust testen.
- [ ] Logo und fünf Bildplätze: Upload, Ersetzen, Entfernen und Sichtbarkeit für Admin prüfen.
- [ ] RLS/RPC/Storage mit zwei unterschiedlichen Firmen, Admin und anonymem Nutzer negativ testen. Keine fremden Profil-/Medienzugriffe.
- [ ] Originalkonzept im privaten Bucket hochgeladen und mit Bildern lesbar, Zugriff als Normalnutzer verweigert.
- [ ] Supabase-Kapitel (insbesondere Konzept/Aufgaben/Tests) und lokale Archivkopie vor Entfernen alter öffentlicher docs verifizieren.
- [ ] Öffentliche `staffkeeping/docs/`-Altdateien aus Git entfernen und gepushte GitHub-Pages-URLs prüfen; `README.md` und weitere Dateien gesondert auf interne Inhalte prüfen.
- [ ] Versionshistorie, Teststatus und Übergabe direkt in **bestehenden Admin-Kapiteln** nachführen; kein paralleler Dokumentationsbestand.
**Hinweis:** Entfernen aus dem Git-HEAD bedeutet nicht Löschen aus der Git-Historie. Bei tatsächlich vertraulichen alten Inhalten sind zusätzlich Repo-Historie und Caches zu prüfen.
$txt$,updated_at=now()
 WHERE slug='issues' AND strpos(body,'## Prüfschritte bis zum Abschluss Registrierung / Profil und öffentliche Dokumentation (0.28)')=0;
COMMIT;
