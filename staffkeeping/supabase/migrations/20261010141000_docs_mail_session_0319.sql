-- StaffKeeping 0.31.9 – Existing central documentation / handbook, no new duplicate chapters.
-- 1 transaction, 6 UPDATE statements, no SELECT resultsets. Idempotent per appended section.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $d$## Cron-Maildiagnose 0.31.9

- Der wiederkehrende HTTP 403 wird in der Edge Function kategorisiert als `missing_header` oder `token_mismatch`. Log-Ausgabe enthält nur Version und Fehlerkategorie; niemals Token, Header-Inhalte, JWT oder Hashes loggen.
- `X-SK-Cron-Diagnostic` erscheint nur bei 403 in der HTTP-Antwort; im Supabase-Edge-Function-Log steht `cron_auth_rejected`. Erfolgreiche Läufe protokollieren `cron_auth_accepted` und liefern `version: 0.31.9` im JSON.
- Ein vorhandener Cron-Header und korrekt benannter Vault-Eintrag beweisen **keine** Übereinstimmung der Secrets; `403` wurde nach zwischenzeitlich `200` erneut beobachtet.
- Versandwarteschlange: Zwei Aufträge (`changes_requested`, `approved`) waren zum Diagnosezeitpunkt `pending`, `attempts=0`. HTTP 200 mit `processed=0` ist kein Versandnachweis.
- Bei weiterhin `403`: nach Deploy Logs/Invocations prüfen, Kategorie lesen, im nächsten Schritt gezielt die Ursache beheben. Nicht auf Verdacht Postmark-, Service-Role- oder Cron-Secrets wechseln.
$d$, updated_at=now() WHERE slug='concept' AND position('## Cron-Maildiagnose 0.31.9' in body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $d$## Test: Cron-403 und gelöschte Benutzersitzung (0.31.9)

1. Edge Function 0.31.9 bereitstellen; Supabase `verify_jwt` bleibt an. Nächste `net._http_response` sowie `sk-registration-mails`-Logs prüfen: HTTP 200 (`version=0.31.9`, nach erfolgter Bearbeitung `processed>0`) oder 403 mit kategorieller Diagnose. Keine geheimen Werte ausgeben.
2. Warteschlange prüfen: Nachbesserung und Genehmigung werden von `pending` übernommen; `attempts`, `status`, `last_error`, `provider_message_id` verfolgen. `sent` belegt nur die Annahme durch Postmark, nicht Zustellung.
3. Betrieb in zwei Browsern anmelden; Admin führt vollständige Löschung aus. Im bereits offenen Betriebsbrowser ohne Reload in einen geschützten Tab wechseln. Erwartung: automatische Login-Ansicht und kein erneuter Zugriff. Nach Reload darf Login mit gelöschtem Konto nicht funktionieren.
4. Netzwerkfehler bei Sitzungsprüfung: Keine zwanghafte lokale Löschung der gültigen Sitzung; aber geschützte Navigation unterbinden, bis Auth erreichbar ist.
5. Serverseitige RLS/RPC-/Storage- und Alt-JWT-Prüfung gesondert durchführen; diese Client-Navigationskorrektur ersetzt **keine** RLS-Regel und ist kein Beweis für die serverseitige Sperre.
$d$, updated_at=now() WHERE slug='tests' AND position('## Test: Cron-403 und gelöschte Benutzersitzung (0.31.9)' in body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $d$## StaffKeeping 0.31.9

Diagnose der wiederkehrenden Cron-403-Ablehnung ohne Secret-Offenlegung; App prüft gelöschte Supabase-Auth-Konten vor geschützter Navigation. Die serverseitige Sperre mit noch gültigem JWT erfordert separaten RLS-/RPC-Audit. Live-Test und Postmark-Zustellung noch offen.
$d$, updated_at=now() WHERE slug='history' AND position('## StaffKeeping 0.31.9' in body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $d$## Stand 0.31.9

Diagnose-Build für wiederkehrende 403 beim Registrierungs-Mailjob erstellt; zwei Entscheidungs-Mails standen auf `pending` (0 Versuche). Die Browser-Navigation prüft Auth vor Seitenwechsel; serverseitige Alt-JWT-Abwehr/RLS noch nicht verifiziert. Live-Abnahme ausstehend.
$d$, updated_at=now() WHERE slug='status' AND position('## Stand 0.31.9' in body)=0;
UPDATE sk_internal.help_chapters SET body=body || E'\n\n' || $h$## Gelöschtes Konto – aktive Sitzung

Nach vollständiger administrativer Kontolöschung soll eine bereits geöffnete StaffKeeping-Seite bei der nächsten geschützten Navigation zur Anmeldung wechseln. Ein gültiges Konto wird bei einem Netzwerkproblem nicht automatisch gelöscht; geschützte Navigation wird bis zur Wiederherstellung der Auth-Prüfung unterbunden.

![Screenshot: Konto nach Löschung](screenshot:konto-geloescht-session-0319)
$h$,updated_at=now() WHERE page_key IN ('login','pending','profile') AND position('## Gelöschtes Konto – aktive Sitzung' in body)=0;
UPDATE sk_internal.help_chapters SET body=body || E'\n\n' || $h$## Maildiagnose bei 403 (0.31.9)

Edge Function → Logs zeigt `cron_auth_rejected` mit `missing_header` (Header fehlt) oder `token_mismatch` (Geheimnisse ungleich). Beide Meldungen enthalten **keine** geheimen Schlüssel. `cron_auth_accepted` bestätigt lediglich die Cron-Autorisierung. Danach Outbox, Postmark-Annahme und Zustellung einzeln kontrollieren.

![Screenshot: Cron-Diagnose](screenshot:cron-mail-diagnose-0319)
$h$,updated_at=now() WHERE page_key IN ('admin-home','admin-businesses','admin-deletions') AND position('## Maildiagnose bei 403 (0.31.9)' in body)=0;
COMMIT;
