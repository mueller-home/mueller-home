-- StaffKeeping 0.33.1.8.26 – zentrale Projektdokumentation.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$doc$
## 0.33.1.8.26 – Gespeicherte Suchen
Im Marktplatz können angemeldete Mitglieder die Filter Stichwort, Inserattyp, Kategorie, Umkreis, Startdatum und Unterkunft als private Suche speichern. Suchen lassen sich öffnen, bearbeiten und löschen. Bis zu 30 Suchen pro Benutzer. Speicherung in sk_internal.saved_searches; keine direkten Tabellenrechte; RPC sk_list_saved_searches, sk_save_saved_search, sk_delete_saved_search mit serverseitiger Benutzerbindung und Eingabeprüfung. E-Mail-Präferenz kann gespeichert werden, hat aber noch keinen Versand zur Folge. Die spätere automatische Prüfung benötigt Duplikatschutz und einen belastbaren Bezugsstandort für den Radiusfilter bei mehreren Betrieben. Keine automatischen Mails in dieser Version.
$doc$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.8.26 – Gespeicherte Suchen' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$doc$
## 0.33.1.8.26 – Status
Frontend, private Tabelle und drei RPCs vorbereitet. Installation und Browser-Retest offen. Kurztest: Suche speichern, wieder aufrufen, aktualisieren, löschen; Trennung Brave/Chrome prüfen. Folgeentwicklung: automatische Trefferprüfung zweimal täglich, Versandinfrastruktur und Dashboard-Trefferzählung. Offene Aufgabe für Annette und Patrick: produktive Google-Maps-Karten-ID statt DEMO_MAP_ID.
$doc$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.8.26 – Status' IN body)=0;
COMMIT;
