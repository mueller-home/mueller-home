-- StaffKeeping 0.33.1.8.12 – zentrale Dokumentation.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$doc$
## 0.33.1.8.12 – Neue Betriebsentwürfe und responsive Aktionen
Unter «Meine Betriebe» brechen Aktionsbuttons bei schmalen Fenstern automatisch um. «Weiteren Betrieb hinzufügen» hat einen eigenständigen, privaten, benutzerbezogenen und versionierten Entwurfsspeicher in sk_internal.new_business_drafts, ohne Betriebs-ID und ohne Betriebsanlage oder Admin-Einreichung. Neue RPCs: sk_list_new_business_drafts, sk_save_new_business_draft, sk_delete_new_business_draft; direkte Tabellenrechte für angemeldete und anonyme Benutzer entzogen. «Entwurf speichern» und «Schliessen» sichern unvollständige Eingaben; X steht für «Abbrechen» mit Schutz für ungesicherte Änderungen. Entwürfe können in «Meine Betriebe» fortgesetzt oder ausdrücklich gelöscht werden. Betrieb entsteht erst nach gesondertem «Betrieb zur Prüfung erfassen». Sprachstandard Deutsch (Schweiz). Browser- und Migrationstests noch offen.
$doc$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.8.12 – Neue Betriebsentwürfe' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$doc$
## 0.33.1.8.12 – Status und Test
Update zur Erprobung bereit, nicht abgenommen. Prüfen: 1) SQL-RPCs, 2) Umbruch der Buttons bei schmalem Fenster, 3) unvollständigen Entwurf speichern/schliessen/fortsetzen, 4) X/Verwerfen, 5) zwei unabhängige Entwürfe, 6) Marker nach Wiederöffnung, 7) ausschliesslich explizite Betriebsanlage, 8) fremde Entwürfe unsichtbar. Frühere Migrationen und Freigaberegeln bleiben unverändert.
$doc$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.8.12 – Status' IN body)=0;
COMMIT;
SELECT slug,updated_at FROM sk_internal.project_doc_chapters WHERE slug IN ('concept','status') ORDER BY slug;
