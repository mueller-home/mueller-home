# StaffKeeping 0.27 – Führende Projektdokumentation

Nach Installation der Migration `20261009164500_admin_project_docs.sql` ist **Admin → Projektdoku** die einzige führende aktuelle Arbeitsdokumentation. Der Anfangsbestand ist aus den vorhandenen `docs/*.md` einmalig in `sk_internal.project_doc_chapters` übernommen. Ab dann Aktualisierungen nur dort; die bisherigen Markdown-Dateien sind ein archivierter Quellstand der initialen Übernahme und dürfen nicht unabhängig weiterbearbeitet werden. SQL-Migrationen bleiben technische Versionsartefakte.

Das vollständige historische Migrationskonzept v2.2 bleibt unverändert als HTML im privaten Bucket `sk-project-docs`, Objekt `original/staffkeeping_migrationskonzept_v2.2.html`. Es wird ausschliesslich von Administratoren gelesen und im Sandbox-Frame ohne Skriptrechte angezeigt. HTML niemals in öffentliche GitHub-Assets kopieren. Der einmalige Upload erfolgt nach Migration 0.26.

**Einrichtung:** Zuerst Migration 0.26, dann 0.27 im StaffKeeping-Supabase-Projekt ausführen. 0.27 führt mehrere SQL-Anweisungen in EINER Transaktion aus, keine eigenständigen SELECT-Resultsets. Dateien über GitHub veröffentlichen. Admin: Kapitel laden, bearbeiten, speichern, reload; normales Unternehmenskonto via RPC negativ testen. Original ggf. einmalig hochladen; Bilder prüfen. Bestehende Migrationen niemals löschen.

**Noch nicht live getestet:** SQL-Ausführung, Rollen-Negativtests, Bearbeiten/Speichern und Originalabruf. Veröffentlichung erst danach als abgeschlossen dokumentieren.
