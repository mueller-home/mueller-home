-- StaffKeeping 0.33.1.4 – gemeinsames Speichern von Betriebsprofil und Standort.
-- Eine Transaktion; mehrere DDL-/DCL-Anweisungen, EIN abschliessender Kontroll-SELECT.
-- Vorbedingung: 0.33.1.3 sk_update_business_by_id und bestehende location-Spalten.
BEGIN;
CREATE OR REPLACE FUNCTION public.sk_update_business_with_location(
 p_profile jsonb,p_latitude double precision DEFAULT NULL,p_longitude double precision DEFAULT NULL,
 p_source text DEFAULT NULL,p_address_key text DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE v_id uuid;v_business public.sk_businesses%ROWTYPE;v_key text;
BEGIN
 IF auth.uid() IS NULL OR p_profile IS NULL OR jsonb_typeof(p_profile) <> 'object' THEN
  RAISE EXCEPTION 'Anmeldung und gültige Profildaten erforderlich.' USING ERRCODE='42501';
 END IF;
 v_id:=(p_profile->>'p_business_id')::uuid;
 -- Die bisherige, bereits getestete Eigentümer-/Freigabe-/Nachbesserungsprüfung
 -- bleibt für alle Profilfelder massgebend; bei Fehler wird die gesamte Transaktion zurückgerollt.
 PERFORM public.sk_update_business_by_id(
  v_id,p_profile->>'p_company_name',p_profile->>'p_vat_id',
  (p_profile->>'p_industry')::public.sk_industry,(p_profile->>'p_country')::public.sk_country,
  p_profile->>'p_postal_code',p_profile->>'p_city',p_profile->>'p_street',
  p_profile->>'p_house_number',p_profile->>'p_address_extra',
  p_profile->>'p_contact_name',p_profile->>'p_contact_email',
  p_profile->>'p_contact_phone',p_profile->>'p_description'
 );
 IF p_latitude IS NULL AND p_longitude IS NULL THEN RETURN; END IF;
 IF p_latitude IS NULL OR p_longitude IS NULL OR p_source IS NULL OR p_source NOT IN ('geocoded','manual')
 OR NOT (p_latitude BETWEEN -90 AND 90) OR NOT (p_longitude BETWEEN -180 AND 180)

 THEN RAISE EXCEPTION 'Ungültige Standortkoordinaten.' USING ERRCODE='22023'; END IF;
 SELECT b.* INTO v_business FROM public.sk_businesses b
 JOIN public.sk_business_members m ON m.business_id=b.id
 JOIN auth.users u ON u.id=m.user_id
 WHERE b.id=v_id AND m.user_id=auth.uid()
 AND m.role='owner'::public.sk_member_role AND u.email_confirmed_at IS NOT NULL
 FOR UPDATE OF b;
 IF NOT FOUND THEN RAISE EXCEPTION 'Keine Berechtigung für diesen Standort.' USING ERRCODE='42501'; END IF;
 v_key:=lower(btrim(coalesce(v_business.country::text,'')))||'|'||lower(btrim(coalesce(v_business.postal_code,'')))||'|'||lower(btrim(coalesce(v_business.city,'')))||'|'||lower(btrim(coalesce(v_business.street,'')))||'|'||lower(btrim(coalesce(v_business.house_number,'')));
 IF p_address_key IS DISTINCT FROM v_key THEN
  RAISE EXCEPTION 'Adresse und Kartenstandort stimmen nicht überein; bitte neu ermitteln.' USING ERRCODE='22023';
 END IF;
 UPDATE public.sk_businesses SET latitude=p_latitude,longitude=p_longitude,
  location_source=p_source,location_address_key=v_key,location_updated_at=now()
 WHERE id=v_id;
END;
$fn$;
REVOKE ALL ON FUNCTION public.sk_update_business_with_location(jsonb,double precision,double precision,text,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_update_business_with_location(jsonb,double precision,double precision,text,text) TO authenticated;
COMMIT;
SELECT p.proname AS funktion,p.prosecdef AS security_definer,
 has_function_privilege('authenticated',p.oid,'EXECUTE') AS authenticated_execute
FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname='public' AND p.proname='sk_update_business_with_location';
