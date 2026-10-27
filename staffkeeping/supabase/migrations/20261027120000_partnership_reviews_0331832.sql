-- StaffKeeping 0.33.1.8.32: verbindliche Vergabe, Abschluss, gegenseitige Bewertungen.
BEGIN;
ALTER TABLE public.sk_listings DROP CONSTRAINT IF EXISTS sk_listings_status_check;
ALTER TABLE public.sk_listings ADD CONSTRAINT sk_listings_status_check CHECK(status IN ('Aktiv','Inaktiv','Abgelaufen','Vergeben','Abgeschlossen'));
CREATE TABLE IF NOT EXISTS sk_internal.partnerships (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 thread_id uuid NOT NULL UNIQUE REFERENCES sk_internal.chat_threads(id) ON DELETE RESTRICT,
 listing_id uuid NOT NULL REFERENCES public.sk_listings(id) ON DELETE RESTRICT,
 owner_business_id uuid NOT NULL REFERENCES public.sk_businesses(id) ON DELETE RESTRICT,
 partner_business_id uuid NOT NULL REFERENCES public.sk_businesses(id) ON DELETE RESTRICT,
 state text NOT NULL DEFAULT 'angeboten' CHECK(state IN ('angeboten','angenommen','abgelehnt','abgeschlossen')),
 offered_at timestamptz NOT NULL DEFAULT now(), accepted_at timestamptz,
 owner_finished_at timestamptz, partner_finished_at timestamptz, finished_at timestamptz,
 CHECK(owner_business_id<>partner_business_id)
);
CREATE TABLE IF NOT EXISTS sk_internal.partnership_reviews (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 partnership_id uuid NOT NULL REFERENCES sk_internal.partnerships(id) ON DELETE RESTRICT,
 reviewer_business_id uuid NOT NULL REFERENCES public.sk_businesses(id) ON DELETE RESTRICT,
 rated_business_id uuid NOT NULL REFERENCES public.sk_businesses(id) ON DELETE RESTRICT,
 stars smallint NOT NULL CHECK(stars BETWEEN 1 AND 5),
 comment text NOT NULL DEFAULT '' CHECK(length(comment)<=1000),
 created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(partnership_id,reviewer_business_id), CHECK(reviewer_business_id<>rated_business_id)
);
CREATE UNIQUE INDEX IF NOT EXISTS sk_partnership_one_open_per_listing ON sk_internal.partnerships(listing_id) WHERE state IN ('angeboten','angenommen','abgeschlossen');
CREATE INDEX IF NOT EXISTS sk_partnerships_state_idx ON sk_internal.partnerships(state,offered_at DESC);
CREATE INDEX IF NOT EXISTS sk_partnership_reviews_rated_idx ON sk_internal.partnership_reviews(rated_business_id,created_at DESC);
ALTER TABLE sk_internal.partnerships ENABLE ROW LEVEL SECURITY;
ALTER TABLE sk_internal.partnership_reviews ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON sk_internal.partnerships,sk_internal.partnership_reviews FROM PUBLIC,anon,authenticated;

