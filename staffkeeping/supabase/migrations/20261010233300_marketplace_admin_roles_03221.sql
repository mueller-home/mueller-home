-- StaffKeeping 0.32.2.1: admin visibility is not a business membership.
-- 1 transaction: DROP/CREATE POLICY + CREATE FUNCTION + REVOKE/GRANT; 1 final SELECT.
-- Browser-facing public.sk_listings remains RLS-protected.
-- Write rules remain unchanged: membership + active business approval required.
BEGIN;
DROP POLICY IF EXISTS sk_listings_owner_select ON public.sk_listings;
CREATE POLICY sk_listings_owner_select ON public.sk_listings
  FOR SELECT TO authenticated
  USING (
    -- Own entries: used only for My Listings management.
    EXISTS (
      SELECT 1 FROM public.sk_business_members owner_member
      WHERE owner_member.business_id=sk_listings.business_id
        AND owner_member.user_id=(SELECT auth.uid())
    )
    OR (
      -- Published listings of approved businesses, for approved participants
      -- OR staff admins reading for moderation/support.
      status='Aktiv'
      AND date_to>=CURRENT_DATE
      AND public.sk_is_approved_member(sk_listings.business_id)
      AND (
        (SELECT public.sk_is_admin())
        OR EXISTS (
          SELECT 1 FROM public.sk_business_members viewer
          WHERE viewer.user_id=(SELECT auth.uid())
            AND public.sk_is_approved_member(viewer.business_id)
        )
      )
    )
  );
-- Server-side distance calculation: only published external listings, never expose
-- exact private coordinates of another business to the browser.
CREATE OR REPLACE FUNCTION public.sk_marketplace_distances()
RETURNS TABLE(listing_id uuid, distance_km double precision, origin_available boolean)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $fn$
  WITH origin AS (
    SELECT b.latitude, b.longitude
    FROM public.sk_business_members m
    JOIN public.sk_businesses b ON b.id=m.business_id
    WHERE m.user_id=auth.uid()
      AND b.status='Freigeschaltet' AND b.review_state='approved'
      AND b.latitude IS NOT NULL AND b.longitude IS NOT NULL
      AND b.location_source IN ('geocoded','manual')
    ORDER BY b.created_at, b.id LIMIT 1
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
  WHERE auth.uid() IS NOT NULL
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
REVOKE ALL ON FUNCTION public.sk_marketplace_distances() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.sk_marketplace_distances() TO authenticated;
COMMIT;
SELECT policyname,cmd,roles,qual AS lesebedingung
FROM pg_policies
WHERE schemaname='public' AND tablename='sk_listings'
ORDER BY policyname;
