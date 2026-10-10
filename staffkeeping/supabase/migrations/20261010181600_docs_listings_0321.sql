-- StaffKeeping 0.32.1: Dokumentation in bestehenden Kapiteln (keine Parallel-Dokumentation).
-- 6 UPDATE in einer Transaktion, 1 Kontroll-SELECT; separate SELECT-Ergebnisse gibt es nicht.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $d$## Phase 0.32.1 – Eigene Inserate (10.10.2026)

Neue Browser-Tabelle `public.sk_listings` mit RLS (SELECT, INSERT, UPDATE, DELETE nur fuer Mitglieder des zugeordneten Betriebes; schreibende Aktionen nur bei freigegebenem Betrieb). `business_id` hat FK mit ON DELETE CASCADE. Serverseitiger Trigger erzwingt `city`/`country` aus dem freigegebenen Betriebsprofil und unterbindet das Umhaengen eines bestehenden Inserats auf einen anderen Betrieb. Keine anonymen Tabellenrechte. Status `Aktiv`/`Inaktiv`; Felder Typ (Suche/Biete), Kategorie, Titel, Beschreibung, Von/Bis, Bedingungen, Unterkunft, Sprachen. Neuer Code verwendet echte Supabase-CRUD-Abfragen. Demo-Inserate aus «Meine Inserate» entfernt. Erfolg erst nach Serverantwort, Fehler angezeigt. **Die Suche und die Kontaktaufnahme sind in 0.32.1 weiterhin Demo und haben noch keinen Zugriff auf echte Inserate.** Keine produktive Moderation oder Vergabe in diesem Schritt.

Ausfuehrungsreihenfolge: zuerst SQL 20261010181500_listings_0321.sql, danach Browser-Dateien veroeffentlichen, danach 20261010181600_docs_listings_0321.sql.
$d$,updated_at=now() WHERE slug='concept' AND position('## Phase 0.32.1 – Eigene Inserate' in body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $d$## 0.32.1 – Inserats-CRUD
Neue Tabelle sk_listings, serverseitige Profil-Ortsuebernahme und Row-Level-Security; eigene Inserate speichern, bearbeiten, aktivieren/deaktivieren und loeschen. Marktplatzsuche/Antworten bleiben Demo (0.32.2/0.32.3). Deploy/Tests beim Benutzer ausstehend.
$d$,updated_at=now() WHERE slug='history' AND position('## 0.32.1 – Inserats-CRUD' in body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $d$## 0.32.1 – Implementiert, noch live zu testen
Erstellen, Bearbeiten, Aktiv/Inaktiv und Loeschen eigener Inserate inklusive Datums- und Feldvalidierung; serverseitiger Standort aus dem Betriebsprofil, RLS. Suche, Antworten, Vergabe, Bewertung und Partnerschaften sind noch nicht produktiv.
$d$,updated_at=now() WHERE slug='status' AND position('## 0.32.1 – Implementiert, noch live zu testen' in body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $d$## Zu testen – StaffKeeping 0.32.1
1. Betrieb A: Inserat erstellen; korrekten Ort und Land kontrollieren; Browser-Reload: Datensatz weiterhin vorhanden.
2. Inhalt pruefen: Beschreibung, Rahmenbedingungen, Unterkunft, Sprachen und Datumsbereich bleiben nach Bearbeiten erhalten.
3. Status Aktiv/Inaktiv bleibt nach Reload erhalten; Loeschen entfernt nur eigenes Inserat.
4. Betrieb B: fremde Inserate ueber sk_listings nicht lesbar/aenderbar/loeschbar; direkter REST-Test mit JWT und RLS (kein Service-Role-Key).
5. Nicht freigegebener Betrieb darf keine Inserate erstellen oder aendern. Datum Bis < Von wird abgewiesen.
6. Vollstaendige Betriebloeschung entfernt die verknuepften sk_listings per FK CASCADE; anschliessend kein Zugriff mit Alt-JWT.
7. Suche/Antworten zeigen weiterhin nur Demo; nicht als produktive Funktion freigeben.
$d$,updated_at=now() WHERE slug='tests' AND position('## Zu testen – StaffKeeping 0.32.1' in body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $d$## Nach 0.32.1
P1 Testen/Abnehmen von Inserat-CRUD und RLS. P2 Suche echter Inserate (sorgfaeltige Sichtbarkeit/Datenschutz). P3 Antworten/Anfragen zwischen Betrieben und persistente Nachrichten. P4 Maps-Marker modernisieren. Offene Demo-Bausteine nicht als fertig markieren.
$d$,updated_at=now() WHERE slug='issues' AND position('## Nach 0.32.1' in body)=0;
UPDATE sk_internal.help_chapters SET body=body || E'\n\n' || $h$## Eigene Inserate – ab Version 0.32.1
Unter «Meine Inserate» «+ Neues Inserat» waehlen. Typ, Kategorie, Titel, Beschreibung und Zeitraum angeben. Optional Rahmenbedingungen, Unterkunft und Sprachen. Ort/Land kommen automatisch aus dem freigegebenen Betriebsprofil. Nach «Inserat speichern» ist der Eintrag in Supabase gespeichert und bleibt nach erneutem Laden erhalten. Ueber die Symbole bearbeiten, Aktiv/Inaktiv umschalten oder dauerhaft loeschen. Bei Fehlern erfolgt keine Speicherbestaetigung. «Vergeben», «Als Partner», Suche und Antworten sind noch nicht produktiv (folgende Phase).
![Screenshot: Neues Inserat, Standort aus Betriebsprofil](screenshot:marketplace-inserat-erstellen-032)
$h$,updated_at=now() WHERE page_key='my-listings' AND position('## Eigene Inserate – ab Version 0.32.1' in body)=0;
COMMIT;
SELECT 'project_docs' AS bereich,count(*) FILTER (WHERE body LIKE '%0.32.1%') AS kapitel_mit_0321 FROM sk_internal.project_doc_chapters
UNION ALL SELECT 'help',count(*) FILTER (WHERE body LIKE '%Eigene Inserate – ab Version 0.32.1%') FROM sk_internal.help_chapters;
