-- StaffKeeping 0.33.1.8.21: zentrale Projektdokumentation
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'

'||$doc$
## 0.33.1.8.21 – Inserate mit Chats und Abschluss
Beide beteiligten freigeschalteten Betriebe können eine Unterhaltung verbindlich abschliessen; geschlossene Gespräche bleiben lesbar, aber nicht beschreibbar. Wird ein Inserat inaktiv, werden alle zugehörigen Unterhaltungen für beide Seiten archiviert. Ein Inserat mit Chat darf nicht endgültig gelöscht werden: Die berechtigungsgeprüfte RPC sk_delete_or_deactivate_listing deaktiviert es stattdessen. Datenbank-Trigger unterbindet direkte Löschungen. Standard-Nachrichtenübersicht zeigt aktive Gespräche; Archivfilter erlaubt Lesenzugriff. Kein automatisches Wiederöffnen bei erneuter Inserataktivierung.
$doc$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.8.21 – Inserate mit Chats' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'

'||$doc$
## 0.33.1.8.21 – Status
Neue Chat-Lebenszyklusmigration, Browser-Chatabschluss und Archivfilter, Löschaktion mit atomarer Deaktivierung. Syntax- und ZIP-Prüfungen lokal; Supabase-/Browsertest noch offen. Sicherheits-Negativtests und parallele Lösch-/Schreibzugriffe gesondert testen.
$doc$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.8.21 – Status' IN body)=0;
COMMIT;
