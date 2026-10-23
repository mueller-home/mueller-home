-- StaffKeeping 0.33.1.8.6 – zentrale Dokumentation; genau ein Schluss-SELECT.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$d$
## 0.33.1.8.6 – Rechtliche Aenderungsantraege mit Betriebs-ID
0.33.1.8.5: Medienverwaltung 7/7 Retests bestanden und abgenommen. Im neuen Bereich «Meine Betriebe» koennen freigeschaltete Inhaber Aenderungen an Firmenname, UID/USt-ID und Land pro Betrieb beantragen. Neue RPC sk_request_business_sensitive_change_by_id verlangt explizite Betriebs-ID, bestaetigte E-Mail, Rolle owner, status Freigeschaltet und review_state approved. Der Antrag wird nur in business_change_requests und admin_events erfasst; keine direkte Live-Aenderung. Annette entscheidet weiterhin mit vorhandenem Admin-Workflow. Die Legacy-Seite fuer Einreichungen, Loeschantraege und alten Live-Auto-Save bleibt vorerst erreichbar; keine stillschweigende Migration.
$d$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.8.6 – Rechtliche Aenderungsantraege' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$d$
## 0.33.1.8.6 – Status
Neu: betriebsbezogener Antrag fuer kritische Profildaten in «Meine Betriebe», ohne Rollenvervielfachung oder Live-Auto-Save. Regression: Mehrbetriebsbenutzer, einzelner Betrieb, fremde UUID per direktem RPC, bestaetigte Freigabe, bestehende Antragsfreigabe bei Annette. Nicht umgesetzt: Loeschantraege und Registrierungseinreichung fuer jeden einzelnen weiteren Betrieb; vorher muss die Navigation fuer ausstehende Betriebe sauber geklaert werden. Neue Version noch nicht produktiv getestet.
$d$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.8.6 – Status' IN body)=0;
COMMIT;
SELECT slug,updated_at FROM sk_internal.project_doc_chapters WHERE slug IN ('concept','status') ORDER BY slug;
