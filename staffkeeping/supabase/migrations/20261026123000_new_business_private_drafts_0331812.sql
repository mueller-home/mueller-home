-- StaffKeeping 0.33.1.8.12 – private Entwürfe neuer Betriebe, ohne Betriebsdatensatz.
BEGIN;
CREATE TABLE IF NOT EXISTS sk_internal.new_business_drafts (
 user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
 draft_id uuid NOT NULL,
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object' AND pg_column_size(payload)<=32768),
 revision bigint NOT NULL DEFAULT 1 CHECK(revision>0),
 updated_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY (user_id,draft_id)
);
ALTER TABLE sk_internal.new_business_drafts ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON sk_internal.new_business_drafts FROM PUBLIC,anon,authenticated;
CREATE OR REPLACE FUNCTION public.sk_list_new_business_drafts()
RETURNS TABLE(draft_id uuid,payload jsonb,revision bigint,updated_at timestamptz)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $func$
 SELECT d.draft_id,d.payload,d.revision,d.updated_at
 FROM sk_internal.new_business_drafts d
 WHERE auth.uid() IS NOT NULL AND d.user_id=auth.uid()
 ORDER BY d.updated_at DESC;
$func$;
CREATE OR REPLACE FUNCTION public.sk_save_new_business_draft(p_draft_id uuid,p_payload jsonb,p_expected_revision bigint)
RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $func$
DECLARE v_rev bigint;
BEGIN
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Anmeldung erforderlich' USING ERRCODE='42501'; END IF;
 IF p_draft_id IS NULL OR p_payload IS NULL OR jsonb_typeof(p_payload)<>'object'
    OR pg_column_size(p_payload)>32768 OR p_expected_revision IS NULL OR p_expected_revision<0 THEN
   RAISE EXCEPTION 'Ungültige Entwurfsdaten' USING ERRCODE='22023'; END IF;
 IF p_expected_revision=0 THEN
   INSERT INTO sk_internal.new_business_drafts(user_id,draft_id,payload)
   VALUES(auth.uid(),p_draft_id,p_payload)
   ON CONFLICT DO NOTHING RETURNING revision INTO v_rev;
 ELSE
   UPDATE sk_internal.new_business_drafts d
   SET payload=p_payload,revision=d.revision+1,updated_at=now()
   WHERE d.user_id=auth.uid() AND d.draft_id=p_draft_id AND d.revision=p_expected_revision
   RETURNING d.revision INTO v_rev;
 END IF;
 IF v_rev IS NULL THEN RAISE EXCEPTION 'Entwurf wurde zwischenzeitlich geändert. Bitte neu laden.' USING ERRCODE='SK409'; END IF;
 RETURN v_rev;
END;
$func$;
CREATE OR REPLACE FUNCTION public.sk_delete_new_business_draft(p_draft_id uuid,p_expected_revision bigint)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $func$
DECLARE v_count integer;
BEGIN
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Anmeldung erforderlich' USING ERRCODE='42501'; END IF;
 IF p_draft_id IS NULL OR p_expected_revision IS NULL OR p_expected_revision<1 THEN
  RAISE EXCEPTION 'Ungültiger Entwurf' USING ERRCODE='22023'; END IF;
 DELETE FROM sk_internal.new_business_drafts d
 WHERE d.user_id=auth.uid() AND d.draft_id=p_draft_id AND d.revision=p_expected_revision;
 GET DIAGNOSTICS v_count=ROW_COUNT;
 IF v_count=0 AND EXISTS(SELECT 1 FROM sk_internal.new_business_drafts d
   WHERE d.user_id=auth.uid() AND d.draft_id=p_draft_id) THEN
   RAISE EXCEPTION 'Entwurf wurde zwischenzeitlich geändert. Bitte neu laden.' USING ERRCODE='SK409';
 END IF;
END;
$func$;
REVOKE ALL ON FUNCTION public.sk_list_new_business_drafts() FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.sk_save_new_business_draft(uuid,jsonb,bigint) FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.sk_delete_new_business_draft(uuid,bigint) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_list_new_business_drafts() TO authenticated;
GRANT EXECUTE ON FUNCTION public.sk_save_new_business_draft(uuid,jsonb,bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.sk_delete_new_business_draft(uuid,bigint) TO authenticated;
COMMIT;
SELECT proname,has_function_privilege('authenticated',oid,'EXECUTE') AS authenticated_execute,
 has_function_privilege('anon',oid,'EXECUTE') AS anon_execute
 FROM pg_proc WHERE pronamespace='public'::regnamespace AND proname IN
 ('sk_list_new_business_drafts','sk_save_new_business_draft','sk_delete_new_business_draft') ORDER BY proname;
