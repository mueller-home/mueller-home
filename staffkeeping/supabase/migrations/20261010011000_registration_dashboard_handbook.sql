-- StaffKeeping 0.30 – Registration 2.0, audit notifications, integrated help.
-- Run AFTER all migrations through 0.29.1. One transaction; many statements; no separate SELECT resultsets.
-- Existing approved businesses stay approved. No Bubble migration or re-seeding of project documentation.
BEGIN;
ALTER TABLE public.sk_businesses ADD COLUMN IF NOT EXISTS review_state text NOT NULL DEFAULT 'draft'
 CHECK (review_state IN ('draft','submitted','changes_requested','approved'));
ALTER TABLE public.sk_businesses ADD COLUMN IF NOT EXISTS submitted_at timestamptz;
ALTER TABLE public.sk_businesses ADD COLUMN IF NOT EXISTS reviewed_at timestamptz;
ALTER TABLE public.sk_businesses ADD COLUMN IF NOT EXISTS review_message text;
UPDATE public.sk_businesses SET review_state='approved' WHERE status='Freigeschaltet' AND review_state='draft';

CREATE TABLE IF NOT EXISTS sk_internal.admin_events (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 business_id uuid REFERENCES public.sk_businesses(id) ON DELETE CASCADE,
 kind text NOT NULL CHECK (kind IN ('submitted','approved','changes_requested','profile_changed','media_changed','location_changed','change_requested','change_approved','change_rejected','blocked')),
 title text NOT NULL, detail text NOT NULL DEFAULT '',
 created_at timestamptz NOT NULL DEFAULT now(),
 resolved_at timestamptz, resolved_by uuid REFERENCES auth.users(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS sk_admin_events_recent ON sk_internal.admin_events(created_at DESC);
CREATE INDEX IF NOT EXISTS sk_admin_events_open ON sk_internal.admin_events(resolved_at,created_at DESC);
REVOKE ALL ON sk_internal.admin_events FROM PUBLIC,anon,authenticated;

CREATE TABLE IF NOT EXISTS sk_internal.business_change_requests (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 business_id uuid NOT NULL REFERENCES public.sk_businesses(id) ON DELETE CASCADE,
 requested_by uuid NOT NULL REFERENCES auth.users(id),
 field text NOT NULL CHECK(field IN ('company_name','vat_id','country')),
 old_value text NOT NULL, new_value text NOT NULL,
 status text NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','approved','rejected')),
 created_at timestamptz NOT NULL DEFAULT now(), reviewed_at timestamptz,
 reviewed_by uuid REFERENCES auth.users(id), admin_message text
);
CREATE UNIQUE INDEX IF NOT EXISTS sk_change_one_pending ON sk_internal.business_change_requests(business_id,field) WHERE status='pending';
REVOKE ALL ON sk_internal.business_change_requests FROM PUBLIC,anon,authenticated;

-- Ownership and state checks are centralized in locked RPCs, not in JavaScript.
CREATE OR REPLACE FUNCTION public.sk_update_my_business_profile(
 p_company_name text,p_industry public.sk_industry,p_postal_code text,p_city text,
 p_contact_name text,p_contact_email text,p_contact_phone text,p_description text,
 p_email_notifications_enabled boolean,p_street text,p_house_number text,
 p_address_extra text,p_show_street_address boolean
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE b public.sk_businesses%ROWTYPE;
BEGIN
 SELECT x.* INTO b FROM public.sk_businesses x
 JOIN public.sk_business_members m ON m.business_id=x.id
 JOIN auth.users u ON u.id=m.user_id
 WHERE m.user_id=auth.uid() AND m.role='owner'::public.sk_member_role
 AND u.email_confirmed_at IS NOT NULL
 AND x.status IN ('Ausstehend','Freigeschaltet')
 AND (x.status='Freigeschaltet' OR x.review_state IN ('draft','changes_requested'))
 FOR UPDATE OF x;
 IF NOT FOUND THEN RAISE EXCEPTION 'Profil ist zur Prüfung gesperrt oder Konto nicht berechtigt' USING ERRCODE='42501'; END IF;
 IF char_length(btrim(coalesce(p_company_name,''))) NOT BETWEEN 2 AND 160
 OR p_industry IS NULL OR char_length(btrim(coalesce(p_postal_code,''))) NOT BETWEEN 2 AND 16
 OR char_length(btrim(coalesce(p_city,''))) NOT BETWEEN 2 AND 120
 OR char_length(btrim(coalesce(p_contact_name,''))) NOT BETWEEN 2 AND 160
 OR char_length(btrim(coalesce(p_contact_email,''))) NOT BETWEEN 3 AND 254
 OR char_length(coalesce(p_description,''))>1000 OR p_email_notifications_enabled IS NULL
 OR char_length(coalesce(p_street,''))>180 OR char_length(coalesce(p_house_number,''))>24
 OR char_length(coalesce(p_address_extra,''))>180 OR p_show_street_address IS NULL
 THEN RAISE EXCEPTION 'Ungültige Profilangaben' USING ERRCODE='22023'; END IF;
 -- Legally relevant fields are immutable after approval, via every profile path.
 IF b.status='Freigeschaltet' AND b.company_name IS DISTINCT FROM btrim(p_company_name)
 THEN RAISE EXCEPTION 'Firmenname nur per Änderungsantrag' USING ERRCODE='42501'; END IF;
 UPDATE public.sk_businesses SET
  company_name=btrim(p_company_name),industry=p_industry,postal_code=btrim(p_postal_code),
  city=btrim(p_city),contact_name=btrim(p_contact_name),contact_email=btrim(p_contact_email),
  contact_phone=nullif(btrim(coalesce(p_contact_phone,'')),''),description=p_description,
  email_notifications_enabled=p_email_notifications_enabled,
  street=nullif(btrim(coalesce(p_street,'')),''),house_number=nullif(btrim(coalesce(p_house_number,'')),''),
  address_extra=nullif(btrim(coalesce(p_address_extra,'')),''),show_street_address=p_show_street_address,
  updated_at=now() WHERE id=b.id;
END;$fn$;

CREATE OR REPLACE FUNCTION public.sk_set_my_business_location(
 p_latitude double precision,p_longitude double precision,p_source text,p_address_key text
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE b public.sk_businesses%ROWTYPE; v_key text;
BEGIN
 SELECT x.* INTO b FROM public.sk_businesses x
 JOIN public.sk_business_members m ON m.business_id=x.id
 JOIN auth.users u ON u.id=m.user_id
 WHERE m.user_id=auth.uid() AND m.role='owner'::public.sk_member_role
 AND u.email_confirmed_at IS NOT NULL
 AND x.status IN ('Ausstehend','Freigeschaltet')
 AND (x.status='Freigeschaltet' OR x.review_state IN ('draft','changes_requested'))
 FOR UPDATE OF x;
 IF NOT FOUND THEN RAISE EXCEPTION 'Standort ist zur Prüfung gesperrt' USING ERRCODE='42501'; END IF;
 v_key:=lower(trim(coalesce(b.country::text,'')))||'|'||lower(trim(coalesce(b.postal_code,'')))||'|'||lower(trim(coalesce(b.city,'')))||'|'||lower(trim(coalesce(b.street,'')))||'|'||lower(trim(coalesce(b.house_number,'')));
 IF p_address_key IS DISTINCT FROM v_key THEN RAISE EXCEPTION 'Adresse inzwischen geändert' USING ERRCODE='40001'; END IF;
 IF p_source='reset' THEN
  UPDATE public.sk_businesses SET latitude=NULL,longitude=NULL,location_source=NULL,location_address_key=NULL,location_updated_at=now() WHERE id=b.id;
  RETURN;
 END IF;
 IF p_source NOT IN ('geocoded','manual') OR p_latitude IS NULL OR p_longitude IS NULL OR NOT(p_latitude BETWEEN -90 AND 90) OR NOT(p_longitude BETWEEN -180 AND 180)
 THEN RAISE EXCEPTION 'Ungültige Position' USING ERRCODE='22023'; END IF;
 IF p_source='geocoded' AND b.location_source='manual' THEN RAISE EXCEPTION 'Manuelle Position bleibt geschützt' USING ERRCODE='42501'; END IF;
 UPDATE public.sk_businesses SET latitude=p_latitude,longitude=p_longitude,location_source=p_source,location_address_key=v_key,location_updated_at=now() WHERE id=b.id;
END;$fn$;

-- Correct initial legal data while the application is in editable review state.
CREATE OR REPLACE FUNCTION public.sk_update_my_registration_legal(p_vat_id text,p_country public.sk_country)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE v_id uuid;
BEGIN
 SELECT b.id INTO v_id FROM public.sk_businesses b JOIN public.sk_business_members m ON m.business_id=b.id
 JOIN auth.users u ON u.id=m.user_id
 WHERE m.user_id=auth.uid() AND m.role='owner'::public.sk_member_role AND u.email_confirmed_at IS NOT NULL
 AND b.status='Ausstehend' AND b.review_state IN ('draft','changes_requested') FOR UPDATE OF b;
 IF NOT FOUND THEN RAISE EXCEPTION 'Rechtliche Angaben während der Prüfung gesperrt' USING ERRCODE='42501'; END IF;
 IF length(btrim(coalesce(p_vat_id,''))) NOT BETWEEN 2 AND 64 OR p_country IS NULL
 THEN RAISE EXCEPTION 'Ungültige Unternehmensangaben' USING ERRCODE='22023'; END IF;
 UPDATE public.sk_businesses SET vat_id=btrim(p_vat_id),country=p_country,
 latitude=CASE WHEN country IS DISTINCT FROM p_country THEN NULL ELSE latitude END,
 longitude=CASE WHEN country IS DISTINCT FROM p_country THEN NULL ELSE longitude END,
 location_source=CASE WHEN country IS DISTINCT FROM p_country THEN NULL ELSE location_source END,
 location_address_key=CASE WHEN country IS DISTINCT FROM p_country THEN NULL ELSE location_address_key END,
 updated_at=now() WHERE id=v_id;
END;$fn$;

CREATE OR REPLACE FUNCTION public.sk_submit_my_business() RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE b public.sk_businesses%ROWTYPE;
BEGIN
 SELECT x.* INTO b FROM public.sk_businesses x JOIN public.sk_business_members m ON m.business_id=x.id
 WHERE m.user_id=auth.uid() AND m.role='owner'::public.sk_member_role AND x.status='Ausstehend'
 AND x.review_state IN ('draft','changes_requested') FOR UPDATE OF x;
 IF NOT FOUND THEN RAISE EXCEPTION 'Einreichung nicht erlaubt oder bereits eingereicht' USING ERRCODE='42501'; END IF;
 IF length(btrim(b.description))<30 OR length(btrim(coalesce(b.contact_phone,'')))<5
 THEN RAISE EXCEPTION 'Bitte Beschreibung (mindestens 30 Zeichen) und Telefonnummer ergänzen' USING ERRCODE='22023'; END IF;
 UPDATE public.sk_businesses SET review_state='submitted',submitted_at=now(),review_message=NULL,updated_at=now() WHERE id=b.id;
 INSERT INTO sk_internal.admin_events(business_id,kind,title,detail) VALUES(b.id,'submitted','Neuer Freigabeantrag',b.company_name);
END;$fn$;

CREATE OR REPLACE FUNCTION public.sk_admin_review_business(p_business_id uuid,p_action text,p_message text DEFAULT NULL)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE b public.sk_businesses%ROWTYPE;
BEGIN
 IF NOT public.sk_is_admin() THEN RAISE EXCEPTION 'Nur Administratoren' USING ERRCODE='42501'; END IF;
 SELECT * INTO b FROM public.sk_businesses WHERE id=p_business_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Betrieb unbekannt' USING ERRCODE='22023'; END IF;
 IF p_action='approve' THEN
  IF b.status<>'Ausstehend' OR b.review_state<>'submitted' THEN RAISE EXCEPTION 'Nur eingereichte Anträge freigeben' USING ERRCODE='22023'; END IF;
  UPDATE public.sk_businesses SET review_state='approved',status='Freigeschaltet',reviewed_at=now(),review_message=NULL,updated_at=now() WHERE id=b.id;
  INSERT INTO sk_internal.business_status_audit(business_id,changed_by,old_status,new_status) VALUES(b.id,auth.uid(),b.status,'Freigeschaltet');
  INSERT INTO sk_internal.admin_events(business_id,kind,title,detail,resolved_at,resolved_by) VALUES(b.id,'approved','Betrieb freigegeben',b.company_name,now(),auth.uid());
 ELSIF p_action='changes' THEN
  IF b.status<>'Ausstehend' OR b.review_state<>'submitted' THEN RAISE EXCEPTION 'Nur eingereichte Anträge zurückgeben' USING ERRCODE='22023'; END IF;
  IF length(btrim(coalesce(p_message,'')))<5 THEN RAISE EXCEPTION 'Nachbesserung bitte begründen' USING ERRCODE='22023'; END IF;
  UPDATE public.sk_businesses SET review_state='changes_requested',review_message=left(p_message,3000),updated_at=now() WHERE id=b.id;
  INSERT INTO sk_internal.admin_events(business_id,kind,title,detail,resolved_at,resolved_by) VALUES(b.id,'changes_requested','Nachbesserung verlangt',left(p_message,3000),now(),auth.uid());
 ELSE RAISE EXCEPTION 'Ungültige Prüfaktion' USING ERRCODE='22023'; END IF;
 UPDATE sk_internal.admin_events SET resolved_at=now(),resolved_by=auth.uid()
 WHERE business_id=b.id AND kind='submitted' AND resolved_at IS NULL;
END;$fn$;

-- Block bypass via legacy approval RPC: only submitted businesses can be approved.
CREATE OR REPLACE FUNCTION public.sk_admin_set_business_status(p_business_id uuid,p_status public.sk_business_status)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE b public.sk_businesses%ROWTYPE;
BEGIN
 IF NOT public.sk_is_admin() THEN RAISE EXCEPTION 'Nur Administratoren' USING ERRCODE='42501'; END IF;
 SELECT * INTO b FROM public.sk_businesses WHERE id=p_business_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Betrieb nicht gefunden' USING ERRCODE='22023'; END IF;
 IF p_status='Freigeschaltet' AND NOT (b.status='Gesperrt' AND b.review_state='approved') THEN RAISE EXCEPTION 'Freigabe nur über Einreichungsprüfung' USING ERRCODE='42501'; END IF;
 IF p_status='Ausstehend' THEN RAISE EXCEPTION 'Rückstellung nur über Prüfworkflow' USING ERRCODE='42501'; END IF;
 IF b.status=p_status THEN RETURN; END IF;
 UPDATE public.sk_businesses SET status=p_status,updated_at=now() WHERE id=b.id;
 INSERT INTO sk_internal.business_status_audit(business_id,changed_by,old_status,new_status) VALUES(b.id,auth.uid(),b.status,p_status);
 INSERT INTO sk_internal.admin_events(business_id,kind,title,detail) VALUES(b.id,'blocked','Betriebsstatus geändert',b.company_name||': '||p_status::text);
END;$fn$;

CREATE OR REPLACE FUNCTION public.sk_request_sensitive_change(p_field text,p_new_value text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE b public.sk_businesses%ROWTYPE; v_old text;
BEGIN
 SELECT x.* INTO b FROM public.sk_businesses x JOIN public.sk_business_members m ON m.business_id=x.id
 WHERE m.user_id=auth.uid() AND m.role='owner'::public.sk_member_role AND x.status='Freigeschaltet'
 FOR UPDATE OF x;
 IF NOT FOUND THEN RAISE EXCEPTION 'Nur freigegebene Betriebsinhaber' USING ERRCODE='42501'; END IF;
 IF p_field NOT IN ('company_name','vat_id','country') THEN RAISE EXCEPTION 'Ungültiges Feld'; END IF;
 v_old:=CASE p_field WHEN 'company_name' THEN b.company_name WHEN 'vat_id' THEN b.vat_id ELSE b.country::text END;
 IF length(btrim(coalesce(p_new_value,''))) NOT BETWEEN 2 AND 160 THEN RAISE EXCEPTION 'Ungültiger neuer Wert'; END IF;
 IF p_field='country' AND p_new_value NOT IN ('CH','DE','AT') THEN RAISE EXCEPTION 'Ungültiges Land'; END IF;
 IF v_old=p_new_value THEN RAISE EXCEPTION 'Keine Änderung'; END IF;
 INSERT INTO sk_internal.business_change_requests(business_id,requested_by,field,old_value,new_value)
 VALUES(b.id,auth.uid(),p_field,v_old,btrim(p_new_value));
 INSERT INTO sk_internal.admin_events(business_id,kind,title,detail)
 VALUES(b.id,'change_requested','Prüfpflichtige Profiländerung',p_field||': '||v_old||' → '||p_new_value);
END;$fn$;
CREATE OR REPLACE FUNCTION public.sk_admin_review_sensitive_change(p_request_id bigint,p_approve boolean,p_message text DEFAULT NULL)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE r sk_internal.business_change_requests%ROWTYPE; b public.sk_businesses%ROWTYPE;
BEGIN
 IF NOT public.sk_is_admin() THEN RAISE EXCEPTION 'Nur Administratoren' USING ERRCODE='42501'; END IF;
 SELECT * INTO r FROM sk_internal.business_change_requests WHERE id=p_request_id AND status='pending' FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Antrag nicht offen'; END IF;
 SELECT * INTO b FROM public.sk_businesses WHERE id=r.business_id FOR UPDATE;
 IF p_approve THEN
  IF r.field='company_name' THEN UPDATE public.sk_businesses SET company_name=r.new_value,updated_at=now() WHERE id=b.id;
  ELSIF r.field='vat_id' THEN UPDATE public.sk_businesses SET vat_id=r.new_value,updated_at=now() WHERE id=b.id;
  ELSE UPDATE public.sk_businesses SET country=r.new_value::public.sk_country,latitude=NULL,longitude=NULL,location_source=NULL,location_address_key=NULL,updated_at=now() WHERE id=b.id; END IF;
 END IF;
 UPDATE sk_internal.business_change_requests SET status=CASE WHEN p_approve THEN 'approved' ELSE 'rejected' END,
 reviewed_at=now(),reviewed_by=auth.uid(),admin_message=left(coalesce(p_message,''),3000) WHERE id=r.id;
 INSERT INTO sk_internal.admin_events(business_id,kind,title,detail,resolved_at,resolved_by)
 VALUES(b.id,CASE WHEN p_approve THEN 'change_approved' ELSE 'change_rejected' END,'Änderungsantrag entschieden',r.field,now(),auth.uid());
 UPDATE sk_internal.admin_events SET resolved_at=now(),resolved_by=auth.uid()
 WHERE business_id=b.id AND kind='change_requested' AND detail LIKE r.field||':%' AND resolved_at IS NULL;
END;$fn$;

-- Changes to an approved profile are recorded as activity; only meaningful field differences.
CREATE OR REPLACE FUNCTION sk_internal.log_profile_changes() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE changes text[]:=ARRAY[]::text[];
BEGIN
 IF OLD.status<>'Freigeschaltet' OR NEW.status<>'Freigeschaltet' THEN RETURN NEW; END IF;
 IF ROW(OLD.industry,OLD.postal_code,OLD.city,OLD.contact_name,OLD.contact_email,OLD.contact_phone,OLD.description,OLD.email_notifications_enabled,OLD.show_street_address)
 IS DISTINCT FROM ROW(NEW.industry,NEW.postal_code,NEW.city,NEW.contact_name,NEW.contact_email,NEW.contact_phone,NEW.description,NEW.email_notifications_enabled,NEW.show_street_address) THEN changes:=array_append(changes,'Profilangaben'); END IF;
 IF ROW(OLD.street,OLD.house_number,OLD.address_extra,OLD.latitude,OLD.longitude,OLD.location_source)
 IS DISTINCT FROM ROW(NEW.street,NEW.house_number,NEW.address_extra,NEW.latitude,NEW.longitude,NEW.location_source) THEN changes:=array_append(changes,'Adresse/Standort'); END IF;
 IF array_length(changes,1)>0 THEN
 INSERT INTO sk_internal.admin_events(business_id,kind,title,detail)
 VALUES(NEW.id,CASE WHEN 'Adresse/Standort'=ANY(changes) THEN 'location_changed' ELSE 'profile_changed' END,
 'Betriebsprofil geändert',array_to_string(changes,', '));
 END IF;
 RETURN NEW;
END;$fn$;
DROP TRIGGER IF EXISTS sk_profile_activity ON public.sk_businesses;
CREATE TRIGGER sk_profile_activity AFTER UPDATE ON public.sk_businesses FOR EACH ROW EXECUTE FUNCTION sk_internal.log_profile_changes();

-- Storage policies extend edit access to unsubmitted / revision profiles and read to their owner.
DROP POLICY IF EXISTS sk_media_read ON storage.objects;
CREATE POLICY sk_media_read ON storage.objects FOR SELECT TO authenticated USING(
 bucket_id IN ('sk-business-logos','sk-business-photos') AND
 (public.sk_is_admin() OR EXISTS(SELECT 1 FROM public.sk_business_members m WHERE m.user_id=auth.uid() AND m.business_id::text=(storage.foldername(name))[1]))
);
DROP POLICY IF EXISTS sk_media_insert ON storage.objects;
CREATE POLICY sk_media_insert ON storage.objects FOR INSERT TO authenticated WITH CHECK(
 ((bucket_id='sk-business-logos' AND name ~ '^[0-9a-f-]{36}/logo\.(png|jpg|webp)$') OR
  (bucket_id='sk-business-photos' AND name ~ '^[0-9a-f-]{36}/[1-5]\.(png|jpg|webp)$'))
 AND EXISTS(SELECT 1 FROM public.sk_business_members m JOIN public.sk_businesses b ON b.id=m.business_id
 WHERE m.user_id=auth.uid() AND m.role='owner'::public.sk_member_role AND m.business_id::text=(storage.foldername(name))[1]
 AND (b.status='Freigeschaltet' OR (b.status='Ausstehend' AND b.review_state IN ('draft','changes_requested'))))
);
DROP POLICY IF EXISTS sk_media_update ON storage.objects;
CREATE POLICY sk_media_update ON storage.objects FOR UPDATE TO authenticated USING(
 bucket_id IN ('sk-business-logos','sk-business-photos') AND EXISTS(SELECT 1 FROM public.sk_business_members m JOIN public.sk_businesses b ON b.id=m.business_id
 WHERE m.user_id=auth.uid() AND m.role='owner'::public.sk_member_role AND m.business_id::text=(storage.foldername(name))[1]
 AND (b.status='Freigeschaltet' OR (b.status='Ausstehend' AND b.review_state IN ('draft','changes_requested'))))
) WITH CHECK(
 ((bucket_id='sk-business-logos' AND name ~ '^[0-9a-f-]{36}/logo\.(png|jpg|webp)$') OR
  (bucket_id='sk-business-photos' AND name ~ '^[0-9a-f-]{36}/[1-5]\.(png|jpg|webp)$'))
 AND EXISTS(SELECT 1 FROM public.sk_business_members m JOIN public.sk_businesses b ON b.id=m.business_id
 WHERE m.user_id=auth.uid() AND m.role='owner'::public.sk_member_role AND m.business_id::text=(storage.foldername(name))[1]
 AND (b.status='Freigeschaltet' OR (b.status='Ausstehend' AND b.review_state IN ('draft','changes_requested'))))
);
DROP POLICY IF EXISTS sk_media_delete ON storage.objects;
CREATE POLICY sk_media_delete ON storage.objects FOR DELETE TO authenticated USING(
 bucket_id IN ('sk-business-logos','sk-business-photos') AND EXISTS(SELECT 1 FROM public.sk_business_members m JOIN public.sk_businesses b ON b.id=m.business_id
 WHERE m.user_id=auth.uid() AND m.role='owner'::public.sk_member_role AND m.business_id::text=(storage.foldername(name))[1]
 AND (b.status='Freigeschaltet' OR (b.status='Ausstehend' AND b.review_state IN ('draft','changes_requested'))))
);
-- Admin-restricted event query, unread/open counters, and pending sensitive requests.
CREATE OR REPLACE FUNCTION public.sk_admin_activity() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $fn$
DECLARE result jsonb;
BEGIN
 IF NOT public.sk_is_admin() THEN RAISE EXCEPTION 'Nur Administratoren' USING ERRCODE='42501'; END IF;
 SELECT jsonb_build_object(
  'open_count',(SELECT count(*) FROM sk_internal.admin_events WHERE resolved_at IS NULL),
  'pending_businesses',(SELECT count(*) FROM public.sk_businesses WHERE status='Ausstehend' AND review_state='submitted'),
  'pending_changes',(SELECT count(*) FROM sk_internal.business_change_requests WHERE status='pending'),
  'events',coalesce((SELECT jsonb_agg(to_jsonb(e) ORDER BY e.created_at DESC) FROM (SELECT id,business_id,kind,title,detail,created_at,resolved_at FROM sk_internal.admin_events ORDER BY created_at DESC LIMIT 100)e),'[]'::jsonb),
  'changes',coalesce((SELECT jsonb_agg(to_jsonb(r) ORDER BY r.created_at DESC) FROM (SELECT id,business_id,field,old_value,new_value,created_at FROM sk_internal.business_change_requests WHERE status='pending' ORDER BY created_at DESC LIMIT 100)r),'[]'::jsonb)
 ) INTO result;
 RETURN result;
END;$fn$;
CREATE OR REPLACE FUNCTION public.sk_admin_resolve_event(p_event_id bigint) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
BEGIN
 IF NOT public.sk_is_admin() THEN RAISE EXCEPTION 'Nur Administratoren' USING ERRCODE='42501'; END IF;
 UPDATE sk_internal.admin_events SET resolved_at=now(),resolved_by=auth.uid() WHERE id=p_event_id AND resolved_at IS NULL;
END;$fn$;

-- Storage events are audited server-side (cannot be suppressed by the browser).
CREATE OR REPLACE FUNCTION sk_internal.log_media_change() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE obj storage.objects%ROWTYPE; v_id uuid;
BEGIN
 IF TG_OP='DELETE' THEN obj:=OLD; ELSE obj:=NEW; END IF;
 IF obj.bucket_id NOT IN ('sk-business-logos','sk-business-photos') THEN RETURN NULL; END IF;
 BEGIN v_id:=split_part(obj.name,'/',1)::uuid; EXCEPTION WHEN invalid_text_representation THEN RETURN NULL; END;
 IF EXISTS(SELECT 1 FROM public.sk_businesses WHERE id=v_id AND status='Freigeschaltet') THEN
  INSERT INTO sk_internal.admin_events(business_id,kind,title,detail)
  VALUES(v_id,'media_changed','Betriebsmedien geändert',
    CASE WHEN TG_OP='DELETE' THEN 'Bild entfernt: ' ELSE 'Bild hochgeladen: ' END||obj.bucket_id);
 END IF;
 RETURN NULL;
END;$fn$;
DROP TRIGGER IF EXISTS sk_media_activity ON storage.objects;
CREATE TRIGGER sk_media_activity AFTER INSERT OR DELETE ON storage.objects
FOR EACH ROW EXECUTE FUNCTION sk_internal.log_media_change();

-- HANDBOOK is integrated into the existing documentation infrastructure, with a separate doc type.
CREATE TABLE IF NOT EXISTS sk_internal.help_chapters(
 slug text PRIMARY KEY CHECK(slug ~ '^[a-z0-9-]{2,60}$'),
 title text NOT NULL, body text NOT NULL DEFAULT '', section text NOT NULL DEFAULT 'Allgemein',
 page_key text NOT NULL, audience text NOT NULL CHECK(audience IN ('public','business','admin')),
 status text NOT NULL DEFAULT 'draft' CHECK(status IN ('draft','published')),
 position integer NOT NULL DEFAULT 100,
 updated_at timestamptz NOT NULL DEFAULT now(),updated_by uuid REFERENCES auth.users(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS sk_help_page_index ON sk_internal.help_chapters(page_key,audience,status);
REVOKE ALL ON sk_internal.help_chapters FROM PUBLIC,anon,authenticated;
-- No direct reads; the RPC enforces publication and role.
CREATE OR REPLACE FUNCTION public.sk_help_list(p_preview boolean DEFAULT false)
RETURNS TABLE(slug text,title text,body text,section text,page_key text,audience text,status text,"position" integer,updated_at timestamptz)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $fn$
DECLARE v_admin boolean:=public.sk_is_admin(); v_business boolean:=false;
BEGIN
 IF auth.uid() IS NOT NULL THEN
 SELECT EXISTS(SELECT 1 FROM public.sk_business_members WHERE user_id=auth.uid()) INTO v_business;
 END IF;
 IF p_preview AND NOT v_admin THEN RAISE EXCEPTION 'Admin-Berechtigung erforderlich' USING ERRCODE='42501'; END IF;
 RETURN QUERY SELECT h.slug,h.title,h.body,h.section,h.page_key,h.audience,h.status,h.position,h.updated_at
 FROM sk_internal.help_chapters h
 WHERE (p_preview AND v_admin) OR (h.status='published' AND
 (h.audience='public' OR (h.audience='business' AND v_business) OR (h.audience='admin' AND v_admin)))
 ORDER BY h.position,h.slug;
END;$fn$;
CREATE OR REPLACE FUNCTION public.sk_admin_save_help(p_slug text,p_title text,p_body text,p_section text,p_page_key text,p_audience text,p_status text,p_position integer)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
BEGIN
 IF NOT public.sk_is_admin() THEN RAISE EXCEPTION 'Nur Administratoren' USING ERRCODE='42501'; END IF;
 IF p_slug !~ '^[a-z0-9-]{2,60}$' OR length(coalesce(p_title,'')) NOT BETWEEN 2 AND 160
 OR length(coalesce(p_body,''))>40000 OR p_audience NOT IN ('public','business','admin') OR p_status NOT IN ('draft','published')
 OR length(coalesce(p_page_key,''))<2 THEN RAISE EXCEPTION 'Ungültige Handbuchangaben'; END IF;
 INSERT INTO sk_internal.help_chapters(slug,title,body,section,page_key,audience,status,position,updated_by)
 VALUES(p_slug,p_title,p_body,coalesce(p_section,'Allgemein'),p_page_key,p_audience,p_status,coalesce(p_position,100),auth.uid())
 ON CONFLICT (slug) DO UPDATE SET title=excluded.title,body=excluded.body,section=excluded.section,
 page_key=excluded.page_key,audience=excluded.audience,status=excluded.status,position=excluded.position,
 updated_at=now(),updated_by=auth.uid();
END;$fn$;

-- Screenshots: published manual-only assets in a public bucket; no project/private data.
-- An image becomes public as soon as admin uploads it. Admin UI makes this explicit.
INSERT INTO storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
VALUES ('sk-help-images','sk-help-images',true,5242880,ARRAY['image/jpeg','image/png','image/webp'])
ON CONFLICT (id) DO NOTHING;
CREATE POLICY sk_help_image_insert ON storage.objects FOR INSERT TO authenticated WITH CHECK(
 bucket_id='sk-help-images' AND public.sk_is_admin() AND name ~ '^[a-z0-9-]{2,60}/[a-z0-9-]{2,80}\.(png|jpg|webp)$');
CREATE POLICY sk_help_image_update ON storage.objects FOR UPDATE TO authenticated USING(bucket_id='sk-help-images' AND public.sk_is_admin()) WITH CHECK(bucket_id='sk-help-images' AND public.sk_is_admin());
CREATE POLICY sk_help_image_delete ON storage.objects FOR DELETE TO authenticated USING(bucket_id='sk-help-images' AND public.sk_is_admin());
CREATE POLICY sk_help_image_read ON storage.objects FOR SELECT TO anon,authenticated USING(bucket_id='sk-help-images');

INSERT INTO sk_internal.help_chapters(slug,title,body,section,page_key,audience,status,position) VALUES
('start','StaffKeeping kennenlernen',E'# Erste Schritte\n\nStaffKeeping verbindet Unternehmen für den flexiblen Personalaustausch.\n\n1. Registriere dein Unternehmenskonto.\n2. Bestätige deine E-Mail-Adresse.\n3. Vervollständige das Unternehmensprofil.\n4. Reiche das Profil zur Prüfung ein.\n5. Nach Freigabe kannst du den Marktplatz nutzen.\n\n![Screenshot: Anmeldeseite](screenshot:start-login-01)','Einstieg','login','public','published',10),
('registration','Unternehmen registrieren',E'# Registrierung\n\nGib E-Mail, Passwort und die Grundangaben zum Unternehmen an. Nach Bestätigung der E-Mail kannst du dein vollständiges Profil erfassen. Erst mit **Zur Prüfung einreichen** wird es für die Administration zur Prüfung bereitgestellt.\n\n![Screenshot: Registrierungsformular](screenshot:registrierung-01)','Einstieg','register','public','published',20),
('pending','Profil einreichen und Freigabe',E'# Registrierungsprüfung\n\nBis zur Einreichung kannst du dein Profil bearbeiten. Mit dem Einreichen wird es gesperrt, damit die Administration einen unveränderlichen Stand prüft. Falls eine Nachbesserung verlangt wird, wird die Bearbeitung wieder freigeschaltet. Nach Freigabe ist die Marktplatznutzung möglich.\n\n![Screenshot: Prüfstatus](screenshot:pruefstatus-01)','Einstieg','pending','public','published',30),
('profile','Unternehmensprofil verwalten',E'# Profil und Standort\n\nUnter **Profil** bearbeitest du die Kontaktdaten, Betriebsbeschreibung, Logo und bis zu fünf Bilder. Änderungen werden automatisch gespeichert. Die Adresse bestimmt den ungefähren Kartenstandort; du kannst den Marker verschieben.\n\n## Nach der Freigabe\n\nNormale Änderungen lösen eine interne Benachrichtigung für die Administration aus. Für Firmenname, USt-ID und Land stellst du einen gesonderten Änderungsantrag.\n\n![Screenshot: Unternehmensprofil](screenshot:profil-unternehmen-01)\n\n![Screenshot: Standortkarte](screenshot:profil-standort-01)','Betrieb','profile','business','published',40),
('market','Marktplatz',E'# Marktplatz\n\nNach der Freigabe kannst du Inserate suchen und filtern. **Hinweis:** Inserate sind aktuell noch Demodaten; produktive Inserate folgen in einer späteren Version.\n\n![Screenshot: Marktplatz](screenshot:marktplatz-01)','Betrieb','market','business','published',50),
('listings','Meine Inserate',E'# Inserate\n\nDieses Kapitel wird mit der echten Inserateverwaltung ergänzt. Der aktuelle Bildschirm ist eine Designvorschau.\n\n![Screenshot: Inserateverwaltung](screenshot:inserate-01)','Betrieb','my-listings','business','draft',60),
('messages','Nachrichten',E'# Nachrichten\n\nDer Nachrichtenbereich ist noch eine Designvorschau. Die echte Nachrichtenfunktion wird später eingeführt.\n\n![Screenshot: Nachrichten](screenshot:nachrichten-01)','Betrieb','messages','business','draft',70),
('admin-review','Betriebe prüfen und freigeben',E'# Administration: Betriebsprüfung\n\nDas Dashboard zeigt neue Prüfaufträge, Profiländerungen und Änderungsanträge. Öffne einen eingereichten Betrieb, prüfe seine Angaben und erteile die Freigabe oder verlange mit Begründung eine Nachbesserung. Die Profilbearbeitung ist während einer eingereichten Prüfung gesperrt.\n\n![Screenshot: Admin-Dashboard](screenshot:admin-dashboard-01)\n\n![Screenshot: Betriebsprüfung](screenshot:admin-pruefung-01)','Administration','admin-home','admin','published',80),
('reset','Passwort zurücksetzen',E'# Passwort vergessen\n\nÖffne **Passwort zurücksetzen** und fordere über deine Login-E-Mail einen Link an. Öffne den Link und vergib ein neues Passwort. Anschliessend erneut anmelden.\n\n![Screenshot: Neues Passwort](screenshot:passwort-01)','Einstieg','reset','public','published',25),
('listing-detail','Inserat ansehen',E'# Inseratdetails\n\nIn dieser Ansicht stehen die Angaben zu einem Inserat. **Aktuell handelt es sich um eine Designvorschau.** Echte Kontaktanfragen werden später integriert.\n\n![Screenshot: Inseratdetails](screenshot:inserat-detail-01)','Betrieb','detail','business','published',55),
('my-listings-help','Eigene Inserate',E'# Eigene Inserate\n\nDie Inserateverwaltung ist derzeit noch eine **Demo**. Echte Datenspeicherung und Bearbeitung folgen in einer weiteren Phase.\n\n![Screenshot: Meine Inserate](screenshot:eigene-inserate-01)','Betrieb','my-listings','business','published',60),
('chat-help','Nachrichten nutzen',E'# Nachrichten\n\nDer Nachrichtenbereich ist derzeit eine **Designvorschau**. Nachrichten werden nicht dauerhaft gespeichert oder versendet.\n\n![Screenshot: Nachrichtenseite](screenshot:nachrichten-demo-01)','Betrieb','messages','business','published',70),
('review-help','Bewertungen',E'# Bewertungen\n\nDie Bewertungsseite ist derzeit eine **Designvorschau**. Die sichtbaren Bewertungen sind keine produktiven Daten.\n\n![Screenshot: Bewertungen](screenshot:bewertungen-01)','Betrieb','reviews','business','published',75),
('admin-businesses-help','Betriebsdetails prüfen',E'# Betriebsprüfung\n\nPrüfe Firmen- und Kontaktdaten, Beschreibung, Standort und Medien eines **eingereichten** Betriebs. Anschliessend kannst du ihn freigeben oder eine begründete Nachbesserung verlangen.\n\n![Screenshot: Betriebsdetail](screenshot:admin-betrieb-01)','Administration','admin-businesses','admin','published',90),
('admin-activity-help','Aktivitäten und Anträge',E'# Aktivitäten\n\nPrüfe offene Benachrichtigungen. Profiländerungen nach Freigabe werden protokolliert. Rechtlich relevante Anträge zu Firmenname, USt-ID und Land werden separat genehmigt oder abgelehnt.\n\n![Screenshot: Admin-Aktivitäten](screenshot:admin-aktivitaeten-01)','Administration','admin-activity','admin','published',95),
('admin-listings-help','Inserate moderieren',E'# Inserate moderieren\n\nDie Moderationsansicht für Inserate zeigt aktuell **Demodaten**. Echte Admin-Aktionen werden mit dem produktiven Inseratemodul eingeführt.\n\n![Screenshot: Inseratmoderation](screenshot:admin-inserate-01)','Administration','admin-listings','admin','published',100),
('admin-impact-help','Impact-Bericht',E'# Impact\n\nDer Impact-Bereich ist derzeit ein **Designprototyp** mit Beispielzahlen. Zahlungs- und Auswertungssystem werden gesondert umgesetzt.\n\n![Screenshot: Impact](screenshot:admin-impact-01)','Administration','admin-dashboard','admin','published',110),
('admin-docs-help','Projektdokumentation pflegen',E'# Projektdokumentation\n\nUnter **Projektdoku** wird die aktuelle führende Systemdokumentation aus Supabase bearbeitet. Daneben pflegst du hier die Kapitel des Benutzerhandbuchs. Das historische Bubble-Konzept bleibt als unveränderte Referenz erhalten.\n\n![Screenshot: Projektdoku](screenshot:admin-doku-01)','Administration','admin-docs','admin','published',120)
ON CONFLICT(slug) DO NOTHING;

-- Extend existing leading documentation, preserving previously edited content.
-- Each chapter receives only material relevant to that chapter.
UPDATE sk_internal.project_doc_chapters
SET body=body||E'\n\n## 0.30: Registrierung und Betriebsprüfung\n\nNeues Unternehmen: E-Mail bestätigen, vollständiges Profil samt Medien und Standort pflegen (Entwurf), zur Prüfung einreichen (gesperrt), durch Admin freigeben oder zur Nachbesserung zurückgeben. Bestehende aktive Betriebe bleiben freigegeben. Normale Änderungen nach Freigabe erzeugen Aktivitätsmeldungen; Firmenname, Land und USt-ID laufen über separate genehmigungspflichtige Anträge.\n',updated_at=now()
WHERE slug='concept' AND body NOT LIKE '%## 0.30: Registrierung und Betriebsprüfung%';
UPDATE sk_internal.project_doc_chapters
SET body=body||E'\n\n## Entwicklungsstand 0.30 (implementiert, noch nicht live abgenommen)\n\nRegistrierung 2.0, Profil-Einreichung/Sperre, Admin-Cockpit, Änderungsanträge und integriertes Benutzerhandbuch sind im Code vorbereitet. Supabase-Migration und Testfälle müssen durchlaufen werden. Inserate/Chats/Bewertungen/Impact weiter Demo.\n',updated_at=now()
WHERE slug='status' AND body NOT LIKE '%## Entwicklungsstand 0.30%';
UPDATE sk_internal.project_doc_chapters
SET body=body||E'\n\n## Entscheidungen 0.30\n\nDer vollständige Betriebsantrag wird beim Einreichen bis zur Entscheidung gesperrt. Nachbesserung entsperrt, erneutes Einreichen sperrt erneut. Nach Freigabe: normale Profiländerungen sofort wirksam plus internes Admin-Ereignis; rechtliche Stammdaten nur über Antrag und Admin-Freigabe. Admin-Dashboard ist die Admin-Startseite. Handbuch seitenbezogen und vollständig integriert; Screenshot-Platzhalter mit eigener ID.\n',updated_at=now()
WHERE slug='decisions' AND body NOT LIKE '%## Entscheidungen 0.30%';
UPDATE sk_internal.project_doc_chapters
SET body=body||E'\n\n## Entwicklungsregeln 0.30\n\nAlle neuen oder geänderten Benutzerfunktionen erhalten zugleich technische Projektdoku, zugehöriges Handbuchkapitel mit Seitenzuordnung, ggf. Screenshot-Platzhalter sowie Test-/Abnahmestatus. Handbuch und Systemdoku werden ausschliesslich in derselben geschützten Admin-Dokumentationsverwaltung gepflegt. Öffentliche Hilfe darf nie interne Admin-Inhalte liefern.\n',updated_at=now()
WHERE slug='rules' AND body NOT LIKE '%## Entwicklungsregeln 0.30%';
UPDATE sk_internal.project_doc_chapters
SET body=body||E'\n\n## Release 0.30\n\nRegistrierung 2.0 und gesperrter Einreichungsworkflow; Admin-Dashboard für Aktivitäten und Entscheidungen; Änderungsanträge für Firmenname/Land/USt-ID; integriertes Handbuch mit Kapiteln auf jeder Seite, Suche und Screenshot-Platzhaltern. Datenbankmigration: 20261010011000_registration_dashboard_handbook.sql. Code- und SQL-Livetests noch ausstehend.\n',updated_at=now()
WHERE slug='history' AND body NOT LIKE '%## Release 0.30%';
UPDATE sk_internal.project_doc_chapters
SET body=body||E'\n\n## Zu testen: Release 0.30\n\n1. Neuer Benutzer: Registrierung, E-Mail bestätigen, vollständiges Profil (inkl. Land, USt-ID, Beschreibung, Logo, Bilder, Maps) vor Freigabe speichern.\n2. Profil einreichen: bis Adminentscheidung weder Text, Medien noch Standort via UI oder RPC ändern.\n3. Admin-Cockpit: Einreichung sichtbar, Prüfung; Nachbesserung entsperrt; erneutes Einreichen sperrt; Freigabe ermöglicht Marktplatz.\n4. Bestehender aktiver Betrieb bleibt aktiv und kann normale Angaben ändern; Admin erhält Aktivitäten auch nach Neuladen.\n5. Firmenname, Land, USt-ID nach Freigabe nur per Antrag; Admin kann genehmigen oder ablehnen.\n6. Hilfe vor Login (öffentlich), Hilfe für Betriebe, Admin-Handbuch. Normales Konto darf weder Admin-Handbuch-Entwürfe noch Admin-RPCs lesen. Screenshot-Platzhalter und Upload mit anonymisierten Bildern.\n7. Negativtests: fremde Unternehmen ändern, fremde Medien herunterladen, offene Prüfung umgehen, Adminstatus direkt ändern müssen fehlschlagen.\n8. Regressionsprüfung: Passwort-Recovery, Auto-Save bei Navigation/Zurück, Google Maps Marker und Reset, bereits genehmigtes Testunternehmen.\n',updated_at=now()
WHERE slug='tests' AND body NOT LIKE '%## Zu testen: Release 0.30%';
UPDATE sk_internal.project_doc_chapters
SET body=body||E'\n\n## Offen nach 0.30\n\nLive-Abnahme des gesamten Registrierungs- und Prüfworkflows mit neuem Betrieb und negativem API-Berechtigungstest. Weitere Fachmodule Inserate, Chats, Bewertungen und Impact produktiv umsetzen. Administrativer Benachrichtigungsversand per E-Mail bleibt separat; In-App-Aktivitäten werden sofort gespeichert. Öffentliche Screenshots erst nach Anonymisierung und Freigabe hochladen.\n',updated_at=now()
WHERE slug='issues' AND body NOT LIKE '%## Offen nach 0.30%';
UPDATE sk_internal.project_doc_chapters
SET body=body||E'\n\n## Chat-Übergabe 0.30\n\nLetzter vorbereiteter Release: 0.30 (Registrierung 2.0, Admin-Cockpit, integrierte Hilfe). SQL-Migration 20261010011000_registration_dashboard_handbook.sql vor Frontend-Push ausführen. Bestehende Unternehmensfreigaben erhalten. Bedien- und Sicherheitstests offen. Führende Systemdokumentation und Handbuch unter Admin → Projektdoku in Supabase, historisches Bubble-Konzept privat. Bei Folgereleases Kapitel statt paralleler Dokumente nachführen.\n',updated_at=now()
WHERE slug='handoff' AND body NOT LIKE '%## Chat-Übergabe 0.30%';

REVOKE ALL ON FUNCTION public.sk_update_my_registration_legal(text,public.sk_country) FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.sk_submit_my_business() FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.sk_admin_review_business(uuid,text,text) FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.sk_request_sensitive_change(text,text) FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.sk_admin_review_sensitive_change(bigint,boolean,text) FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.sk_admin_activity() FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.sk_admin_resolve_event(bigint) FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.sk_help_list(boolean) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.sk_admin_save_help(text,text,text,text,text,text,text,integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_update_my_registration_legal(text,public.sk_country) TO authenticated;
GRANT EXECUTE ON FUNCTION public.sk_submit_my_business() TO authenticated;
GRANT EXECUTE ON FUNCTION public.sk_admin_review_business(uuid,text,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.sk_request_sensitive_change(text,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.sk_admin_review_sensitive_change(bigint,boolean,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.sk_admin_activity() TO authenticated;
GRANT EXECUTE ON FUNCTION public.sk_admin_resolve_event(bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.sk_help_list(boolean) TO anon,authenticated;
GRANT EXECUTE ON FUNCTION public.sk_admin_save_help(text,text,text,text,text,text,text,integer) TO authenticated;
COMMIT;
