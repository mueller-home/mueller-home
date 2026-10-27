-- StaffKeeping 0.33.1.8.37 – Lesender Zugriff auf angenommene Vergaben, Sperre gegen nachträgliche Änderungen.
BEGIN;
CREATE OR REPLACE FUNCTION public.sk_partnership_listing(p_thread_id uuid)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $fn$
DECLARE p sk_internal.partnerships%ROWTYPE; l public.sk_listings%ROWTYPE;
BEGIN
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Anmeldung erforderlich' USING ERRCODE='42501'; END IF;
 SELECT * INTO p FROM sk_internal.partnerships WHERE thread_id=p_thread_id AND state IN('angenommen','abgeschlossen');
 IF NOT FOUND OR NOT (sk_internal.chat_allowed(p.owner_business_id) OR sk_internal.chat_allowed(p.partner_business_id))
 THEN RAISE EXCEPTION 'Kein Zugriff auf dieses Partnerinserat' USING ERRCODE='42501'; END IF;
 SELECT * INTO l FROM public.sk_listings WHERE id=p.listing_id;
 IF NOT FOUND THEN RAISE EXCEPTION 'Inserat nicht vorhanden'; END IF;
 RETURN jsonb_build_object('id',l.id,'title',l.title,'status',l.status,'city',l.city,'country',l.country,
  'type',l.type,'category',l.category,'date_from',l.date_from,'date_to',l.date_to,
  'description',l.description,'conditions',l.conditions,'accommodation',l.accommodation,'languages',l.languages);
END;$fn$;
REVOKE ALL ON FUNCTION public.sk_partnership_listing(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_partnership_listing(uuid) TO authenticated;
-- Verhindert Datenänderungen selbst über alte Clients, direkte API und ungesicherte Schreibwege.
-- Zulässig bleiben nur interne Statuswechsel von Vergeben zu Abgeschlossen im bestehenden Vergabeablauf.
CREATE OR REPLACE FUNCTION sk_internal.partnership_listing_immutable()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
BEGIN
 IF OLD.status IN ('Vergeben','Abgeschlossen') THEN
  IF (to_jsonb(NEW) - 'status' - 'updated_at') IS DISTINCT FROM (to_jsonb(OLD) - 'status' - 'updated_at') THEN
   RAISE EXCEPTION 'Vergebene und abgeschlossene Inserate dürfen nicht bearbeitet werden' USING ERRCODE='42501';
  END IF;
 END IF;
 RETURN NEW;
END;$fn$;
DROP TRIGGER IF EXISTS sk_partnership_listing_immutable ON public.sk_listings;
CREATE TRIGGER sk_partnership_listing_immutable BEFORE UPDATE ON public.sk_listings
FOR EACH ROW EXECUTE FUNCTION sk_internal.partnership_listing_immutable();
COMMIT;
