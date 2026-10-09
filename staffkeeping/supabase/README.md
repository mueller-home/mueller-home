# StaffKeeping · Supabase-Migrationen

Migrationen in Dateinamensreihenfolge auf dem richtigen Supabase-Projekt ausführen. Keine alten Skripte erneut installieren.

- `20261009120000_auth_foundation.sql` – bereits installiert, nicht wiederholen.
- `20261009153000_admin_business_review.sql` – Admin-Details/Notizen, bereits für 0.24 vorgesehen.
- **`20261009160500_business_profile_media.sql`** – 0.25, **vor dem Frontend-Update ausführen**.

Die 0.25-Datei enthält mehrere CREATE/ALTER/GRANT/POLICY-Anweisungen in **einer Transaktion**, **keine separaten SELECT-Resultsets**. Bei Supabase-RLS-Warnung `Run and enable RLS` verwenden; zusätzlich die RLS-Policies auf Storage prüfen.

Sie erstellt die privaten Buckets `sk-business-logos` (2 MiB) und `sk-business-photos` (5 MiB), die nie öffentlich gestellt werden dürfen.

**Tests:** Registriertes freigegebenes Unternehmen kann sein eigenes Profil bearbeiten und Bilder hochladen; Admin sieht Beschreibungen/Bilder; fremde und anonyme Nutzer nicht. Erfolgreiche SQL-Ausführung ist noch kein Berechtigungstest.


## 0.26 – Private Projektdokumentation
Nach der 0.25-Migration `20261009163000_private_project_docs.sql` genau einmal ausführen. Eine Transaktion, keine separaten SELECT-Resultsets. Der Bucket `sk-project-docs` ist privat und erlaubt Lesen/Schreiben nur für Administratoren und nur unter dem fixen Originalobjektpfad. Danach über die Web-Admin-Oberfläche das lokale HTML-Original hochladen. Nicht ins GitHub-Repository committen. Negative Zugriffstests sind vor dem Einsatz zwingend.
