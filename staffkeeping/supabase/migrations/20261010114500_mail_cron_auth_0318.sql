-- StaffKeeping 0.31.8: Cron job authentication, run only AFTER the SAME random value
-- is stored in Supabase Vault as sk_mail_cron_token and as Edge Function secret SK_MAIL_CRON_TOKEN.
-- Existing sk_cron_service_role (Legacy service_role JWT) is reused for Supabase gateway verification.
-- A single cron.schedule statement; returns one job id. No secrets embedded in SQL or the repository.
-- Prerequisites: pg_cron and pg_net installed, Edge Function deployed with verify_jwt enabled.
DO $check$
BEGIN
 IF NOT EXISTS (SELECT 1 FROM vault.decrypted_secrets WHERE name='sk_mail_cron_token' AND length(decrypted_secret)>=32) THEN
  RAISE EXCEPTION 'Vault secret sk_mail_cron_token missing or too short; configure before scheduling';
 END IF;
 IF NOT EXISTS (SELECT 1 FROM vault.decrypted_secrets WHERE name='sk_cron_service_role' AND length(decrypted_secret)>50) THEN
  RAISE EXCEPTION 'Vault secret sk_cron_service_role missing';
 END IF;
END;$check$;

SELECT cron.schedule(
 'sk-registration-mails',
 '* * * * *',
 $job$
 SELECT net.http_post(
  url := 'https://uubpsjvcvhinzpxkvxtc.supabase.co/functions/v1/sk-registration-mails',
  headers := jsonb_build_object(
   'Content-Type','application/json',
   'Authorization','Bearer ' || (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name='sk_cron_service_role'),
   'x-sk-cron-token',(SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name='sk_mail_cron_token')
  ),
  body := '{}'::jsonb,
  timeout_milliseconds := 30000
 );
 $job$
);
