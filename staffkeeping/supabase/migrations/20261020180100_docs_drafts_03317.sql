-- StaffKeeping 0.33.1.7 Testkandidat: Dokumentationsnachtrag, KEIN Live-Abnahmevermerk.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$d$
## 0.33.1.7 – private Formulardrafts (20.10.2026)
Technischer Testkandidat: interne Tabelle sk_internal.form_drafts (RLS aktiviert, kein direkter Data-API-Zugriff), RPCs sk_get_form_draft/sk_save_form_draft/sk_discard_form_draft mit auth.uid(), Betriebsberechtigung, JSONB-Laengenlimit und optimistischer Revision. Neues Betriebsprofil und Inseratsformular sichern Formulardaten nach Tippstopp als private Entwuerfe; ausdrueckliches Live-Speichern/Veroeffentlichen bleibt unveraendert. Keine automatisch eingereichten Antraege und keine automatische Annette-Freigabe. Gespeicherte Drafts werden beim Oeffnen nur nach Benutzerzustimmung wiederhergestellt; Google-Koordinaten werden dabei nicht als bestaetigt rekonstruiert. Aeltere Unternehmensprofil-Live-Autosave-Funktion und neue Betriebserstellung sind in dieser ersten Stufe noch NICHT umgestellt; die alte RPC sk_set_my_business_location bleibt bis zur sicheren Ablösung bestehen.
$d$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.7 – private Formulardrafts' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$d$
## 0.33.1.7 – Testkandidat (20.10.2026)
Frontend/Migration bereitgestellt, nicht produktiv abgenommen. Browser- und DB-Livetests noetig; insbesondere Entwurfs-Restore, mehrfacher Betrieb, parallele Tabs, Fehler-/Konfliktstatus, manuelle Koordinaten und alle Navigationswege. Standorttests 1–10 in 0.33.1.6.3 vom Benutzer erfolgreich gemeldet. Offene Arbeit nach diesem Testkandidaten: altes Unternehmensprofil mit Live-Autosave konsolidieren, neue Betriebsantraege als sichere Entwuerfe ermoeglichen, Legacy-Standort-RPC betriebsbezogen migrieren, History-/Browser-Navigation vollstaendig testen.
$d$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.7 – Testkandidat' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$d$
## Testplan 0.33.1.7 (20.10.2026)
1. Neue Draftmigration und Adminrechte pruefen. 2. Entwurf in Betriebsprofil nach Tippstopp persistiert ohne Live-Tabellenupdates. 3. Popup schliessen, Entwurf wiederherstellen, keine Stilleinspielung. 4. Inseratsentwurf vor Live-Speichern pruefen und nicht im Marktplatz. 5. Zwei Betriebe eines Users trennen; fremde User duerfen keinen Draft lesen. 6. Zwei Tabs: veraltete Revision muss 40001 melden. 7. Offline/Netzwerkfehler: Daten nicht als gesichert ausweisen. 8. Manuelle Google-Position bleibt bei Live-Speicherung erhalten. 9. Browser-/Menue-/Zurueck-/Reload-Abbruchtests. 10. Nach erfolgreichem Live-Speichern Draft bereinigen; Regression bestehende Freigaben.
$d$,updated_at=now() WHERE slug='tests' AND position('## Testplan 0.33.1.7' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$d$
## 0.33.1.7 – Implementierungsstand (20.10.2026)
Ausschliesslich geaenderte Frontenddateien, internes Draft-Schema und Doku-Migration. Keine Ueberschreibung bestehender Tabellen/RLS der Betriebe oder Inserate. Erst DB-Migration, dann Frontend ausrollen. Nicht als vollstaendige Auto-Save-Migration deklarieren, solange Legacy- und Neuregistrierungs-Pfade nicht konsolidiert und Livetests ausstehend sind.
$d$,updated_at=now() WHERE slug='history' AND position('## 0.33.1.7 – Implementierungsstand' IN body)=0;
COMMIT;
SELECT slug,updated_at FROM sk_internal.project_doc_chapters WHERE slug IN ('concept','status','tests','history') ORDER BY slug;
