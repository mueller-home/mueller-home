-- StaffKeeping 0.33.1.8.2, Phase A: betriebsbezogene Praeferenzen atomar mit Profil und Standort speichern.
-- Ein BEGIN/COMMIT, CREATE FUNCTION, REVOKE/GRANT; EIN abschliessender SELECT.
BEGIN;
CREATE OR REPLACE FUNCTION public.sk_update_business_with_preferences_location(
 p_profile jsonb, p_latitude double precision DEFAULT NULL,
 p_longitude double precision DEFAULT NULL, p_source text DEFAULT NULL,
 p_address_key text DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE v_id uuid;
BEGIN
 IF auth.uid() IS NULL OR p_profile IS NULL OR jsonb_typeof(p_profile)<>'object'
    OR jsonb_typeof(p_profile->'p_email_notifications_enabled') IS DISTINCT FROM 'boolean'
    OR jsonb_typeof(p_profile->'p_show_street_address') IS DISTINCT FROM 'boolean' THEN
   RAISE EXCEPTION 'Ungueltige Betriebsprofil-Einstellungen' USING ERRCODE='22023';
 END IF;
 -- Vor dem Profil-Update identische Eigentuermerpruefung wie im bestehenden RPC;
 -- der vorhandene Profil-RPC kontrolliert zusaetzlich E-Mail, Status und Nachbesserung.
 v_id := (p_profile->>'p_business_id')::uuid;
 PERFORM public.sk_update_business_with_location(p_profile,p_latitude,p_longitude,p_source,p_address_key);
 -- Alles im selben Datenbank-Transaktionsaufruf. Fehler rollen Stammdaten und Standort zurueck.
 UPDATE public.sk_businesses b SET
   email_notifications_enabled=(p_profile->>'p_email_notifications_enabled')::boolean,
   show_street_address=(p_profile->>'p_show_street_address')::boolean
 WHERE b.id=v_id
 AND EXISTS(SELECT 1 FROM public.sk_business_members m
            WHERE m.business_id=b.id AND m.user_id=auth.uid()
              AND m.role='owner'::public.sk_member_role);
 IF NOT FOUND THEN
   RAISE EXCEPTION 'Keine Berechtigung fuer diesen Betrieb' USING ERRCODE='42501';
 END IF;
END;
$fn$;
REVOKE ALL ON FUNCTION public.sk_update_business_with_preferences_location(jsonb,double precision,double precision,text,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.sk_update_business_with_preferences_location(jsonb,double precision,double precision,text,text) TO authenticated;
COMMIT;
SELECT p.proname AS funktion,p.prosecdef AS security_definer,
 has_function_privilege('authenticated',p.oid,'EXECUTE') AS authenticated_execute,
 has_function_privilege('anon',p.oid,'EXECUTE') AS anon_execute
FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname='public' AND p.proname='sk_update_business_with_preferences_location';
