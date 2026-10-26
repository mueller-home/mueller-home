BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$doc$
## 0.33.1.8.15 – Kontaktaufnahme und Nachrichtenoberfläche
Die erste Nachricht wird unmittelbar im Inseratdetail in einem Formular erfasst. Bei mehreren freigegebenen Absenderbetrieben wird dort ein Auswahlfeld eingeblendet; bei genau einem wird die Auswahl ohne weiteren Dialog automatisch vorgenommen. Es werden keine Browser-Pop-ups zur Kontaktaufnahme verwendet. Die Nachrichtenübersicht kann auf den eigenen Betrieb gefiltert werden, wobei «Alle meine Betriebe» die Standardansicht bleibt. Der Inseratetitel steht in Liste und Nachrichtenkopf im Vordergrund, der Gesprächspartner wird sekundär dargestellt. Bestehende Chat-RPCs und Berechtigungen bleiben unverändert.
$doc$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.8.15 – Kontaktaufnahme' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$doc$
## 0.33.1.8.15 – Status
UX-Update vorbereitet: Inline-Erstnachricht im Inseratdetail, Inline-Betriebsauswahl für mehrere Betriebe, optionaler Unterhaltungsfilter nach eigenem Betrieb und Inseratetitel als Hauptinformation. Keine neue Chat-Datenbankmigration notwendig; Berechtigungs-RPCs aus 0.33.1.8.13 bleiben Voraussetzung. Produktive Funktionsprüfung offen.
$doc$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.8.15 – Status' IN body)=0;
COMMIT;
