-- Read-only, einmaliger SELECT. Als Datenbankadministrator im Supabase SQL Editor ausführen.
-- Bestätigt nur DB-Daten, NICHT RLS-/Storage-Zugriff unter fremder Benutzerrolle.
SELECT slug, title, char_length(body) AS characters, updated_at,
       CASE WHEN slug='concept' THEN strpos(body,'## Quellenprüfung und Abnahmegrenze – Version 0.28')>0
            WHEN slug='issues' THEN strpos(body,'## Prüfschritte bis zum Abschluss Registrierung / Profil und öffentliche Dokumentation (0.28)')>0
            ELSE NULL END AS audit_028_present
FROM sk_internal.project_doc_chapters
ORDER BY position,slug;
