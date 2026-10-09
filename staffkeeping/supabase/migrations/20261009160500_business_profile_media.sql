-- StaffKeeping 0.25 · Profil, Benachrichtigungsvorliebe und private Betriebsmedien
-- NACH 0.19 (Auth) und 0.24 (Admin-Details) genau einmal ausführen.
-- Eine Transaktion mit mehreren DDL-/DCL-Anweisungen, KEINE separaten SELECT-Resultsets.
-- Keine Migration bestehender Bubble-Daten; bestehende StaffKeeping-Betriebe bleiben erhalten.
BEGIN;
ALTER TABLE public.sk_businesses
  ADD COLUMN description text NOT NULL DEFAULT '' CHECK (char_length(description) <= 1000),
  ADD COLUMN email_notifications_enabled boolean NOT NULL DEFAULT true;

-- Private Buckets; allein Authentifizierung genügt NICHT: Storage-Policies unten.
INSERT INTO storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
VALUES ('sk-business-logos','sk-business-logos',false,2097152,ARRAY['image/jpeg','image/png','image/webp']),
       ('sk-business-photos','sk-business-photos',false,5242880,ARRAY['image/jpeg','image/png','image/webp']);

-- Nur angemeldete, bestätigte OWNER einer freigeschalteten Firma können Profil bearbeiten.
-- Rückgabe der eigenen Daten auch bei Ausstehend erlaubt (z.B. nach Registrierung).
CREATE FUNCTION public.sk_get_my_business_profile()
RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT jsonb_build_object('business', to_jsonb(b),'role',m.role,'login_email',u.email)
  FROM public.sk_business_members m
  JOIN public.sk_businesses b ON b.id=m.business_id
  JOIN auth.users u ON u.id=m.user_id
  WHERE m.user_id=auth.uid() AND u.email_confirmed_at IS NOT NULL
  LIMIT 1;
