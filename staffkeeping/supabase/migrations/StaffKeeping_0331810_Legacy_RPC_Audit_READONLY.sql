-- READ ONLY: Produktive Bestandsprüfung für sichere Migration der Legacy-Profilabläufe.
-- EIN SELECT; EIN Resultset. Keine Änderungen an Daten oder Berechtigungen.
SELECT p.proname AS funktion,
       pg_get_function_identity_arguments(p.oid) AS parameter,
       p.prosecdef AS security_definer,
       p.proconfig AS konfiguration,
       pg_get_functiondef(p.oid) AS funktionsdefinition
FROM pg_proc p
JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname='public'
  AND p.proname IN (
    'sk_submit_my_business',
    'sk_request_my_business_deletion',
    'sk_my_business_deletion_status',
    'sk_admin_decide_deletion',
    'sk_request_business_sensitive_change_by_id',
    'sk_update_business_with_preferences_location'
  )
ORDER BY p.proname, pg_get_function_identity_arguments(p.oid);
