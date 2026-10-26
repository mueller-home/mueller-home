-- StaffKeeping 0.33.1.8.13: private, business-specific chat. Run before deploying the ZIP.
BEGIN;
CREATE TABLE IF NOT EXISTS sk_internal.chat_threads (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), listing_id uuid NOT NULL REFERENCES public.sk_listings(id) ON DELETE CASCADE,
 sender_business_id uuid NOT NULL REFERENCES public.sk_businesses(id) ON DELETE CASCADE,
 recipient_business_id uuid NOT NULL REFERENCES public.sk_businesses(id) ON DELETE CASCADE,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(),
 CONSTRAINT sk_chat_different_businesses CHECK(sender_business_id<>recipient_business_id),
 CONSTRAINT sk_chat_unique UNIQUE(listing_id,sender_business_id)
);
CREATE TABLE IF NOT EXISTS sk_internal.chat_messages (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 thread_id uuid NOT NULL REFERENCES sk_internal.chat_threads(id) ON DELETE CASCADE,
 sender_business_id uuid NOT NULL REFERENCES public.sk_businesses(id) ON DELETE CASCADE,
 sender_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
 body text NOT NULL CHECK(length(btrim(body)) BETWEEN 1 AND 2000),
 created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS sk_chat_messages_thread_idx ON sk_internal.chat_messages(thread_id,id);
CREATE INDEX IF NOT EXISTS sk_chat_threads_sender_idx ON sk_internal.chat_threads(sender_business_id,updated_at DESC);
CREATE INDEX IF NOT EXISTS sk_chat_threads_recipient_idx ON sk_internal.chat_threads(recipient_business_id,updated_at DESC);
ALTER TABLE sk_internal.chat_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE sk_internal.chat_messages ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON sk_internal.chat_threads,sk_internal.chat_messages FROM PUBLIC,anon,authenticated;
CREATE OR REPLACE FUNCTION sk_internal.chat_allowed(p_business uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $fn$
 SELECT auth.uid() IS NOT NULL AND EXISTS(
 SELECT 1 FROM public.sk_business_members m JOIN public.sk_businesses b ON b.id=m.business_id
 WHERE m.business_id=p_business AND m.user_id=auth.uid() AND b.status='Freigeschaltet' AND b.review_state='approved'
 );
$fn$;
REVOKE ALL ON FUNCTION sk_internal.chat_allowed(uuid) FROM PUBLIC,anon,authenticated;
CREATE OR REPLACE FUNCTION public.sk_chat_start(p_listing_id uuid,p_sender_business_id uuid,p_body text)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE l public.sk_listings%ROWTYPE; v_thread uuid;
BEGIN
 IF NOT sk_internal.chat_allowed(p_sender_business_id) THEN RAISE EXCEPTION 'Kein Zugriff auf den ausgewählten Betrieb' USING ERRCODE='42501'; END IF;
 SELECT * INTO l FROM public.sk_listings WHERE id=p_listing_id AND status='Aktiv' AND date_to >= (now() AT TIME ZONE 'Europe/Zurich')::date;
 IF NOT FOUND OR NOT EXISTS(
  SELECT 1 FROM public.sk_businesses b WHERE b.id=l.business_id AND b.status='Freigeschaltet' AND b.review_state='approved'
 ) THEN RAISE EXCEPTION 'Inserat nicht verfügbar' USING ERRCODE='42501'; END IF;
 IF l.business_id=p_sender_business_id THEN RAISE EXCEPTION 'Eigene Inserate können nicht kontaktiert werden'; END IF;
 IF length(btrim(coalesce(p_body,''))) NOT BETWEEN 1 AND 2000 THEN RAISE EXCEPTION 'Nachricht muss 1 bis 2000 Zeichen enthalten'; END IF;
 INSERT INTO sk_internal.chat_threads(listing_id,sender_business_id,recipient_business_id)
 VALUES(p_listing_id,p_sender_business_id,l.business_id)
 ON CONFLICT(listing_id,sender_business_id) DO UPDATE SET updated_at=sk_internal.chat_threads.updated_at
 RETURNING id INTO v_thread;
 INSERT INTO sk_internal.chat_messages(thread_id,sender_business_id,sender_user_id,body)
 VALUES(v_thread,p_sender_business_id,auth.uid(),btrim(p_body));
 UPDATE sk_internal.chat_threads SET updated_at=now() WHERE id=v_thread;
 RETURN v_thread;
END;$fn$;
CREATE OR REPLACE FUNCTION public.sk_chat_threads()
RETURNS TABLE(id uuid,listing_title text,listing_id uuid,own_business_id uuid,other_business_name text,last_message_at timestamptz)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $fn$
 SELECT t.id,l.title,t.listing_id,
 CASE WHEN sk_internal.chat_allowed(t.sender_business_id) THEN t.sender_business_id ELSE t.recipient_business_id END,
 b.company_name,t.updated_at
 FROM sk_internal.chat_threads t JOIN public.sk_listings l ON l.id=t.listing_id
 JOIN public.sk_businesses b ON b.id=CASE WHEN sk_internal.chat_allowed(t.sender_business_id) THEN t.recipient_business_id ELSE t.sender_business_id END
 WHERE sk_internal.chat_allowed(t.sender_business_id) OR sk_internal.chat_allowed(t.recipient_business_id)
 ORDER BY t.updated_at DESC LIMIT 200;
$fn$;
CREATE OR REPLACE FUNCTION public.sk_chat_messages(p_thread_id uuid)
RETURNS TABLE(id bigint,body text,sender_business_id uuid,created_at timestamptz)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $fn$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM sk_internal.chat_threads t WHERE t.id=p_thread_id AND (sk_internal.chat_allowed(t.sender_business_id) OR sk_internal.chat_allowed(t.recipient_business_id))) THEN RAISE EXCEPTION 'Unterhaltung nicht verfügbar' USING ERRCODE='42501'; END IF;
 RETURN QUERY SELECT m.id,m.body,m.sender_business_id,m.created_at FROM sk_internal.chat_messages m WHERE m.thread_id=p_thread_id ORDER BY m.id ASC LIMIT 500;
END;$fn$;
CREATE OR REPLACE FUNCTION public.sk_chat_send(p_thread_id uuid,p_sender_business_id uuid,p_body text)
RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE v_id bigint;
BEGIN
 IF NOT sk_internal.chat_allowed(p_sender_business_id) OR NOT EXISTS(SELECT 1 FROM sk_internal.chat_threads t WHERE t.id=p_thread_id AND p_sender_business_id IN (t.sender_business_id,t.recipient_business_id)) THEN RAISE EXCEPTION 'Kein Zugriff auf diese Unterhaltung' USING ERRCODE='42501'; END IF;
 IF length(btrim(coalesce(p_body,''))) NOT BETWEEN 1 AND 2000 THEN RAISE EXCEPTION 'Nachricht muss 1 bis 2000 Zeichen enthalten'; END IF;
 INSERT INTO sk_internal.chat_messages(thread_id,sender_business_id,sender_user_id,body) VALUES(p_thread_id,p_sender_business_id,auth.uid(),btrim(p_body)) RETURNING id INTO v_id;
 UPDATE sk_internal.chat_threads SET updated_at=now() WHERE id=p_thread_id;
 RETURN v_id;
END;$fn$;
REVOKE ALL ON FUNCTION public.sk_chat_start(uuid,uuid,text),public.sk_chat_threads(),public.sk_chat_messages(uuid),public.sk_chat_send(uuid,uuid,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_chat_start(uuid,uuid,text),public.sk_chat_threads(),public.sk_chat_messages(uuid),public.sk_chat_send(uuid,uuid,text) TO authenticated;
COMMIT;
SELECT 'Chat-Funktionen eingerichtet' AS ergebnis;
