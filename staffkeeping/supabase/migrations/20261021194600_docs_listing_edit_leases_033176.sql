-- StaffKeeping 0.33.1.7.6: Projektdokumentation, 2 UPDATEs + ein SELECT-Resultset.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $d$
## 0.33.1.7.6 – Bearbeitungssperren und Entwurfs-Timeout (21.10.2026)
Private Inseratsentwuerfe erhalten eine 90-Sekunden-Lease pro Benutzer/Entwurfs-ID, serverseitig bei der Entwurfssicherung erzwungen und alle 25 Sekunden erneuert. Zweites Fenster oeffnet nur lesend. Ein abgelaufener Lock kann neu erworben werden. Revisionkonflikte verwenden SK409 statt 40001. Client bricht Entwurfssicherungsanforderungen nach 15 Sekunden ab, meldet unklaren Speicherstand und setzt nicht blind eine Revision fort. Offene Formulare bleiben bei Fehler erhalten. Keine neuen Test-UI-Funktionen. BEGRENZUNG: Die Lease erzwingt Schreibschutz der privaten Entwurfs-RPC, nicht aller direkten Live-Inserat-Tabellenupdates. Ursache fuer frueher beobachteten upstream request timeout ist noch nicht abschliessend nachgewiesen.
$d$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.7.6 – Bearbeitungssperren' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $d$
## 0.33.1.7.6 – Teststand (21.10.2026)
Statischer Patch, Browser-/Supabase-Livetest noch offen. Ausstehende Tests: paralleles Oeffnen desselben Entwurfs (B nur lesend), Freigabe beim X-Schliessen, automatischer Ablauf nach Absturz, Betriebstrennung, Timeoutfehler und Wiederherstellen. Datenbankmigration vor Frontend ausrollen, da geaenderte RPC-Signatur. Der urspruengliche upstream request timeout bleibt nicht nachweislich behoben.
$d$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.7.6 – Teststand' IN body)=0;
COMMIT;
SELECT slug,updated_at FROM sk_internal.project_doc_chapters WHERE slug IN ('concept','status') ORDER BY slug;
