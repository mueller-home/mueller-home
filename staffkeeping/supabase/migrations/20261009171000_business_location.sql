-- StaffKeeping 0.29 – optionaler Strassenstandort und geschützte Koordinaten
-- Nach Profil-Migration 0.25 ausführen; eine Transaktion, keine SELECT-Resultsets.
BEGIN;
ALTER TABLE public.sk_businesses
 ADD COLUMN IF NOT EXISTS street text,
 ADD COLUMN IF NOT EXISTS house_number text,
 ADD COLUMN IF NOT EXISTS address_extra text,
 ADD COLUMN IF NOT EXISTS show_street_address boolean NOT NULL DEFAULT false,
 ADD COLUMN IF NOT EXISTS latitude double precision,
 ADD COLUMN IF NOT EXISTS longitude double precision,
 ADD COLUMN IF NOT EXISTS location_source text,
 ADD COLUMN IF NOT EXISTS location_address_key text,
 ADD COLUMN IF NOT EXISTS location_updated_at timestamptz;
ALTER TABLE public.sk_businesses
 ADD CONSTRAINT sk_location_lat CHECK(latitude IS NULL OR latitude BETWEEN -90 AND 90),
 ADD CONSTRAINT sk_location_lng CHECK(longitude IS NULL OR longitude BETWEEN -180 AND 180),
 ADD CONSTRAINT sk_location_pair CHECK ((latitude IS NULL)=(longitude IS NULL)),
 ADD CONSTRAINT sk_location_source CHECK (location_source IS NULL OR location_source IN ('geocoded','manual')),
 ADD CONSTRAINT sk_address_lengths CHECK (char_length(coalesce(street,''))<=180 AND char_length(coalesce(house_number,''))<=24 AND char_length(coalesce(address_extra,''))<=180);

