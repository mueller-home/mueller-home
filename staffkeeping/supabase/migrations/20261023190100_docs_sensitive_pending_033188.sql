-- StaffKeeping 0.33.1.8.8: Dokumentation der Behandlung doppelter Aenderungsantraege.
-- Zwei UPDATE-Anweisungen, ein abschliessender SELECT.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$d$
## 0.33.1.8.8 – Rechtliche Aenderungsantraege
Pro freigeschaltetem Betrieb und sensibler Eigenschaft (Firmenname, UID/USt-ID, Land) ist weiterhin maximal ein offener Aenderungsantrag zulaessig (Unique-Index sk_change_one_pending). Die RPC gibt bei erneuter Einreichung nun den fachlichen Fehler SK409 zurueck, statt einen rohen Unique-Constraint-Fehler durchzureichen. Das Frontend zeigt einen verstaendlichen Hinweis und behaelt die Eingaben. Bereits bestehende Antraege werden nicht geaendert oder geloescht. Die automatische Dialogschliessung nach erfolgreichem Antrag aus 0.33.1.8.7 bleibt bestehen. UX: Der User braucht vor erneuter Beantragung die Entscheidung von Annette.
$d$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.8.8 – Rechtliche' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$d$
## 0.33.1.8.8 – Status
Retest 0.33.1.8.7: 4 OK, 1 wegen bestehendem offenem Antrag abgewiesen, 2 offen; kein Nachweis eines Fehlers im erfolgreichen Dialogschluss. Doppelte Antraege werden fuer Benutzer verstaendlich behandelt, ohne die fachliche Einmaligkeitsregel zu lockern. Legacy-Bereinigung der Einreichungs- und Loeschantragsablaeufe steht weiterhin aus. Keine neue Benutzerrolle.
$d$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.8.8 – Status' IN body)=0;
COMMIT;
SELECT slug,updated_at FROM sk_internal.project_doc_chapters WHERE slug IN ('concept','status') ORDER BY slug;