-- Alle Zustandswechsel erfolgen atomar in dieser RPC; keine direkten Tabellenrechte.
CREATE OR REPLACE FUNCTION public.sk_partnership_action(p_thread_id uuid,p_business_id uuid,p_action text)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE t sk_internal.chat_threads%ROWTYPE; l public.sk_listings%ROWTYPE; p sk_internal.partnerships%ROWTYPE; is_owner boolean; is_partner boolean;
BEGIN
 IF auth.uid() IS NULL OR NOT sk_internal.chat_allowed(p_business_id) THEN RAISE EXCEPTION 'Kein Zugriff auf diesen Betrieb' USING ERRCODE='42501'; END IF;
 SELECT * INTO t FROM sk_internal.chat_threads WHERE id=p_thread_id FOR UPDATE;
 IF NOT FOUND OR p_business_id NOT IN(t.sender_business_id,t.recipient_business_id) THEN RAISE EXCEPTION 'Unterhaltung nicht verfügbar' USING ERRCODE='42501'; END IF;
 SELECT * INTO l FROM public.sk_listings WHERE id=t.listing_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Inserat nicht vorhanden'; END IF;
 is_owner := p_business_id=l.business_id; is_partner := p_business_id<>l.business_id;
 SELECT * INTO p FROM sk_internal.partnerships WHERE thread_id=t.id FOR UPDATE;
 IF p_action='offer' THEN
  IF NOT is_owner OR (l.status<>'Aktiv' OR l.date_to<(now() AT TIME ZONE 'Europe/Zurich')::date) OR t.closed_at IS NOT NULL OR t.archived_at IS NOT NULL THEN RAISE EXCEPTION 'Vergabe kann nicht angeboten werden' USING ERRCODE='42501'; END IF;
  IF EXISTS(SELECT 1 FROM sk_internal.partnerships WHERE listing_id=l.id AND state IN('angeboten','angenommen','abgeschlossen') AND thread_id<>t.id) THEN RAISE EXCEPTION 'Es besteht bereits eine Vergabe für dieses Inserat'; END IF;
  IF p.id IS NULL THEN
   INSERT INTO sk_internal.partnerships(thread_id,listing_id,owner_business_id,partner_business_id) VALUES(t.id,l.id,l.business_id,t.sender_business_id) RETURNING * INTO p;
  ELSIF p.state='abgelehnt' THEN
   UPDATE sk_internal.partnerships SET state='angeboten',offered_at=now(),accepted_at=NULL,owner_finished_at=NULL,partner_finished_at=NULL,finished_at=NULL WHERE id=p.id;
  ELSE RAISE EXCEPTION 'Für diese Unterhaltung besteht bereits eine Vergabe'; END IF;
  RETURN 'angeboten';
 ELSIF p_action='accept' THEN
  IF NOT is_partner OR p.id IS NULL OR p.state<>'angeboten' OR p.partner_business_id<>p_business_id OR l.status<>'Aktiv' THEN RAISE EXCEPTION 'Diese Vergabe kann nicht angenommen werden' USING ERRCODE='42501'; END IF;
  UPDATE sk_internal.partnerships SET state='angenommen',accepted_at=now() WHERE id=p.id;
  UPDATE public.sk_listings SET status='Vergeben' WHERE id=l.id;
  UPDATE sk_internal.chat_threads SET archived_at=coalesce(archived_at,now()),closed_at=coalesce(closed_at,now()) WHERE listing_id=l.id AND id<>t.id;
  UPDATE sk_internal.chat_threads SET archived_at=NULL WHERE id=t.id;
  RETURN 'angenommen';
 ELSIF p_action='reject' THEN
  IF NOT is_partner OR p.id IS NULL OR p.state<>'angeboten' OR p.partner_business_id<>p_business_id THEN RAISE EXCEPTION 'Vergabe kann nicht abgelehnt werden' USING ERRCODE='42501'; END IF;
  UPDATE sk_internal.partnerships SET state='abgelehnt' WHERE id=p.id;
  RETURN 'abgelehnt';
 ELSIF p_action='finish' THEN
  IF p.id IS NULL OR p.state<>'angenommen' OR p_business_id NOT IN(p.owner_business_id,p.partner_business_id) THEN RAISE EXCEPTION 'Zusammenarbeit kann noch nicht abgeschlossen werden' USING ERRCODE='42501'; END IF;
  IF is_owner THEN UPDATE sk_internal.partnerships SET owner_finished_at=coalesce(owner_finished_at,now()) WHERE id=p.id;
  ELSE UPDATE sk_internal.partnerships SET partner_finished_at=coalesce(partner_finished_at,now()) WHERE id=p.id; END IF;
  SELECT * INTO p FROM sk_internal.partnerships WHERE id=p.id;
  IF p.owner_finished_at IS NOT NULL AND p.partner_finished_at IS NOT NULL THEN
   UPDATE sk_internal.partnerships SET state='abgeschlossen',finished_at=now() WHERE id=p.id;
   UPDATE public.sk_listings SET status='Abgeschlossen' WHERE id=l.id;
   UPDATE sk_internal.chat_threads SET archived_at=coalesce(archived_at,now()),closed_at=coalesce(closed_at,now()) WHERE id=t.id;
   RETURN 'abgeschlossen';
  END IF;
  RETURN 'abschluss_ausstehend';
 END IF;
 RAISE EXCEPTION 'Unbekannte Aktion';
END;$fn$;

-- Ein bestätigter Einsatz bleibt auch nach dem Enddatum vergeben bzw. abgeschlossen.
CREATE OR REPLACE FUNCTION public.sk_listing_expiration_guard()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE today_ch date := (now() AT TIME ZONE 'Europe/Zurich')::date;
BEGIN
 IF NEW.status IN('Vergeben','Abgeschlossen') THEN RETURN NEW; END IF;
 IF NEW.date_to<today_ch THEN NEW.status:='Abgelaufen';
 ELSIF TG_OP='UPDATE' AND OLD.status='Abgelaufen' AND NEW.status='Abgelaufen' THEN NEW.status:='Inaktiv'; END IF;
 RETURN NEW;
END;$fn$;

