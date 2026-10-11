-- StaffKeeping 0.33.1.2 – fix navigation of the existing single-business profile.
-- Two UPDATE statements in one transaction; one final SELECT result set.
BEGIN;
UPDATE sk_internal.project_doc_chapters
SET body = body || E'\n\n' || $note$
## StaffKeeping 0.33.1.2 – Betriebsprofil öffnen
In „Profil → Meine Betriebe“ öffnet „Betriebsprofil bearbeiten“ das bisherige Betriebsformular, sofern dem Benutzer genau ein Betrieb zugeordnet ist. Der Button verwendet eine eindeutige Betriebs-ID und zeigt bei blockierter Navigation eine Fehlermeldung statt still nichts zu tun. Bei mehreren Betrieben bleibt das alte Formular bis zur vollständig ID-gebundenen Lese-/Schreib- und Medienlogik deaktiviert. Getestet werden: Button bei genau einem Betrieb; geladene Daten; Auth-Prüfung; Navigation zurück; Mehrbetriebs-Sperre; keine Änderung fremder Betriebe. Keine Datenbankberechtigungen geändert.
$note$,updated_at=now()
WHERE slug='concept' AND position('## StaffKeeping 0.33.1.2 – Betriebsprofil öffnen' IN body)=0;
UPDATE sk_internal.help_chapters
SET body=body || E'\n\n' || $note$
## Betriebsprofil bearbeiten · 0.33.1.2
Öffne „Profil → Meine Betriebe“ und klicke beim einzigen zugeordneten Betrieb „Betriebsprofil bearbeiten“. Die Anwendung öffnet die Betriebsdaten oder zeigt bei einer fehlgeschlagenen Sitzungsprüfung eine verständliche Meldung. Bei mehreren Betrieben ist die alte Profilbearbeitung vorübergehend gesperrt, bis die einzelnen Betriebe über ihre ID sicher bearbeitet werden können.
$note$,updated_at=now()
WHERE page_key='my-listings' AND position('## Betriebsprofil bearbeiten · 0.33.1.2' IN body)=0;
COMMIT;
SELECT '0.33.1.2 Profilbutton-Dokumentation aktualisiert' AS result;
