-- StaffKeeping 0.33.1.8.3: Anzeigefehler nach Speichern der Betriebsoptionen korrigiert.
-- Zwei UPDATE-Anweisungen, EIN abschliessender Kontroll-SELECT.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET
 body=body||E'\n\n'||$d$
## 0.33.1.8.3 – Betriebsoptionen erneut laden (21.10.2026)
Retest 0.33.1.8.2: 6/7 erfolgreich, Wiederanzeige der beiden Einstellungen fehlgeschlagen. Ursache im Frontend: listMyBusinesses() selektierte weder show_street_address noch email_notifications_enabled aus public.sk_businesses. Checkboxen zeigten deshalb Standardwerte, obwohl die Speicherung erfolgreich gemeldet wurde. Der Lese-SELECT wurde um beide Felder erweitert, sodass nach erneutem Öffnen der echte Datenbankwert erscheint. Text zur E-Mail-Präferenz präzisiert; der Nachrichtenversand ist weiterhin nicht implementiert. Keine Änderungen an Datenbankstruktur, RPCs, Rechten, Entwurfs- oder Legacy-Speicherwegen. Produktiver Retest ausstehend.
$d$,updated_at=now()
WHERE slug='concept' AND position('## 0.33.1.8.3 – Betriebsoptionen erneut laden' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET
 body=body||E'\n\n'||$d$
## 0.33.1.8.3 – Status
Korrektur zur Wiederanzeige nach 0.33.1.8.2. Kein Datenbank-Schema-Patch. Nach Installation testen: Einstellungen in Betrieb A abweichend setzen, sichern, erneut öffnen, Werte vergleichen; Betrieb B unverändert; Seiten-Reload und neue Browser-Sitzung. Legacy-Profilmigration noch offen; erst nach bestandener Regression fortsetzen.
$d$,updated_at=now()
WHERE slug='status' AND position('## 0.33.1.8.3 – Status' IN body)=0;
COMMIT;
SELECT slug,updated_at FROM sk_internal.project_doc_chapters WHERE slug IN ('concept','status') ORDER BY slug;