-- Schutz gegen nachträgliches Umstellen eines vergebenen/abgeschlossenen Inserats über alte Schreibwege.
CREATE OR REPLACE FUNCTION sk_internal.partnership_listing_guard()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
BEGIN
 IF TG_OP='DELETE' AND EXISTS(SELECT 1 FROM sk_internal.partnerships WHERE listing_id=OLD.id) THEN RAISE EXCEPTION 'Inserat mit Vergabe darf nicht gelöscht werden' USING ERRCODE='23503'; END IF;
 IF TG_OP='UPDATE' THEN
  IF OLD.status IN('Vergeben','Abgeschlossen') AND NEW.status<>OLD.status AND NOT (OLD.status='Vergeben' AND NEW.status='Abgeschlossen' AND EXISTS(SELECT 1 FROM sk_internal.partnerships WHERE listing_id=OLD.id AND state='abgeschlossen')) THEN
   RAISE EXCEPTION 'Vergebenes Inserat darf nicht manuell umgestellt werden' USING ERRCODE='42501';
  END IF;
  IF NEW.status='Vergeben' AND OLD.status<>'Vergeben' AND NOT EXISTS(SELECT 1 FROM sk_internal.partnerships WHERE listing_id=NEW.id AND state='angenommen') THEN RAISE EXCEPTION 'Vergabe muss bestätigt sein'; END IF;
 END IF;
 RETURN CASE WHEN TG_OP='DELETE' THEN OLD ELSE NEW END;
END;$fn$;
DROP TRIGGER IF EXISTS sk_partnership_listing_guard ON public.sk_listings;
CREATE TRIGGER sk_partnership_listing_guard BEFORE UPDATE OF status OR DELETE ON public.sk_listings FOR EACH ROW EXECUTE FUNCTION sk_internal.partnership_listing_guard();

-- Akzeptierte Vergabe ist die einzige Ausnahme von der Inaktiv-Archivregel.
CREATE OR REPLACE FUNCTION sk_internal.chat_message_guard()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
BEGIN
 IF EXISTS(SELECT 1 FROM sk_internal.chat_threads t JOIN public.sk_listings l ON l.id=t.listing_id
 WHERE t.id=NEW.thread_id AND (t.closed_at IS NOT NULL OR t.archived_at IS NOT NULL OR
 (l.status<>'Aktiv' AND NOT (l.status='Vergeben' AND EXISTS(SELECT 1 FROM sk_internal.partnerships p WHERE p.thread_id=t.id AND p.state='angenommen'))))) THEN
  RAISE EXCEPTION 'Unterhaltung abgeschlossen oder archiviert' USING ERRCODE='42501';
 END IF;
 RETURN NEW;
END;$fn$;
CREATE OR REPLACE FUNCTION public.sk_chat_send(p_thread_id uuid,p_sender_business_id uuid,p_body text)
RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE v_id bigint;
BEGIN
 IF NOT sk_internal.chat_allowed(p_sender_business_id) OR NOT EXISTS(
 SELECT 1 FROM sk_internal.chat_threads t JOIN public.sk_listings l ON l.id=t.listing_id
 WHERE t.id=p_thread_id AND p_sender_business_id IN(t.sender_business_id,t.recipient_business_id)
 AND t.closed_at IS NULL AND t.archived_at IS NULL
 AND (l.status='Aktiv' OR (l.status='Vergeben' AND EXISTS(SELECT 1 FROM sk_internal.partnerships p WHERE p.thread_id=t.id AND p.state='angenommen')))) THEN
 RAISE EXCEPTION 'Unterhaltung abgeschlossen oder archiviert' USING ERRCODE='42501'; END IF;
 IF length(btrim(coalesce(p_body,''))) NOT BETWEEN 1 AND 2000 THEN RAISE EXCEPTION 'Nachricht muss 1 bis 2000 Zeichen enthalten'; END IF;
 INSERT INTO sk_internal.chat_messages(thread_id,sender_business_id,sender_user_id,body)
 VALUES(p_thread_id,p_sender_business_id,auth.uid(),btrim(p_body)) RETURNING id INTO v_id;
 UPDATE sk_internal.chat_threads SET updated_at=now() WHERE id=p_thread_id;
 RETURN v_id;
END;$fn$;

CREATE OR REPLACE FUNCTION public.sk_partnership_overview()
RETURNS TABLE(id uuid,thread_id uuid,listing_id uuid,listing_title text,owner_business_id uuid,partner_business_id uuid,state text,owner_finished boolean,partner_finished boolean,finished_at timestamptz,offered_at timestamptz,has_reviewed boolean)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $fn$
 SELECT p.id,p.thread_id,p.listing_id,l.title,p.owner_business_id,p.partner_business_id,p.state,
 p.owner_finished_at IS NOT NULL,p.partner_finished_at IS NOT NULL,p.finished_at,p.offered_at,
 EXISTS(SELECT 1 FROM sk_internal.partnership_reviews r WHERE r.partnership_id=p.id AND sk_internal.chat_allowed(r.reviewer_business_id) AND r.reviewer_business_id IN(p.owner_business_id,p.partner_business_id))
 FROM sk_internal.partnerships p JOIN public.sk_listings l ON l.id=p.listing_id
 WHERE sk_internal.chat_allowed(p.owner_business_id) OR sk_internal.chat_allowed(p.partner_business_id)
 ORDER BY p.offered_at DESC LIMIT 200;
