-- StaffKeeping 0.33.1.7.3: ausschliesslich interne Projektdokumentation.
-- Zwei UPDATE-Anweisungen, anschliessend ein Kontroll-SELECT (ein Resultset).
BEGIN;
UPDATE sk_internal.project_doc_chapters
SET body = body || E'\n\n' || $doc$
## 0.33.1.7.3 – Explizit Entwurf speichern (21.10.2026)
Das Inseratsformular bietet neben «Veröffentlichen» bzw. «Änderungen veröffentlichen» eine sekundäre Aktion «Entwurf speichern». Diese sichert sofort den vollständigen privaten Entwurf (auch unvollständig, ohne Live-Pflichtfeldvalidierung), wartet auf die serverseitige Versionskontrolle und schliesst erst nach bestätigtem Erfolg. Bei Fehler/Versionskonflikt bleibt das Formular mit seinen Eingaben offen. «Veröffentlichen» behält seine gesonderte bewusste Live-Speicherung mit Validierung. Das bisherige Auto-Save bleibt bestehen; keine neue Tabelle, kein neuer RPC, keine zusätzlichen Testfunktionen. Auf dem Server gesicherte Entwürfe gehören zu Benutzer und Betrieb; keine automatische Veröffentlichung.
$doc$, updated_at = now()
WHERE slug = 'concept' AND position('## 0.33.1.7.3 – Explizit Entwurf speichern' IN body) = 0;
UPDATE sk_internal.project_doc_chapters
SET body = body || E'\n\n' || $doc$
## 0.33.1.7.3 – Teststand (21.10.2026)
Zusätzlicher Button «Entwurf speichern» im Inseratsformular implementiert: Speichern auch mit unvollständigen Angaben, Schliessen erst nach Erfolg, auf Fehler Eingaben erhalten. Versionsprüfung im vorhandenen Entwurfs-RPC bleibt unverändert. JavaScript-Syntax und Paketintegrität lokal geprüft. Live-Retests noch offen: leerer Entwurf, teilweise ausgefüllter Entwurf, Speichern/Schliessen und Wiederöffnen, Versionskonflikt, unveränderte Live-Inserate sowie die bereits offenen Legacy-Profil-/Standortthemen.
$doc$, updated_at = now()
WHERE slug = 'status' AND position('## 0.33.1.7.3 – Teststand' IN body) = 0;
COMMIT;
SELECT slug, updated_at FROM sk_internal.project_doc_chapters WHERE slug IN ('concept','status') ORDER BY slug;
