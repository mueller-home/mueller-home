-- StaffKeeping 0.32.2: Marktplatz-Leserechte für freigegebene Betriebe.
-- 1 Transaktion mit DROP/CREATE POLICY, danach 1 Kontroll-SELECT.
-- Eigentümer sehen eigene aktive und inaktive Inserate; andere freigegebene
-- Betriebe sehen nur aktive, nicht abgelaufene Inserate freigegebener Betriebe.
BEGIN;
DROP POLICY IF EXISTS sk_listings_owner_select ON public.sk_listings;
CREATE POLICY sk_listings_owner_select ON public.sk_listings
FOR SELECT TO authenticated USING (
  EXISTS (
    SELECT 1 FROM public.sk_business_members m
    WHERE m.business_id=sk_listings.business_id
      AND m.user_id=(SELECT auth.uid())
  )
  OR (
    status='Aktiv'
    AND date_to>=CURRENT_DATE
    AND public.sk_is_approved_member(sk_listings.business_id)
    AND EXISTS (
      SELECT 1 FROM public.sk_business_members viewer
      WHERE viewer.user_id=(SELECT auth.uid())
        AND public.sk_is_approved_member(viewer.business_id)
    )
  )
);
COMMIT;
SELECT policyname, cmd, roles, qual AS lesebedingung
FROM pg_policies WHERE schemaname='public' AND tablename='sk_listings' AND policyname='sk_listings_owner_select';
