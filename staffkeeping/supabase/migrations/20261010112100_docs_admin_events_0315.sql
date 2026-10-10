-- StaffKeeping 0.31.5 – updates existing documentation and handbook in Supabase.
-- Multiple UPDATE statements, one transaction, no SELECT result sets.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $content$## Admin-Ereignisse 0.31.5

| Vorgang | Meldung | Muss freigegeben werden? |
|---|---|---|
| PLZ, Ort, Strasse, Kartenposition | Standortänderung mit geänderten Feldnamen | Nein |
| Branche, Beschreibung, Kontaktangaben | Profiländerung mit geänderten Feldnamen | Nein |
| Firmenname, Land, USt-ID | Änderungsantrag | Ja |
| Löschung eines Betriebs abgeschlossen | Löschmeldung wird abgeschlossen | Nein; Abschluss durch Backend |

Das Audit speichert für neue Änderungen nur **Feldnamen**, keine früheren oder neuen Kontaktwerte. Vorhandene ältere Ereignisse werden nicht umgedeutet. Das Dashboard gruppiert Informationsmeldungen eines Betriebs innerhalb von fünf Minuten, auch bei gemischten Kategorien; Originalereignisse bleiben erhalten. Berechtigte Prüfentscheidungen bleiben separat.
$content$,updated_at=now() WHERE slug='concept' AND position('## Admin-Ereignisse 0.31.5' in body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $content$## Abnahme 0.31.5 – Registrierung 2.0 und Mandantentrennung

1. Neues, separates Testkonto registrieren; E-Mail bestätigen; vor Einreichung alle Profilfelder inklusive Medien und Karte bearbeiten.
2. Einreichen; Profil, Bilder und Standort dürfen anschliessend nicht mehr verändert werden (auch nicht durch direkte RPC-/Storage-Zugriffe).
3. Admin fordert Nachbesserung; Konto darf wieder bearbeiten und erneut einreichen.
4. Admin genehmigt; Marktplatzzugang prüfen.
5. Normale Änderung durchführen: Feldnamen im Admin-Cockpit prüfen; keine Werte in der Meldung; zusammengefasste Anzeige.
6. Firmenname/Land/USt-ID über Antrag ändern; ohne Admin-Zustimmung keine direkte Änderung möglich.
7. Mit einem **zweiten** Betrieb fremde Profiländerung, fremde Medien und Admin-RPCs negativ testen.
8. Bei neuer Testlöschung kontrollieren, dass das zugehörige Löschereignis automatisch geschlossen wird.

Status: **zur manuellen Live-Abnahme**; kein hier nicht bestätigter Test wird als bestanden markiert.
$content$,updated_at=now() WHERE slug='tests' AND position('## Abnahme 0.31.5 – Registrierung 2.0 und Mandantentrennung' in body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $content$## StaffKeeping 0.31.5

Korrekturen am Audit: feldgenaue neue Informationsmeldungen ohne Speicherung von Vorher-/Nachherwerten; zusammengefasste Anzeige über normale Profil- und Standortereignisse; automatische Schliessung abgeschlossener Löschmeldungen. Gezielter Testplan für Registrierung 2.0, Profilsperre, Nachbesserung, Admin-Freigabe und Mandantentrennung. SQL-Livetest offen.
$content$,updated_at=now() WHERE slug='history' AND position('StaffKeeping 0.31.5' in body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $content$## Stand 0.31.5

Navigation 0.31.4 vom Nutzer positiv bestätigt. Löschung Testbetrieb mit Auth und UUID-Medienprüfung positiv bestätigt. 0.31.5 Audit-Korrektur implementiert; Live-Prüfung von SQL, neuem Registrierungsablauf und Mandantentrennung steht aus.
$content$,updated_at=now() WHERE slug='status' AND position('## Stand 0.31.5' in body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $content$## Übergabe 0.31.5

Release 0.31.5 enthält eine SQL-Migration für Admin-Ereignisse und eine ergänzende Dokumentationsmigration. Beide in Supabase ausführen, dann GitHub veröffentlichen. Keine zweite Dokumentationsquelle etablieren. Zwei verschiedene Testbetriebe für Negativtests verwenden. Alte Auditmeldungen haben keine zuverlässigen Feldnamen.
$content$,updated_at=now() WHERE slug='handoff' AND position('## Übergabe 0.31.5' in body)=0;
UPDATE sk_internal.help_chapters
SET body=body || E'\n\n' || $manual$
## Änderungen und Hinweise im Admin-Cockpit

| Änderung | Anzeige | Bestätigung |
|---|---|---|
| Profil / Kontakt | Geänderte Feldnamen, ohne alte und neue Werte | Nur zur Kenntnis |
| PLZ / Ort / Strasse / Standort | Standortangaben geändert | Nur zur Kenntnis |
| Firmenname, Land, USt-ID | Prüfpflichtiger Antrag | Admin muss entscheiden |
| Löschantrag | Datenschutzaufgabe | Abschluss erst nach Entscheidung und Löschung |

Gehören mehrere Meldungen desselben Betriebs zeitlich zusammen, werden sie in der Übersicht zusammengefasst. Über **Protokollierte Änderungen anzeigen** können die verfügbaren Feldnamen eingesehen werden. Historische Ereignisse ohne Feldangaben bleiben allgemein bezeichnet.

![Admin-Dashboard mit Änderungsdetails](screenshot:admin-ereignisse-felder-0315)
$manual$, updated_at=now()
WHERE page_key IN ('admin-home','admin-activity') AND position('## Änderungen und Hinweise im Admin-Cockpit' in body)=0;
COMMIT;
