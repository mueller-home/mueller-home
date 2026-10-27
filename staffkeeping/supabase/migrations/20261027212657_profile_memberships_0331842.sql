-- StaffKeeping: Mitgliedschaft pro Auth-Benutzerprofil, unabhängig von den Betriebszuordnungen.
-- Bewusst KEINE neue Abo-Sperre und KEIN echter Zahlungseinzug.
BEGIN;
CREATE TABLE IF NOT EXISTS sk_internal.profile_memberships (
 user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
 tariff_code text REFERENCES sk_internal.subscription_tariffs(code),
 state text NOT NULL DEFAULT 'unbezahlt' CHECK (state IN ('unbezahlt','zahlung_ausstehend','aktiv','zahlung_ueberfaellig','gekündigt')),
 amount_cents integer CHECK (amount_cents IS NULL OR amount_cents >= 0),
 started_at timestamptz,
 valid_until timestamptz,
 stripe_customer_id text UNIQUE,
 stripe_subscription_id text UNIQUE,
 cancelled_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT now(),
 updated_at timestamptz NOT NULL DEFAULT now(),
 CHECK(tariff_code IS NULL OR tariff_code IN ('classic','flex'))
);
CREATE TABLE IF NOT EXISTS sk_internal.profile_manual_access (
 user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
 reason text NOT NULL CHECK(length(btrim(reason)) BETWEEN 4 AND 500),
 valid_until date,
 revoked_at timestamptz,
 granted_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
 updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS sk_internal.profile_manual_access_audit (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
 changed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
 operation text NOT NULL CHECK(operation IN ('grant','change','revoke')),
 reason text,
 valid_until date,
 occurred_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE sk_internal.profile_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE sk_internal.profile_manual_access ENABLE ROW LEVEL SECURITY;
ALTER TABLE sk_internal.profile_manual_access_audit ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON sk_internal.profile_memberships,sk_internal.profile_manual_access,sk_internal.profile_manual_access_audit FROM PUBLIC,anon,authenticated;

-- Anzeige ohne direkte Tabellenrechte, Tarife werden aus der Administration geladen.
CREATE OR REPLACE FUNCTION public.sk_my_membership()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $fn$
DECLARE v_user uuid:=auth.uid(); v_member record; v_manual record; v_plans jsonb;
BEGIN
 IF v_user IS NULL THEN RAISE EXCEPTION 'Bitte anmelden' USING ERRCODE='42501'; END IF;
 SELECT m.* INTO v_member FROM sk_internal.profile_memberships m WHERE m.user_id=v_user;
 SELECT a.* INTO v_manual FROM sk_internal.profile_manual_access a WHERE a.user_id=v_user;
 SELECT coalesce(jsonb_agg(jsonb_build_object('code',t.code,'name',t.name,'description',t.description,'amount_cents',t.amount_cents,'billing_period',t.billing_period) ORDER BY CASE t.code WHEN 'classic' THEN 1 WHEN 'flex' THEN 2 ELSE 3 END),'[]'::jsonb)
 INTO v_plans FROM sk_internal.subscription_tariffs t;
 RETURN jsonb_build_object(
  'state',coalesce(v_member.state,'unbezahlt'),'tariff_code',v_member.tariff_code,
  'amount_cents',v_member.amount_cents,'started_at',v_member.started_at,'valid_until',v_member.valid_until,
  'cancelled_at',v_member.cancelled_at,
  'manual_active',coalesce(v_manual.revoked_at IS NULL AND (v_manual.valid_until IS NULL OR v_manual.valid_until >= (now() AT TIME ZONE 'Europe/Zurich')::date),false),
  'manual_valid_until',v_manual.valid_until,
  'payment_enforced',false,'checkout_available',false,'tariffs',v_plans);
END;$fn$;
REVOKE ALL ON FUNCTION public.sk_my_membership() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_my_membership() TO authenticated;

CREATE OR REPLACE FUNCTION public.sk_admin_profile_memberships()
RETURNS TABLE(user_id uuid,email text,state text,tariff_code text,manual_active boolean,manual_reason text,manual_valid_until date)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $fn$
BEGIN
 IF NOT public.sk_is_admin() THEN RAISE EXCEPTION 'Nur Administration' USING ERRCODE='42501'; END IF;
 RETURN QUERY SELECT u.id,u.email::text,coalesce(s.state,'unbezahlt'),s.tariff_code,
 coalesce(a.revoked_at IS NULL AND (a.valid_until IS NULL OR a.valid_until >= (now() AT TIME ZONE 'Europe/Zurich')::date),false),
 a.reason,a.valid_until
 FROM auth.users u LEFT JOIN sk_internal.profile_memberships s ON s.user_id=u.id
 LEFT JOIN sk_internal.profile_manual_access a ON a.user_id=u.id
 ORDER BY lower(u.email) NULLS LAST;
END;$fn$;
REVOKE ALL ON FUNCTION public.sk_admin_profile_memberships() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_admin_profile_memberships() TO authenticated;

CREATE OR REPLACE FUNCTION public.sk_admin_set_profile_manual_access(p_user_id uuid,p_enable boolean,p_reason text DEFAULT NULL,p_valid_until date DEFAULT NULL)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE v_old boolean:=false; v_today date:=(now() AT TIME ZONE 'Europe/Zurich')::date;
BEGIN
 IF NOT public.sk_is_admin() THEN RAISE EXCEPTION 'Nur Administration' USING ERRCODE='42501'; END IF;
 IF p_user_id IS NULL OR NOT EXISTS (SELECT 1 FROM auth.users u WHERE u.id=p_user_id) THEN RAISE EXCEPTION 'Benutzerprofil unbekannt' USING ERRCODE='22023'; END IF;
 IF p_enable IS NULL THEN RAISE EXCEPTION 'Entscheidung fehlt' USING ERRCODE='22023'; END IF;
 IF p_enable THEN
   IF length(btrim(coalesce(p_reason,''))) < 4 THEN RAISE EXCEPTION 'Grund (mindestens 4 Zeichen) erforderlich' USING ERRCODE='22023'; END IF;
   IF p_valid_until IS NOT NULL AND p_valid_until < v_today THEN RAISE EXCEPTION 'Ablaufdatum liegt in der Vergangenheit' USING ERRCODE='22023'; END IF;
   SELECT a.revoked_at IS NULL INTO v_old FROM sk_internal.profile_manual_access a WHERE a.user_id=p_user_id;
   INSERT INTO sk_internal.profile_manual_access(user_id,reason,valid_until,revoked_at,granted_by)
    VALUES(p_user_id,btrim(p_reason),p_valid_until,NULL,auth.uid())
   ON CONFLICT(user_id) DO UPDATE SET reason=EXCLUDED.reason,valid_until=EXCLUDED.valid_until,revoked_at=NULL,granted_by=auth.uid(),updated_at=now();
 ELSE
   IF NOT EXISTS (SELECT 1 FROM sk_internal.profile_manual_access a WHERE a.user_id=p_user_id AND a.revoked_at IS NULL) THEN RETURN; END IF;
   UPDATE sk_internal.profile_manual_access SET revoked_at=now(),updated_at=now() WHERE user_id=p_user_id;
 END IF;
 INSERT INTO sk_internal.profile_manual_access_audit(user_id,changed_by,operation,reason,valid_until)
 VALUES(p_user_id,auth.uid(),CASE WHEN p_enable THEN CASE WHEN coalesce(v_old,false) THEN 'change' ELSE 'grant' END ELSE 'revoke' END,
 CASE WHEN p_enable THEN btrim(p_reason) ELSE NULL END,p_valid_until);
END;$fn$;
REVOKE ALL ON FUNCTION public.sk_admin_set_profile_manual_access(uuid,boolean,text,date) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_admin_set_profile_manual_access(uuid,boolean,text,date) TO authenticated;
COMMIT;