-- Genau die bestehende RPC-Signatur ersetzen, mit drei neuen optionalen Feldern als
-- zusätzliche Argumente: alte Funktion bleibt als Wrapper für bestehende Clients.
CREATE OR REPLACE FUNCTION public.sk_update_my_business_profile(
 p_company_name text,p_industry public.sk_industry,p_postal_code text,p_city text,
 p_contact_name text,p_contact_email text,p_contact_phone text,p_description text,
 p_email_notifications_enabled boolean,
 p_street text,p_house_number text,p_address_extra text,p_show_street_address boolean
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE v_id uuid;
BEGIN
 SELECT b.id INTO v_id FROM public.sk_businesses b
 JOIN public.sk_business_members m ON m.business_id=b.id
 JOIN auth.users u ON u.id=m.user_id
 WHERE m.user_id=auth.uid() AND m.role='owner'::public.sk_member_role
 AND u.email_confirmed_at IS NOT NULL AND b.status='Freigeschaltet'::public.sk_business_status;
 IF v_id IS NULL THEN RAISE EXCEPTION 'Profiländerung nicht erlaubt' USING ERRCODE='42501'; END IF;
 IF p_company_name IS NULL OR char_length(btrim(p_company_name)) NOT BETWEEN 2 AND 160
 OR p_industry IS NULL OR p_postal_code IS NULL OR char_length(btrim(p_postal_code)) NOT BETWEEN 2 AND 16
 OR p_city IS NULL OR char_length(btrim(p_city)) NOT BETWEEN 2 AND 120
 OR p_contact_name IS NULL OR char_length(btrim(p_contact_name)) NOT BETWEEN 2 AND 160
 OR p_contact_email IS NULL OR char_length(btrim(p_contact_email)) NOT BETWEEN 3 AND 254
 OR p_description IS NULL OR char_length(p_description)>1000 OR p_email_notifications_enabled IS NULL
 OR char_length(coalesce(p_street,''))>180 OR char_length(coalesce(p_house_number,''))>24
 OR char_length(coalesce(p_address_extra,''))>180 OR p_show_street_address IS NULL
 THEN RAISE EXCEPTION 'Ungültige Profilangaben' USING ERRCODE='22023'; END IF;
 UPDATE public.sk_businesses SET
 company_name=btrim(p_company_name),industry=p_industry,postal_code=btrim(p_postal_code),city=btrim(p_city),
 contact_name=btrim(p_contact_name),contact_email=btrim(p_contact_email),
 contact_phone=nullif(btrim(p_contact_phone),''),description=p_description,
 email_notifications_enabled=p_email_notifications_enabled,
 street=nullif(btrim(p_street),''),house_number=nullif(btrim(p_house_number),''),
 address_extra=nullif(btrim(p_address_extra),''),show_street_address=p_show_street_address,updated_at=now()
 WHERE id=v_id;
END;$$;
-- Alten RPC nicht für spätere Profilupdates offenhalten; neue Benutzer benötigen nur neue Signatur.
REVOKE ALL ON FUNCTION public.sk_update_my_business_profile(text,public.sk_industry,text,text,text,text,text,text,boolean) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.sk_update_my_business_profile(text,public.sk_industry,text,text,text,text,text,text,boolean,text,text,text,boolean) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_update_my_business_profile(text,public.sk_industry,text,text,text,text,text,text,boolean,text,text,text,boolean) TO authenticated;

CREATE OR REPLACE FUNCTION public.sk_set_my_business_location(
 p_latitude double precision,p_longitude double precision,p_source text,p_address_key text
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE v_business public.sk_businesses%ROWTYPE; v_key text;
BEGIN
 SELECT b.* INTO v_business FROM public.sk_businesses b
 JOIN public.sk_business_members m ON m.business_id=b.id
 JOIN auth.users u ON u.id=m.user_id
 WHERE m.user_id=auth.uid() AND m.role='owner'::public.sk_member_role
 AND u.email_confirmed_at IS NOT NULL AND b.status='Freigeschaltet'::public.sk_business_status
 FOR UPDATE OF b;
 IF NOT FOUND THEN RAISE EXCEPTION 'Standortänderung nicht erlaubt' USING ERRCODE='42501'; END IF;
 v_key:=lower(trim(coalesce(v_business.country::text,'')))||'|'||lower(trim(coalesce(v_business.postal_code,'')))||'|'||lower(trim(coalesce(v_business.city,'')))||'|'||lower(trim(coalesce(v_business.street,'')))||'|'||lower(trim(coalesce(v_business.house_number,'')));
 IF p_address_key IS DISTINCT FROM v_key THEN RAISE EXCEPTION 'Adresse wurde geändert; Standort erneut ermitteln' USING ERRCODE='40001'; END IF;
 IF p_source='reset' THEN
  UPDATE public.sk_businesses SET latitude=NULL,longitude=NULL,location_source=NULL,location_address_key=NULL,location_updated_at=now() WHERE id=v_business.id;
  RETURN;
 END IF;
 IF p_source NOT IN ('geocoded','manual') OR p_latitude IS NULL OR p_longitude IS NULL
 OR NOT (p_latitude BETWEEN -90 AND 90) OR NOT (p_longitude BETWEEN -180 AND 180)
 THEN RAISE EXCEPTION 'Ungültige Koordinaten' USING ERRCODE='22023'; END IF;
 IF p_source='geocoded' AND v_business.location_source='manual' THEN
  RAISE EXCEPTION 'Manuell bestätigter Standort darf nicht überschrieben werden' USING ERRCODE='42501';
 END IF;
 UPDATE public.sk_businesses SET latitude=p_latitude,longitude=p_longitude,
 location_source=p_source,location_address_key=v_key,location_updated_at=now() WHERE id=v_business.id;
END;$$;
REVOKE ALL ON FUNCTION public.sk_set_my_business_location(double precision,double precision,text,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_set_my_business_location(double precision,double precision,text,text) TO authenticated;
COMMIT;
