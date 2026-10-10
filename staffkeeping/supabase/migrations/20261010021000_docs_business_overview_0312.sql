-- StaffKeeping 0.31.2: Admin-Betriebsliste; nur bestehende Dokumentation aktualisieren.
-- Eine Transaktion mit UPDATEs, keine separaten SELECT-Resultsets.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || '## Admin → Betriebe: Übersicht 0.31.2

Die Betriebsliste zeigt Name, Land, PLZ / Ort, Status (farbiges Symbol), Prüfstatus mit Einreichungs-/Freigabedatum soweit erfasst sowie Datum der letzten Änderung (`sk_businesses.updated_at`). Die Suche filtert die bereits geladenen Betriebe nach Name, Ort, PLZ, Land und Status. Historische Freigaben ohne `reviewed_at` zeigen ausdrücklich „Datum nicht erfasst“; es wird kein Ersatzdatum erfunden. Keine neuen Datenbankspalten; Anzeige erfolgt nur nach Admin-Zugriffsprüfung.
', updated_at=now() WHERE slug='concept' AND position('## Admin → Betriebe: Übersicht 0.31.2' in body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || '## 0.31.2 – Admin-Betriebsliste

Tabellendarstellung, farbige Statussymbole, PLZ/Ort, Prüfdatum, Änderungsdatum und clientseitige Suche implementiert. Browser-Livetest und Datumslücken bei Altbetrieben offen.
', updated_at=now() WHERE slug='status' AND position('## 0.31.2 – Admin-Betriebsliste' in body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || '## Release 0.31.2

Admin → Betriebe: durchsuchbare Betriebsübersicht; Standort, Statussymbol, deutschsprachiger Prüfstatus mit passendem Zeitstempel, letzte Änderung. Ausschliesslich Frontend-Anpassung plus Aktualisierung bestehender Dokumentation; keine Schemaänderung.
', updated_at=now() WHERE slug='history' AND position('## Release 0.31.2' in body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || '## Zu testen: 0.31.2 – Betriebsübersicht

1. Betriebsstatus „Freigeschaltet“, „Ausstehend“, „Gesperrt“ farblich und textlich korrekt.
2. Prüfstatus „Entwurf“, „Eingereicht“, „Nachbesserung“, „Freigegeben“ korrekt; fehlende historische Datumswerte sichtbar als „Datum nicht erfasst“.
3. Suche nach Betriebsname, PLZ, Ort, Land und Status; keine Treffer verständlich anzeigen.
4. `updated_at` verändert sich bei Profiländerung, Tabelle nach erneutem Aufruf aktualisiert.
5. Normale Unternehmensbenutzer können die Admin-Tabelle nicht lesen.
', updated_at=now() WHERE slug='tests' AND position('## Zu testen: 0.31.2 – Betriebsübersicht' in body)=0;
UPDATE sk_internal.help_chapters SET body=body || E'\n\n## Betriebe finden und prüfen\n\nUnter **Admin → Betriebe** lassen sich alle Betriebe nach Name, PLZ, Ort, Land und Status suchen. Die Statussymbole zeigen den Betriebsstatus; darunter steht der Prüfstatus mit Datum, soweit vorhanden. „Letzte Änderung“ gibt das Datum der letzten Änderung am Unternehmensdatensatz an. Über **Details / Prüfen** wird die vollständige Prüfung geöffnet.\n\n| Anzeige | Bedeutung |\n|---|---|\n| Grün · Freigeschaltet | Betrieb aktiv |\n| Gelb · Ausstehend | Freigabe offen |\n| Rot · Gesperrt | Zugang gesperrt |\n| Eingereicht am | Zeitpunkt der Einreichung |\n| Freigegeben am | Zeitpunkt der Freigabe, falls erfasst |\n\n![Admin-Betriebe mit Status und Suche](screenshot:admin-betriebe-uebersicht-01)\n',updated_at=now() WHERE page_key='admin-businesses' AND position('admin-betriebe-uebersicht-01' in body)=0;
COMMIT;
