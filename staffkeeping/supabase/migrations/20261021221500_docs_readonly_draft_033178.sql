-- StaffKeeping 0.33.1.7.8: docs only. 2 UPDATE statements, one final SELECT resultset.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $d$
## 0.33.1.7.8 – Gesperrte Entwuerfe anzeigen
Fix fuer den Lesemodus: Deaktivierte Formularelemente duerfen nicht als lokale Aenderung gelten und das Laden des gespeicherten Entwurfs verhindern. Bei readOnly wird die Dirty-Snapshot-Pruefung vor dem Laden umgangen; der gespeicherte Payload wird danach angezeigt, die Schreibsperre bleibt aktiv. Keine neue RPC und keine Datenbankschema-Aenderung.
$d$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.7.8 – Gesperrte Entwuerfe anzeigen' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $d$
## 0.33.1.7.8 – Lesemodus-Retest offen
In Fenster A Entwurf bearbeiten; in Fenster B denselben Entwurf gesperrt oeffnen: Titel und Beschreibung muessen angezeigt werden; alle Speicheraktionen bleiben deaktiviert. Uebernahme weiter pruefen. Browser-Livetest noch offen.
$d$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.7.8 – Lesemodus-Retest offen' IN body)=0;
COMMIT;
SELECT slug,updated_at FROM sk_internal.project_doc_chapters WHERE slug IN ('concept','status') ORDER BY slug;
