-- StaffKeeping 0.31.8: update existing central documentation and handbook, no duplicated chapters.
-- Multiple UPDATE statements in one transaction; no separate SELECT resultsets.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $d$## Registrierungsmails – Cron-Autorisierung 0.31.8

| Bestandteil | Regel |
|---|---|
| Cron | `sk-registration-mails`, jede Minute, pg_cron + pg_net |
| Supabase-Gateway | `Authorization: Bearer <Legacy service_role JWT>` aus Vault `sk_cron_service_role`; JWT-Prüfung der Edge Function bleibt aktiv |
| Zusätzliche Versandberechtigung | Separates zufälliges Geheimnis `SK_MAIL_CRON_TOKEN` (Edge Function Secret), identisch zum Vault-Wert `sk_mail_cron_token` |
| PostgreSQL / Versand | `SUPABASE_SERVICE_ROLE_KEY` ausschliesslich innerhalb der Edge Function für Datenbank-RPCs; nicht mit dem Cron-Token vergleichen |
| Fehler 403 | Cron-Job kann technisch erfolgreich laufen, obwohl Function die Berechtigung ablehnt; HTTP-Response und Function Logs separat prüfen |
| Sicherheit | Geheimnisse nie im Browser, SQL-Datei, GitHub, Screenshot oder Handbuch veröffentlichen |

Installation: Function 0.31.8 bereitstellen, dasselbe unabhängig erzeugte Cron-Geheimnis unter beiden Namen sicher hinterlegen, dann `20261010114500_mail_cron_auth_0318.sql` ausführen. Bereits bestehender gleichnamiger Cron-Job wird ersetzt. Vor Live-Abnahme HTTP 200 und den Postmark-Versand einer Testentscheidung getrennt bestätigen. Bestehende Warteschlangenaufträge bleiben erhalten.
$d$,updated_at=now() WHERE slug='concept' AND position('## Registrierungsmails – Cron-Autorisierung 0.31.8' in body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $d$## Mailversand 0.31.8 – Tests

1. Beide Cron-Vault-Secrets vorhanden (ohne Werte auszugeben), Function Secret `SK_MAIL_CRON_TOKEN` gesetzt.
2. Edge Function mit aktiviertem JWT-Schutz neu deployen; Cron-SQL installieren; letzte Ausführungen (`cron.job_run_details`) prüfen.
3. `net._http_response` kontrollieren: HTTP 200 statt bisher 403; bei 403 Header und Secret-Namen kontrollieren, Tokens niemals protokollieren.
4. Bewilligung, Nachbesserung und Ablehnung mit Testbetrieben prüfen; Outbox `sent` und Postmark-Annahme kontrollieren.
5. Negativtest: Anfrage ohne Cron-Secret bzw. falsches Secret wird abgewiesen; normale Benutzer dürfen keinen Versand auslösen.

Status 0.31.8: Code statisch geprüft; Cron/Edge Function/Postmark live noch nicht abgenommen.
$d$,updated_at=now() WHERE slug='tests' AND position('## Mailversand 0.31.8 – Tests' in body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $d$## StaffKeeping 0.31.8

Korrektur für HTTP 403 beim automatischen Entscheidungs-Mailversand: getrenntes Cron-Secret statt direktem Vergleich mit dem Service-Role-Key der Edge Function. Erfordert neuen Function-Deploy, zweites Cron-Secret (Vault + Edge Function) und Aktualisierung des bestehenden Cron-Jobs. Live-Test offen.
$d$,updated_at=now() WHERE slug='history' AND position('## StaffKeeping 0.31.8' in body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $d$## Mailversand: Stand 0.31.8

Cron, pg_net und Vault eingerichtet; letzter nachgewiesener HTTP-Status 403. Getrennte Cron-Autorisierung ist implementiert, Deployment und HTTP-200-/Postmark-Livetest stehen aus.
$d$,updated_at=now() WHERE slug='status' AND position('## Mailversand: Stand 0.31.8' in body)=0;
UPDATE sk_internal.help_chapters SET body=body || E'\n\n' || $h$## Automatische Entscheidungs-E-Mails – Betrieb

Nach Freigabe, Nachbesserung oder Ablehnung informiert StaffKeeping per E-Mail an die hinterlegte Kontaktadresse. Die Entscheidung ist auch im Konto sichtbar. Bleibt eine E-Mail aus, Spam-Ordner prüfen und den Support kontaktieren. Der technische Versandstatus ist für Administratoren prüfbar.

![Screenshot: Benachrichtigung nach Registrierungsentscheidung](screenshot:registrierung-mail-0318)
$h$,updated_at=now() WHERE page_key IN ('register','pending','profile') AND position('## Automatische Entscheidungs-E-Mails – Betrieb' in body)=0;
UPDATE sk_internal.help_chapters SET body=body || E'\n\n' || $h$## Mailversand kontrollieren – Admin

| Anzeige | Bedeutung |
|---|---|
| Cron erfolgreich | Zeitgesteuerter Datenbankjob lief; **kein Nachweis** für E-Mail-Versand |
| HTTP 403 | Edge Function weist Berechtigung zurück; Dienstkonfiguration prüfen |
| HTTP 200 | Edge Function beantwortete den Aufruf; Outbox-Status separat prüfen |
| Outbox `sent` | Postmark hat Nachricht angenommen; Zustellung bleibt gesondert zu prüfen |

Keine Tokens oder Headerwerte in Screenshots oder Protokollnotizen übernehmen. Ein Fehler im Postmark-Versand ändert eine bereits gespeicherte Admin-Entscheidung nicht.

![Screenshot: Admin-Mailstatus](screenshot:admin-mailstatus-0318)
$h$,updated_at=now() WHERE page_key IN ('admin-home','admin-businesses') AND position('## Mailversand kontrollieren – Admin' in body)=0;
COMMIT;
