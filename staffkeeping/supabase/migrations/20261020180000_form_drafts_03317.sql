-- StaffKeeping 0.33.1.7: private, versionierte Entwuerfe. Vor Frontend-Deployment ausfuehren.
BEGIN;
CREATE TABLE IF NOT EXISTS sk_internal.form_drafts (
 user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
 form_kind text NOT NULL CHECK (form_kind IN ('business','listing')),
 draft_key text NOT NULL CHECK (char_length(draft_key) BETWEEN 1 AND 120),
 business_id uuid NOT NULL REFERENCES public.sk_businesses(id) ON DELETE CASCADE,
 payload jsonb NOT NULL CHECK (jsonb_typeof(payload)='object' AND pg_column_size(payload)<=32768),
 revision bigint NOT NULL DEFAULT 1 CHECK (revision>0),
 updated_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY(user_id,form_kind,draft_key)
);
ALTER TABLE sk_internal.form_drafts ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE sk_internal.form_drafts FROM PUBLIC, anon, authenticated;
-- Alle Zugriffe ausschliesslich ueber qualifizierte SECURITY DEFINER RPCs.
CREATE OR REPLACE FUNCTION public.sk_form_draft_authorized(p_kind text,p_key text,p_business uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $f$
 SELECT auth.uid() IS NOT NULL AND p_kind IN ('business','listing')
 AND p_key IS NOT NULL AND length(p_key) BETWEEN 1 AND 120
 AND EXISTS (SELECT 1 FROM public.sk_business_members m
   WHERE m.user_id=auth.uid() AND m.business_id=p_business
   AND (p_kind='listing' OR m.role='owner'::public.sk_member_role))
 AND (p_kind<>'listing' OR public.sk_is_approved_member(p_business));
$f$;
REVOKE ALL ON FUNCTION public.sk_form_draft_authorized(text,text,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_form_draft_authorized(text,text,uuid) TO authenticated;
CREATE OR REPLACE FUNCTION public.sk_get_form_draft(p_kind text,p_key text,p_business uuid)
RETURNS TABLE(payload jsonb,revision bigint,updated_at timestamptz)
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $f$
BEGIN
 IF NOT public.sk_form_draft_authorized(p_kind,p_key,p_business) THEN
   RAISE EXCEPTION 'Keine Berechtigung fuer den Entwurf' USING ERRCODE='42501'; END IF;
 RETURN QUERY SELECT d.payload,d.revision,d.updated_at FROM sk_internal.form_drafts d
 WHERE d.user_id=auth.uid() AND d.form_kind=p_kind AND d.draft_key=p_key AND d.business_id=p_business;
END $f$;
CREATE OR REPLACE FUNCTION public.sk_save_form_draft(p_kind text,p_key text,p_business uuid,p_payload jsonb,p_expected_revision bigint)
RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $f$
DECLARE v_revision bigint;
BEGIN
 IF NOT public.sk_form_draft_authorized(p_kind,p_key,p_business) THEN
   RAISE EXCEPTION 'Keine Berechtigung fuer den Entwurf' USING ERRCODE='42501'; END IF;
 IF p_payload IS NULL OR jsonb_typeof(p_payload)<>'object' OR pg_column_size(p_payload)>32768 OR p_expected_revision IS NULL OR p_expected_revision<0 THEN
   RAISE EXCEPTION 'Ungueltige Entwurfsdaten' USING ERRCODE='22023'; END IF;
 -- Neue Entwuerfe koennen nur mit erwarteter Revision 0 entstehen.
 IF p_expected_revision=0 THEN
   INSERT INTO sk_internal.form_drafts(user_id,form_kind,draft_key,business_id,payload)
   VALUES(auth.uid(),p_kind,p_key,p_business,p_payload)
   ON CONFLICT DO NOTHING RETURNING revision INTO v_revision;
 ELSE
   UPDATE sk_internal.form_drafts d SET payload=p_payload,revision=d.revision+1,updated_at=now()
   WHERE d.user_id=auth.uid() AND d.form_kind=p_kind AND d.draft_key=p_key
     AND d.business_id=p_business AND d.revision=p_expected_revision
   RETURNING d.revision INTO v_revision;
 END IF;
 IF v_revision IS NULL THEN
   RAISE EXCEPTION 'Entwurf wurde zwischenzeitlich veraendert; bitte neu laden' USING ERRCODE='40001'; END IF;
 RETURN v_revision;
END $f$;
CREATE OR REPLACE FUNCTION public.sk_discard_form_draft(p_kind text,p_key text,p_business uuid,p_expected_revision bigint)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $f$
DECLARE v_deleted integer;
BEGIN
 IF NOT public.sk_form_draft_authorized(p_kind,p_key,p_business) THEN
   RAISE EXCEPTION 'Keine Berechtigung fuer den Entwurf' USING ERRCODE='42501'; END IF;
 DELETE FROM sk_internal.form_drafts d WHERE d.user_id=auth.uid() AND d.form_kind=p_kind
 AND d.draft_key=p_key AND d.business_id=p_business AND d.revision=p_expected_revision;
 GET DIAGNOSTICS v_deleted = ROW_COUNT;
 IF v_deleted=0 AND EXISTS (SELECT 1 FROM sk_internal.form_drafts d WHERE d.user_id=auth.uid() AND d.form_kind=p_kind AND d.draft_key=p_key) THEN
  RAISE EXCEPTION 'Entwurf wurde zwischenzeitlich veraendert' USING ERRCODE='40001'; END IF;
END $f$;
REVOKE ALL ON FUNCTION public.sk_get_form_draft(text,text,uuid),public.sk_save_form_draft(text,text,uuid,jsonb,bigint),public.sk_discard_form_draft(text,text,uuid,bigint) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_get_form_draft(text,text,uuid),public.sk_save_form_draft(text,text,uuid,jsonb,bigint),public.sk_discard_form_draft(text,text,uuid,bigint) TO authenticated;
COMMIT;
-- Ein Kontroll-Resultset. Die Funktionen sind absichtlich exponiert, die Tabelle sk_internal nicht.
SELECT proname,prosecdef FROM pg_proc WHERE pronamespace='public'::regnamespace AND proname IN ('sk_get_form_draft','sk_save_form_draft','sk_discard_form_draft') ORDER BY proname;
