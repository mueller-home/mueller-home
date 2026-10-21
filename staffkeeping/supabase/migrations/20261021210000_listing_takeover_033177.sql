-- StaffKeeping 0.33.1.7.7: manual, explicit edit takeover with session fencing.
-- Same authenticated user only; the previous session immediately loses write permissions.
BEGIN;
CREATE OR REPLACE FUNCTION public.sk_takeover_form_draft_lock(p_kind text,p_key text,p_business uuid,p_session uuid)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $f$
DECLARE v_ok uuid;
BEGIN
 IF p_kind<>'listing' OR p_session IS NULL OR NOT public.sk_form_draft_authorized(p_kind,p_key,p_business) THEN
  RAISE EXCEPTION 'Keine Berechtigung zur Uebernahme' USING ERRCODE='42501'; END IF;
 -- Atomic replacement: one active session per user, draft. Old sessions are fenced at save/renew.
 INSERT INTO sk_internal.form_draft_leases(user_id,form_kind,draft_key,business_id,session_id,expires_at)
 VALUES(auth.uid(),p_kind,p_key,p_business,p_session,now()+interval '90 seconds')
 ON CONFLICT(user_id,form_kind,draft_key) DO UPDATE SET
  session_id=EXCLUDED.session_id,business_id=EXCLUDED.business_id,expires_at=EXCLUDED.expires_at
 WHERE sk_internal.form_draft_leases.business_id=EXCLUDED.business_id
 RETURNING session_id INTO v_ok;
 RETURN v_ok=p_session;
END $f$;
REVOKE ALL ON FUNCTION public.sk_takeover_form_draft_lock(text,text,uuid,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_takeover_form_draft_lock(text,text,uuid,uuid) TO authenticated;
COMMIT;
SELECT proname,prosecdef,has_function_privilege('authenticated',oid,'EXECUTE') AS auth_execute
FROM pg_proc WHERE oid='public.sk_takeover_form_draft_lock(text,text,uuid,uuid)'::regprocedure;
