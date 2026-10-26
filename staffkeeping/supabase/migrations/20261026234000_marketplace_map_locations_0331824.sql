-- StaffKeeping 0.33.1.8.24: gerundete Kartenpositionen für sichtbare Inserate.
-- Exakte Betriebskoordinaten werden durch diese RPC nicht offengelegt.
BEGIN;
CREATE OR REPLACE FUNCTION public.sk_marketplace_map_locations()
RETURNS TABLE(listing_id uuid, latitude double precision, longitude double precision)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $fn$
 SELECT l.id,
        round(b.latitude::numeric,2)::double precision,
        round(b.longitude::numeric,2)::double precision
 FROM public.sk_listings l
 JOIN public.sk_businesses b ON b.id=l.business_id
 WHERE auth.uid() IS NOT NULL
   AND l.status='Aktiv' AND l.date_to>=CURRENT_DATE
   AND b.status='Freigeschaltet' AND b.review_state='approved'
   AND b.location_source IN ('geocoded','manual')
   AND b.latitude BETWEEN -90 AND 90 AND b.longitude BETWEEN -180 AND 180
   AND NOT EXISTS (
     SELECT 1 FROM public.sk_business_members own
     WHERE own.user_id=auth.uid() AND own.business_id=l.business_id
   )
   AND (
     public.sk_is_admin()
     OR EXISTS (
       SELECT 1 FROM public.sk_business_members my
       JOIN public.sk_businesses approved ON approved.id=my.business_id
       WHERE my.user_id=auth.uid()
         AND approved.status='Freigeschaltet' AND approved.review_state='approved'
     )
   );
$fn$;
REVOKE ALL ON FUNCTION public.sk_marketplace_map_locations() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.sk_marketplace_map_locations() TO authenticated;
COMMIT;
SELECT p.proname AS funktion,p.prosecdef AS security_definer,
 has_function_privilege('authenticated',p.oid,'EXECUTE') AS authenticated_execute
FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname='public' AND p.proname='sk_marketplace_map_locations';
