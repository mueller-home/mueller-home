-- StaffKeeping 0.32.1: Eigene Inserate mit dauerhafter Speicherung.
-- Ausfuehrung: 1 Transaktion mit DDL/RLS/Trigger/GRANT; abschliessend 1 SELECT als Kontrollresultat.
-- Architektur: public, weil Browserzugriff notwendig; keine anonyme Tabellenberechtigung.
BEGIN;
CREATE TABLE IF NOT EXISTS public.sk_listings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid NOT NULL REFERENCES public.sk_businesses(id) ON DELETE CASCADE,
  type text NOT NULL CHECK (type IN ('Suche','Biete')),
  category text NOT NULL CHECK (category IN ('Küche','Service','Housekeeping','Technik','Animation')),
  title text NOT NULL CHECK (char_length(btrim(title)) BETWEEN 5 AND 80),
  description text NOT NULL CHECK (char_length(btrim(description)) BETWEEN 20 AND 1000),
  date_from date NOT NULL,
  date_to date NOT NULL,
  conditions text NOT NULL DEFAULT '' CHECK (char_length(conditions) <= 500),
  accommodation boolean NOT NULL DEFAULT false,
  languages text[] NOT NULL DEFAULT '{}'::text[],
  city text NOT NULL,
  country text NOT NULL,
  status text NOT NULL DEFAULT 'Aktiv' CHECK (status IN ('Aktiv','Inaktiv')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT sk_listings_dates_ok CHECK(date_to >= date_from),
  CONSTRAINT sk_listings_languages_ok CHECK(languages <@ ARRAY['DE','FR','IT','EN','ES']::text[])
);
CREATE INDEX IF NOT EXISTS sk_listings_business_created_idx ON public.sk_listings (business_id,created_at DESC);
CREATE INDEX IF NOT EXISTS sk_listings_status_dates_idx ON public.sk_listings (status,date_from,date_to);

CREATE OR REPLACE FUNCTION public.sk_listing_enforce_profile_location()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $fn$
DECLARE v_city text; v_country text; v_status text; v_review text;
BEGIN
  -- Einfuegen/Wechsel des Betriebes nur nach serverseitiger Freigabe.
  IF TG_OP='UPDATE' AND NEW.business_id IS DISTINCT FROM OLD.business_id THEN
    RAISE EXCEPTION 'Der Inseratsbetrieb kann nicht geaendert werden';
  END IF;
  SELECT b.city,b.country,b.status,b.review_state
    INTO v_city,v_country,v_status,v_review
    FROM public.sk_businesses b WHERE b.id=NEW.business_id;
  IF NOT FOUND OR v_status IS DISTINCT FROM 'Freigeschaltet' OR v_review IS DISTINCT FROM 'approved' THEN
    RAISE EXCEPTION 'Nur freigegebene Betriebe duerfen Inserate speichern';
  END IF;
  IF nullif(btrim(v_city),'') IS NULL OR nullif(btrim(v_country),'') IS NULL THEN
    RAISE EXCEPTION 'Bitte zuerst Ort und Land im Betriebsprofil vervollstaendigen';
  END IF;
  NEW.city:=v_city;
  NEW.country:=v_country;
  NEW.updated_at:=now();
  RETURN NEW;
END;
$fn$;
DROP TRIGGER IF EXISTS sk_listings_enforce_profile_location ON public.sk_listings;
CREATE TRIGGER sk_listings_enforce_profile_location BEFORE INSERT OR UPDATE ON public.sk_listings
FOR EACH ROW EXECUTE FUNCTION public.sk_listing_enforce_profile_location();

ALTER TABLE public.sk_listings ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.sk_listings FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.sk_listings TO authenticated;
DROP POLICY IF EXISTS sk_listings_owner_select ON public.sk_listings;
CREATE POLICY sk_listings_owner_select ON public.sk_listings FOR SELECT TO authenticated USING (
  EXISTS (SELECT 1 FROM public.sk_business_members m
    WHERE m.business_id=sk_listings.business_id AND m.user_id=(SELECT auth.uid()))
);
DROP POLICY IF EXISTS sk_listings_owner_insert ON public.sk_listings;
CREATE POLICY sk_listings_owner_insert ON public.sk_listings FOR INSERT TO authenticated WITH CHECK (
  EXISTS (SELECT 1 FROM public.sk_business_members m
    WHERE m.business_id=sk_listings.business_id AND m.user_id=(SELECT auth.uid()))
  AND public.sk_is_approved_member(sk_listings.business_id)
);
DROP POLICY IF EXISTS sk_listings_owner_update ON public.sk_listings;
CREATE POLICY sk_listings_owner_update ON public.sk_listings FOR UPDATE TO authenticated
 USING (EXISTS (SELECT 1 FROM public.sk_business_members m WHERE m.business_id=sk_listings.business_id AND m.user_id=(SELECT auth.uid())) AND public.sk_is_approved_member(sk_listings.business_id))
 WITH CHECK (EXISTS (SELECT 1 FROM public.sk_business_members m WHERE m.business_id=sk_listings.business_id AND m.user_id=(SELECT auth.uid())) AND public.sk_is_approved_member(sk_listings.business_id));
DROP POLICY IF EXISTS sk_listings_owner_delete ON public.sk_listings;
CREATE POLICY sk_listings_owner_delete ON public.sk_listings FOR DELETE TO authenticated USING (
  EXISTS (SELECT 1 FROM public.sk_business_members m WHERE m.business_id=sk_listings.business_id AND m.user_id=(SELECT auth.uid()))
  AND public.sk_is_approved_member(sk_listings.business_id)
);
COMMIT;

SELECT n.nspname AS schema_name,c.relname AS table_name,c.relrowsecurity AS rls_enabled,
 (SELECT count(*) FROM pg_policies p WHERE p.schemaname='public' AND p.tablename='sk_listings') AS policy_count
FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relname='sk_listings';
