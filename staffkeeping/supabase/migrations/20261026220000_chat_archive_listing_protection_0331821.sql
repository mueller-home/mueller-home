-- StaffKeeping 0.33.1.8.21: abgeschlossene Chats; Schutz vor Inseratlöschung mit Chat.
BEGIN;
ALTER TABLE sk_internal.chat_threads
 ADD COLUMN IF NOT EXISTS closed_at timestamptz,
 ADD COLUMN IF NOT EXISTS closed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
 ADD COLUMN IF NOT EXISTS archived_at timestamptz;
-- Für bereits inaktive Inserate zugehörige Gespräche archivieren.
UPDATE sk_internal.chat_threads t SET archived_at=now()
 FROM public.sk_listings l WHERE l.id=t.listing_id AND l.status<>'Aktiv' AND t.archived_at IS NULL;
CREATE OR REPLACE FUNCTION sk_internal.chat_listing_lifecycle()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
BEGIN
 IF TG_OP='DELETE' THEN
  IF EXISTS(SELECT 1 FROM sk_internal.chat_threads t WHERE t.listing_id=OLD.id) THEN
   RAISE EXCEPTION 'Inserat mit Unterhaltungen darf nicht endgültig gelöscht werden. Bitte deaktivieren.' USING ERRCODE='23503';
  END IF;
  RETURN OLD;
 END IF;
 IF NEW.status<>'Aktiv' AND OLD.status='Aktiv' THEN
  UPDATE sk_internal.chat_threads SET archived_at=coalesce(archived_at,now()) WHERE listing_id=NEW.id;
 END IF;
 RETURN NEW;
END;$fn$;
DROP TRIGGER IF EXISTS sk_chat_listing_lifecycle ON public.sk_listings;
CREATE TRIGGER sk_chat_listing_lifecycle BEFORE UPDATE OF status OR DELETE ON public.sk_listings
 FOR EACH ROW EXECUTE FUNCTION sk_internal.chat_listing_lifecycle();
-- RPC statt direktem DELETE: atomar inaktiv setzen wenn Chat existiert.
CREATE OR REPLACE FUNCTION public.sk_delete_or_deactivate_listing(p_listing_id uuid,p_business_id uuid)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE v_has_chat boolean;
BEGIN
 IF auth.uid() IS NULL OR NOT sk_internal.chat_allowed(p_business_id) THEN
  RAISE EXCEPTION 'Kein Zugriff auf den Betrieb' USING ERRCODE='42501';
 END IF;
 PERFORM 1 FROM public.sk_listings WHERE id=p_listing_id AND business_id=p_business_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Inserat nicht gefunden oder kein Zugriff' USING ERRCODE='42501'; END IF;
 SELECT EXISTS(SELECT 1 FROM sk_internal.chat_threads WHERE listing_id=p_listing_id) INTO v_has_chat;
 IF v_has_chat THEN
  UPDATE public.sk_listings SET status='Inaktiv' WHERE id=p_listing_id AND business_id=p_business_id;
  UPDATE sk_internal.chat_threads SET archived_at=coalesce(archived_at,now()) WHERE listing_id=p_listing_id;
  RETURN 'deaktiviert';
 ELSE
  DELETE FROM public.sk_listings WHERE id=p_listing_id AND business_id=p_business_id;
  RETURN 'geloescht';
 END IF;
