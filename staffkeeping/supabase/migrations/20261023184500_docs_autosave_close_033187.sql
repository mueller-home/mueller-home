-- 0.33.1.8.7: UX-Korrektur, keine Schema- oder Rechteaenderungen.
-- Zwei UPDATEs, ein abschliessendes SELECT-Resultset.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$d$
## 0.33.1.8.7 – UX-Regel Schliessen und Abbrechen
Applikationsweite Vorgabe: Auto-Save-Eingabemasken erhalten einen gut sichtbaren Button «Schliessen». Er wartet die private Entwurfssicherung ab und schliesst nur bei erfolgreichem Abschluss. Bei Fehler bleiben Eingaben erhalten; es erfolgt keine stille Publikation oder Live-Speicherung. X und Escape gelten als Abbrechen mit Schutz ungespeicherter Eingaben. Umgesetzt fuer Inserat und neues betriebsbezogenes Betriebsprofil. Nach erfolgreicher verbindlicher Einreichung eines rechtlichen Aenderungsantrags wird der Dialog ohne falsche Unsaved-Warnung geschlossen und eine Bestaetigung unter Meine Betriebe angezeigt.
$d$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.8.7 – UX-Regel' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$d$
## 0.33.1.8.7 – Stand und Retest
Frontend-Fix fuer Auto-Save-Masken und rechtliche Aenderungsantraege. Keine neue RPC, kein DB-Schemawechsel. Regression: Inseratsentwurf mit/ohne Aenderungen schliessen, Fehlschlag der Sicherung, lesender gesperrter Entwurf, Betriebsentwurf, Abbrechen per X sowie erfolgreicher/fehlgeschlagener rechtlicher Antrag. Andere alte Profilmasken werden weiterhin im Rahmen der Legacy-Bereinigung ueberprueft.
$d$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.8.7 – Stand' IN body)=0;
COMMIT;
SELECT slug,updated_at FROM sk_internal.project_doc_chapters WHERE slug IN ('concept','status') ORDER BY slug;
