-- StaffKeeping 0.33.1.8.11: eindeutige Betriebs-ID bei Einreichung und Löschanträgen.
-- Keine automatische Löschung von Auth-Konten. Vorhandene Legacy-RPCs bleiben für Kompatibilität bestehen.
BEGIN;
CREATE OR REPLACE FUNCTION public.sk_submit_business_by_id(p_business_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE b public.sk_businesses%ROWTYPE;
BEGIN
 IF auth.uid() IS NULL OR p_business_id IS NULL THEN RAISE EXCEPTION 'Anmeldung und Betrieb erforderlich' USING ERRCODE='42501'; END IF;
 SELECT x.* INTO b FROM public.sk_businesses x
 JOIN public.sk_business_members m ON m.business_id=x.id
 JOIN auth.users u ON u.id=m.user_id
 WHERE x.id=p_business_id AND m.user_id=auth.uid() AND m.role='owner'::public.sk_member_role
 AND u.email_confirmed_at IS NOT NULL AND x.status='Ausstehend'
 AND x.review_state IN ('draft','changes_requested') FOR UPDATE OF x;
 IF NOT FOUND THEN RAISE EXCEPTION 'Einreichung für diesen Betrieb nicht erlaubt' USING ERRCODE='42501'; END IF;
 IF length(btrim(coalesce(b.description,'')))<30 OR length(btrim(coalesce(b.contact_phone,'')))<5
 THEN RAISE EXCEPTION 'Bitte Beschreibung (mindestens 30 Zeichen) und Telefonnummer ergänzen' USING ERRCODE='22023'; END IF;
 UPDATE public.sk_businesses SET review_state='submitted',submitted_at=now(),review_message=NULL,updated_at=now() WHERE id=b.id;
 INSERT INTO sk_internal.admin_events(business_id,kind,title,detail) VALUES(b.id,'submitted','Neuer Freigabeantrag',b.company_name);
END $fn$;
REVOKE ALL ON FUNCTION public.sk_submit_business_by_id(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.sk_submit_business_by_id(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.sk_business_deletion_status_by_id(p_business_id uuid)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $fn$
BEGIN
 IF auth.uid() IS NULL OR p_business_id IS NULL OR NOT EXISTS(
  SELECT 1 FROM public.sk_business_members m WHERE m.user_id=auth.uid() AND m.business_id=p_business_id AND m.role='owner'::public.sk_member_role
 ) THEN RAISE EXCEPTION 'Keine Berechtigung für diesen Betrieb' USING ERRCODE='42501'; END IF;
 RETURN (SELECT jsonb_build_object('id',r.id,'status',r.status,'created_at',r.created_at,'request_type',r.request_type)
 FROM sk_internal.business_deletion_requests r WHERE r.business_id=p_business_id ORDER BY r.created_at DESC LIMIT 1);
END $fn$;
REVOKE ALL ON FUNCTION public.sk_business_deletion_status_by_id(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.sk_business_deletion_status_by_id(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.sk_request_business_deletion_by_id(p_business_id uuid,p_confirm_name text,p_reason text DEFAULT '')
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE b public.sk_businesses%ROWTYPE; v_request uuid; v_fast boolean;
BEGIN
 IF auth.uid() IS NULL OR p_business_id IS NULL THEN RAISE EXCEPTION 'Anmeldung und Betrieb erforderlich' USING ERRCODE='42501'; END IF;
 SELECT x.* INTO b FROM public.sk_businesses x JOIN public.sk_business_members m ON m.business_id=x.id
 JOIN auth.users u ON u.id=m.user_id
 WHERE x.id=p_business_id AND m.user_id=auth.uid() AND m.role='owner'::public.sk_member_role
 AND u.email_confirmed_at IS NOT NULL FOR UPDATE OF x;
 IF NOT FOUND THEN RAISE EXCEPTION 'Nur der bestätigte Betriebsinhaber darf die Löschung beantragen' USING ERRCODE='42501'; END IF;
 IF btrim(coalesce(p_confirm_name,'')) IS DISTINCT FROM b.company_name THEN RAISE EXCEPTION 'Firmenname zur Bestätigung stimmt nicht überein' USING ERRCODE='22023'; END IF;
 IF EXISTS(SELECT 1 FROM sk_internal.staff_admins WHERE user_id=auth.uid()) THEN RAISE EXCEPTION 'Administratorkonten dürfen nicht über eine Betriebslöschung entfernt werden' USING ERRCODE='42501'; END IF;
 IF EXISTS(SELECT 1 FROM sk_internal.business_deletion_requests WHERE business_id=b.id AND status IN ('requested','approved','processing','database_removed','failed')) THEN RAISE EXCEPTION 'Es gibt bereits einen laufenden Löschvorgang' USING ERRCODE='SK409'; END IF;
 v_fast := b.status='Ausstehend' AND b.review_state IN ('draft','changes_requested');
 INSERT INTO sk_internal.business_deletion_requests(business_id,business_name,requested_by,request_type,reason,status,approved_at)
 VALUES(b.id,b.company_name,auth.uid(),'owner',left(btrim(coalesce(p_reason,'')),2000),CASE WHEN v_fast THEN 'approved' ELSE 'requested' END,CASE WHEN v_fast THEN now() ELSE NULL END)
 RETURNING id INTO v_request;
 IF v_fast THEN UPDATE public.sk_businesses SET status='Gesperrt',updated_at=now() WHERE id=b.id; END IF;
 INSERT INTO sk_internal.admin_events(business_id,kind,title,detail)
 VALUES(b.id,'deletion_requested','Löschung beantragt',CASE WHEN v_fast THEN 'Registrierungsabbruch: kontrollierte Löschung ausstehend' ELSE 'Admin-Prüfung erforderlich' END);
 RETURN jsonb_build_object('id',v_request,'status',CASE WHEN v_fast THEN 'approved' ELSE 'requested' END,'immediate',v_fast);
END $fn$;
REVOKE ALL ON FUNCTION public.sk_request_business_deletion_by_id(uuid,text,text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.sk_request_business_deletion_by_id(uuid,text,text) TO authenticated;
COMMIT;
SELECT p.proname AS funktion,p.prosecdef AS security_definer,
 has_function_privilege('authenticated',p.oid,'EXECUTE') AS authenticated_execute,
 has_function_privilege('anon',p.oid,'EXECUTE') AS anon_execute
FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname='public' AND p.proname IN ('sk_submit_business_by_id','sk_business_deletion_status_by_id','sk_request_business_deletion_by_id')
ORDER BY p.proname;
