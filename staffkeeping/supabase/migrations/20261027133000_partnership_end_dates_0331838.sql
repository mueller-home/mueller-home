-- StaffKeeping 0.33.1.8.38: Leserechte auf Enddatum nur für Beteiligte.
BEGIN;
CREATE OR REPLACE FUNCTION public.sk_partnership_end_dates()
RETURNS TABLE(partnership_id uuid, date_to date)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $fn$
  SELECT p.id, l.date_to
  FROM sk_internal.partnerships AS p
  JOIN public.sk_listings AS l ON l.id = p.listing_id
  WHERE sk_internal.chat_allowed(p.owner_business_id)
     OR sk_internal.chat_allowed(p.partner_business_id)
  ORDER BY p.offered_at DESC
  LIMIT 200;
$fn$;
REVOKE ALL ON FUNCTION public.sk_partnership_end_dates() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.sk_partnership_end_dates() TO authenticated;
NOTIFY pgrst, 'reload schema';
COMMIT;
