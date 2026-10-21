-- StaffKeeping 0.33.1.8.1: Standort-Speicherung mit expliziter Betriebs-ID.
-- DDL/DCL in einer Transaktion; EIN abschliessender Kontroll-SELECT.
-- Die bisherige RPC bleibt vorübergehend bestehen (Rollback-Kompatibilität).
BEGIN;
CREATE OR REPLACE FUNCTION public.sk_set_business_location_by_id(
 p_business_id uuid,
 p_latitude double precision,
 p_longitude double precision,
 p_source text,
 p_address_key text
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE b public.sk_businesses%ROWTYPE; v_key text;
BEGIN
 IF auth.uid() IS NULL OR p_business_id IS NULL THEN
   RAISE EXCEPTION 'Betrieb und Anmeldung erforderlich' USING ERRCODE='42501';
 END IF;
 SELECT x.* INTO b
 FROM public.sk_businesses x
 JOIN public.sk_business_members m ON m.business_id=x.id
 JOIN auth.users u ON u.id=m.user_id
 WHERE x.id=p_business_id
   AND m.user_id=auth.uid()
   AND m.role='owner'::public.sk_member_role
   AND u.email_confirmed_at IS NOT NULL
   AND x.status IN ('Ausstehend','Freigeschaltet')
   AND (x.status='Freigeschaltet' OR x.review_state IN ('draft','changes_requested'))
 FOR UPDATE OF x;
 IF NOT FOUND THEN
   RAISE EXCEPTION 'Keine Berechtigung oder Standort zur Pruefung gesperrt' USING ERRCODE='42501';
 END IF;
 v_key:=lower(btrim(coalesce(b.country::text,'')))||'|'||lower(btrim(coalesce(b.postal_code,'')))||'|'||lower(btrim(coalesce(b.city,'')))||'|'||lower(btrim(coalesce(b.street,'')))||'|'||lower(btrim(coalesce(b.house_number,'')));
 IF p_address_key IS DISTINCT FROM v_key THEN
   RAISE EXCEPTION 'Adresse inzwischen geaendert; Standort bitte erneut ermitteln' USING ERRCODE='22023';
 END IF;
 IF p_source='reset' THEN
   UPDATE public.sk_businesses SET latitude=NULL,longitude=NULL,location_source=NULL,
     location_address_key=NULL,location_updated_at=now() WHERE id=p_business_id;
   RETURN;
 END IF;
 IF p_source NOT IN ('geocoded','manual')
    OR p_latitude IS NULL OR p_longitude IS NULL
    OR NOT (p_latitude BETWEEN -90 AND 90)
    OR NOT (p_longitude BETWEEN -180 AND 180) THEN
   RAISE EXCEPTION 'Ungueltige Standortkoordinaten' USING ERRCODE='22023';
 END IF;
 IF p_source='geocoded' AND b.location_source='manual' THEN
   RAISE EXCEPTION 'Manuell bestaetigte Position bleibt geschuetzt' USING ERRCODE='42501';
 END IF;
 UPDATE public.sk_businesses
 SET latitude=p_latitude,longitude=p_longitude,location_source=p_source,
     location_address_key=v_key,location_updated_at=now()
 WHERE id=p_business_id;
END;
$fn$;
REVOKE ALL ON FUNCTION public.sk_set_business_location_by_id(uuid,double precision,double precision,text,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_set_business_location_by_id(uuid,double precision,double precision,text,text) TO authenticated;
-- Alte RPC fuer bestehende Clients kompatibel halten, aber bei mehr als einem
-- zugeordneten Betrieb fail-closed: nie einen zufaelligen Betrieb waehlen.
CREATE OR REPLACE FUNCTION public.sk_set_my_business_location(
 p_latitude double precision,p_longitude double precision,p_source text,p_address_key text
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $legacy$
DECLARE v_business uuid; v_count integer;
BEGIN
 SELECT count(*),min(m.business_id) INTO v_count,v_business
 FROM public.sk_business_members m
 WHERE m.user_id=auth.uid() AND m.role='owner'::public.sk_member_role;
 IF v_count<>1 OR v_business IS NULL THEN
   RAISE EXCEPTION 'Bitte Betriebsstandort im eindeutig ausgewählten Betriebsprofil bearbeiten' USING ERRCODE='42501';
 END IF;
 PERFORM public.sk_set_business_location_by_id(
   v_business,p_latitude,p_longitude,p_source,p_address_key
 );
END;
$legacy$;
REVOKE ALL ON FUNCTION public.sk_set_my_business_location(double precision,double precision,text,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_set_my_business_location(double precision,double precision,text,text) TO authenticated;
COMMIT;
SELECT p.proname AS funktion,p.prosecdef AS security_definer,
 has_function_privilege('authenticated',p.oid,'EXECUTE') AS authenticated_execute,
 has_function_privilege('anon',p.oid,'EXECUTE') AS anon_execute
FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname='public' AND p.proname='sk_set_business_location_by_id';
