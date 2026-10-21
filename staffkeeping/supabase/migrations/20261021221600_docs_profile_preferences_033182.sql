-- StaffKeeping 0.33.1.8.2; ein Kontroll-SELECT, nur zentrale Projektdokumentation.
BEGIN;
UPDATE sk_internal.project_doc_chapters
 SET body=coalesce(body,'') || E'\n\n0.33.1.8.2 (21.10.2026, Umsetzungsetappe A): Der neue betriebsbezogene Editor bietet email_notifications_enabled und show_street_address. Beide Werte werden mit Stammdaten und Standort atomar ueber sk_update_business_with_preferences_location gespeichert. Legacy-Profilseite bleibt fuer Medien, sensible Aenderungsantraege, Loeschantrag und Einreichung bestehen. Weitere Vereinheitlichung erst nach Funktionsparitaet und Tests. Nicht als fertig abgenommen markieren.',updated_at=now()
 WHERE slug='concept';
UPDATE sk_internal.project_doc_chapters
 SET body=coalesce(body,'') || E'\n\n0.33.1.8.2: Umsetzungsetappe A bereit, noch nicht live getestet. Legacy-Profil-Auto-Save und direkte Live-Speicherwege nicht entfernt; naechster Schritt: Medien, Antraege und Registrierung sicher in den Betriebs-ID-Kontext ueberfuehren. Keine neuen Benutzerrollen.',updated_at=now()
 WHERE slug='status';
COMMIT;
SELECT slug,updated_at FROM sk_internal.project_doc_chapters WHERE slug IN ('concept','status') ORDER BY slug;
