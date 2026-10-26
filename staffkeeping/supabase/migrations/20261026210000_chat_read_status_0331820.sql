-- StaffKeeping 0.33.1.8.20: Lesestatus je Benutzer, Betrieb und Unterhaltung.
BEGIN;
CREATE TABLE IF NOT EXISTS sk_internal.chat_read_states (
 thread_id uuid NOT NULL REFERENCES sk_internal.chat_threads(id) ON DELETE CASCADE,
 user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
 business_id uuid NOT NULL REFERENCES public.sk_businesses(id) ON DELETE CASCADE,
 last_read_message_id bigint NOT NULL DEFAULT 0 CHECK(last_read_message_id >= 0),
 read_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY(thread_id,user_id,business_id)
);
ALTER TABLE sk_internal.chat_read_states ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON sk_internal.chat_read_states FROM PUBLIC,anon,authenticated;
CREATE OR REPLACE FUNCTION public.sk_chat_unread_counts()
RETURNS TABLE(thread_id uuid, unread_count bigint)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $fn$
 SELECT t.id, count(m.id)::bigint
 FROM sk_internal.chat_threads t
 CROSS JOIN LATERAL (
  SELECT CASE WHEN sk_internal.chat_allowed(t.sender_business_id) THEN t.sender_business_id
              ELSE t.recipient_business_id END AS own_id
 ) own
 LEFT JOIN sk_internal.chat_read_states r ON r.thread_id=t.id AND r.user_id=auth.uid() AND r.business_id=own.own_id
 LEFT JOIN sk_internal.chat_messages m ON m.thread_id=t.id
  AND m.sender_business_id<>own.own_id
  AND m.id>coalesce(r.last_read_message_id,0)
 WHERE auth.uid() IS NOT NULL AND (sk_internal.chat_allowed(t.sender_business_id) OR sk_internal.chat_allowed(t.recipient_business_id))
 GROUP BY t.id;
$fn$;
CREATE OR REPLACE FUNCTION public.sk_chat_mark_read(p_thread_id uuid,p_business_id uuid,p_last_message_id bigint)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE v_max bigint;
BEGIN
 IF auth.uid() IS NULL OR NOT sk_internal.chat_allowed(p_business_id)
    OR NOT EXISTS(SELECT 1 FROM sk_internal.chat_threads t WHERE t.id=p_thread_id AND p_business_id IN (t.sender_business_id,t.recipient_business_id))
 THEN RAISE EXCEPTION 'Kein Zugriff auf diese Unterhaltung' USING ERRCODE='42501'; END IF;
 SELECT max(m.id) INTO v_max FROM sk_internal.chat_messages m WHERE m.thread_id=p_thread_id;
 IF p_last_message_id IS NULL OR p_last_message_id<0 OR p_last_message_id>coalesce(v_max,0)
 THEN RAISE EXCEPTION 'Ungültiger Nachrichtenstand' USING ERRCODE='22023'; END IF;
 INSERT INTO sk_internal.chat_read_states(thread_id,user_id,business_id,last_read_message_id)
 VALUES(p_thread_id,auth.uid(),p_business_id,p_last_message_id)
 ON CONFLICT(thread_id,user_id,business_id) DO UPDATE
 SET last_read_message_id=greatest(sk_internal.chat_read_states.last_read_message_id,excluded.last_read_message_id),read_at=now();
END;$fn$;
REVOKE ALL ON FUNCTION public.sk_chat_unread_counts(),public.sk_chat_mark_read(uuid,uuid,bigint) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_chat_unread_counts(),public.sk_chat_mark_read(uuid,uuid,bigint) TO authenticated;
COMMIT;
