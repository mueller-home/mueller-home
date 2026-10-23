-- StaffKeeping 0.33.1.8.9: UX rechtlicher Aenderungsantrag.
-- Zwei UPDATE-Anweisungen und ein abschliessender SELECT (ein Resultset).
BEGIN;
UPDATE sk_internal.project_doc_chapters
SET body=body||E'\n\n'||$d$
## 0.33.1.8.9 – Dialog rechtliche Aenderungsantraege
Bearbeitbarer Antrag: unterer Button «Abbrechen» und X oben rechts loesen den bestehenden Schutz vor ungespeicherten Eingaben aus. Es gibt keinen Auto-Save fuer Antraege. Bereits offener Antrag (SK409/23505): Formular wechselt in reinen Informationszustand, Einreichen und Eingabefelder sind deaktiviert, unterer Button «Schliessen» schliesst ohne Speicherung. Erfolgreiche Einreichung schliesst weiterhin automatisch und zeigt eine Bestaetigung in «Meine Betriebe». Datenbankrechte und bestehende Antraege unveraendert.
$d$,updated_at=now()
WHERE slug='concept' AND position('## 0.33.1.8.9 – Dialog' IN body)=0;
UPDATE sk_internal.project_doc_chapters
SET body=body||E'\n\n'||$d$
## 0.33.1.8.9 – Status
Korrektur des Antragsdialogs nach Retest des Hinweises auf bereits offenen Antrag. Kein neues Datenbankschema, keine Aenderung der Berechtigungen; gezielte UI-Regressionstests stehen aus. Die verbliebenen Legacy-Ablaufmigrationen bleiben offen.
$d$,updated_at=now()
WHERE slug='status' AND position('## 0.33.1.8.9 – Status' IN body)=0;
COMMIT;
SELECT slug, updated_at FROM sk_internal.project_doc_chapters WHERE slug IN ('concept','status') ORDER BY slug;
