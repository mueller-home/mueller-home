-- StaffKeeping Dokumentationsabgleich 18.10.2026 / Stand 0.33.1.6
-- NUR Dokumentation. Sechs UPDATEs innerhalb EINER Transaktion; EIN abschliessender SELECT/Resultset.
-- Additiv und wiederholbar: alte Kapitel bleiben ungekürzt; Marker verhindern Doppelanhaenge.
-- Live-Export 18.10.2026: zwoelf Projektkapitel, 18 Handbuchdatensaetze.
-- Kein Rollback durch automatisches Entfernen historischer Eintraege.
BEGIN;
DO $check$
BEGIN
 IF (SELECT count(*) FROM sk_internal.project_doc_chapters WHERE slug IN ('status','issues','tests','history','handoff','rules')) <> 6 THEN
   RAISE EXCEPTION 'Dokumentationsstruktur weicht ab: erwartete sechs Zielkapitel nicht gefunden';
 END IF;
END $check$;

UPDATE sk_internal.project_doc_chapters
SET body = body || E'\n\n' || $skdoc$## Aktueller konsolidierter Stand · 18.10.2026 · 0.33.1.6
Führend für den aktuellen Entwicklungsstand ist dieser Abschnitt; ältere versionsbezogene Einträge bleiben historische Momentaufnahmen. Nach Angaben des Betreibers live bestätigt: Registrierung, E-Mail-Bestätigung, Freigabe/Nachbesserung, automatischer Mailversand über Cron/Edge Function/Postmark, vollständige Betriebslöschung und ein gezielter direkter API-Sicherheitstest. Diese punktuelle API-Prüfung ersetzt keinen umfassenden RLS/RPC/Storage-Audit. Echte eigene Inserate und Marktplatzsuche sind an Supabase angebunden; eigene Inserate werden im Marktplatz ausgeblendet. Jeder zusätzliche Betrieb benötigt eine separate Freigabe durch Annette. Die manuelle Freigabe auf Kundenkontoebene ist vorbereitet; die Abo-/Stufe-2-Zugriffssperre ist inaktiv. Kontaktanfragen und echte Chats sind weiterhin nicht produktiv. Version 0.33.1.3: 17 von 23 Tests bestanden, 6 offen. Version 0.33.1.6: zehn Standorttests noch nicht abschliessend live bestätigt. 0.33.1.7 ist geplant, nicht implementiert oder abgenommen: zentraler Schutz ungespeicherter Änderungen, konsistentes Auto-Save und Schutz genehmigter Standortdaten.$skdoc$, updated_at = now()
WHERE slug = 'status' AND position($marker$## Aktueller konsolidierter Stand · 18.10.2026 · 0.33.1.6$marker$ IN body) = 0;

UPDATE sk_internal.project_doc_chapters
SET body = body || E'\n\n' || $skdoc$## Konsolidierte aktuelle Prioritäten · 18.10.2026
**P0 Testabschluss 0.33.1.6:** Zehn Standortprüfungen wie im Kapitel Tests & Abnahme; kein Codestatus als bestandenen Browsertest werten. **P0 0.33.1.3:** sechs verbleibende Prüfungen zu Status/Gültigkeit/Grund, Aktionsbuttons und Tooltips, manueller Stufe-2-Freigabe, Befristung, Widerruf und Koordinaten bei Adressänderung. Die inaktive Abo-Sperre als absichtlichen aktuellen Zustand prüfen, nicht aktivieren. **P0 Datenintegrität 0.33.1.7:** vor Auto-Save festlegen, ob und wie genehmigte Standortdaten von Entwürfen getrennt werden; konkurrierende Speicherpfade und parallele Sitzungen verhindern. **P1:** zentraler Dirty-State-Navigationsschutz und persistenter Speicherstatus, mit Browser-Warnung bei Reload/Schliessen, ausdrücklicher Bestätigung fachlicher Entscheidungen. **P1/P2:** Mehrbenutzerrollen je Betrieb; manuelle Kundenkonto-/Abo-Zuordnung durch Annette, kein automatischer Zusammenschluss; zweistufige Berechtigung später mit eigenen Server-Sicherheitstests; echte betriebsbezogene Anfragen/Chats. **Technische Schulden:** google.maps.Marker modernisieren; Google-Cloud-Key Referrer/API-Limits zusammen mit Annette prüfen. Ältere Aufgaben weiter historisch lesen; durch spätere Versionen erledigte Aufgaben nicht erneut als aktuell offen interpretieren.$skdoc$, updated_at = now()
WHERE slug = 'issues' AND position($marker$## Konsolidierte aktuelle Prioritäten · 18.10.2026$marker$ IN body) = 0;

UPDATE sk_internal.project_doc_chapters
SET body = body || E'\n\n' || $skdoc$## Konsolidierter offener Teststand · 18.10.2026
**Bestätigt durch Betreiber:** Registrierungs- und Genehmigungsworkflow inkl. Nachbesserung, Entscheidungsmails (Cron/Edge Function/Postmark), vollständige Betriebslöschung, punktueller direkter API-Sicherheitstest. Keine pauschale Abnahme weiterer Endpunkte daraus ableiten.

**0.33.1.3:** 17/23 bestanden; sechs verbliebene Fälle sind nach Original-Testprotokoll einzeln zuzuordnen. Themen: Freigabestatus/Gültigkeit/Grund anzeigen; Aktionen/Tooltips; manuelle Freigabe Stufe 2; Befristung; Widerruf; Koordinatenrücksetzung bei Adressänderung. Der bewusst inaktive Abo-Gate ist als Sollzustand zu prüfen. Keine einzelnen Fall-IDs oder Ergebnisse erfinden.

**0.33.1.6 Standort – zehn offene Prüfpunkte (alle Status: offen, nicht fehlgeschlagen):**
1. Gespeicherte Koordinaten im richtigen Betriebsprofil erneut laden und nach Reload anzeigen.
2. Vollständige Adresse führt zur automatischen Standortermittlung.
3. Geänderte Adresse führt kontrolliert zur Neuermittlung, ohne alte Position unbemerkt zu behalten.
4. Manuelles Marker-Verschieben bleibt bis zur Adressänderung erhalten.
5. Verschobenen Marker speichern und nach Reload mit gespeicherten Zahlen vergleichen.
6. Weiteren Betrieb mit Strasse/Hausnummer und Karte registrieren.
7. Zweiten Betrieb getrennt von Annette prüfen/freigeben; keine automatische Kundenkonto-/Abo-Verknüpfung.
8. Admin-Standortansicht zeigt gespeicherte Position bzw. eindeutig unverifizierte Vorschau.
9. Geocoding-Fehler/fehlende Koordinaten verständlich behandeln, keine falsche Standortbestätigung.
10. Fremde Betriebs-ID darf über direkten RPC/API-Zugriff nicht gelesen oder verändert werden; die Testmethode und das Ergebnis protokollieren.

**0.33.1.7 – noch nicht ausführen/als bestanden markieren:** Text/Dropdown/Untertabs/Menü/Zurück/Vorwärts/Reload/Tab-Schliessen, parallele Speichervorgänge und Serverfehler; fachliche Entscheidungen explizit bestätigen; genehmigte Standortdaten vor Entwurfsüberschreibung schützen.

Testprotokolle künftig mit Status **bestanden / offen / fehlgeschlagen / blockiert**, Datum TT.MM.JJJJ, Betrieb/Rolle, Vorgehen, Erwartung, Ist-Ergebnis und Beleg festhalten. Ein implementierter Codepfad ist kein bestandener Live-Test.$skdoc$, updated_at = now()
WHERE slug = 'tests' AND position($marker$## Konsolidierter offener Teststand · 18.10.2026$marker$ IN body) = 0;

UPDATE sk_internal.project_doc_chapters
SET body = body || E'\n\n' || $skdoc$## 0.33.1.6 · Dokumentationsabgleich 18.10.2026
Aktueller veröffentlichter Entwicklungsrelease nach Betreiberübergabe: 0.33.1.6. Mehrbetriebsverwaltung, einzelbetriebliche Freigabe, echte eigene Inserate und echte Marktplatzsuche wurden bis dahin entwickelt; Standortverwaltung zuletzt um Laden gespeicherter Koordinaten, Auto-Geocoding, Marker und zusätzliche Betriebsregistrierung erweitert. Live-Abnahme der zehn Standortprüfungen steht aus. 0.33.1.3 hat 17/23 bestandene Tests und sechs offene. 0.33.1.7 (Auto-Save/zentraler Navigationsschutz) ist nur geplant. Diese Fortschreibung ist **ausschliesslich Dokumentation**, ändert weder Fachschema noch App-Code und bestätigt keine zusätzlichen Tests.$skdoc$, updated_at = now()
WHERE slug = 'history' AND position($marker$## 0.33.1.6 · Dokumentationsabgleich 18.10.2026$marker$ IN body) = 0;

UPDATE sk_internal.project_doc_chapters
SET body = body || E'\n\n' || $skdoc$## Übergabe an Folgearbeit · 18.10.2026
Letzter erstellter Release: 0.33.1.6. Im Supabase-Liveexport vom 18.10.2026 sind zwölf zentrale Projektkapitel und achtzehn Handbuchdatensätze enthalten; die Systemkonzept-Ergänzung 0.33.1.6 ist vorhanden. Status-/Test-/Aufgabenkapitel wurden zum Teil nicht zeitgleich fortgeschrieben und erhalten mit diesem separaten, kontrollierten Dokumentationsschritt einen datierten konsolidierten Nachtrag. Nächste Reihenfolge: 1) Dokumentationsmigration kontrollieren, 2) die zehn offenen Standorttests 0.33.1.6 mit Betreiber ausführen, 3) verbleibende 0.33.1.3-Fälle prüfen, 4) Entwurfs-/Freigabelogik vor Auto-Save entscheiden, 5) erst dann 0.33.1.7 implementieren. Keine Freigabe, Abo-Zuordnung oder Stufe-2-Sperre automatisch aktivieren; Admin ohne eigenen freigegebenen Betrieb bleibt von Inseraten und Chats ausgeschlossen.$skdoc$, updated_at = now()
WHERE slug = 'handoff' AND position($marker$## Übergabe an Folgearbeit · 18.10.2026$marker$ IN body) = 0;

UPDATE sk_internal.project_doc_chapters
SET body = body || E'\n\n' || $skdoc$## Präzisierung 18.10.2026 – Navigation und Auto-Save
Bei ungespeicherten Benutzeränderungen muss vor internem Menü-/Untertab-Wechsel und Browser-Zurück/Vorwärts eine Entscheidung mit „Weiter bearbeiten“ und „Änderungen verwerfen“ angeboten werden; ein automatisches Speichern kann die Warnung erst ersetzen, wenn der Servererfolg nachweislich bestätigt ist. Bei Reload, Tab-Schliessen und externem Verlassen native beforeunload-Warnung, soweit Browser unterstützt. Auto-Save-Fehler und laufende Speicheraufträge dürfen nicht als „Gespeichert“ erscheinen. Einreichen, Genehmigen, Ablehnen, Widerrufen und Löschen bleiben explizite fachliche Aktionen. Bei freigegebenen Standortdaten darf ein Entwurf nicht unkontrolliert den bestätigten Datensatz verändern. Diese Regel beschreibt den Sollzustand für 0.33.1.7, keine Behauptung einer fertigen Implementierung.$skdoc$, updated_at = now()
WHERE slug = 'rules' AND position($marker$## Präzisierung 18.10.2026 – Navigation und Auto-Save$marker$ IN body) = 0;

COMMIT;
SELECT slug, (position('18.10.2026' IN body)>0) AS contains_20261018_update
FROM sk_internal.project_doc_chapters
WHERE slug IN ('status','issues','tests','history','handoff','rules')
ORDER BY slug;
