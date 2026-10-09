-- StaffKeeping 0.28.1 – punktuelle Pflege der führenden Projektdokumentation.
-- Voraussetzung: Migration 0.28 ausgeführt. Eine Transaktion; keine SELECT-Resultsets.
-- Bereits vom Administrator bearbeitete Kapitel bleiben bestehen: nur eindeutig
-- gekennzeichnete Ergänzungen, keine REPLACE-Operation und kein Re-Seed.
BEGIN;
DO $check$
BEGIN
  IF (SELECT count(*) FROM sk_internal.project_doc_chapters
      WHERE slug IN ('status','history','ownership')) <> 3 THEN
    RAISE EXCEPTION 'Ein oder mehrere Kapitel fehlen; Migration 0.27 prüfen';
  END IF;
END $check$;

UPDATE sk_internal.project_doc_chapters
SET body = body || $append$

## Stand 0.28.1 – 09.10.2026
- Die 12 zentralen Kapitel in Supabase sind durch die Benutzerabfrage bestätigt; die Ergänzungen von Version 0.28 in `concept` und `issues` sind vorhanden.
- Versionsanzeige der Anwendung auf **0.28.1** aktualisiert. Die Anzeige ist erst nach Veröffentlichung des Frontend-Updates sichtbar.
- Registrierung mit bestätigter E-Mail, Administratorfreigabe und Testkonto-Anmeldung wurden im Browser durch den Benutzer bestätigt.
- Unternehmensprofil, Auto-Save bei Navigation, Logo/Bilder, private Dokumente und Negativtests der Berechtigungen sind **noch nicht vollständig live abgenommen**.
- Die Markdown-Altdateien unter `staffkeeping/docs/` können im öffentlichen Git-Stand verbleiben. Ihre Entfernung erfolgt **erst nach gesicherter Prüfung**; Git-Historie und fremde Kopien bleiben davon unberührt.
- Ein endgültiger fachlicher Einzelabgleich der Bubble-Anforderungen sowie die Prüfung des öffentlichen README und weiterer Repo-Dateien stehen noch aus.
$append$,
updated_at=now()
WHERE slug='status' AND strpos(body,'## Stand 0.28.1 – 09.10.2026')=0;

UPDATE sk_internal.project_doc_chapters
SET body = body || $append$

## Version 0.28.1 – 09.10.2026
**Korrektur ohne neues Fachschema:** Sichtbare Versionsnummer in Website, Footer und Admin-Dokumentationsübersicht auf 0.28.1 gesetzt. Die führenden Kapitel `status`, `history` und `ownership` in Supabase punktuell ergänzt (ohne Neuimport). Öffentliche Markdown-Altdateien und historisches Original bleiben unverändert; Bereinigung erst nach expliziter Sicherungs- und Inhaltskontrolle. Keine neuen Funktionen der Inserate-/Chat-Logik.
**Prüfung:** JavaScript/Frontend statisch, SQL erst nach Ausführung in Supabase; keine Behauptung einer Live-Abnahme.
$append$,
updated_at=now()
WHERE slug='history' AND strpos(body,'## Version 0.28.1 – 09.10.2026')=0;

UPDATE sk_internal.project_doc_chapters
SET body = body || $append$

## Übergabe an Annette – Zielbild und Prüfliste (Stand 0.28.1)
**Ziel:** Annette soll später die technische und organisatorische Kontrolle über StaffKeeping erhalten. Das ist **geplant, noch nicht vollzogen**. Bis dahin läuft die Entwicklung unter der temporären App-Adresse `https://www.mueller-home.me/staffkeeping/`. Die bestehende öffentliche Marketing-Website `staffkeeping.com` wird durch unsere App-Updates nicht verändert.

### GitHub / Frontend
- Den künftigen Repository-Eigentümer beziehungsweise das Ziel-Repository zusammen mit Annette festlegen; Administrationsrechte, Deploy-/Pages-Konfiguration und Domainzuordnung prüfen.
- Historisches Bubble-Material (`_bubble/`) und vertrauliche Projektunterlagen nicht in öffentliche GitHub-Pages-Dateien verschieben.
- Ziel-Domain für die App erst nach Abnahme umstellen; dabei absolute URLs, Supabase Auth Site URL, Redirect-URLs und E-Mail-Links testen.

### Supabase / Daten
- Projektübernahme oder kontrollierte Migration mit Annette planen; Datenbank, Auth-Benutzer, RLS, interne Schemata, RPCs, Storage-Buckets, Edge Functions, Secrets und Backups berücksichtigen.
- Privaten Bucket `sk-project-docs` und zentrale Projektdokumentation `sk_internal.project_doc_chapters` mit ihren Admin-Zugriffsregeln erhalten.
- Administratorrechte des aktuellen Entwicklers nach der Übergabe nur mit ausdrücklicher Vereinbarung beibehalten; vorhandene UUIDs und Berechtigungen vor Rollenänderungen prüfen.
- **Keine** Produktivdaten oder Geheimnisse in ein öffentliches Repository beziehungsweise Update-ZIP aufnehmen.

### Postmark / E-Mail und Dienste
- Postmark-Server, Absenderdomain, DNS-Einträge, SMTP-Anbindung und Eigentümerschaft gemeinsam mit Annette abstimmen; vor einem Wechsel Zustellbarkeit und Supabase-Auth-Mails testen.
- Google-Maps-API-Key gehört bereits Annette; bei Domainwechsel erlaubte Referrer, Quoten und Abrechnung prüfen.
- Stripe/Abos, weitere Integrationen und ihre Eigentümerschaft erst nach fachlicher Entscheidung ergänzen.

### Abnahme vor Übergabe
- Registrierung, E-Mail-Bestätigung, Passwort-Reset, Unternehmensprüfung/-freigabe, Firmenprofil/Auto-Save, Medien und Adminrechte end-to-end testen.
- RLS-/RPC-/Storage-Negativtests mit Administrator, zwei Unternehmen und anonymem Zugriff dokumentieren.
- Offene Punkte, Testprotokolle, Architektur, bekannte Einschränkungen, Deploy-/Rollback-Verfahren und Notfallkontakte innerhalb dieser zentralen Projektdoku nachführen.
- Zeitpunkt, Verantwortliche und tatsächliche Übergabeschritte separat als **durchgeführt** bestätigen; keine vorzeitige Erfolgsbehauptung.
$append$,
updated_at=now()
WHERE slug='ownership' AND strpos(body,'## Übergabe an Annette – Zielbild und Prüfliste (Stand 0.28.1)')=0;
COMMIT;