$$;
CREATE FUNCTION public.sk_update_my_business_profile(
 p_company_name text, p_industry public.sk_industry,
 p_postal_code text, p_city text, p_contact_name text,
 p_contact_email text, p_contact_phone text, p_description text,
 p_email_notifications_enabled boolean
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_id uuid;
BEGIN
 SELECT b.id INTO v_id
 FROM public.sk_businesses b
 JOIN public.sk_business_members m ON m.business_id=b.id
 JOIN auth.users u ON u.id=m.user_id
 WHERE m.user_id=auth.uid() AND m.role='owner'::public.sk_member_role
   AND u.email_confirmed_at IS NOT NULL AND b.status='Freigeschaltet'::public.sk_business_status;
 IF v_id IS NULL THEN RAISE EXCEPTION 'Profiländerung nur durch freigeschalteten Firmeninhaber' USING ERRCODE='42501'; END IF;
 IF p_company_name IS NULL OR char_length(btrim(p_company_name)) NOT BETWEEN 2 AND 160
 OR p_industry IS NULL OR p_postal_code IS NULL OR char_length(btrim(p_postal_code)) NOT BETWEEN 2 AND 16
 OR p_city IS NULL OR char_length(btrim(p_city)) NOT BETWEEN 2 AND 120
 OR p_contact_name IS NULL OR char_length(btrim(p_contact_name)) NOT BETWEEN 2 AND 160
 OR p_contact_email IS NULL OR char_length(btrim(p_contact_email)) NOT BETWEEN 3 AND 254
 OR p_description IS NULL OR char_length(p_description)>1000 OR p_email_notifications_enabled IS NULL THEN
   RAISE EXCEPTION 'Ungültige Profilangaben' USING ERRCODE='22023';
 END IF;
 UPDATE public.sk_businesses SET
 company_name=btrim(p_company_name),industry=p_industry,
 postal_code=btrim(p_postal_code),city=btrim(p_city),contact_name=btrim(p_contact_name),
 contact_email=btrim(p_contact_email),contact_phone=NULLIF(btrim(p_contact_phone),''),
 description=p_description,email_notifications_enabled=p_email_notifications_enabled,
 updated_at=now() WHERE id=v_id;
END;
$$;
REVOKE ALL ON FUNCTION public.sk_get_my_business_profile() FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.sk_update_my_business_profile(text,public.sk_industry,text,text,text,text,text,text,boolean) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_get_my_business_profile() TO authenticated;
GRANT EXECUTE ON FUNCTION public.sk_update_my_business_profile(text,public.sk_industry,text,text,text,text,text,text,boolean) TO authenticated;

-- Storage: strikte Slot-Namen und Firmen-ID als erstes Verzeichnis; nur bestätigte
-- freigeschaltete owner dürfen hochladen/verändern; Administratoren dürfen lesen.
-- Erlaubte Slots: logos/<uuid>/logo.jpg|png|webp; photos/<uuid>/1..5.jpg|png|webp
CREATE POLICY sk_media_read ON storage.objects FOR SELECT TO authenticated USING (
 bucket_id IN ('sk-business-logos','sk-business-photos')
 AND (public.sk_is_admin() OR EXISTS (
   SELECT 1 FROM public.sk_business_members m
   JOIN public.sk_businesses b ON b.id=m.business_id
   WHERE m.user_id=auth.uid() AND b.status='Freigeschaltet'::public.sk_business_status
    AND m.business_id::text=(storage.foldername(name))[1]
 ))
);
CREATE POLICY sk_media_insert ON storage.objects FOR INSERT TO authenticated WITH CHECK (
 (
 (bucket_id='sk-business-logos' AND name ~ '^[0-9a-f-]{36}/logo\.(png|jpg|webp)$')
 OR (bucket_id='sk-business-photos' AND name ~ '^[0-9a-f-]{36}/[1-5]\.(png|jpg|webp)$')
 ) AND EXISTS (
  SELECT 1 FROM public.sk_business_members m
  JOIN public.sk_businesses b ON b.id=m.business_id
  WHERE m.user_id=auth.uid() AND m.role='owner'::public.sk_member_role
    AND b.status='Freigeschaltet'::public.sk_business_status
    AND m.business_id::text=(storage.foldername(name))[1]
 )
);
CREATE POLICY sk_media_update ON storage.objects FOR UPDATE TO authenticated USING (
 bucket_id IN ('sk-business-logos','sk-business-photos')
 AND EXISTS (SELECT 1 FROM public.sk_business_members m JOIN public.sk_businesses b ON b.id=m.business_id
  WHERE m.user_id=auth.uid() AND m.role='owner'::public.sk_member_role
  AND b.status='Freigeschaltet'::public.sk_business_status
  AND m.business_id::text=(storage.foldername(name))[1])
) WITH CHECK (
 ((bucket_id='sk-business-logos' AND name ~ '^[0-9a-f-]{36}/logo\.(png|jpg|webp)$')
 OR (bucket_id='sk-business-photos' AND name ~ '^[0-9a-f-]{36}/[1-5]\.(png|jpg|webp)$'))
 AND EXISTS (SELECT 1 FROM public.sk_business_members m JOIN public.sk_businesses b ON b.id=m.business_id
 WHERE m.user_id=auth.uid() AND m.role='owner'::public.sk_member_role
 AND b.status='Freigeschaltet'::public.sk_business_status
 AND m.business_id::text=(storage.foldername(name))[1])
);
CREATE POLICY sk_media_delete ON storage.objects FOR DELETE TO authenticated USING (
 bucket_id IN ('sk-business-logos','sk-business-photos')
 AND EXISTS (SELECT 1 FROM public.sk_business_members m JOIN public.sk_businesses b ON b.id=m.business_id
  WHERE m.user_id=auth.uid() AND m.role='owner'::public.sk_member_role
  AND b.status='Freigeschaltet'::public.sk_business_status
  AND m.business_id::text=(storage.foldername(name))[1])
);
COMMIT;
