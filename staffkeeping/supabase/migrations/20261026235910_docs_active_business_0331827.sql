-- StaffKeeping 0.33.1.8.27 – zentrale Dokumentation.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$note$
## 0.33.1.8.27 – Aktiver Betrieb
Ein zentraler Arbeitskontext wählt einen freigegebenen Betrieb: bei genau einem Betrieb automatisch, bei mehreren im Header. Im Browser wird der Kontext kontobezogen gespeichert; er ist keine Berechtigung. Er wird für neue Inserate vorausgewählt, beim Kontaktformular als Absender bevorzugt, in Nachrichten als Ausgangsfilter verwendet und für Marktplatz-Distanzen explizit als p_business_id übergeben. Die neue SECURITY DEFINER-RPC sk_marketplace_distances_for_business prüft die Betriebsmitgliedschaft und Freigabe serverseitig. Gespeicherte Suchen halten origin_business_id fest; die Speicher-RPC prüft deren Zugehörigkeit. Fehlende Freigabe darf nicht stillschweigend auf einen anderen Standort umgebogen werden. Noch offen: E-Mail-Trefferprüfung, vollständige Bereichsfilterung aller betriebsübergreifenden Verwaltungsansichten, produktive Karten-ID (Annette/Patrick).
$note$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.8.27 – Aktiver Betrieb' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$note$
## 0.33.1.8.27 – Status
SQL und Web-Patch vorbereitet, produktive Installation und Retest offen. Test mit einem und mehreren freigegebenen Betrieben, Wechsel mit Umkreissuche, gespeicherter Suche und Kontaktaufnahme; manipulierter p_business_id muss keine Daten zurückgeben. Gespeicherte Suchen 0.33.1.8.26 SQL-Fehler laut Benutzer behoben.
$note$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.8.27 – Status' IN body)=0;
COMMIT;
