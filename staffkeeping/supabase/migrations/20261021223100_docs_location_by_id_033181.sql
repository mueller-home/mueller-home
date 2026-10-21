-- Zwei UPDATE-Anweisungen, EIN abschliessender Kontroll-SELECT.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET
 body=body||E'\n\n'||$d$
## 0.33.1.8.1 – Legacy-Standortabsicherung (21.10.2026)
Die alte Kartenansicht des Einzelbetriebsprofils verwendet neu sk_set_business_location_by_id(p_business_id, p_latitude, p_longitude, p_source, p_address_key). Berechtigung wird pro konkretem Betrieb serverseitig geprueft (auth.uid, owner, bestaetigte Mail, editierbarer Status); Adressschluessel und Koordinaten werden validiert. Die alte Signatur sk_set_my_business_location bleibt als Kompatibilitaets-Wrapper bestehen, verweigert nun jedoch bei mehreren Owner-Betrieben jede mehrdeutige Standort-Speicherung und delegiert nur bei genau einem Betrieb an die neue RPC. Keine Aenderungen an aktuellen Standorten oder Inseraten. Das Legacy-Profil selbst fuehrt weiterhin Live-Auto-Save ueber alte RPCs durch und wird hier bewusst NICHT umgebaut, da Einreichung/Medien/Rechtsaenderungen noch davon abhaengen. Als Folgearbeit braucht es die betriebs-ID-basierte Vereinheitlichung aller alten Profil-RPCs und eine sichere Ablösung der Live-Auto-Save-Oberflaeche. Regressionstest ausstehend.
$d$,updated_at=now()
WHERE slug='concept' AND position('## 0.33.1.8.1 – Legacy-Standortabsicherung' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET
 body=body||E'\n\n'||$d$
## 0.33.1.8.1 – Status
Vorversion 0.33.1.8: Anwender meldete 6/6 Regressionstests erfolgreich, einschliesslich beider SQL-Migrationen und privatem Inseratsentwurf. Dieser Patch adressiert nur den verbliebenen mehrdeutigen Standort-Frontendpfad durch neue betriebs-ID-basierte RPC. Legacy-Funktionen sk_update_my_business_profile, sk_update_my_registration_legal, sk_submit_my_business und sk_get_my_business_profile sind noch in Gebrauch und duerfen nicht unkontrolliert entfernt werden. Legacy-Standort-RPC als gegen mehrdeutige Updates abgesicherter Wrapper verfuegbar. SQL und Browser-Retest 0.33.1.8.1 ausstehend.
$d$,updated_at=now()
WHERE slug='status' AND position('## 0.33.1.8.1 – Status' IN body)=0;
COMMIT;
SELECT slug,updated_at FROM sk_internal.project_doc_chapters WHERE slug IN ('concept','status') ORDER BY slug;
