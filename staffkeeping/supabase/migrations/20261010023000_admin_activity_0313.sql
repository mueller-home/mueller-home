-- StaffKeeping 0.31.3 – Admin-Dashboard: Nur Informationsmeldungen gesammelt quittieren.
-- Die bestehenden Tabellen werden nicht verändert. Mehrere Statements in einer Transaktion;
-- keine separaten SELECT-Resultsets.
BEGIN;
-- Nur wirklich protokollierte historische Freigaben werden zurückdatiert.
UPDATE public.sk_businesses b
SET reviewed_at=a.first_approval
FROM (SELECT business_id,min(changed_at) AS first_approval
      FROM sk_internal.business_status_audit
      WHERE new_status='Freigeschaltet'
      GROUP BY business_id) a
WHERE b.id=a.business_id AND b.review_state='approved' AND b.reviewed_at IS NULL;
CREATE OR REPLACE FUNCTION public.sk_admin_activity() RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $fn$
DECLARE result jsonb;
BEGIN
 IF NOT public.sk_is_admin() THEN RAISE EXCEPTION 'Nur Administratoren' USING ERRCODE='42501'; END IF;
 SELECT jsonb_build_object(
  'open_count',(SELECT count(*) FROM sk_internal.admin_events WHERE resolved_at IS NULL AND kind IN ('profile_changed','location_changed','media_changed')),
  'pending_businesses',(SELECT count(*) FROM public.sk_businesses WHERE status='Ausstehend' AND review_state='submitted'),
  'pending_changes',(SELECT count(*) FROM sk_internal.business_change_requests WHERE status='pending'),
  'events',coalesce((SELECT jsonb_agg(to_jsonb(e) ORDER BY e.created_at DESC) FROM
    (SELECT a.id,a.business_id,a.kind,a.title,a.detail,a.created_at,a.resolved_at,
      b.company_name AS business_name,(b.id IS NOT NULL) AS business_exists
     FROM sk_internal.admin_events a LEFT JOIN public.sk_businesses b ON b.id=a.business_id
     ORDER BY a.created_at DESC LIMIT 100)e),'[]'::jsonb),
  'changes',coalesce((SELECT jsonb_agg(to_jsonb(r) ORDER BY r.created_at DESC) FROM
    (SELECT c.id,c.business_id,c.field,c.old_value,c.new_value,c.created_at,b.company_name AS business_name
     FROM sk_internal.business_change_requests c LEFT JOIN public.sk_businesses b ON b.id=c.business_id
     WHERE c.status='pending' ORDER BY c.created_at DESC LIMIT 100)r),'[]'::jsonb)
 ) INTO result;
 RETURN result;
END;$fn$;
CREATE OR REPLACE FUNCTION public.sk_admin_resolve_normal_events() RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE n integer;
BEGIN
 IF NOT public.sk_is_admin() THEN RAISE EXCEPTION 'Nur Administratoren' USING ERRCODE='42501'; END IF;
 UPDATE sk_internal.admin_events
 SET resolved_at=now(),resolved_by=auth.uid()
 WHERE resolved_at IS NULL AND kind IN ('profile_changed','location_changed','media_changed');
 GET DIAGNOSTICS n=ROW_COUNT;
 RETURN n;
END;$fn$;
-- Auch die Einzelaktion darf Prüfaufträge nicht als erledigt markieren.
CREATE OR REPLACE FUNCTION public.sk_admin_resolve_event(p_event_id bigint) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
BEGIN
 IF NOT public.sk_is_admin() THEN RAISE EXCEPTION 'Nur Administratoren' USING ERRCODE='42501'; END IF;
 UPDATE sk_internal.admin_events SET resolved_at=now(),resolved_by=auth.uid()
 WHERE id=p_event_id AND resolved_at IS NULL AND kind IN ('profile_changed','location_changed','media_changed');
END;$fn$;
REVOKE ALL ON FUNCTION public.sk_admin_resolve_normal_events() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_admin_resolve_normal_events() TO authenticated;
COMMIT;
