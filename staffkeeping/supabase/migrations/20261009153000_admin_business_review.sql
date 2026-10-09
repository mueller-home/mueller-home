-- StaffKeeping 0.24 – geschützte Admin-Details, Notizen und Freigabehistorie
-- Einmal nach 20261009120000_auth_foundation.sql im StaffKeeping-Projekt ausführen.
-- Eine Transaktion: DDL, Funktionen, Rechte. Keine SELECT-Resultsets.
-- Erst SQL installieren, DANN die Frontend-Dateien von 0.24 veröffentlichen.
BEGIN;

CREATE TABLE sk_internal.business_admin_notes (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  business_id uuid NOT NULL REFERENCES public.sk_businesses(id) ON DELETE CASCADE,
  author_id uuid NOT NULL REFERENCES auth.users(id),
  note text NOT NULL CHECK (char_length(btrim(note)) BETWEEN 1 AND 3000),
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX business_admin_notes_business_created_idx
  ON sk_internal.business_admin_notes (business_id, created_at DESC);
REVOKE ALL ON sk_internal.business_admin_notes FROM PUBLIC, anon, authenticated;

-- Ausschliesslich über eine nachgewiesene Admin-Rolle abrufbar.
-- Keine Offenlegung der Notiz-/Audit-Tabelle via Data API.
CREATE FUNCTION public.sk_admin_get_business_details(p_business_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE v_result jsonb;
BEGIN
 IF NOT public.sk_is_admin() THEN
   RAISE EXCEPTION 'Nur Administratoren' USING ERRCODE = '42501';
 END IF;
 SELECT jsonb_build_object(
   'business', to_jsonb(b),
   'members', COALESCE((
     SELECT jsonb_agg(jsonb_build_object('role',m.role,'email',u.email,'created_at',m.created_at)
                      ORDER BY m.created_at)
     FROM public.sk_business_members m JOIN auth.users u ON u.id = m.user_id
     WHERE m.business_id=b.id
   ),'[]'::jsonb),
   'notes', COALESCE((
     SELECT jsonb_agg(jsonb_build_object('id',n.id,'note',n.note,'created_at',n.created_at,'author',u.email)
                      ORDER BY n.created_at DESC,n.id DESC)
     FROM sk_internal.business_admin_notes n JOIN auth.users u ON u.id=n.author_id
     WHERE n.business_id=b.id
   ),'[]'::jsonb),
   'audit', COALESCE((
     SELECT jsonb_agg(jsonb_build_object('old_status',a.old_status,'new_status',a.new_status,'changed_at',a.changed_at,'changed_by',u.email)
                      ORDER BY a.changed_at DESC,a.id DESC)
     FROM sk_internal.business_status_audit a JOIN auth.users u ON u.id=a.changed_by
     WHERE a.business_id=b.id
   ),'[]'::jsonb)
 ) INTO v_result FROM public.sk_businesses b WHERE b.id=p_business_id;
 IF v_result IS NULL THEN
   RAISE EXCEPTION 'Unternehmen nicht gefunden' USING ERRCODE='22023';
 END IF;
 RETURN v_result;
END;
$$;

CREATE FUNCTION public.sk_admin_add_business_note(p_business_id uuid, p_note text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
 IF NOT public.sk_is_admin() THEN
   RAISE EXCEPTION 'Nur Administratoren' USING ERRCODE = '42501';
 END IF;
 IF p_note IS NULL OR char_length(btrim(p_note)) NOT BETWEEN 1 AND 3000 THEN
   RAISE EXCEPTION 'Notiz muss 1 bis 3000 Zeichen haben' USING ERRCODE = '22023';
 END IF;
 INSERT INTO sk_internal.business_admin_notes(business_id,author_id,note)
 VALUES (p_business_id,auth.uid(),btrim(p_note));
END;
$$;

REVOKE ALL ON FUNCTION public.sk_admin_get_business_details(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.sk_admin_add_business_note(uuid,text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.sk_admin_get_business_details(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.sk_admin_add_business_note(uuid,text) TO authenticated;
COMMIT;
