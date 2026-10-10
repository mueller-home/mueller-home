-- StaffKeeping 0.32.2.2: Verbindlicher Inseratsablauf nach Schweizer Datum.
-- 1 Transaktion (CHECK, Trigger, Policy), anschliessend Cron-Einrichtung und Kontroll-SELECT.
-- Hinweis: pg_cron aktualisiert den gespeicherten Status stuendlich; RLS blendet
-- abgelaufene Eintraege unabhaengig vom Cron sofort aus.
BEGIN;
ALTER TABLE public.sk_listings DROP CONSTRAINT IF EXISTS sk_listings_status_check;
ALTER TABLE public.sk_listings ADD CONSTRAINT sk_listings_status_check
  CHECK (status IN ('Aktiv','Inaktiv','Abgelaufen'));
CREATE OR REPLACE FUNCTION public.sk_listing_expiration_guard()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $fn$
DECLARE today_ch date := (now() AT TIME ZONE 'Europe/Zurich')::date;
BEGIN
  IF NEW.date_to < today_ch THEN
    NEW.status := 'Abgelaufen';
  ELSIF TG_OP = 'UPDATE' AND OLD.status = 'Abgelaufen' AND NEW.status = 'Abgelaufen' THEN
    -- Verlaengerte Inserate bleiben bewusst inaktiv bis zur expliziten Aktivierung.
    NEW.status := 'Inaktiv';
  END IF;
  RETURN NEW;
END;
$fn$;
DROP TRIGGER IF EXISTS sk_listing_expiration_guard ON public.sk_listings;
CREATE TRIGGER sk_listing_expiration_guard BEFORE INSERT OR UPDATE ON public.sk_listings
FOR EACH ROW EXECUTE FUNCTION public.sk_listing_expiration_guard();
-- Freigabe des Inseratsbetriebes muss unabhaengig von der aktuellen Benutzer-
-- Mitgliedschaft geprueft werden. sk_is_approved_member ist dafuer NICHT geeignet,
-- falls diese Funktion auth.uid() als Mitglied voraussetzt.
CREATE OR REPLACE FUNCTION public.sk_listing_owner_is_approved(p_business_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $fn$
  SELECT EXISTS (
    SELECT 1 FROM public.sk_businesses b
    WHERE b.id = p_business_id
      AND b.status = 'Freigeschaltet'
      AND b.review_state = 'approved'
  );
$fn$;
REVOKE ALL ON FUNCTION public.sk_listing_owner_is_approved(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.sk_listing_owner_is_approved(uuid) TO authenticated;
-- RLS muss ohne Hintergrundjob korrekt und zeitlich praezise sein.
DROP POLICY IF EXISTS sk_listings_owner_select ON public.sk_listings;
CREATE POLICY sk_listings_owner_select ON public.sk_listings FOR SELECT TO authenticated USING (
  -- Eigene Inserate fuer Meine Inserate sichtbar, unabhaengig vom Publikationsstatus.
  EXISTS (SELECT 1 FROM public.sk_business_members m
    WHERE m.business_id=sk_listings.business_id AND m.user_id=(SELECT auth.uid()))
  OR (status='Aktiv'
    AND date_to >= (now() AT TIME ZONE 'Europe/Zurich')::date
    AND public.sk_listing_owner_is_approved(sk_listings.business_id)
    AND ((SELECT public.sk_is_admin()) OR EXISTS (
      SELECT 1 FROM public.sk_business_members viewer
      WHERE viewer.user_id=(SELECT auth.uid())
        AND public.sk_listing_owner_is_approved(viewer.business_id)
    ))
  )
);
UPDATE public.sk_listings SET status='Abgelaufen'
WHERE date_to < (now() AT TIME ZONE 'Europe/Zurich')::date AND status <> 'Abgelaufen';
COMMIT;
-- Einmaliger Job, gleicher Name beim erneuten Ausfuehren. Supabase pg_cron muss installiert sein.
SELECT cron.schedule('sk-expire-listings', '0 * * * *',
  $$UPDATE public.sk_listings SET status='Abgelaufen'
    WHERE date_to < (now() AT TIME ZONE 'Europe/Zurich')::date AND status <> 'Abgelaufen'$$);
-- Ein einzelnes abschliessendes Kontrollergebnis (kein Versand/keine Auth-Keys).
SELECT l.id,l.title,l.status,l.date_from,l.date_to,
  (l.date_to >= (now() AT TIME ZONE 'Europe/Zurich')::date) AS within_validity,
  b.status AS business_status,b.review_state,
  public.sk_listing_owner_is_approved(l.business_id) AS owner_approved,
  (SELECT count(*) FROM cron.job WHERE jobname='sk-expire-listings' AND active) AS active_expiry_jobs
FROM public.sk_listings l JOIN public.sk_businesses b ON b.id=l.business_id
ORDER BY l.created_at DESC LIMIT 20;
