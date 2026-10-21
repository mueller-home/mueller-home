-- StaffKeeping 0.33.1.7.7 – central project documentation; 2 UPDATEs + 1 SELECT.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $d$
## 0.33.1.7.7 – Lesemodus und kontrollierte Wiederuebernahme
Gesperrte Inseratsentwuerfe werden nach dem Laden der Entwurfsdaten schreibgeschuetzt angezeigt (Inhalte sichtbar, Bearbeitungsaktionen deaktiviert). Ein berechtigter Benutzer kann ueber einen bewusst bestaetigten Button Bearbeitung uebernehmen. Die serverseitige SQL-Funktion ersetzt atomar die gueltige Session-ID; die alte Sitzung darf nicht mehr in sk_save_form_draft schreiben und verliert bei naechster Lease-Erneuerung ihren Bearbeitungsstatus. Die Uebernahme ist absichtlich nicht automatisch: Ein Server kann Browserabsturz und bloss inaktives Fenster nicht sicher unterscheiden. Die vorhandene Versionspruefung bleibt bestehen. Einschränkung: Direkte Live-Inserat-Aenderungswege besitzen noch keine vollstaendige Lease-Erzwingung; separat auditieren.
$d$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.7.7 – Lesemodus' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $d$
## 0.33.1.7.7 – Retest offen
Test: A editierbar; B gleiches Inserat nur Ansicht mit Titel/Beschreibung; B uebernimmt erst nach ausdruecklicher Warnung; A darf danach nicht mehr auto-speichern; B kann sichern; X-Freigabe/90-Sekunden-Ablauf weiterhin testen. SQL und Frontend statisch validiert, kein Supabase- oder Browser-Livetest. Urspruenglicher Upstream-Timeout nicht als behoben nachgewiesen.
$d$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.7.7 – Retest offen' IN body)=0;
COMMIT;
SELECT slug,updated_at FROM sk_internal.project_doc_chapters WHERE slug IN ('concept','status') ORDER BY slug;
