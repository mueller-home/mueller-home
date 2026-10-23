-- StaffKeeping 0.33.1.8.5: Nur zentrale Projektdokumentation.
-- Hintergrund: 0.33.1.8.4 hat member_role in listMyBusinesses() verwendet,
-- ohne sk_business_members.role mitzuladen. Deshalb war die Medienverwaltung
-- auch bei Betriebsinhabern schreibgeschuetzt. Korrektur nur im Frontend.
-- Ein abschliessender SELECT (ein Resultset).
BEGIN;
UPDATE sk_internal.project_doc_chapters
SET body = body || E'\n\n' || $doc$
## 0.33.1.8.5 – Korrektur Medienberechtigung
In Version 0.33.1.8.4 wurde bei «Meine Betriebe» die Mitgliederrolle im Frontend nicht mitgeladen. Dadurch war «Logo & Bilder» auch fuer berechtigte Betriebsinhaber faelschlich nur lesbar. listMyBusinesses() laedt nun business_id UND role; die Medienansicht nutzt die bereits vorhandene Rollen- und Statuspruefung. Server-/Storage-Policies sind unveraendert. Version 0.33.1.8.4: SQL/Versionsanzeige und Oeffnen getestet; Medien-Upload noch nicht abgenommen. Retest 0.33.1.8.5 ausstehend.
$doc$, updated_at = now()
WHERE slug = 'concept' AND position('## 0.33.1.8.5 – Korrektur Medienberechtigung' IN body) = 0;
UPDATE sk_internal.project_doc_chapters
SET body = body || E'\n\n' || $doc$
## 0.33.1.8.5 – Status
Front-End-Fix: sk_business_members.role beim Laden der Betriebe aufgenommen. Testen: Besitzer kann Medien hochladen, ersetzen, entfernen; anderer Betrieb bleibt unveraendert; eingereichte/gesperrte Betriebe bleiben lesend; private Profilentwuerfe und bisherige Legacy-Funktionen unveraendert. Bis zum erfolgreichen Retest nicht abgenommen.
$doc$, updated_at = now()
WHERE slug = 'status' AND position('## 0.33.1.8.5 – Status' IN body) = 0;
COMMIT;
SELECT slug, updated_at FROM sk_internal.project_doc_chapters
WHERE slug IN ('concept','status') ORDER BY slug;
