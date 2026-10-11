-- StaffKeeping 0.33.1 consolidated: includes 0.33.0; do NOT additionally run the older 0.33.0 migration.
-- Multiple DDL / RPC operations in ONE transaction, ONE final verification SELECT.
-- StaffKeeping 0.33.0 – additive foundation for multiple businesses/users.
-- IMPORTANT: no existing auth user, membership, listing, approval, subscription or RLS policy is changed.
-- Only Annette decides account/business grouping and subscription eligibility.
-- One transaction, then ONE final verification SELECT. Run as Supabase migration owner.
BEGIN;
CREATE SCHEMA IF NOT EXISTS sk_internal;
CREATE TABLE IF NOT EXISTS sk_internal.customer_accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  label text NOT NULL CHECK (length(btrim(label)) BETWEEN 1 AND 160),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS sk_internal.customer_account_businesses (
  business_id uuid PRIMARY KEY REFERENCES public.sk_businesses(id) ON DELETE CASCADE,
  account_id uuid NOT NULL REFERENCES sk_internal.customer_accounts(id) ON DELETE RESTRICT,
  assignment_source text NOT NULL DEFAULT 'initial_single_business'
    CHECK (assignment_source IN ('initial_single_business','new_registration','annette_confirmed')),
  assigned_at timestamptz NOT NULL DEFAULT now(),
  assigned_by uuid REFERENCES auth.users(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS sk_account_businesses_account_idx
  ON sk_internal.customer_account_businesses(account_id);
-- Permissions registry is preparatory only: not yet used by listing or chat RLS.
-- Membership (not an account link) will determine access in subsequent releases.
CREATE TABLE IF NOT EXISTS sk_internal.business_member_grants (
  business_id uuid NOT NULL REFERENCES public.sk_businesses(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  business_manager boolean NOT NULL DEFAULT false,
  can_manage_listings boolean NOT NULL DEFAULT false,
  can_chat boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (business_id,user_id)
);
-- Existing business memberships retain their current effective permissions.
-- The new grants are NOT enforced yet; backfill only to prepare migration.
INSERT INTO sk_internal.business_member_grants
  (business_id,user_id,business_manager,can_manage_listings,can_chat)
SELECT m.business_id,m.user_id,true,true,true
FROM public.sk_business_members m
JOIN auth.users u ON u.id=m.user_id
JOIN public.sk_businesses b ON b.id=m.business_id
ON CONFLICT (business_id,user_id) DO NOTHING;
-- Each existing business starts in its OWN account. No automatic merging by address/email/name.
INSERT INTO sk_internal.customer_accounts (id,label)
SELECT b.id,'Kundenkonto · ' || coalesce(nullif(btrim(b.company_name),''),b.id::text)
FROM public.sk_businesses b
WHERE NOT EXISTS (
  SELECT 1 FROM sk_internal.customer_account_businesses ab WHERE ab.business_id=b.id
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO sk_internal.customer_account_businesses (business_id,account_id,assignment_source)
SELECT b.id,b.id,'initial_single_business'
FROM public.sk_businesses b
WHERE NOT EXISTS (
  SELECT 1 FROM sk_internal.customer_account_businesses ab WHERE ab.business_id=b.id
)
ON CONFLICT (business_id) DO NOTHING;
-- Future registrations also begin as independent accounts, awaiting Annette's manual grouping.
CREATE OR REPLACE FUNCTION sk_internal.sk_initialize_customer_account()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
BEGIN
  INSERT INTO sk_internal.customer_accounts(id,label)
  VALUES(NEW.id,'Kundenkonto · ' || coalesce(nullif(btrim(NEW.company_name),''),NEW.id::text))
  ON CONFLICT(id) DO NOTHING;
  INSERT INTO sk_internal.customer_account_businesses(business_id,account_id,assignment_source)
  VALUES(NEW.id,NEW.id,'new_registration')
  ON CONFLICT(business_id) DO NOTHING;
  RETURN NEW;
END;
$fn$;
DROP TRIGGER IF EXISTS sk_initialize_customer_account ON public.sk_businesses;
CREATE TRIGGER sk_initialize_customer_account
AFTER INSERT ON public.sk_businesses FOR EACH ROW
EXECUTE FUNCTION sk_internal.sk_initialize_customer_account();
-- Administrative read-only overview, no raw database records exposed to client RLS.
CREATE OR REPLACE FUNCTION public.sk_admin_customer_account_overview()
RETURNS TABLE (account_id uuid, account_label text, business_id uuid,
  business_name text, approval_status text, review_state text, member_count bigint)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $fn$
BEGIN
  IF NOT public.sk_is_admin() THEN RAISE EXCEPTION 'Not authorized' USING ERRCODE='42501'; END IF;
  RETURN QUERY
  SELECT a.id,a.label,b.id,b.company_name::text,b.status::text,b.review_state::text,
    (SELECT count(*) FROM public.sk_business_members m WHERE m.business_id=b.id)
  FROM sk_internal.customer_account_businesses ab
  JOIN sk_internal.customer_accounts a ON a.id=ab.account_id
  JOIN public.sk_businesses b ON b.id=ab.business_id
  ORDER BY a.label,b.company_name;
END;
$fn$;
REVOKE ALL ON FUNCTION public.sk_admin_customer_account_overview() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_admin_customer_account_overview() TO authenticated;
-- Explicitly keep internal tables inaccessible via exposed schema roles.
REVOKE ALL ON sk_internal.customer_accounts,
  sk_internal.customer_account_businesses,
  sk_internal.business_member_grants FROM PUBLIC,anon,authenticated;

-- Remove legacy one-business-only membership restriction; no data deleted.
ALTER TABLE public.sk_business_members DROP CONSTRAINT IF EXISTS sk_one_business_per_user_initially;
-- Internal manual entitlements: explicitly separate from paid subscriptions.
CREATE TABLE IF NOT EXISTS sk_internal.customer_manual_access (
 account_id uuid PRIMARY KEY REFERENCES sk_internal.customer_accounts(id) ON DELETE CASCADE,
 reason text NOT NULL CHECK (length(btrim(reason)) BETWEEN 4 AND 500),
 valid_from timestamptz NOT NULL DEFAULT now(),
 valid_until date,
 revoked_at timestamptz,
 granted_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
 updated_at timestamptz NOT NULL DEFAULT now(),
 CHECK (valid_until IS NULL OR valid_until >= (valid_from AT TIME ZONE 'Europe/Zurich')::date)
);
CREATE TABLE IF NOT EXISTS sk_internal.customer_manual_access_audit (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 account_id uuid NOT NULL REFERENCES sk_internal.customer_accounts(id) ON DELETE CASCADE,
 changed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
 operation text NOT NULL CHECK (operation IN ('grant','change','revoke')),
 reason text,
 valid_until date,
 occurred_at timestamptz NOT NULL DEFAULT now()
);
REVOKE ALL ON sk_internal.customer_manual_access,sk_internal.customer_manual_access_audit FROM PUBLIC,anon,authenticated;
-- The entitlement is prepared but is NOT yet applied as a restrictive market-access gate.
CREATE OR REPLACE FUNCTION public.sk_admin_set_manual_access(p_account_id uuid,p_enable boolean,p_reason text DEFAULT NULL,p_valid_until date DEFAULT NULL)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE old_enabled boolean; today_ch date;
BEGIN
 IF NOT public.sk_is_admin() THEN RAISE EXCEPTION 'Nur Administration' USING ERRCODE='42501'; END IF;
 IF NOT EXISTS (SELECT 1 FROM sk_internal.customer_accounts WHERE id=p_account_id) THEN RAISE EXCEPTION 'Kundenkonto unbekannt' USING ERRCODE='22023'; END IF;
 today_ch := (now() AT TIME ZONE 'Europe/Zurich')::date;
 IF p_enable IS NULL THEN RAISE EXCEPTION 'Entscheidung fehlt' USING ERRCODE='22023'; END IF;
 IF p_enable THEN
   IF length(btrim(coalesce(p_reason,''))) < 4 THEN RAISE EXCEPTION 'Grund erforderlich (min. 4 Zeichen)' USING ERRCODE='22023'; END IF;
   IF p_valid_until IS NOT NULL AND p_valid_until < today_ch THEN RAISE EXCEPTION 'Ablauf liegt in der Vergangenheit' USING ERRCODE='22023'; END IF;
   SELECT revoked_at IS NULL INTO old_enabled FROM sk_internal.customer_manual_access WHERE account_id=p_account_id;
   INSERT INTO sk_internal.customer_manual_access(account_id,reason,valid_from,valid_until,revoked_at,granted_by)
   VALUES(p_account_id,btrim(p_reason),now(),p_valid_until,NULL,auth.uid())
   ON CONFLICT(account_id) DO UPDATE SET reason=EXCLUDED.reason,valid_from=now(),valid_until=EXCLUDED.valid_until,revoked_at=NULL,granted_by=auth.uid(),updated_at=now();
 ELSE
   IF NOT EXISTS (SELECT 1 FROM sk_internal.customer_manual_access WHERE account_id=p_account_id AND revoked_at IS NULL) THEN RETURN; END IF;
   UPDATE sk_internal.customer_manual_access SET revoked_at=now(),updated_at=now() WHERE account_id=p_account_id;
 END IF;
 INSERT INTO sk_internal.customer_manual_access_audit(account_id,changed_by,operation,reason,valid_until)
 VALUES(p_account_id,auth.uid(),CASE WHEN p_enable THEN CASE WHEN old_enabled THEN 'change' ELSE 'grant' END ELSE 'revoke' END,
 CASE WHEN p_enable THEN btrim(p_reason) ELSE NULL END,p_valid_until);
END;$fn$;
REVOKE ALL ON FUNCTION public.sk_admin_set_manual_access(uuid,boolean,text,date) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_admin_set_manual_access(uuid,boolean,text,date) TO authenticated;
CREATE OR REPLACE FUNCTION public.sk_admin_manual_access_overview()
RETURNS TABLE(account_id uuid,account_label text,manual_active boolean,reason text,valid_until date,revoked_at timestamptz)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $fn$
BEGIN
 IF NOT public.sk_is_admin() THEN RAISE EXCEPTION 'Nur Administration' USING ERRCODE='42501'; END IF;
 RETURN QUERY SELECT a.id,a.label,
  coalesce(m.revoked_at IS NULL AND (m.valid_until IS NULL OR m.valid_until >= (now() AT TIME ZONE 'Europe/Zurich')::date),false),
  m.reason,m.valid_until,m.revoked_at
 FROM sk_internal.customer_accounts a LEFT JOIN sk_internal.customer_manual_access m ON m.account_id=a.id
 ORDER BY a.label;
END;$fn$;
REVOKE ALL ON FUNCTION public.sk_admin_manual_access_overview() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_admin_manual_access_overview() TO authenticated;
-- Approved memberships own their business account; no automatic linking to current account.
CREATE OR REPLACE FUNCTION public.sk_add_business(
 p_company_name text,p_vat_id text,p_industry public.sk_industry,p_country public.sk_country,
 p_postal_code text,p_city text,p_contact_name text,p_contact_email text,p_contact_phone text,p_description text,p_terms_accepted boolean
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE v_id uuid;v_user auth.users%ROWTYPE;
BEGIN
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Anmeldung erforderlich' USING ERRCODE='42501'; END IF;
 SELECT * INTO v_user FROM auth.users WHERE id=auth.uid() AND email_confirmed_at IS NOT NULL;
 IF NOT FOUND THEN RAISE EXCEPTION 'E-Mail muss bestätigt sein' USING ERRCODE='42501'; END IF;
 IF NOT EXISTS (SELECT 1 FROM public.sk_business_members m JOIN public.sk_businesses b ON b.id=m.business_id WHERE m.user_id=auth.uid() AND m.role='owner' AND b.status='Freigeschaltet') THEN RAISE EXCEPTION 'Weitere Betriebe kann nur ein Verantwortlicher eines freigegebenen Betriebs beantragen' USING ERRCODE='42501'; END IF;
 IF p_terms_accepted IS DISTINCT FROM true THEN RAISE EXCEPTION 'Nutzungsbedingungen bestätigen' USING ERRCODE='22023'; END IF;
 IF char_length(btrim(coalesce(p_description,''))) < 30 OR char_length(btrim(coalesce(p_contact_phone,''))) < 5 THEN RAISE EXCEPTION 'Beschreibung min. 30 Zeichen und Telefonnummer erforderlich' USING ERRCODE='22023'; END IF;
 IF lower(btrim(p_contact_email)) IS DISTINCT FROM lower(v_user.email) THEN RAISE EXCEPTION 'E-Mail muss dem angemeldeten Konto entsprechen' USING ERRCODE='42501'; END IF;
 INSERT INTO public.sk_businesses(company_name,vat_id,industry,country,postal_code,city,contact_name,contact_email,contact_phone,description,terms_accepted_at,review_state,submitted_at)
 VALUES(btrim(p_company_name),btrim(p_vat_id),p_industry,p_country,btrim(p_postal_code),btrim(p_city),btrim(p_contact_name),btrim(p_contact_email),nullif(btrim(p_contact_phone),''),btrim(p_description),now(),'submitted',now()) RETURNING id INTO v_id;
 INSERT INTO public.sk_business_members(business_id,user_id,role) VALUES(v_id,auth.uid(),'owner');
 INSERT INTO sk_internal.business_member_grants(business_id,user_id,business_manager,can_manage_listings,can_chat)
 VALUES(v_id,auth.uid(),true,true,true) ON CONFLICT DO NOTHING;
 INSERT INTO sk_internal.admin_events(business_id,kind,title,detail) VALUES(v_id,'submitted','Weiterer Betrieb zur Prüfung',btrim(p_company_name));
 RETURN v_id;
END;$fn$;
REVOKE ALL ON FUNCTION public.sk_add_business(text,text,public.sk_industry,public.sk_country,text,text,text,text,text,text,boolean) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_add_business(text,text,public.sk_industry,public.sk_country,text,text,text,text,text,text,boolean) TO authenticated;
-- Rework a returned second-business application, resubmit without touching account associations.
CREATE OR REPLACE FUNCTION public.sk_resubmit_additional_business(p_business_id uuid,p_description text,p_contact_phone text,p_contact_name text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE b public.sk_businesses%ROWTYPE;
BEGIN
 SELECT x.* INTO b FROM public.sk_businesses x JOIN public.sk_business_members m ON m.business_id=x.id
 WHERE x.id=p_business_id AND m.user_id=auth.uid() AND m.role='owner' AND x.status='Ausstehend'
 AND x.review_state='changes_requested' FOR UPDATE OF x;
 IF NOT FOUND THEN RAISE EXCEPTION 'Keine Nachbesserung für diesen Betrieb offen' USING ERRCODE='42501'; END IF;
 IF length(btrim(coalesce(p_description,'')))<30 OR length(btrim(coalesce(p_contact_phone,'')))<5 OR length(btrim(coalesce(p_contact_name,'')))<2 THEN
 RAISE EXCEPTION 'Pflichtangaben unvollständig' USING ERRCODE='22023'; END IF;
 UPDATE public.sk_businesses SET description=btrim(p_description),contact_phone=btrim(p_contact_phone),contact_name=btrim(p_contact_name),review_state='submitted',submitted_at=now(),review_message=NULL,updated_at=now() WHERE id=p_business_id;
 INSERT INTO sk_internal.admin_events(business_id,kind,title,detail) VALUES(p_business_id,'submitted','Nachbesserung erneut eingereicht',b.company_name);
END;$fn$;
REVOKE ALL ON FUNCTION public.sk_resubmit_additional_business(uuid,text,text,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_resubmit_additional_business(uuid,text,text,text) TO authenticated;
-- An individual user can see their own membership's businesses via existing RLS.
-- Payment integration and cross-account merges are intentionally not enabled.

COMMIT;
SELECT (SELECT count(*) FROM public.sk_businesses) businesses,(SELECT count(*) FROM sk_internal.customer_account_businesses) assigned_businesses,(SELECT count(*) FROM sk_internal.customer_manual_access) manual_access_records,(SELECT count(*) FROM pg_constraint WHERE conname='sk_one_business_per_user_initially') obsolete_unique_constraint_remaining;
