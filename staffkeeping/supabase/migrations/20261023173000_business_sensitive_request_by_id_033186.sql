-- StaffKeeping 0.33.1.8.6 – Sensible Aenderungsantraege pro eindeutiger Betriebs-ID.
-- SQL-Migration: CREATE FUNCTION / REVOKE / GRANT, ein abschliessender Kontroll-SELECT.
BEGIN;
CREATE OR REPLACE FUNCTION public.sk_request_business_sensitive_change_by_id(
 p_business_id uuid, p_field text, p_new_value text
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE b public.sk_businesses%ROWTYPE; v_old text; v_new text;
BEGIN
 IF auth.uid() IS NULL OR p_business_id IS NULL THEN
  RAISE EXCEPTION 'Anmeldung und Betrieb erforderlich' USING ERRCODE='42501';
 END IF;
 SELECT x.* INTO b FROM public.sk_businesses x
 JOIN public.sk_business_members m ON m.business_id=x.id
 JOIN auth.users u ON u.id=m.user_id
 WHERE x.id=p_business_id AND m.user_id=auth.uid() AND m.role='owner'::public.sk_member_role
 AND u.email_confirmed_at IS NOT NULL AND x.status='Freigeschaltet' AND x.review_state='approved'
 FOR UPDATE OF x;
 IF NOT FOUND THEN
  RAISE EXCEPTION 'Keine Berechtigung fuer diesen Betrieb' USING ERRCODE='42501';
 END IF;
 IF p_field NOT IN ('company_name','vat_id','country') OR p_field IS NULL THEN
  RAISE EXCEPTION 'Ungueltiges Feld' USING ERRCODE='22023';
 END IF;
 v_new=btrim(coalesce(p_new_value,''));
 IF length(v_new) NOT BETWEEN 2 AND (CASE WHEN p_field='vat_id' THEN 64 WHEN p_field='country' THEN 2 ELSE 160 END) THEN
  RAISE EXCEPTION 'Ungueltiger neuer Wert' USING ERRCODE='22023';
 END IF;
 IF p_field='country' AND v_new NOT IN ('CH','DE','AT') THEN
  RAISE EXCEPTION 'Ungueltiges Land' USING ERRCODE='22023';
 END IF;
 v_old:=CASE p_field WHEN 'company_name' THEN b.company_name WHEN 'vat_id' THEN b.vat_id ELSE b.country::text END;
 IF v_old=v_new THEN RAISE EXCEPTION 'Keine Aenderung' USING ERRCODE='22023'; END IF;
 INSERT INTO sk_internal.business_change_requests(business_id,requested_by,field,old_value,new_value)
 VALUES(b.id,auth.uid(),p_field,v_old,v_new);
 INSERT INTO sk_internal.admin_events(business_id,kind,title,detail)
 VALUES(b.id,'change_requested','Pruefpflichtige Profilaenderung',p_field||': '||coalesce(v_old,'')||' -> '||v_new);
END $fn$;
REVOKE ALL ON FUNCTION public.sk_request_business_sensitive_change_by_id(uuid,text,text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.sk_request_business_sensitive_change_by_id(uuid,text,text) TO authenticated;
COMMIT;
SELECT p.proname AS funktion, p.prosecdef AS security_definer,
 has_function_privilege('authenticated',p.oid,'EXECUTE') AS authenticated_execute,
 has_function_privilege('anon',p.oid,'EXECUTE') AS anon_execute
FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname='public' AND p.proname='sk_request_business_sensitive_change_by_id';
