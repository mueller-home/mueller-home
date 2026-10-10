-- StaffKeeping 0.31.7 – existing canonical documentation and handbook only.
-- Several UPDATE statements, one transaction, no SELECT result sets.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $d$## Registrierung 0.31.7 – Pflichtbeschreibung und Entscheidungs-E-Mails

| Bereich | Regel |
|---|---|
| Betriebsbeschreibung | Pflicht bei Einreichung, mindestens 30 Zeichen (getrimmt), höchstens 1’000 |
| Entwurf | Teilweise Beschreibung darf per Auto-Save gespeichert werden |
| Freigabe | E-Mail an die zum Entscheidungszeitpunkt gespeicherte Kontaktadresse |
| Nachbesserung | E-Mail mit Admin-Begründung und Link zum Profil |
| Ablehnung | Gesonderter gesperrter Prüfstatus `rejected`, E-Mail mit Begründung |
| Versandfehler | Admin-Entscheidung bleibt bestehen, Versandversuch über interne Outbox erneut |
| Benachrichtigungseinstellung | Betriebliche E-Mail-Vorliebe betrifft NICHT obligatorische Registrierungsentscheidungen |

Technik: Trigger auf `sk_businesses.review_state` stellt in `sk_internal.registration_mail_outbox` einen Job ein. Edge Function `sk-registration-mails` verarbeitet Jobs über Postmark. Periodischen Edge-Function-Aufruf in Supabase Cron konfigurieren; Postmark-Token nur serverseitig speichern. Erfolgreicher Versand ist erst mit bestätigter Postmark-API-Antwort nachgewiesen; tatsächliche Zustellung ist separat zu prüfen. Kein öffentlicher Direktzugriff auf die Outbox.
$d$,updated_at=now() WHERE slug='concept' AND position('## Registrierung 0.31.7 – Pflichtbeschreibung' in body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $d$## Testfälle 0.31.7

1. Entwurf mit weniger als 30 Zeichen automatisch speichern, Einreichung verweigern und Zeichenzähler prüfen.
2. Einreichung mit mindestens 30 Zeichen gestatten; serverseitiges Minimum bestätigen.
3. Admin-Freigabe: Eintrag in Outbox, Postmark-Versand, Mail beim Betrieb.
4. Admin-Nachbesserung mit Begründung: Mail und wieder bearbeitbares Profil.
5. Admin-Ablehnung mit Begründung: Mail und gesperrter Prüfstatus.
6. Versanddienst nicht verfügbar: Admin-Entscheidung bleibt gespeichert, automatischer Retry.
7. Admin- und Mandantenschutz für Outbox und Dispatch-Endpunkt; keine Secrets im Browser.

Bereits vom Nutzer bestätigt: Nachbesserung, erneute Einreichung und Freigabe in 0.31.6. Neue E-Mail-Funktionen noch **nicht live getestet**.
$d$,updated_at=now() WHERE slug='tests' AND position('## Testfälle 0.31.7' in body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $d$## StaffKeeping 0.31.7

Beschreibung sichtbar als Pflichtfeld mit 30-Zeichen-Mindestlänge und Zähler; explizite Admin-Ablehnung; Entscheidungs-E-Mails via Postmark-Outbox und geplante Supabase Edge Function. Integration und Live-Versand noch zu prüfen.
$d$,updated_at=now() WHERE slug='history' AND position('## StaffKeeping 0.31.7' in body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $d$## Stand 0.31.7

Nachbesserung und Freigabe im Test erfolgreich bestätigt. Pflichtfeldhinweis und Entscheidungs-E-Mail-Versand implementiert, Deployment der Edge Function/Cron und Live-Versandtests ausstehend. Mandantentrennung weiter offen.
$d$,updated_at=now() WHERE slug='status' AND position('## Stand 0.31.7' in body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $d$## Installation 0.31.7

SQL `20261010113000_registration_email_0317.sql`, Edge Function `sk-registration-mails`, Secrets `POSTMARK_SERVER_TOKEN` und `SK_MAIL_FROM`, periodischer Aufruf via Supabase Cron mit geheimem Service-Role-Token. Erst anschliessend Browser-Dateien veröffentlichen und E-Mails für alle drei Entscheidungen testen.
$d$,updated_at=now() WHERE slug='handoff' AND position('## Installation 0.31.7' in body)=0;
UPDATE sk_internal.help_chapters SET body=body || E'\n\n' || $h$## Registrierungsbeschreibung und E-Mail-Entscheidungen

Die **Betriebsbeschreibung \*** ist Pflicht für die Einreichung: **mindestens 30 Zeichen**. Während du den Entwurf bearbeitest, kannst du auch kürzere Texte automatisch speichern. Nach der Einreichung ist das Profil gesperrt.

| Entscheidung | Was passiert? |
|---|---|
| Freigabe | Du erhältst eine E-Mail und kannst den Marktplatz nutzen. |
| Nachbesserung | Du erhältst die Begründung per E-Mail; das Profil ist wieder bearbeitbar. |
| Ablehnung | Du erhältst eine E-Mail mit der Begründung; das Profil bleibt gesperrt. |

Die E-Mail geht an die hinterlegte **Kontakt-E-Mail**. Die Entscheidung ist zusätzlich nach dem Login in StaffKeeping sichtbar. E-Mails können verzögert eintreffen oder im Spam landen.

![Screenshot: Beschreibung und Mindestlänge](screenshot:profil-beschreibung-0317)
$h$,updated_at=now() WHERE page_key IN ('profile','register','pending') AND position('## Registrierungsbeschreibung und E-Mail-Entscheidungen' in body)=0;
UPDATE sk_internal.help_chapters SET body=body || E'\n\n' || $h$## E-Mails nach einer Registrierungsentscheidung

| Admin-Aktion | Betrieb wird benachrichtigt |
|---|---|
| Freigeben | E-Mail mit Freigabebestätigung |
| Nachbesserung verlangen | E-Mail mit deiner Begründung und Link zum Profil |
| Ablehnen | E-Mail mit Begründung; Profil bleibt gesperrt |

Die Entscheidung wird unabhängig vom Mailversand verbindlich in Supabase gespeichert. Eine interne Outbox ermöglicht automatische Wiederholungen fehlgeschlagener Postmark-Aufträge. Versandstatus wird erst nach bestätigter Postmark-Annahme als gesendet geführt. **Keinen Zugangsschlüssel im Browser oder Handbuch hinterlegen.**

![Screenshot: Admin-Entscheidungen](screenshot:admin-entscheid-email-0317)
$h$,updated_at=now() WHERE page_key IN ('admin-home','admin-businesses') AND position('## E-Mails nach einer Registrierungsentscheidung' in body)=0;
COMMIT;
