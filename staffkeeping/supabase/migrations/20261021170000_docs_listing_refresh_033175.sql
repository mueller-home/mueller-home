-- StaffKeeping 0.33.1.7.5: ausschliesslich Projektdokumentation.
-- Zwei UPDATE-Anweisungen und ein abschliessender Kontroll-SELECT (ein Resultset).
BEGIN;
UPDATE sk_internal.project_doc_chapters
SET body=body || E'\n\n' || $doc$
## 0.33.1.7.5 – Inseratslisten-Aktualisierung (21.10.2026)
Auf «Meine Inserate» aktualisiert StaffKeeping die Liste bei erneutem Fokus des Browserfensters bzw. bei Wieder-Sichtbarwerden der Registerkarte, nach dem Schliessen des Inseratsdialogs sowie nach bestehenden Speichern-/Veröffentlichen-/Statuswechselaktionen. Hintergrundaktualisierungen zeigen keinen Lade-Platzhalter und bauen offene Bearbeitungsformulare nicht neu auf. Ergebnisse werden erst bei vollstaendig abgeschlossenem, noch aktuellem Ladevorgang angewendet; doppelte Ereignisse werden zusammengefasst. Keine Realtime-Verbindung und keine zusätzlichen Testfunktionen. Bestehende Authentifizierung, RLS, Entwurfs-RPCs und Veroeffentlichung bleiben unveraendert.
$doc$,updated_at=now()
WHERE slug='concept' AND position('## 0.33.1.7.5 – Inseratslisten-Aktualisierung' IN body)=0;
UPDATE sk_internal.project_doc_chapters
SET body=body || E'\n\n' || $doc$
## 0.33.1.7.5 – Teststand (21.10.2026)
Vorheriger Stand 0.33.1.7.4: sieben Formular- und Entwurfstests vom Benutzer bestanden. Neue Listenaktualisierung lokal auf JavaScript-Syntax und Paketstruktur geprueft, Live-Retest noch offen. Browser-Retest: zwei Fenster desselben Nutzers, Titel in A aendern und veroeffentlichen, B fokussieren – neuer Titel ohne Reload; Formular in B oeffnen und schliessen – Liste erneut aktuell; bei offenem Formular keine Ueberschreibung der Eingaben. Der separate Test der parallelen Entwurfs-Versionierung ist nicht bestanden/unklar: In Fenster B wurde «upstream request timeout» beobachtet; Ursache (Supabase/RPC/Netzwerk) noch nicht nachgewiesen. Nicht als behoben markieren. Offene weitere Arbeiten: Fremdzugriff auf private Entwuerfe und alte Standort-RPC / Legacy-Profil-Auto-Save.
$doc$,updated_at=now()
WHERE slug='status' AND position('## 0.33.1.7.5 – Teststand' IN body)=0;
COMMIT;
SELECT slug,updated_at FROM sk_internal.project_doc_chapters WHERE slug IN ('concept','status') ORDER BY slug;
