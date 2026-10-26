-- StaffKeeping 0.33.1.8.26 – private gespeicherte Marktplatzsuchen.
-- E-Mail-Präferenz wird nur gespeichert. Noch kein geplanter Versand.
BEGIN;
CREATE TABLE IF NOT EXISTS sk_internal.saved_searches (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
 name text NOT NULL CHECK (char_length(btrim(name)) BETWEEN 1 AND 80),
 filters jsonb NOT NULL DEFAULT '{}'::jsonb,
 email_enabled boolean NOT NULL DEFAULT false,
 created_at timestamptz NOT NULL DEFAULT now(),
 updated_at timestamptz NOT NULL DEFAULT now(),
 CONSTRAINT sk_saved_filters_object CHECK(jsonb_typeof(filters)='object')
);
CREATE INDEX IF NOT EXISTS sk_saved_searches_user_idx ON sk_internal.saved_searches(user_id,updated_at DESC);
ALTER TABLE sk_internal.saved_searches ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE sk_internal.saved_searches FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.sk_list_saved_searches()
RETURNS TABLE(id uuid,name text,filters jsonb,email_enabled boolean,created_at timestamptz,updated_at timestamptz)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $fn$
BEGIN
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Anmeldung erforderlich' USING ERRCODE='42501'; END IF;
 RETURN QUERY SELECT s.id,s.name,s.filters,s.email_enabled,s.created_at,s.updated_at
 FROM sk_internal.saved_searches s WHERE s.user_id=auth.uid() ORDER BY s.updated_at DESC LIMIT 100;
END;$fn$;

CREATE OR REPLACE FUNCTION public.sk_save_saved_search(p_id uuid,p_name text,p_filters jsonb,p_email_enabled boolean DEFAULT false)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE v_id uuid;v_filter jsonb;
BEGIN
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Anmeldung erforderlich' USING ERRCODE='42501'; END IF;
 IF char_length(btrim(coalesce(p_name,''))) NOT BETWEEN 1 AND 80 THEN RAISE EXCEPTION 'Name muss 1 bis 80 Zeichen enthalten'; END IF;
 IF p_filters IS NULL OR jsonb_typeof(p_filters)<>'object' OR pg_column_size(p_filters)>4096 THEN RAISE EXCEPTION 'Ungültige Suchfilter'; END IF;
 -- Nur bekannte Filter zulassen; keine versteckten Rechte oder beliebige Query-Parameter persistieren.
 IF EXISTS (SELECT 1 FROM jsonb_object_keys(p_filters) k WHERE k NOT IN ('keyword','type','category','radius','date','accommodation')) THEN RAISE EXCEPTION 'Unbekannter Suchfilter'; END IF;
 IF jsonb_typeof(coalesce(p_filters->'accommodation','false'::jsonb))<>'boolean'
    OR EXISTS (SELECT 1 FROM jsonb_each(p_filters) e WHERE e.key <> 'accommodation' AND jsonb_typeof(e.value)<>'string') THEN RAISE EXCEPTION 'Ungültiger Filterwert'; END IF;
 IF length(coalesce(p_filters->>'keyword',''))>200 THEN RAISE EXCEPTION 'Stichwort zu lang'; END IF;
 IF coalesce(p_filters->>'type','') NOT IN ('','Personal gesucht','Personal verfügbar') THEN RAISE EXCEPTION 'Ungültiger Inserattyp'; END IF;
 IF coalesce(p_filters->>'category','') NOT IN ('','Küche','Service','Housekeeping','Technik','Animation') THEN RAISE EXCEPTION 'Ungültige Kategorie'; END IF;
 IF coalesce(p_filters->>'radius','') NOT IN ('','Alle Entfernungen','10 km','25 km','50 km','100 km','200 km') THEN RAISE EXCEPTION 'Ungültiger Umkreis'; END IF;
 IF coalesce(p_filters->>'date','') !~ '^$|^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN RAISE EXCEPTION 'Ungültiges Datum'; END IF;
 IF p_id IS NULL THEN
   IF (SELECT count(*) FROM sk_internal.saved_searches WHERE user_id=auth.uid())>=30 THEN RAISE EXCEPTION 'Maximal 30 gespeicherte Suchen erlaubt'; END IF;
   INSERT INTO sk_internal.saved_searches(user_id,name,filters,email_enabled) VALUES(auth.uid(),btrim(p_name),p_filters,coalesce(p_email_enabled,false)) RETURNING id INTO v_id;
 ELSE
   UPDATE sk_internal.saved_searches s SET name=btrim(p_name),filters=p_filters,email_enabled=coalesce(p_email_enabled,false),updated_at=now()
   WHERE s.id=p_id AND s.user_id=auth.uid() RETURNING s.id INTO v_id;
   IF v_id IS NULL THEN RAISE EXCEPTION 'Gespeicherte Suche nicht gefunden oder kein Zugriff' USING ERRCODE='42501'; END IF;
 END IF;
 RETURN v_id;
END;$fn$;

CREATE OR REPLACE FUNCTION public.sk_delete_saved_search(p_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
BEGIN
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Anmeldung erforderlich' USING ERRCODE='42501'; END IF;
 DELETE FROM sk_internal.saved_searches s WHERE s.id=p_id AND s.user_id=auth.uid();
 IF NOT FOUND THEN RAISE EXCEPTION 'Gespeicherte Suche nicht gefunden oder kein Zugriff' USING ERRCODE='42501'; END IF;
END;$fn$;
REVOKE ALL ON FUNCTION public.sk_list_saved_searches(),public.sk_save_saved_search(uuid,text,jsonb,boolean),public.sk_delete_saved_search(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_list_saved_searches(),public.sk_save_saved_search(uuid,text,jsonb,boolean),public.sk_delete_saved_search(uuid) TO authenticated;
COMMIT;
