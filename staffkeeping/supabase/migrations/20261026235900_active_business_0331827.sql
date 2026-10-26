-- StaffKeeping 0.33.1.8.27 – Betriebskontext und gebundene Umkreissuche.
BEGIN;
CREATE OR REPLACE FUNCTION public.sk_marketplace_distances_for_business(p_business_id uuid)
RETURNS TABLE(listing_id uuid, distance_km double precision, origin_available boolean)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $fn$
  WITH access_check AS (
    SELECT CASE WHEN p_business_id IS NULL THEN public.sk_is_admin()
      ELSE EXISTS(SELECT 1 FROM public.sk_business_members m
       JOIN public.sk_businesses b ON b.id=m.business_id
       WHERE m.user_id=auth.uid() AND b.id=p_business_id AND b.status='Freigeschaltet' AND b.review_state='approved')
      END AS allowed
  ), origin AS (
    SELECT b.latitude, b.longitude
    FROM public.sk_business_members m
    JOIN public.sk_businesses b ON b.id=m.business_id
    WHERE m.user_id=auth.uid() AND b.id=p_business_id
      AND b.status='Freigeschaltet' AND b.review_state='approved'
      AND b.latitude IS NOT NULL AND b.longitude IS NOT NULL
      AND b.location_source IN ('geocoded','manual')
    LIMIT 1
  )
  SELECT l.id,
    CASE WHEN o.latitude IS NOT NULL AND target.latitude IS NOT NULL
            AND target.longitude IS NOT NULL AND target.location_source IN ('geocoded','manual')
      THEN 6371.0 * 2 * asin(sqrt(least(1.0,
        power(sin(radians(target.latitude-o.latitude)/2),2)
        + cos(radians(o.latitude))*cos(radians(target.latitude))
        * power(sin(radians(target.longitude-o.longitude)/2),2))))
      ELSE NULL END AS distance_km,
    (o.latitude IS NOT NULL) AS origin_available
  FROM public.sk_listings l
  JOIN public.sk_businesses target ON target.id=l.business_id
  LEFT JOIN origin o ON true
  WHERE auth.uid() IS NOT NULL AND (SELECT allowed FROM access_check)
    AND l.status='Aktiv' AND l.date_to>=CURRENT_DATE
    AND target.status='Freigeschaltet' AND target.review_state='approved'
    AND NOT EXISTS (
      SELECT 1 FROM public.sk_business_members mine
      WHERE mine.user_id=auth.uid() AND mine.business_id=l.business_id
    )
    AND (
      public.sk_is_admin()
      OR EXISTS (
        SELECT 1 FROM public.sk_business_members mine
        JOIN public.sk_businesses own_b ON own_b.id=mine.business_id
        WHERE mine.user_id=auth.uid()
          AND own_b.status='Freigeschaltet' AND own_b.review_state='approved'
      )
    );
$fn$;
REVOKE ALL ON FUNCTION public.sk_marketplace_distances_for_business(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_marketplace_distances_for_business(uuid) TO authenticated;
-- Auch gespeicherte Suchen müssen ihren Ausgangsbetrieb serverseitig validieren.
CREATE OR REPLACE FUNCTION public.sk_save_saved_search(p_id uuid,p_name text,p_filters jsonb,p_email_enabled boolean DEFAULT false)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE v_id uuid;v_filter jsonb;
BEGIN
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Anmeldung erforderlich' USING ERRCODE='42501'; END IF;
 IF char_length(btrim(coalesce(p_name,''))) NOT BETWEEN 1 AND 80 THEN RAISE EXCEPTION 'Name muss 1 bis 80 Zeichen enthalten'; END IF;
 IF p_filters IS NULL OR jsonb_typeof(p_filters)<>'object' OR pg_column_size(p_filters)>4096 THEN RAISE EXCEPTION 'Ungültige Suchfilter'; END IF;
 -- Nur bekannte Filter zulassen; keine versteckten Rechte oder beliebige Query-Parameter persistieren.
 IF EXISTS (SELECT 1 FROM jsonb_object_keys(p_filters) k WHERE k NOT IN ('keyword','type','category','radius','date','accommodation','origin_business_id')) THEN RAISE EXCEPTION 'Unbekannter Suchfilter'; END IF;
 IF jsonb_typeof(coalesce(p_filters->'accommodation','false'::jsonb))<>'boolean'
    OR EXISTS (SELECT 1 FROM jsonb_each(p_filters) e WHERE e.key <> 'accommodation' AND jsonb_typeof(e.value)<>'string') THEN RAISE EXCEPTION 'Ungültiger Filterwert'; END IF;
 IF length(coalesce(p_filters->>'keyword',''))>200 THEN RAISE EXCEPTION 'Stichwort zu lang'; END IF;
 IF coalesce(p_filters->>'type','') NOT IN ('','Personal gesucht','Personal verfügbar') THEN RAISE EXCEPTION 'Ungültiger Inserattyp'; END IF;
 IF coalesce(p_filters->>'category','') NOT IN ('','Küche','Service','Housekeeping','Technik','Animation') THEN RAISE EXCEPTION 'Ungültige Kategorie'; END IF;
 IF coalesce(p_filters->>'radius','') NOT IN ('','Alle Entfernungen','10 km','25 km','50 km','100 km','200 km') THEN RAISE EXCEPTION 'Ungültiger Umkreis'; END IF;
 IF coalesce(p_filters->>'date','') !~ '^$|^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN RAISE EXCEPTION 'Ungültiges Datum'; END IF;
 IF nullif(p_filters->>'origin_business_id','') IS NOT NULL AND NOT EXISTS (
   SELECT 1 FROM public.sk_business_members m JOIN public.sk_businesses b ON b.id=m.business_id
   WHERE m.user_id=auth.uid() AND b.id=(CASE WHEN (p_filters->>'origin_business_id') ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN (p_filters->>'origin_business_id')::uuid ELSE NULL END)
   AND b.status='Freigeschaltet' AND b.review_state='approved'
 ) THEN RAISE EXCEPTION 'Ausgangsbetrieb nicht freigegeben' USING ERRCODE='42501'; END IF;
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

REVOKE ALL ON FUNCTION public.sk_save_saved_search(uuid,text,jsonb,boolean) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_save_saved_search(uuid,text,jsonb,boolean) TO authenticated;
COMMIT;
