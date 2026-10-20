-- StaffKeeping 0.33.1.6.3: ausschliesslich Projektdokumentation.
-- Vier UPDATE-Anweisungen und ein abschliessendes SELECT (ein Resultset).
-- Keine Schemaaenderung, keine Betriebsdatenveraenderung.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$sk$
## 0.33.1.6.3 – Freie Adresserfassung und manuelle Karte (19.10.2026)
Eine Adresse kann trotz fehlender Google-Geocodierung gespeichert werden. Im Betriebsprofil und bei der Neuanlage gibt es "Marker manuell setzen": Karte anhand PLZ/Ort bzw. Laender-Fallback oeffnen, Standort anklicken, Marker ziehen, "Position bestaetigen", danach speichern. Weder Google-Fallback noch Kartenmittelpunkt werden automatisch als Betriebsstandort gespeichert. Adresse/Strasse/Hausnummer werden nicht durch Google ersetzt. Ohne Standort wird vor dem Speichern ausdruecklich gewarnt. Bestehende Eigentums-/Freigaberegeln und DB-RPC unveraendert.
$sk$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.6.3 – Freie Adresserfassung und manuelle Karte' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$sk$
## 0.33.1.6.3 – Freie Adresserfassung und manuelle Karte (19.10.2026)
Frontend-Patch bereitgestellt, Syntaxpruefung erfolgreich; Browser-Live-Retest noch ausstehend. Standorttests 1–9 erfolgreich. Test 10: bisher fehlende explizite Warnung beim Speichern ungueltiger Google-Adresse; Retest fuer manuelle Positionswahl, Adresspersistenz und Isolation erforderlich. Auto-Save 0.33.1.7 bleibt offen.
$sk$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.6.3 – Freie Adresserfassung und manuelle Karte' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$sk$
## 0.33.1.6.3 – Retests zur manuellen Standortwahl (19.10.2026)
1. Editierbarer Testbetrieb: Fantasiestrasse und Hausnummer erfassen; Google meldet keinen genauen Treffer. 2. "Marker manuell setzen" oeffnet Karte fuer Ort; Kartenausschnitt dient nur als Ausgangspunkt. 3. Auf Karte klicken/Marker ziehen und "Position bestaetigen"; Adresse samt manueller Position speichern, Hard-Refresh pruefen. 4. Testbetrieb ohne Position speichern: ausdrueckliche Warnung und Option "Abbrechen"; nach Zustimmung unbekannte Entfernung. 5. Kontrollbetrieb nach Reload unveraendert; kein Zugriff auf fremde Betriebsdaten. 6. Read-only-Betrieb darf nicht "Standort wird ermittelt" behaupten. Live-Abnahme ausstehend.
$sk$,updated_at=now() WHERE slug='tests' AND position('## 0.33.1.6.3 – Retests zur manuellen Standortwahl' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$sk$
## 0.33.1.6.3 – Freie Adresserfassung und manuelle Karte (19.10.2026)
Nur geaenderte Dateien app.js, location.js, index.html plus Dokumentationsmigration. Keine SQL-Schema- oder Datenmigration. Geocodierung ist keine Adressgueltigkeitspruefung. Anwenderpositionen sind benutzerbestaetigt, nicht durch Google oder Annette verifiziert.
$sk$,updated_at=now() WHERE slug='history' AND position('## 0.33.1.6.3 – Freie Adresserfassung und manuelle Karte' IN body)=0;
COMMIT;
SELECT slug, updated_at FROM sk_internal.project_doc_chapters WHERE slug IN ('concept','status','tests','history') ORDER BY slug;
