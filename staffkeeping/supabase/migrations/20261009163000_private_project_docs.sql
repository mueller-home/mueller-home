-- StaffKeeping 0.26: Privates Original-Migrationskonzept. KEINE Projektdatei auf GitHub Pages.
-- Ausführung genau einmal NACH 0.19 / 0.24 / 0.25. Eine Transaktion; keine SELECT-Resultsets.
-- Bucket kann nur mit einer echten StaffKeeping-Administrator-Session gelesen/beschrieben werden.
BEGIN;
INSERT INTO storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
VALUES ('sk-project-docs','sk-project-docs',false,6291456,ARRAY['text/html'])
ON CONFLICT (id) DO UPDATE SET public=false,file_size_limit=6291456,allowed_mime_types=ARRAY['text/html'];

CREATE POLICY sk_project_docs_admin_read ON storage.objects
FOR SELECT TO authenticated
USING (bucket_id='sk-project-docs' AND public.sk_is_admin()
       AND name='original/staffkeeping_migrationskonzept_v2.2.html');

CREATE POLICY sk_project_docs_admin_insert ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id='sk-project-docs' AND public.sk_is_admin()
            AND name='original/staffkeeping_migrationskonzept_v2.2.html');

CREATE POLICY sk_project_docs_admin_update ON storage.objects
FOR UPDATE TO authenticated
USING (bucket_id='sk-project-docs' AND public.sk_is_admin()
       AND name='original/staffkeeping_migrationskonzept_v2.2.html')
WITH CHECK (bucket_id='sk-project-docs' AND public.sk_is_admin()
            AND name='original/staffkeeping_migrationskonzept_v2.2.html');

-- Kein DELETE-Recht über den Browser: revisionssicherer Erhalt des hochgeladenen Originals.
COMMIT;
