-- StaffKeeping 0.33.1.7.2: zentrale Projektdokumentation, keine Schema-/Betriebsdaten-Aenderung.
BEGIN;
UPDATE sk_internal.project_doc_chapters
SET body = body || E'\n\n' || $doc$
## 0.33.1.7.2 – Entwurfsbedienung und Speicherstatus (20.10.2026)
Gezielte Korrektur: Bei Meine Inserate → privater Entwurf → Bearbeiten wird der bewusst gewaehlte Entwurf ohne erneute Wiederherstellungsfrage geladen. Fuer andere Formularoeffnungen bleibt die Wiederherstellungsentscheidung bestehen. Auto-Save und zentraler Dialog-Schutz verwenden denselben Entwurfsstatus: nach erfolgreichem serverseitigem Speichern nur dann ungesicherte Aenderungen, wenn nach dem bestaetigten Snapshot neue Eingaben erfolgt sind, eine Anfrage noch laeuft oder ein Fehler/Versionskonflikt besteht. Die bestehende optimistic-locking-Revision in sk_save_form_draft bleibt verbindlich; bei 40001 wird nicht automatisch mit einer veralteten Revision ueberschrieben, sondern ein Konflikt gemeldet. Betriebsspezifische Entwurfsschluessel und gesicherter Betriebswechsel bleiben unveraendert. Kein Schema- oder RLS-Umbau, keine neuen Testfunktionen. Statische JavaScript-Pruefung erfolgt; Live-Browsertests und zwei parallele Sitzungen stehen noch aus.
$doc$, updated_at = now()
WHERE slug = 'concept' AND position('## 0.33.1.7.2 – Entwurfsbedienung' IN body) = 0;
UPDATE sk_internal.project_doc_chapters
SET body = body || E'\n\n' || $doc$
## 0.33.1.7.2 – Teststatus (20.10.2026)
Version 0.33.1.7.1: Benutzer bestaetigte Inseratsverwaltungstest 6/6, einschliesslich Entwurfsanzeige, Zuordnung, bewusstem Veroeffentlichen und Trennung anderer Betriebe. Darauf aufbauend 0.33.1.7.2 als Korrektur der doppelten Wiederherstellungsfrage und des dauerhaft sichtbaren Ungespeichert-Hinweises erstellt. Korrektur noch nicht live abgenommen. Ausstehend: Auto-Save-Status nach Speicherung, Entwurf beim expliziten Bearbeiten, Betriebswechsel, konkurrierende Sitzungen/Versionskonflikte, weitere Navigationswege, aeltere Profil-/Standort-RPC.
$doc$, updated_at = now()
WHERE slug = 'status' AND position('## 0.33.1.7.2 – Teststatus' IN body) = 0;
COMMIT;
-- Genau ein Resultset. Kontrolliert, welche zentralen Kapitel vorliegen.
SELECT slug, updated_at FROM sk_internal.project_doc_chapters WHERE slug IN ('concept','status') ORDER BY slug;
