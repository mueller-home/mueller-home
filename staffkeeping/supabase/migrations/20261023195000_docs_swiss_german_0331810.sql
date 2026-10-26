-- StaffKeeping 0.33.1.8.10: Schweizer Deutsch, sichtbare Texte.
-- Zwei UPDATE-Anweisungen, abschliessend ein SELECT (ein Resultset).
BEGIN;
UPDATE sk_internal.project_doc_chapters
SET body=body||E'\n\n'||$d$
## 0.33.1.8.10 – Sprachstandard Deutsch (Schweiz)
Sämtliche sichtbaren UI-Texte, Dialogmeldungen und Hilfetexte verwenden ä, ö, ü und ss statt ß. Technische Datenbankbezeichner, bestehende Funktionssignaturen, Fehlercodes und gespeicherte Benutzerdaten dürfen durch reine Sprachkorrekturen nicht verändert werden. Die sichtbaren Texte des Dialogs «Rechtliche Änderung beantragen» und die Bezeichnung der E-Mail-Benachrichtigungen im Adminbereich wurden bereinigt. Künftige Änderungen werden konsequent nach Deutsch (Schweiz) geprüft.
$d$,updated_at=now()
WHERE slug='concept' AND position('## 0.33.1.8.10 – Sprachstandard' IN body)=0;
UPDATE sk_internal.project_doc_chapters
SET body=body||E'\n\n'||$d$
## 0.33.1.8.10 – Status
Retest 0.33.1.8.9: 6/6 bestanden. Sprachkorrektur im rechtlichen Änderungsantrag umgesetzt, Produktivtest 0.33.1.8.10 noch offen. Legacy-RPCs für Freischaltungseinreichung und Löschanträge benötigen vor der betriebsbezogenen Migration eine genaue Bestandsprüfung: aktuelle Signaturen ohne eindeutige Betriebs-ID. Kein Umbau dieser RPCs in diesem Release.
$d$,updated_at=now()
WHERE slug='status' AND position('## 0.33.1.8.10 – Status' IN body)=0;
COMMIT;
SELECT slug,updated_at FROM sk_internal.project_doc_chapters WHERE slug IN ('concept','status') ORDER BY slug;
