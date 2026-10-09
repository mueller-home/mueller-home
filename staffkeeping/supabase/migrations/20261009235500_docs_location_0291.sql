-- StaffKeeping 0.29.1: nur bestehende zentrale Projektdokumentation aktualisieren.
-- Eine Transaktion, vier UPDATEs; keine separaten SELECT-Resultsets.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||$addition$

### Ergänzung 0.29.1 – Google Maps / Standort
- **Live bestätigt:** Maps JavaScript lädt nach Hard-Refresh; Geocoding im Unternehmensprofil und manuelles Verschieben des Markers funktionieren.
- **Ursache des zuvor gemeldeten InvalidKeyMapError:** Nach Hard-Refresh funktionierte die Karte; eine veraltete Browserdatei war wahrscheinlich beteiligt, aber nicht unabhängig nachgewiesen.
- Eigener Button „Position automatisch neu ermitteln“ erscheint bei manuell bestätigter Position. Zuerst Google-Abfrage, erst danach ausdrückliches Zurücksetzen und Speichern.
- Bei Geocoding-Fehler vor dem Zurücksetzen bleibt die manuelle Position bestehen. Treten Fehler **zwischen** den beiden Supabase-Schreibvorgängen auf, wird die vorherige Position bestmöglich wiederhergestellt; eine atomare Server-RPC bleibt ein möglicher späterer Härtungspunkt.
- Google Maps JavaScript lädt nun mit `loading=async`; Browser-Cache-Versionen werden releasebezogen aktualisiert.
$addition$,updated_at=now() WHERE slug='concept' AND strpos(body,'### Ergänzung 0.29.1 – Google Maps / Standort')=0;
UPDATE sk_internal.project_doc_chapters SET body=body||$addition$

## 0.29.1 – Korrekturen Standort (09./10.10.2026)
- Sichtbarer Reset-/Neuermittlungsbutton bei manuell bestätigter Position; „Marker verschieben“ dient wieder nur dem Verschieben.
- Google-SDK-Laden optimiert (`loading=async`), neue Versionsparameter gegen alte Browserdateien.
- Keine Datenbankstrukturänderung. Bestehende Standorte und Profilinformationen bleiben erhalten.
- Statisch geprüft; Reset, Persistenz nach Reload und Admin-Anzeige in der Live-Instanz erneut testen.
$addition$,updated_at=now() WHERE slug='history' AND strpos(body,'## 0.29.1 – Korrekturen Standort')=0;
UPDATE sk_internal.project_doc_chapters SET body=body||$addition$

### Teststand 0.29.1
- **Vom Anwender bestätigt:** Google Maps lädt, automatische Standortermittlung und Marker verschieben funktionieren.
- **Noch offen:** Manuelle Position speichern und nach Neuladen prüfen; „Position automatisch neu ermitteln“ testen, auch bei Google-Fehlern; Position in Admin-Betriebsdetails nach Neuladen prüfen; Zugriff eines fremden Unternehmens negativ testen.
$addition$,updated_at=now() WHERE slug='tests' AND strpos(body,'### Teststand 0.29.1')=0;
UPDATE sk_internal.project_doc_chapters SET body=body||$addition$

### 0.29.1 – Ausstehende Standort-Abnahme
- Neuermittlung nach manueller Korrektur inklusive Speichern und Reload testen.
- Fehlerfall beim Geocoding sowie Wiederherstellung einer Position nach einem RPC-Fehler gesondert prüfen.
- Fremdmandanten-Zugriff auf Standortänderung und Medien weiterhin negativ testen.
$addition$,updated_at=now() WHERE slug='issues' AND strpos(body,'### 0.29.1 – Ausstehende Standort-Abnahme')=0;
COMMIT;
