-- StaffKeeping 0.33.1.7.1 – sichtbare private Inseratsentwürfe (nur eigene, freigegebene Betriebe).
BEGIN;
CREATE OR REPLACE FUNCTION public.sk_list_my_listing_drafts()
RETURNS TABLE(draft_key text,business_id uuid,payload jsonb,revision bigint,updated_at timestamptz)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $f$
 SELECT d.draft_key,d.business_id,d.payload,d.revision,d.updated_at
 FROM sk_internal.form_drafts d
 WHERE auth.uid() IS NOT NULL AND d.user_id=auth.uid() AND d.form_kind='listing'
 AND EXISTS (SELECT 1 FROM public.sk_business_members m
   WHERE m.user_id=auth.uid() AND m.business_id=d.business_id)
 AND public.sk_is_approved_member(d.business_id)
 ORDER BY d.updated_at DESC;
$f$;
REVOKE ALL ON FUNCTION public.sk_list_my_listing_drafts() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_list_my_listing_drafts() TO authenticated;
COMMIT;
SELECT proname,prosecdef,has_function_privilege('authenticated',oid,'EXECUTE') AS auth_execute
FROM pg_proc WHERE oid='public.sk_list_my_listing_drafts()'::regprocedure;
