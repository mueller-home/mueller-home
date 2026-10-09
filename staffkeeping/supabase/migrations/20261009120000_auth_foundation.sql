-- StaffKeeping 0.19 · Basisschema für Unternehmen, Mitgliedschaft und Adminfreigabe
-- Ausführung: EINMAL über Supabase SQL Editor (gesamte Datei als ein Skript).
-- Insgesamt mehrere DDL/DCL-Anweisungen, keine SELECT-Ergebnisfenster.
-- NUR für neues leeres StaffKeeping-Projekt; nicht erneut ausführen.
-- ACHTUNG: Keine Test- oder Produktivdatenmigration; keine Admin-Bootstrap-Aktion.
-- Tabellen und Funktionen werden für die spätere Auth-Anbindung bereitgestellt.
BEGIN;

CREATE SCHEMA IF NOT EXISTS sk_internal;
REVOKE ALL ON SCHEMA sk_internal FROM PUBLIC, anon, authenticated;

CREATE TYPE public.sk_industry AS ENUM ('Hotel', 'Gastro', 'Camping');
CREATE TYPE public.sk_country AS ENUM ('CH', 'DE', 'AT');
CREATE TYPE public.sk_business_status AS ENUM ('Ausstehend', 'Freigeschaltet', 'Gesperrt');
CREATE TYPE public.sk_member_role AS ENUM ('owner', 'member');

