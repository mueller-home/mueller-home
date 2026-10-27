-- StaffKeeping 0.33.1.8.39: drei Bewertungsdimensionen und administrative Tarifvorlagen.
-- Keine echte Zahlung, Vertragsaktivierung oder Abo-Sperre in diesem Release.
BEGIN;
ALTER TABLE sk_internal.partnership_reviews
 ADD COLUMN IF NOT EXISTS communication smallint CHECK (communication BETWEEN 1 AND 5),
 ADD COLUMN IF NOT EXISTS reliability smallint CHECK (reliability BETWEEN 1 AND 5),
 ADD COLUMN IF NOT EXISTS collaboration smallint CHECK (collaboration BETWEEN 1 AND 5);

CREATE OR REPLACE FUNCTION public.sk_partnership_review_criteria(
 p_partnership_id uuid,p_reviewer_business_id uuid,p_communication integer,
 p_reliability integer,p_collaboration integer,p_comment text DEFAULT '')
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE p sk_internal.partnerships%ROWTYPE; v_id uuid; v_other uuid; v_avg smallint;
BEGIN
 SELECT * INTO p FROM sk_internal.partnerships WHERE id=p_partnership_id FOR SHARE;
 IF NOT FOUND OR p.state<>'abgeschlossen' OR p_reviewer_business_id NOT IN(p.owner_business_id,p.partner_business_id)
 OR NOT sk_internal.chat_allowed(p_reviewer_business_id) THEN
   RAISE EXCEPTION 'Bewertung nicht erlaubt' USING ERRCODE='42501';
 END IF;
 IF p_communication IS NULL OR p_reliability IS NULL OR p_collaboration IS NULL OR
 p_communication NOT BETWEEN 1 AND 5 OR p_reliability NOT BETWEEN 1 AND 5 OR p_collaboration NOT BETWEEN 1 AND 5 OR
 length(coalesce(p_comment,''))>1000 THEN RAISE EXCEPTION 'Ungültige Bewertung'; END IF;
 v_avg:=round((p_communication+p_reliability+p_collaboration)/3.0)::smallint;
 v_other:=CASE WHEN p_reviewer_business_id=p.owner_business_id THEN p.partner_business_id ELSE p.owner_business_id END;
 INSERT INTO sk_internal.partnership_reviews(partnership_id,reviewer_business_id,rated_business_id,stars,communication,reliability,collaboration,comment)
 VALUES(p.id,p_reviewer_business_id,v_other,v_avg,p_communication,p_reliability,p_collaboration,btrim(coalesce(p_comment,''))) RETURNING id INTO v_id;
 RETURN v_id;
