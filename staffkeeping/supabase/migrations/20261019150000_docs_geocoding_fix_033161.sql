-- StaffKeeping 0.33.1.6.1 – gezielte Dokumentation des Geocoding-Fehlerfalls.
-- Nur Dokumentations-UPDATEs, keine Schema-/Berechtigungs-/Betriebsdatenänderungen.
-- Vier UPDATEs in einer Transaktion, genau EIN Kontroll-SELECT.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$txt$
## 0.33.1.6.1 – Standortermittlung: Genauigkeit und Timeout
Browser-Test am 19.10.2026: Standorttests 1–6 von 0.33.1.6 bestanden. Test 7 fehlgeschlagen: Bei einer erfundenen Strasse bleibt die Statusmeldung stehen; auch manueller Wiederholungsversuch half nicht. Direktes Google-Geocoding war verfügbar und antwortete für Bern erfolgreich, für «Xyzphantasiestrasse 98765, Schweiz» aber nur mit «Schweiz», location_type APPROXIMATE (kein Adresstreffer). Der Karteneditor akzeptierte bislang den ersten Treffer ungeachtet der Genauigkeit. 0.33.1.6.1 prüft deshalb den fachlichen Detailgrad: Bei Strassenadressen nur Strassentreffer mit brauchbarer Position; bei PLZ/Ort sind entsprechend ungefähre Orts-/PLZ-Treffer weiterhin zulässig, aber kein Länderfallback. Ein Timeout (10 s) mit Fehlermeldung verhindert unbegrenztes Warten; veraltete Antworten dürfen aktuelle Koordinaten nicht überschreiben. Keine Schemaänderung, keine automatische Freigabe. Genaues Zustandekommen der vorher dauerhaft hängenden UI-Meldung ist nicht abschliessend bewiesen. Status des Patches: implementiert und statisch geprüft; Live-Retest ausstehend. Alte Tests 1–6 bei Bedarf regressiv prüfen; Tests 8–10 weiterhin offen.
$txt$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.6.1 – Standortermittlung:' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$txt$
## Stand 19.10.2026 – 0.33.1.6.1
0.33.1.6: Standorttests 1–6 vom Betreiber als bestanden bestätigt. Test 7 fehlgeschlagen (nicht auffindbare Strasse, Statusmeldung hängt); gezielter Frontend-Fix 0.33.1.6.1 vorbereitet, noch nicht live abgenommen. Tests 8–10 offen. Keine Änderung am Abonnement-/Genehmigungssystem. 0.33.1.7 Auto-Save und Dirty-State-Schutz erst nach Standortabnahme.
$txt$,updated_at=now() WHERE slug='status' AND position('## Stand 19.10.2026 – 0.33.1.6.1' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$txt$
## Standort-Regression 0.33.1.6.1 (19.10.2026)
BESTANDEN (durch Betreiber, VOR Patch): 1 gespeicherte Position nach Reload, 2 automatische Standortermittlung, 3 Marker verschieben/speichern/reload, 4 Adresse ändert manuelle Position, 5 zusätzlicher Betrieb mit eigenem Standort, 6 Admin sieht Standort. FEHLGESCHLAGEN: 7 Geocoding bei nicht existierender Strasse, Status hängt; Google-Live-Direktprobe lieferte Schweiz APPROXIMATE statt Strassenposition. OFFEN: 7 Retest nach Patch: verständliche Fehlermeldung, keine falschen Koordinaten; 8 Mandantentrennung/API, 9 weitere Fehlerfälle, 10 abschliessender Standort-/Regressionstest. Keine bestandenen Tests durch Codebefund ersetzen.
$txt$,updated_at=now() WHERE slug='tests' AND position('## Standort-Regression 0.33.1.6.1' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$txt$
## 0.33.1.6.1 – Geocoding-Härtung (19.10.2026)
Nur Frontend-Korrektur im Mehrbetriebs-Karteneditor: grobe Länder-/Regions-Fallbacks statt Adresse zurückweisen, PLZ-/Ortspositionen weiter zulassen, 10-Sekunden-Timeout und verständliche Fehlermeldungen. Keine Datenbank-Schemaänderung. Test 7 zuvor fehlgeschlagen; Patch noch live zu testen. 0.33.1.7 bleibt nächster funktionaler Release.
$txt$,updated_at=now() WHERE slug='history' AND position('## 0.33.1.6.1 – Geocoding-Härtung' IN body)=0;
COMMIT;
SELECT slug, updated_at FROM sk_internal.project_doc_chapters WHERE slug IN ('concept','status','tests','history') ORDER BY slug;