CREATE TABLE public.sk_businesses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_name text NOT NULL CHECK (char_length(btrim(company_name)) BETWEEN 2 AND 160),
  vat_id text NOT NULL CHECK (char_length(btrim(vat_id)) BETWEEN 2 AND 64),
  industry public.sk_industry NOT NULL,
  country public.sk_country NOT NULL,
  postal_code text NOT NULL CHECK (char_length(btrim(postal_code)) BETWEEN 2 AND 16),
  city text NOT NULL CHECK (char_length(btrim(city)) BETWEEN 2 AND 120),
  contact_name text NOT NULL CHECK (char_length(btrim(contact_name)) BETWEEN 2 AND 160),
  contact_email text NOT NULL CHECK (char_length(btrim(contact_email)) BETWEEN 3 AND 254),
  contact_phone text,
  terms_accepted_at timestamptz NOT NULL,
  status public.sk_business_status NOT NULL DEFAULT 'Ausstehend',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.sk_business_members (
  business_id uuid NOT NULL REFERENCES public.sk_businesses(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role public.sk_member_role NOT NULL DEFAULT 'member',
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (business_id, user_id),
  CONSTRAINT sk_one_business_per_user_initially UNIQUE (user_id)
);

-- StaffKeeping-Systemadministratoren werden NICHT durch Benutzer oder Registrierung vergeben.
-- Nur ein privilegierter Datenbankoperator darf hier eine auth.users-ID eintragen.
CREATE TABLE sk_internal.staff_admins (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE sk_internal.business_status_audit (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  business_id uuid NOT NULL REFERENCES public.sk_businesses(id) ON DELETE CASCADE,
  changed_by uuid NOT NULL REFERENCES auth.users(id),
  old_status public.sk_business_status NOT NULL,
  new_status public.sk_business_status NOT NULL,
  changed_at timestamptz NOT NULL DEFAULT now()
);

-- Der SECURITY DEFINER liest ausschliesslich die interne Admin-Liste.
-- Keine Benutzereingaben, kein dynamisches SQL, fester search_path.
CREATE FUNCTION public.sk_is_admin() RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT auth.uid() IS NOT NULL AND EXISTS (
    SELECT 1 FROM sk_internal.staff_admins a WHERE a.user_id = auth.uid()
  );
$$;

CREATE FUNCTION public.sk_is_approved_member(p_business_id uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
  SELECT auth.uid() IS NOT NULL AND EXISTS (
    SELECT 1 FROM public.sk_business_members m
    JOIN public.sk_businesses b ON b.id = m.business_id
    WHERE m.business_id = p_business_id AND m.user_id = auth.uid()
      AND b.status = 'Freigeschaltet'::public.sk_business_status
  );
$$;

-- Registrierung erfolgt ausschliesslich über diesen RPC. Zuvor muss der Benutzer
-- über Supabase Auth angemeldet und seine E-Mail bestätigt sein.
CREATE FUNCTION public.sk_register_business(
  p_company_name text, p_vat_id text, p_industry public.sk_industry,
  p_country public.sk_country, p_postal_code text, p_city text,
  p_contact_name text, p_contact_email text, p_contact_phone text,
  p_terms_accepted boolean
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Anmeldung erforderlich' USING ERRCODE = '42501'; END IF;
  IF NOT EXISTS (SELECT 1 FROM auth.users u WHERE u.id = auth.uid() AND u.email_confirmed_at IS NOT NULL) THEN
    RAISE EXCEPTION 'E-Mail muss bestätigt sein' USING ERRCODE = '42501';
  END IF;
  IF p_terms_accepted IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'Nutzungsbedingungen bestätigen' USING ERRCODE = '22023';
  END IF;
  IF EXISTS (SELECT 1 FROM public.sk_business_members WHERE user_id = auth.uid()) THEN
    RAISE EXCEPTION 'Benutzer ist bereits einem Unternehmen zugeordnet' USING ERRCODE = '23505';
  END IF;
  INSERT INTO public.sk_businesses
    (company_name, vat_id, industry, country, postal_code, city, contact_name, contact_email, contact_phone, terms_accepted_at)
  VALUES
    (btrim(p_company_name), btrim(p_vat_id), p_industry, p_country, btrim(p_postal_code), btrim(p_city), btrim(p_contact_name), btrim(p_contact_email), NULLIF(btrim(p_contact_phone), ''), now())
  RETURNING id INTO v_id;
  INSERT INTO public.sk_business_members(business_id, user_id, role)
  VALUES (v_id, auth.uid(), 'owner');
  RETURN v_id;
END;
$$;

CREATE FUNCTION public.sk_admin_set_business_status(p_business_id uuid, p_status public.sk_business_status)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_old public.sk_business_status;
BEGIN
  IF NOT public.sk_is_admin() THEN
    RAISE EXCEPTION 'Nur Administratoren' USING ERRCODE = '42501';
  END IF;
  IF p_status IS NULL THEN RAISE EXCEPTION 'Status fehlt' USING ERRCODE = '22023'; END IF;
  SELECT status INTO v_old FROM public.sk_businesses WHERE id = p_business_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Unternehmen nicht gefunden' USING ERRCODE = '22023'; END IF;
  IF v_old IS NOT DISTINCT FROM p_status THEN RETURN; END IF;
  UPDATE public.sk_businesses SET status = p_status, updated_at = now() WHERE id = p_business_id;
  INSERT INTO sk_internal.business_status_audit(business_id, changed_by, old_status, new_status)
    VALUES (p_business_id, auth.uid(), v_old, p_status);
END;
$$;

ALTER TABLE public.sk_businesses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sk_business_members ENABLE ROW LEVEL SECURITY;
-- RLS eingeschaltet; FORCE RLS bewusst nicht gesetzt, damit die eng kontrollierten
-- SECURITY-DEFINER-Funktionen mit geeignetem Eigentümer arbeiten können.
-- Vor Ausführung Funktions-Eigentümer und BYPASSRLS-Konfiguration prüfen.

CREATE POLICY sk_business_select ON public.sk_businesses FOR SELECT TO authenticated
USING (public.sk_is_admin() OR EXISTS (
  SELECT 1 FROM public.sk_business_members m
  WHERE m.business_id = sk_businesses.id AND m.user_id = (SELECT auth.uid())
));
CREATE POLICY sk_members_select ON public.sk_business_members FOR SELECT TO authenticated
USING (public.sk_is_admin() OR user_id = (SELECT auth.uid()));
-- Kein INSERT/UPDATE/DELETE-Policy für den Browser: kein Selbst-Freischalten oder Rollenwechsel.

REVOKE ALL ON public.sk_businesses FROM PUBLIC, anon, authenticated;
REVOKE ALL ON public.sk_business_members FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.sk_businesses, public.sk_business_members TO authenticated;
REVOKE ALL ON SCHEMA sk_internal FROM PUBLIC, anon, authenticated;
REVOKE ALL ON ALL TABLES IN SCHEMA sk_internal FROM PUBLIC, anon, authenticated;
-- Default-EXECUTE für PUBLIC explizit nur für unsere vier Funktionen widerrufen.
-- Niemals pauschal bestehende Supabase-Funktionen verändern.
REVOKE ALL ON FUNCTION public.sk_is_admin() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.sk_is_approved_member(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.sk_register_business(text,text,public.sk_industry,public.sk_country,text,text,text,text,text,boolean) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.sk_admin_set_business_status(uuid,public.sk_business_status) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.sk_is_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.sk_is_approved_member(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.sk_register_business(text,text,public.sk_industry,public.sk_country,text,text,text,text,text,boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.sk_admin_set_business_status(uuid,public.sk_business_status) TO authenticated;

COMMIT;
