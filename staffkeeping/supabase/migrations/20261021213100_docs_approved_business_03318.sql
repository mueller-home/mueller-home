-- StaffKeeping 0.33.1.8: technische Dokumentation.
-- Zwei UPDATEs; EIN abschliessendes SELECT-Resultset.
BEGIN;
UPDATE sk_internal.project_doc_chapters
SET body=body||E'\n\n'||$d$
## 0.33.1.8 – Konsistente Betriebsfreigabe (21.10.2026)
Die gemeinsame serverseitige Funktion sk_is_approved_member(uuid) verlangt jetzt pro Betrieb zugleich status = Freigeschaltet und review_state = approved sowie aktuelle Mitgliedschaft. Damit sind Entwurf/RLS/Inseratszugriff und bestehende Inserats-Trigger bei der Betriebsfreigabe konsistent. Jeder Betrieb wird weiterhin einzeln durch Annette freigegeben; keine neuen Mitarbeiterrollen. Keine Aenderung an bestehenden Inserats- oder Entwurfsdatensaetzen. Der Funktionsname, die Signatur und die authentifizierten Ausfuehrungsrechte bleiben bestehen. Diese Migration veraendert NICHT das bisherige private Entwurfsmodell, die Inseratssperre oder die Standortdaten.
$d$,updated_at=now()
WHERE slug='concept' AND position('## 0.33.1.8 – Konsistente Betriebsfreigabe' IN body)=0;
UPDATE sk_internal.project_doc_chapters
SET body=body||E'\n\n'||$d$
## 0.33.1.8 – Stand und offene Arbeiten (21.10.2026)
Vom Anwender bestaetigte Tests: Mandantentrennung der privaten Entwuerfe zwischen Brave-Konto A und Chrome-Konto B 4/4 OK; alle 5 bestehenden Betriebe laut SQL in status Freigeschaltet und review_state approved. Bearbeitungssperre/Lesemodus/Uebernahme zuletzt 5/5 in 0.33.1.7.8 OK. Migration 0.33.1.8 lokal vorbereitet, Supabase-Ausfuehrung und Regression noch nicht bestaetigt. Legacy-RPC sk_set_my_business_location arbeitet ohne explizite Betriebs-ID und bleibt vorerst bestehen, weil die weiterhin geladene alte Profil-/Kartenoberflaeche sie aufruft. Legacy-Unternehmensprofil speichert weiterhin live automatisch (sk_update_my_business_profile); es ist NICHT auf private Entwuerfe umgestellt. Diese beiden Pfade nur in einem separaten, nachvollziehbaren Umstieg deaktivieren; keine ungepruefte DROP-Anweisung. Direkte Schreibwege fuer veroeffentlichte Inserate sowie ungewoehnliche API-Negativtests weiterhin als abschliessende Sicherheitskontrolle offen. Frueherer upstream request timeout beim parallelen Auto-Save nicht ursachlich aufgeklaert.
$d$,updated_at=now()
WHERE slug='status' AND position('## 0.33.1.8 – Stand und offene Arbeiten' IN body)=0;
COMMIT;
SELECT slug, updated_at FROM sk_internal.project_doc_chapters WHERE slug IN ('concept','status') ORDER BY slug;
