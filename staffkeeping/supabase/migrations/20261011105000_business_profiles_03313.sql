-- StaffKeeping 0.33.1.3: eindeutig betriebsbezogene Profilbearbeitung.
-- Eine Transaktion, CREATE FUNCTION / REVOKE / GRANT, ein abschliessendes Resultset.
-- Vorbedingungen: Migration 0.33.1, Standort-Spalten seit 0.29.
BEGIN;
CREATE OR REPLACE FUNCTION public.sk_update_business_by_id(
  p_business_id uuid,
  p_company_name text,
  p_vat_id text,
  p_industry public.sk_industry,
  p_country public.sk_country,
  p_postal_code text,
  p_city text,
  p_street text,
  p_house_number text,
  p_address_extra text,
  p_contact_name text,
  p_contact_email text,
  p_contact_phone text,
  p_description text
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $fn$
DECLARE
 b public.sk_businesses%ROWTYPE;
 u auth.users%ROWTYPE;
 v_rework boolean;
 v_address_changed boolean;
BEGIN
 IF auth.uid() IS NULL THEN
   RAISE EXCEPTION 'Bitte anmelden.' USING ERRCODE='42501';
 END IF;
 SELECT * INTO u FROM auth.users WHERE id=auth.uid() AND email_confirmed_at IS NOT NULL;
 IF NOT FOUND THEN
   RAISE EXCEPTION 'Bestätigtes Konto erforderlich.' USING ERRCODE='42501';
 END IF;
 SELECT x.* INTO b
 FROM public.sk_businesses x
 JOIN public.sk_business_members m ON m.business_id=x.id
 WHERE x.id=p_business_id AND m.user_id=auth.uid() AND m.role='owner'::public.sk_member_role
 FOR UPDATE OF x;
 IF NOT FOUND THEN
   RAISE EXCEPTION 'Keine Berechtigung für diesen Betrieb.' USING ERRCODE='42501';
 END IF;
 v_rework := b.status='Ausstehend' AND b.review_state='changes_requested';
 IF NOT v_rework AND b.status IS DISTINCT FROM 'Freigeschaltet'::public.sk_business_status THEN
   RAISE EXCEPTION 'Betrieb ist während der Prüfung oder Sperre nicht bearbeitbar.' USING ERRCODE='42501';
 END IF;
 IF p_industry IS NULL OR p_country IS NULL
  OR length(btrim(coalesce(p_company_name,''))) NOT BETWEEN 2 AND 160
  OR length(btrim(coalesce(p_vat_id,''))) NOT BETWEEN 2 AND 64
  OR length(btrim(coalesce(p_postal_code,''))) NOT BETWEEN 2 AND 16
  OR length(btrim(coalesce(p_city,''))) NOT BETWEEN 2 AND 120
  OR length(btrim(coalesce(p_contact_name,''))) NOT BETWEEN 2 AND 160
  OR length(btrim(coalesce(p_contact_email,''))) NOT BETWEEN 3 AND 254
  OR length(btrim(coalesce(p_contact_phone,''))) NOT BETWEEN 5 AND 60
  OR length(btrim(coalesce(p_description,''))) NOT BETWEEN 30 AND 1000
  OR length(coalesce(p_street,'')) > 180
  OR length(coalesce(p_house_number,'')) > 24
  OR length(coalesce(p_address_extra,'')) > 180 THEN
   RAISE EXCEPTION 'Bitte alle Pflichtfelder vollständig ausfüllen (Beschreibung mindestens 30 Zeichen).' USING ERRCODE='22023';
 END IF;
 IF b.status='Freigeschaltet' AND (
   p_company_name IS DISTINCT FROM b.company_name
   OR p_vat_id IS DISTINCT FROM b.vat_id
   OR p_country IS DISTINCT FROM b.country
 ) THEN
   RAISE EXCEPTION 'Firmenname, UID und Land können bei freigegebenen Betrieben nur über den bestehenden Admin-Änderungsprozess geändert werden.' USING ERRCODE='42501';
 END IF;
 v_address_changed := (b.country IS DISTINCT FROM p_country OR b.postal_code IS DISTINCT FROM btrim(p_postal_code)
   OR b.city IS DISTINCT FROM btrim(p_city) OR b.street IS DISTINCT FROM nullif(btrim(coalesce(p_street,'')),'')
   OR b.house_number IS DISTINCT FROM nullif(btrim(coalesce(p_house_number,'')),''));
 UPDATE public.sk_businesses SET
   company_name=CASE WHEN v_rework THEN btrim(p_company_name) ELSE company_name END,
   vat_id=CASE WHEN v_rework THEN btrim(p_vat_id) ELSE vat_id END,
   industry=p_industry,
   country=CASE WHEN v_rework THEN p_country ELSE country END,
   postal_code=btrim(p_postal_code),city=btrim(p_city),
   street=nullif(btrim(coalesce(p_street,'')),''),
   house_number=nullif(btrim(coalesce(p_house_number,'')),''),
   address_extra=nullif(btrim(coalesce(p_address_extra,'')),''),
   contact_name=btrim(p_contact_name),contact_email=btrim(p_contact_email),
   contact_phone=btrim(p_contact_phone),description=btrim(p_description),
   latitude=CASE WHEN v_address_changed THEN NULL ELSE latitude END,
   longitude=CASE WHEN v_address_changed THEN NULL ELSE longitude END,
   location_source=CASE WHEN v_address_changed THEN NULL ELSE location_source END,
   location_address_key=CASE WHEN v_address_changed THEN NULL ELSE location_address_key END,
   location_updated_at=CASE WHEN v_address_changed THEN now() ELSE location_updated_at END,
   review_state=CASE WHEN v_rework THEN 'submitted' ELSE review_state END,
   submitted_at=CASE WHEN v_rework THEN now() ELSE submitted_at END,
   review_message=CASE WHEN v_rework THEN NULL ELSE review_message END,
   updated_at=now()
 WHERE id=p_business_id;
 IF v_rework THEN
   INSERT INTO sk_internal.admin_events(business_id,kind,title,detail)
   VALUES(p_business_id,'submitted','Nachbesserung erneut eingereicht',b.company_name);
 END IF;
END;
$fn$;
REVOKE ALL ON FUNCTION public.sk_update_business_by_id(uuid,text,text,public.sk_industry,public.sk_country,text,text,text,text,text,text,text,text,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_update_business_by_id(uuid,text,text,public.sk_industry,public.sk_country,text,text,text,text,text,text,text,text,text) TO authenticated;
COMMIT;
SELECT p.proname AS funktion, p.prosecdef AS security_definer,
       has_function_privilege('authenticated',p.oid,'EXECUTE') AS authenticated_execute
FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname='public' AND p.proname='sk_update_business_by_id';
