-- StaffKeeping 0.33.1.6: Neuen Betrieb und optionalen Standort atomar erstellen.
-- Mehrere SQL-Anweisungen (CREATE / REVOKE / GRANT) in EINER Transaktion;
-- abschliessend EIN Kontroll-SELECT. Supabase zeigt ggf. nur das letzte Resultset.
-- Voraussetzungen: 0.33.1 und 0.33.1.4 ausgeführt.
BEGIN;
CREATE OR REPLACE FUNCTION public.sk_add_business_with_location(
 p_company_name text,p_vat_id text,p_industry public.sk_industry,p_country public.sk_country,
 p_postal_code text,p_city text,p_contact_name text,p_contact_email text,p_contact_phone text,
 p_description text,p_terms_accepted boolean,p_street text DEFAULT NULL,p_house_number text DEFAULT NULL,
 p_latitude double precision DEFAULT NULL,p_longitude double precision DEFAULT NULL,
 p_source text DEFAULT NULL,p_address_key text DEFAULT NULL
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE v_id uuid;v_key text;
BEGIN
 -- Die vorhandene Freigabe-/Mitgliedschaftsprüfung der Neuanlage unverändert verwenden.
 v_id := public.sk_add_business(p_company_name,p_vat_id,p_industry,p_country,
   p_postal_code,p_city,p_contact_name,p_contact_email,p_contact_phone,p_description,p_terms_accepted);
 IF length(coalesce(p_street,''))>180 OR length(coalesce(p_house_number,''))>24 THEN
   RAISE EXCEPTION 'Adressfelder zu lang' USING ERRCODE='22023';
 END IF;
 UPDATE public.sk_businesses
 SET street=nullif(btrim(p_street),''),house_number=nullif(btrim(p_house_number),'')
 WHERE id=v_id;
 -- Unbekannte Positionen bleiben unbekannt, niemals alte Koordinaten übernehmen.
 IF p_latitude IS NULL AND p_longitude IS NULL AND p_source IS NULL AND p_address_key IS NULL THEN
   RETURN v_id;
 END IF;
 IF p_latitude IS NULL OR p_longitude IS NULL OR p_source NOT IN ('geocoded','manual')
   OR NOT (p_latitude BETWEEN -90 AND 90) OR NOT (p_longitude BETWEEN -180 AND 180) THEN
   RAISE EXCEPTION 'Ungültige Standortkoordinaten' USING ERRCODE='22023';
 END IF;
 v_key:=lower(btrim(coalesce(p_country::text,'')))||'|'||lower(btrim(coalesce(p_postal_code,'')))||'|'||
  lower(btrim(coalesce(p_city,'')))||'|'||lower(btrim(coalesce(p_street,'')))||'|'||
  lower(btrim(coalesce(p_house_number,'')));
 IF p_address_key IS DISTINCT FROM v_key THEN
   RAISE EXCEPTION 'Adresse und Kartenstandort stimmen nicht überein' USING ERRCODE='22023';
 END IF;
 UPDATE public.sk_businesses SET latitude=p_latitude,longitude=p_longitude,
   location_source=p_source,location_address_key=v_key,location_updated_at=now()
 WHERE id=v_id;
 RETURN v_id;
END;
$fn$;
REVOKE ALL ON FUNCTION public.sk_add_business_with_location(
 text,text,public.sk_industry,public.sk_country,text,text,text,text,text,text,boolean,
 text,text,double precision,double precision,text,text
) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_add_business_with_location(
 text,text,public.sk_industry,public.sk_country,text,text,text,text,text,text,boolean,
 text,text,double precision,double precision,text,text
) TO authenticated;
COMMIT;
SELECT p.proname AS funktion,p.prosecdef AS security_definer,
 has_function_privilege('authenticated',p.oid,'EXECUTE') AS authenticated_execute
FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname='public' AND p.proname='sk_add_business_with_location';
