-- StaffKeeping 0.33.1.7.4: Dokumentationsnachtrag, keine Schema-/RLS-Aenderung.
-- Zwei UPDATE-Anweisungen und ein Kontroll-SELECT (ein Resultset).
BEGIN;
UPDATE sk_internal.project_doc_chapters
SET body = body || E'\n\n' || $doc$
## 0.33.1.7.4 – Inserat neu / Entwurf / Schliessen (21.10.2026)
«+ Neues Inserat» startet einen neuen, unabhaengigen Inseratsentwurf mit eigener UUID im bestehenden draft_key (new:<uuid>); mehrere private Inseratsentwuerfe pro Betrieb und Benutzer sind zulaessig. Vorhandene legacy-Entwuerfe mit new:<business_id> bleiben ueber «Meine Inserate» direkt editierbar. «Entwurf bearbeiten» laedt ausschliesslich den angewaehlten Entwurf ohne Wiederherstellungsabfrage. Beim X/Escape/innerer Navigation gilt: Ist der private Entwurf bereits vollstaendig gespeichert, wird ohne weitere Rueckfrage geschlossen; bei ungesicherten Aenderungen erscheinen «Entwurf speichern», «Aenderungen verwerfen» und «Weiter bearbeiten». «Entwurf speichern» sichert mit bestehender Revisionspruefung und schliesst erst nach erfolgreicher Serverantwort. «Aenderungen verwerfen» verwirft nur noch nicht gesicherte Eingaben, nicht den bestehenden gespeicherten Entwurf. Noch laufende Auto-Saves werden vor der Entscheidung abgeglichen; ein wartender Auto-Save wird pausiert, damit er das Verwerfen nicht unterlaufen kann. Fehlgeschlagene Sicherung laesst das Formular offen. Browser-Reload / Tab-Schliessen bleibt bei ungesicherten Aenderungen native beforeunload-Warnung. Keine zusaetzliche Entwurfstabelle oder neue Berechtigungen; keine automatische Veroeffentlichung.
$doc$, updated_at=now()
WHERE slug='concept' AND position('## 0.33.1.7.4 – Inserat neu / Entwurf / Schliessen' IN body)=0;
UPDATE sk_internal.project_doc_chapters
SET body = body || E'\n\n' || $doc$
## 0.33.1.7.4 – Teststand (21.10.2026)
Frontend-Korrektur fuer eindeutige Neuentwuerfe und Schliessen mit drei Aktionen bei ungesicherten Inseratsdaten. JavaScript-Syntax und ZIP-Inhalt lokal geprueft, Live-Browsertest ausstehend. Regressionen pruefen: neues Inserat trotz bestehendem Entwurf; zwei neue Entwuerfe desselben Betriebs; Bearbeiten eines alten/new-UUID-Entwurfs; X bei gesichertem / ungesichertem / laufendem / fehlgeschlagenem Auto-Save; «Verwerfen» erhaelt vorhandene Serverentwuerfe; Veroeffentlichung separat und explizit. Offene Themen der Version 0.33.1.7 (Legacy-Profil-/Standort-RPC, parallele Sitzungen) bleiben bestehen.
$doc$, updated_at=now()
WHERE slug='status' AND position('## 0.33.1.7.4 – Teststand' IN body)=0;
COMMIT;
SELECT slug,updated_at FROM sk_internal.project_doc_chapters WHERE slug IN ('concept','status') ORDER BY slug;