END;$fn$;
REVOKE ALL ON FUNCTION public.sk_partnership_review_criteria(uuid,uuid,integer,integer,integer,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_partnership_review_criteria(uuid,uuid,integer,integer,integer,text) TO authenticated;

CREATE OR REPLACE FUNCTION public.sk_partnership_reviews_detailed()
RETURNS TABLE(partnership_id uuid,listing_title text,reviewer_business_id uuid,rated_business_id uuid,reviewer_name text,
 stars smallint,communication smallint,reliability smallint,collaboration smallint,comment text,created_at timestamptz,visible boolean)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $fn$
 SELECT r.partnership_id,l.title,r.reviewer_business_id,r.rated_business_id,b.company_name,
 CASE WHEN v.can_view THEN r.stars ELSE NULL::smallint END,
 CASE WHEN v.can_view THEN r.communication ELSE NULL::smallint END,
 CASE WHEN v.can_view THEN r.reliability ELSE NULL::smallint END,
 CASE WHEN v.can_view THEN r.collaboration ELSE NULL::smallint END,
 CASE WHEN v.can_view THEN r.comment ELSE '' END,r.created_at,v.can_view
 FROM sk_internal.partnership_reviews r
 JOIN sk_internal.partnerships p ON p.id=r.partnership_id
 JOIN public.sk_listings l ON l.id=p.listing_id
 JOIN public.sk_businesses b ON b.id=r.reviewer_business_id
 CROSS JOIN LATERAL (SELECT (
   sk_internal.chat_allowed(r.reviewer_business_id) OR
   p.finished_at<=now()-interval '14 days' OR
   EXISTS(SELECT 1 FROM sk_internal.partnership_reviews x WHERE x.partnership_id=p.id AND x.reviewer_business_id=r.rated_business_id)
 ) AS can_view) v
 WHERE sk_internal.chat_allowed(r.reviewer_business_id) OR sk_internal.chat_allowed(r.rated_business_id)
 ORDER BY r.created_at DESC LIMIT 200;
$fn$;
REVOKE ALL ON FUNCTION public.sk_partnership_reviews_detailed() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_partnership_reviews_detailed() TO authenticated;

-- Tarife sind Vorlagen, keine Verträge und keine Zahlungsberechtigung.
CREATE TABLE IF NOT EXISTS sk_internal.subscription_tariffs(
 code text PRIMARY KEY CHECK(code IN ('classic','flex','admission')),
 name text NOT NULL,
 description text NOT NULL DEFAULT '',
 amount_cents integer NOT NULL CHECK(amount_cents BETWEEN 0 AND 10000000),
 currency text NOT NULL DEFAULT 'CHF' CHECK(currency='CHF'),
 billing_period text NOT NULL CHECK(billing_period IN ('monthly','once')),
 updated_at timestamptz NOT NULL DEFAULT now(),
 updated_by uuid
);
CREATE TABLE IF NOT EXISTS sk_internal.subscription_tariff_audit(
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 tariff_code text NOT NULL,
 previous_amount_cents integer NOT NULL,
 new_amount_cents integer NOT NULL,
 changed_by uuid NOT NULL,
 changed_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE sk_internal.subscription_tariffs ENABLE ROW LEVEL SECURITY;
ALTER TABLE sk_internal.subscription_tariff_audit ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON sk_internal.subscription_tariffs,sk_internal.subscription_tariff_audit FROM PUBLIC,anon,authenticated;
INSERT INTO sk_internal.subscription_tariffs(code,name,description,amount_cents,billing_period)
VALUES ('classic','Classic','Tarifvorlage mit zwölf Monaten Mindestlaufzeit',9900,'monthly'),
('flex','Flex','Monatlich kündbare Tarifvorlage',11900,'monthly'),
('admission','Aufnahmegebühr','Einmalige Aufnahmegebühr',19900,'once')
ON CONFLICT (code) DO NOTHING;

CREATE OR REPLACE FUNCTION public.sk_admin_tariff_list()
RETURNS TABLE(code text,name text,description text,amount_cents integer,billing_period text,updated_at timestamptz)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $fn$
BEGIN
 IF NOT public.sk_is_admin() THEN RAISE EXCEPTION 'Administratorberechtigung erforderlich' USING ERRCODE='42501'; END IF;
 RETURN QUERY SELECT t.code,t.name,t.description,t.amount_cents,t.billing_period,t.updated_at
 FROM sk_internal.subscription_tariffs t ORDER BY CASE t.code WHEN 'classic' THEN 1 WHEN 'flex' THEN 2 ELSE 3 END;
END;$fn$;
CREATE OR REPLACE FUNCTION public.sk_admin_tariff_set_price(p_code text,p_amount_cents integer)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE v_old integer;
BEGIN
 IF NOT public.sk_is_admin() THEN RAISE EXCEPTION 'Administratorberechtigung erforderlich' USING ERRCODE='42501'; END IF;
 IF p_code NOT IN ('classic','flex','admission') OR p_amount_cents IS NULL OR p_amount_cents NOT BETWEEN 0 AND 10000000 THEN
   RAISE EXCEPTION 'Ungültige Preisangabe'; END IF;
 SELECT t.amount_cents INTO v_old FROM sk_internal.subscription_tariffs t WHERE t.code=p_code FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Unbekannter Tarif'; END IF;
 IF v_old=p_amount_cents THEN RETURN; END IF;
 UPDATE sk_internal.subscription_tariffs SET amount_cents=p_amount_cents,updated_at=now(),updated_by=auth.uid() WHERE code=p_code;
 INSERT INTO sk_internal.subscription_tariff_audit(tariff_code,previous_amount_cents,new_amount_cents,changed_by)
 VALUES(p_code,v_old,p_amount_cents,auth.uid());
END;$fn$;
REVOKE ALL ON FUNCTION public.sk_admin_tariff_list(),public.sk_admin_tariff_set_price(text,integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_admin_tariff_list(),public.sk_admin_tariff_set_price(text,integer) TO authenticated;
-- Einheitlich veröffentlichte Reputation, erst ab drei sichtbaren Bewertungen mit Mittelwerten.
CREATE OR REPLACE FUNCTION public.sk_business_reputation(p_business_id uuid)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $fn$
DECLARE v_name text; v_count integer; v_avg numeric; v_comm numeric; v_rel numeric; v_coll numeric; v_comments jsonb;
BEGIN
 IF auth.uid() IS NULL OR NOT (public.sk_is_admin() OR EXISTS(
   SELECT 1 FROM public.sk_business_members m JOIN public.sk_businesses b ON b.id=m.business_id
   WHERE m.user_id=auth.uid() AND b.status='Freigeschaltet'::public.sk_business_status
 )) THEN RAISE EXCEPTION 'Zugriff nicht erlaubt' USING ERRCODE='42501'; END IF;
 SELECT b.company_name INTO v_name FROM public.sk_businesses b
 WHERE b.id=p_business_id AND b.status='Freigeschaltet'::public.sk_business_status;
 IF NOT FOUND THEN RETURN NULL; END IF;
 WITH visible_reviews AS (
  SELECT r.*,p.finished_at FROM sk_internal.partnership_reviews r
  JOIN sk_internal.partnerships p ON p.id=r.partnership_id
  WHERE r.rated_business_id=p_business_id
   AND (p.finished_at<=now()-interval '14 days' OR EXISTS(
    SELECT 1 FROM sk_internal.partnership_reviews other
    WHERE other.partnership_id=r.partnership_id AND other.reviewer_business_id=r.rated_business_id
   ))
 )
 SELECT count(*)::integer,round(avg(stars)::numeric,1),round(avg(communication)::numeric,1),
 round(avg(reliability)::numeric,1),round(avg(collaboration)::numeric,1)
 INTO v_count,v_avg,v_comm,v_rel,v_coll FROM visible_reviews;
 IF v_count>=3 THEN
  SELECT coalesce(jsonb_agg(x.comment),'[]'::jsonb) INTO v_comments FROM (
    SELECT left(btrim(r.comment),400) AS comment FROM sk_internal.partnership_reviews r
    JOIN sk_internal.partnerships p ON p.id=r.partnership_id
    WHERE r.rated_business_id=p_business_id AND btrim(r.comment)<>''
    AND (p.finished_at<=now()-interval '14 days' OR EXISTS(
     SELECT 1 FROM sk_internal.partnership_reviews other
     WHERE other.partnership_id=r.partnership_id AND other.reviewer_business_id=r.rated_business_id
    )) ORDER BY r.created_at DESC LIMIT 3
  ) x;
 END IF;
 RETURN jsonb_build_object('business_name',v_name,'review_count',v_count,
 'average_stars',CASE WHEN v_count>=3 THEN v_avg ELSE NULL END,
 'communication',CASE WHEN v_count>=3 THEN v_comm ELSE NULL END,
 'reliability',CASE WHEN v_count>=3 THEN v_rel ELSE NULL END,
 'collaboration',CASE WHEN v_count>=3 THEN v_coll ELSE NULL END,
 'comments',CASE WHEN v_count>=3 THEN coalesce(v_comments,'[]'::jsonb) ELSE '[]'::jsonb END);
END;$fn$;
REVOKE ALL ON FUNCTION public.sk_business_reputation(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_business_reputation(uuid) TO authenticated;
-- Alte Einzelstern-Schnittstelle für neue Einreichungen deaktivieren. Bestandsdaten bleiben vorhanden.
REVOKE EXECUTE ON FUNCTION public.sk_partnership_review(uuid,uuid,int,text) FROM authenticated;
COMMIT;
