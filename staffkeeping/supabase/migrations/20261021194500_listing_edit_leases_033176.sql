-- StaffKeeping 0.33.1.7.6 – zeitlich begrenzte serverseitige Entwurfssperre.
-- WICHTIG: Als zusammenhaengende Migration vor dem Frontend ausfuehren.
BEGIN;
CREATE TABLE IF NOT EXISTS sk_internal.form_draft_leases (
 user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
 form_kind text NOT NULL CHECK(form_kind='listing'),
 draft_key text NOT NULL,
 business_id uuid NOT NULL REFERENCES public.sk_businesses(id) ON DELETE CASCADE,
 session_id uuid NOT NULL,
 expires_at timestamptz NOT NULL,
 PRIMARY KEY(user_id,form_kind,draft_key)
);
ALTER TABLE sk_internal.form_draft_leases ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE sk_internal.form_draft_leases FROM PUBLIC,anon,authenticated;
CREATE OR REPLACE FUNCTION public.sk_acquire_form_draft_lock(p_kind text,p_key text,p_business uuid,p_session uuid)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $f$
DECLARE v_ok uuid;
BEGIN
 IF p_kind<>'listing' OR p_session IS NULL OR NOT public.sk_form_draft_authorized(p_kind,p_key,p_business) THEN
  RAISE EXCEPTION 'Keine Berechtigung fuer die Entwurfssperre' USING ERRCODE='42501'; END IF;
 INSERT INTO sk_internal.form_draft_leases(user_id,form_kind,draft_key,business_id,session_id,expires_at)
 VALUES(auth.uid(),p_kind,p_key,p_business,p_session,now()+interval '90 seconds')
 ON CONFLICT(user_id,form_kind,draft_key) DO UPDATE
 SET session_id=excluded.session_id,business_id=excluded.business_id,expires_at=excluded.expires_at
 WHERE sk_internal.form_draft_leases.expires_at < now()
    OR (sk_internal.form_draft_leases.session_id=excluded.session_id AND sk_internal.form_draft_leases.business_id=excluded.business_id)
 RETURNING session_id INTO v_ok;
 RETURN v_ok=p_session;
END $f$;
CREATE OR REPLACE FUNCTION public.sk_renew_form_draft_lock(p_kind text,p_key text,p_business uuid,p_session uuid)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $f$
DECLARE v_ok uuid;
BEGIN
 IF NOT public.sk_form_draft_authorized(p_kind,p_key,p_business) THEN RETURN false; END IF;
 UPDATE sk_internal.form_draft_leases SET expires_at=now()+interval '90 seconds'
 WHERE user_id=auth.uid() AND form_kind=p_kind AND draft_key=p_key AND business_id=p_business
 AND session_id=p_session AND expires_at>now() RETURNING session_id INTO v_ok;
 RETURN v_ok=p_session;
END $f$;
CREATE OR REPLACE FUNCTION public.sk_release_form_draft_lock(p_kind text,p_key text,p_business uuid,p_session uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $f$
BEGIN
 DELETE FROM sk_internal.form_draft_leases WHERE user_id=auth.uid() AND form_kind=p_kind
 AND draft_key=p_key AND business_id=p_business AND session_id=p_session;
END $f$;
-- Alte Signatur entfernen; die neue Signatur verlangt fuer Inserate eine gueltige Lease.
DROP FUNCTION public.sk_save_form_draft(text,text,uuid,jsonb,bigint);
CREATE FUNCTION public.sk_save_form_draft(p_kind text,p_key text,p_business uuid,p_payload jsonb,p_expected_revision bigint,p_session uuid)
RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $f$
DECLARE v_revision bigint;
BEGIN
 IF NOT public.sk_form_draft_authorized(p_kind,p_key,p_business) THEN
  RAISE EXCEPTION 'Keine Berechtigung fuer den Entwurf' USING ERRCODE='42501'; END IF;
 IF p_payload IS NULL OR jsonb_typeof(p_payload)<>'object' OR pg_column_size(p_payload)>32768
 OR p_expected_revision IS NULL OR p_expected_revision<0 THEN
  RAISE EXCEPTION 'Ungueltige Entwurfsdaten' USING ERRCODE='22023'; END IF;
 IF p_kind='listing' AND NOT EXISTS(
  SELECT 1 FROM sk_internal.form_draft_leases l
  WHERE l.user_id=auth.uid() AND l.form_kind=p_kind AND l.draft_key=p_key
  AND l.business_id=p_business AND l.session_id=p_session AND l.expires_at>now()
 ) THEN RAISE EXCEPTION 'Inserat wird anderswo bearbeitet oder Sperre ist abgelaufen' USING ERRCODE='SK423'; END IF;
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
  RAISE EXCEPTION 'Entwurf wurde zwischenzeitlich veraendert; bitte neu laden' USING ERRCODE='SK409'; END IF;
 RETURN v_revision;
END $f$;
REVOKE ALL ON FUNCTION public.sk_save_form_draft(text,text,uuid,jsonb,bigint,uuid),
 public.sk_acquire_form_draft_lock(text,text,uuid,uuid),
 public.sk_renew_form_draft_lock(text,text,uuid,uuid),
 public.sk_release_form_draft_lock(text,text,uuid,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_save_form_draft(text,text,uuid,jsonb,bigint,uuid),
 public.sk_acquire_form_draft_lock(text,text,uuid,uuid),
 public.sk_renew_form_draft_lock(text,text,uuid,uuid),
 public.sk_release_form_draft_lock(text,text,uuid,uuid) TO authenticated;
COMMIT;
SELECT proname,pg_get_function_identity_arguments(oid) AS arguments
FROM pg_proc WHERE pronamespace='public'::regnamespace AND proname IN
('sk_acquire_form_draft_lock','sk_renew_form_draft_lock','sk_release_form_draft_lock','sk_save_form_draft') ORDER BY proname;