$fn$;
CREATE OR REPLACE FUNCTION public.sk_partnership_review(p_partnership_id uuid,p_reviewer_business_id uuid,p_stars int,p_comment text DEFAULT '')
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE p sk_internal.partnerships%ROWTYPE; v_id uuid; v_other uuid;
BEGIN
 SELECT * INTO p FROM sk_internal.partnerships WHERE id=p_partnership_id;
 IF NOT FOUND OR p.state<>'abgeschlossen' OR p_reviewer_business_id NOT IN(p.owner_business_id,p.partner_business_id)
 OR NOT sk_internal.chat_allowed(p_reviewer_business_id) THEN RAISE EXCEPTION 'Bewertung nicht erlaubt' USING ERRCODE='42501'; END IF;
 IF p_stars NOT BETWEEN 1 AND 5 OR length(coalesce(p_comment,''))>1000 THEN RAISE EXCEPTION 'Ungültige Bewertung'; END IF;
 v_other:=CASE WHEN p_reviewer_business_id=p.owner_business_id THEN p.partner_business_id ELSE p.owner_business_id END;
 INSERT INTO sk_internal.partnership_reviews(partnership_id,reviewer_business_id,rated_business_id,stars,comment)
 VALUES(p.id,p_reviewer_business_id,v_other,p_stars,btrim(coalesce(p_comment,''))) RETURNING id INTO v_id;
 RETURN v_id;
END;$fn$;
-- Rückmeldungen nach beidseitiger Abgabe oder nach 14 Tagen sichtbar; eigene Abgaben immer.
CREATE OR REPLACE FUNCTION public.sk_partnership_reviews()
RETURNS TABLE(partnership_id uuid,listing_title text,reviewer_business_id uuid,rated_business_id uuid,reviewer_name text,stars smallint,comment text,created_at timestamptz,visible boolean)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $fn$
 SELECT r.partnership_id,l.title,r.reviewer_business_id,r.rated_business_id,b.company_name,
 CASE WHEN sk_internal.chat_allowed(r.reviewer_business_id) OR p.finished_at<=now()-interval '14 days' OR EXISTS(SELECT 1 FROM sk_internal.partnership_reviews x WHERE x.partnership_id=p.id AND x.reviewer_business_id=r.rated_business_id) THEN r.stars ELSE NULL::smallint END,
 CASE WHEN sk_internal.chat_allowed(r.reviewer_business_id) OR
 (p.finished_at<=now()-interval '14 days' OR EXISTS(SELECT 1 FROM sk_internal.partnership_reviews x WHERE x.partnership_id=p.id AND x.reviewer_business_id=r.rated_business_id))
 THEN r.comment ELSE '' END,r.created_at,
 (sk_internal.chat_allowed(r.reviewer_business_id) OR p.finished_at<=now()-interval '14 days' OR EXISTS(SELECT 1 FROM sk_internal.partnership_reviews x WHERE x.partnership_id=p.id AND x.reviewer_business_id=r.rated_business_id))
 FROM sk_internal.partnership_reviews r JOIN sk_internal.partnerships p ON p.id=r.partnership_id
 JOIN public.sk_listings l ON l.id=p.listing_id JOIN public.sk_businesses b ON b.id=r.reviewer_business_id
 WHERE sk_internal.chat_allowed(r.reviewer_business_id) OR sk_internal.chat_allowed(r.rated_business_id)
 ORDER BY r.created_at DESC LIMIT 200;
$fn$;
REVOKE ALL ON FUNCTION public.sk_partnership_action(uuid,uuid,text),public.sk_partnership_overview(),public.sk_partnership_review(uuid,uuid,int,text),public.sk_partnership_reviews(),public.sk_chat_send(uuid,uuid,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_partnership_action(uuid,uuid,text),public.sk_partnership_overview(),public.sk_partnership_review(uuid,uuid,int,text),public.sk_partnership_reviews(),public.sk_chat_send(uuid,uuid,text) TO authenticated;
COMMIT;
-- Bestehenden Ablaufjob ersetzen: bestätigte Vergaben niemals als abgelaufen überschreiben.
SELECT cron.schedule('sk-expire-listings','0 * * * *',
 $$UPDATE public.sk_listings SET status='Abgelaufen'
 WHERE date_to<(now() AT TIME ZONE 'Europe/Zurich')::date AND status IN('Aktiv','Inaktiv')$$);
NOTIFY pgrst, 'reload schema';
