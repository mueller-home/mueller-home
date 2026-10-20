-- 0.33.1.7.1: zentrale Projektdoku, additiver Nachtrag, ein Resultset.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$d$
## 0.33.1.7.1 – Inseratsentwürfe und Veröffentlichungsaktion (20.10.2026)
Private, automatisch gespeicherte Inseratsentwürfe erscheinen nun unter Meine Inserate je berechtigtem Betrieb, einschliesslich Bearbeiten und Verwerfen. Neue Inserate werden erst durch den ausdruecklichen Button „Veröffentlichen“ in public.sk_listings angelegt; bereits veroeffentlichte Inserate werden erst mit „Änderungen veröffentlichen“ aktualisiert. Auto-Save allein aendert niemals ein Live-Inserat. Die neue RPC public.sk_list_my_listing_drafts() zeigt ausschliesslich Entwuerfe des authentifizierten Benutzers mit genehmigter Betriebszuordnung. Beim Betriebswechsel muss der bestehende Entwurf erst erfolgreich gesichert werden; danach wird ein frisches Formular fuer den neuen Betrieb geoeffnet. Statische Syntaxpruefung durchgefuehrt; Laufzeittests offen.
$d$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.7.1 – Inseratsentwürfe' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$d$
## 0.33.1.7.1 – Teststatus (20.10.2026)
Vorherige Auto-Save-Basistests fuer Betriebsprofil und Inserat je 5/5 durch Benutzer bestanden. Fehler: dauerhafte Ungespeicherte-Änderungen-Anzeige trotz erfolgreich gesichertem Draft bei Inserat beobachtet; mit aktueller Integration weiter zu untersuchen, nicht als behoben deklarieren. Neue private Entwurfsuebersicht, bewusste Veroeffentlichung und Betriebswechsel-Schutz als Testkandidat, noch nicht live abgenommen. Ausstehend: Rechte/Concurrency, alte Standort-RPC, legacy Profil, alle Navigationspfade.
$d$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.7.1 – Teststatus' IN body)=0;
COMMIT;
SELECT slug,updated_at FROM sk_internal.project_doc_chapters WHERE slug IN ('concept','status') ORDER BY slug;
