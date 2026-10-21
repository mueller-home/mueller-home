-- StaffKeeping 0.33.1.8 / Freigabekonsistenz.
-- Bestehende Signatur unveraendert; keine Nutzdaten veraendert.
-- SQL enthaelt DDL/DCL und EIN abschliessendes SELECT-Resultset.
-- Voraussetzung: sk_businesses.review_state und sk_is_approved_member(uuid) vorhanden.
BEGIN;
CREATE OR REPLACE FUNCTION public.sk_is_approved_member(p_business_id uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = ''
AS $fn$
 SELECT auth.uid() IS NOT NULL AND EXISTS (
  SELECT 1
  FROM public.sk_business_members AS m
  JOIN public.sk_businesses AS b ON b.id = m.business_id
  WHERE m.business_id = p_business_id
    AND m.user_id = auth.uid()
    AND b.status = 'Freigeschaltet'::public.sk_business_status
    AND b.review_state = 'approved'
 );
$fn$;
REVOKE ALL ON FUNCTION public.sk_is_approved_member(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.sk_is_approved_member(uuid) TO authenticated;
COMMIT;
-- Ein Resultset: installierte Definition und Rechte pruefen.
SELECT p.proname AS funktion,
       p.prosecdef AS security_definer,
       array_to_string(p.proconfig, ', ') AS funktions_settings,
       has_function_privilege('authenticated', p.oid, 'EXECUTE') AS authenticated_execute,
       has_function_privilege('anon', p.oid, 'EXECUTE') AS anon_execute,
       pg_get_functiondef(p.oid) LIKE '%b.review_state = ''approved''%' AS prueft_review_state
FROM pg_proc AS p
JOIN pg_namespace AS n ON n.oid = p.pronamespace
WHERE n.nspname = 'public' AND p.proname = 'sk_is_approved_member';