END;$fn$;
-- Beide Seiten dürfen schliessen, aber nicht fremde Gespräche.
CREATE OR REPLACE FUNCTION public.sk_chat_close(p_thread_id uuid,p_business_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
BEGIN
 IF auth.uid() IS NULL OR NOT sk_internal.chat_allowed(p_business_id)
 OR NOT EXISTS(SELECT 1 FROM sk_internal.chat_threads t WHERE t.id=p_thread_id
    AND p_business_id IN (t.sender_business_id,t.recipient_business_id)) THEN
  RAISE EXCEPTION 'Kein Zugriff auf diese Unterhaltung' USING ERRCODE='42501';
 END IF;
 UPDATE sk_internal.chat_threads SET closed_at=coalesce(closed_at,now()),closed_by=coalesce(closed_by,auth.uid())
 WHERE id=p_thread_id;
END;$fn$;
-- Sperre ist serverseitig, auch wenn eine alte Website noch sk_chat_send benutzt.
CREATE OR REPLACE FUNCTION public.sk_chat_send(p_thread_id uuid,p_sender_business_id uuid,p_body text)
RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE v_id bigint;
BEGIN
 IF NOT sk_internal.chat_allowed(p_sender_business_id) OR NOT EXISTS(
  SELECT 1 FROM sk_internal.chat_threads t JOIN public.sk_listings l ON l.id=t.listing_id
  WHERE t.id=p_thread_id AND p_sender_business_id IN (t.sender_business_id,t.recipient_business_id)
  AND t.closed_at IS NULL AND t.archived_at IS NULL AND l.status='Aktiv') THEN
  RAISE EXCEPTION 'Unterhaltung abgeschlossen oder archiviert' USING ERRCODE='42501';
 END IF;
 IF length(btrim(coalesce(p_body,''))) NOT BETWEEN 1 AND 2000 THEN RAISE EXCEPTION 'Nachricht muss 1 bis 2000 Zeichen enthalten'; END IF;
 INSERT INTO sk_internal.chat_messages(thread_id,sender_business_id,sender_user_id,body)
 VALUES(p_thread_id,p_sender_business_id,auth.uid(),btrim(p_body)) RETURNING id INTO v_id;
 UPDATE sk_internal.chat_threads SET updated_at=now() WHERE id=p_thread_id;
 RETURN v_id;
END;$fn$;
-- Zusätzliche Zustandsfelder, bestehende RPC-Signatur via DROP/CREATE aktualisieren.
DROP FUNCTION IF EXISTS public.sk_chat_threads();
CREATE FUNCTION public.sk_chat_threads()
RETURNS TABLE(id uuid,listing_title text,listing_id uuid,own_business_id uuid,other_business_name text,last_message_at timestamptz,closed_at timestamptz,archived_at timestamptz)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $fn$
 SELECT t.id,l.title,t.listing_id,
 CASE WHEN sk_internal.chat_allowed(t.sender_business_id) THEN t.sender_business_id ELSE t.recipient_business_id END,
 b.company_name,t.updated_at,t.closed_at,t.archived_at
 FROM sk_internal.chat_threads t JOIN public.sk_listings l ON l.id=t.listing_id
 JOIN public.sk_businesses b ON b.id=CASE WHEN sk_internal.chat_allowed(t.sender_business_id) THEN t.recipient_business_id ELSE t.sender_business_id END
 WHERE sk_internal.chat_allowed(t.sender_business_id) OR sk_internal.chat_allowed(t.recipient_business_id)
 ORDER BY t.updated_at DESC LIMIT 200;
$fn$;
-- Keine ungelesenen Meldungen mehr aus archivierten/abgeschlossenen Chats.
CREATE OR REPLACE FUNCTION public.sk_chat_unread_counts()
RETURNS TABLE(thread_id uuid, unread_count bigint)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $fn$
 SELECT t.id, count(m.id)::bigint FROM sk_internal.chat_threads t
 CROSS JOIN LATERAL (SELECT CASE WHEN sk_internal.chat_allowed(t.sender_business_id) THEN t.sender_business_id ELSE t.recipient_business_id END own_id) own
 LEFT JOIN sk_internal.chat_read_states r ON r.thread_id=t.id AND r.user_id=auth.uid() AND r.business_id=own.own_id
 LEFT JOIN sk_internal.chat_messages m ON m.thread_id=t.id AND m.sender_business_id<>own.own_id AND m.id>coalesce(r.last_read_message_id,0)
 WHERE auth.uid() IS NOT NULL AND t.closed_at IS NULL AND t.archived_at IS NULL
 AND (sk_internal.chat_allowed(t.sender_business_id) OR sk_internal.chat_allowed(t.recipient_business_id))
 GROUP BY t.id;
$fn$;
-- Bereits bestehende Unterhaltungen dürfen nicht über sk_chat_start wiederbeschrieben werden.
-- Zusätzlich unabhängig vom Frontend absichern via INSERT-Trigger auf Nachrichten.
CREATE OR REPLACE FUNCTION sk_internal.chat_message_guard()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
BEGIN
 IF EXISTS(SELECT 1 FROM sk_internal.chat_threads t JOIN public.sk_listings l ON l.id=t.listing_id
   WHERE t.id=NEW.thread_id AND (t.closed_at IS NOT NULL OR t.archived_at IS NOT NULL OR l.status<>'Aktiv')) THEN
  RAISE EXCEPTION 'Unterhaltung abgeschlossen oder archiviert' USING ERRCODE='42501';
 END IF;
 RETURN NEW;
END;$fn$;
DROP TRIGGER IF EXISTS sk_chat_message_guard ON sk_internal.chat_messages;
CREATE TRIGGER sk_chat_message_guard BEFORE INSERT ON sk_internal.chat_messages FOR EACH ROW EXECUTE FUNCTION sk_internal.chat_message_guard();
REVOKE ALL ON FUNCTION public.sk_delete_or_deactivate_listing(uuid,uuid),public.sk_chat_close(uuid,uuid),public.sk_chat_threads() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_delete_or_deactivate_listing(uuid,uuid),public.sk_chat_close(uuid,uuid),public.sk_chat_threads() TO authenticated;
COMMIT;
