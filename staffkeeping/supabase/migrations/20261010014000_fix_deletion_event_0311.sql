-- StaffKeeping 0.31.1 – permanente Korrektur des Löschereignisses und Dokumentationsabnahme.
-- Voraussetzung: 0.31-Migration bereits angewendet. Mehrere SQL-Anweisungen, eine Transaktion;
-- keine separaten SELECT-Resultsets. Bereits ausgeführter Hotfix wird idempotent nachgeführt.
BEGIN;
ALTER TABLE sk_internal.admin_events DROP CONSTRAINT IF EXISTS admin_events_kind_check;
ALTER TABLE sk_internal.admin_events ADD CONSTRAINT admin_events_kind_check
CHECK (kind IN (
 'submitted','approved','changes_requested','profile_changed','media_changed',
 'location_changed','change_requested','change_approved','change_rejected',
 'blocked','deletion_requested'
));

UPDATE sk_internal.project_doc_chapters
SET body = body || E'\n\n' || $skdoc$## 0.31.1 · Löschereignisse und Medienprüfung [SK-0311]

Die Ereignisprüfung `admin_events_kind_check` erlaubt `deletion_requested` zusätzlich zu sämtlichen bisherigen Ereignistypen. Die ursprüngliche Migration 0.31 bleibt als unveränderliche Historie erhalten; die Korrektur steht in einer eigenen Folgemigration.

Die Edge Function `sk-delete-business` entfernt Dateien aus den Buckets `sk-business-logos` und `sk-business-photos` unter dem Pfadpräfix `<Business-UUID>/`. Die bisherige Suche nach dem Firmennamen im Storage-Pfad kann UUID-basierte Medien nicht erfassen.

| Prüffall | Verlässliche Aussage |
|---|---|
| Kein Unternehmensdatensatz gefunden | Das abgefragte Unternehmen existiert in der Unternehmenstabelle nicht mehr |
| Kein Auth-Benutzer gefunden | Das abgefragte Auth-Konto existiert nicht mehr |
| Keine Datei mit Firmenname im Pfad | Nur Namenssuche negativ; kein kompletter Mediennachweis |
| Keine Datei unter bekannter Business-UUID | Medien aus den beiden bekannten Buckets für diese UUID nicht mehr vorhanden |
| Kein bekannter Business-ID-Wert verfügbar | Rückwirkender vollständiger Nachweis nicht möglich |

**Grenze:** Nicht verwendete/verwaiste UUID-Medienordner können auch aus früheren Tests stammen. Ein Prüfergebnis muss fachlich eingeordnet werden. Bei zukünftigen Löschtests die UUID vor dem Auslösen notieren; keine vollständigen Daten oder Schlüssel in Screenshots übernehmen.$skdoc$, updated_at=now()
WHERE slug='concept' AND position('[SK-0311]' in body)=0;

UPDATE sk_internal.project_doc_chapters
SET body = body || E'\n\n' || $skdoc$## 0.31.1 · Beobachteter Löschtest [SK-0311]

Testbetrieb `gastro mueller-icloud` (10.10.2026): Nutzer bestätigte Löschung in der Anwendung. Danach: 0 Treffer bei `sk_businesses`/Mitgliedschaftssuche, 0 Treffer beim Auth-E-Mail-Muster, 0 Treffer bei der Suche nach Firmenname in `storage.objects`.

| Test | Resultat |
|---|---|
| Löschaktion in der Anwendung | Vom Benutzer als erfolgreich bestätigt |
| Unternehmen / Mitgliedschaften per Namensabfrage | 0 Zeilen, bestätigt |
| Auth per E-Mail-Teilstring | 0 Zeilen, bestätigt |
| Storage per Firmenname im Dateipfad | 0 Zeilen, aber unvollständige Prüfung |
| Storage anhand gelöschter Business-UUID | Nicht rückwirkend verifiziert (UUID fehlt) |
| Löschantrag für anderen/aktiven Betrieb | Noch nicht abgenommen |
| Zugriff von unberechtigtem Zweitbetrieb | Noch nicht abgenommen |

Bei der ersten Ausführung blockierte `admin_events_kind_check` den Ereignistyp `deletion_requested`; nach einem SQL-Hotfix gelang die Löschung. Der Hotfix ist mit dieser Migration dauerhaft versioniert. Keine vollständige produktive Freigabe aus diesem Einzeltest ableiten.$skdoc$, updated_at=now()
WHERE slug='tests' AND position('[SK-0311]' in body)=0;

UPDATE sk_internal.project_doc_chapters
SET body = body || E'\n\n' || $skdoc$## 0.31.1 · Korrektur Löschprotokoll [SK-0311]

Ereignistyp `deletion_requested` dauerhaft in der Datenbankprüfung erlaubt. Erste Löschung eines Testbetriebs erfolgreich beobachtet; Unternehmens- und Auth-Datensätze per SQL negativ geprüft. Die vollständige UUID-basierte Storage-Abnahme und Berechtigungstests bleiben offen. Dokumentation und Handbuch wurden in ihren bestehenden Kapiteln nachgeführt; keine neuen Kopien im öffentlichen Repository.$skdoc$, updated_at=now()
WHERE slug='history' AND position('[SK-0311]' in body)=0;

UPDATE sk_internal.project_doc_chapters
SET body = body || E'\n\n' || $skdoc$## Stand 0.31.1 [SK-0311]

Löschprozess: Ein Testkonto wurde erfolgreich gelöscht; SQL-Korrektur gegen `admin_events_kind_check` nachgeführt. Status: **teilweise live geprüft**, noch nicht vollständig abgenommen. Offen: UUID-basierte Medienprüfung beim nächsten kontrollierten Test, Sonderfälle und Zugriffsschutz. Registrierung 2.0 und Admin-Cockpit benötigen weiter vollständige End-to-End-Abnahme.$skdoc$, updated_at=now()
WHERE slug='status' AND position('[SK-0311]' in body)=0;

UPDATE sk_internal.project_doc_chapters
SET body = body || E'\n\n' || $skdoc$## Offene Abnahmeprüfungen nach 0.31.1 [SK-0311]

- Bei nächstem Löschtest Business-UUID VORHER erfassen und NACHHER beide privaten Medien-Buckets gezielt kontrollieren.
- Zweitbetrieb und Nicht-Admin gegen Lösch-RPCs/Edge Function negativ testen.
- Fehler- und Wiederaufnahmefälle der Edge Function testen.
- Künftige produktive Inserate, Chats, Bewertungen und rechtliche Aufbewahrung vor Aktivierung in die Löschlogik aufnehmen.$skdoc$, updated_at=now()
WHERE slug='issues' AND position('[SK-0311]' in body)=0;

UPDATE sk_internal.project_doc_chapters
SET body = body || E'\n\n' || $skdoc$## Übergabe 0.31.1 [SK-0311]

SQL `20261010014000_fix_deletion_event_0311.sql` in Supabase ausführen; dann nur die geänderten Dateien über GitHub veröffentlichen. `verify-business-media-0311.sql` ist eine optionale Einzelprüfung im SQL-Editor, KEINE produktive Migration. Die bei bereits gelöschtetem Testbetrieb fehlende Business-UUID verhindert den rückwirkenden vollständigen Mediennachweis. Bestehende Kapitel bleiben führend.$skdoc$, updated_at=now()
WHERE slug='handoff' AND position('[SK-0311]' in body)=0;

UPDATE sk_internal.project_doc_chapters
SET body = body || E'\n\n' || $skdoc$## Löschabnahme [SK-0311]

Löschtests unterscheiden Unternehmensdaten, Auth-Konten und physisch gespeicherte Medien. Bei UUID-basierten Medien ist eine erfolgreiche Firmennamenssuche kein Nachweis. Vor jedem Test die Business-ID dokumentieren; Daten und Bilder nur aus den vorgesehenen Buckets entfernen; SQL-Migrationen nie nachträglich ändern.$skdoc$, updated_at=now()
WHERE slug='rules' AND position('[SK-0311]' in body)=0;

UPDATE sk_internal.help_chapters
SET body=body || E'\n\n' || $skhelp$## Löschen: Was wird geprüft? [SK-0311]

| Bereich | Nach erfolgreicher Löschung |
|---|---|
| Unternehmensprofil | Entfernt |
| Zugehöriges Benutzerkonto | Entfernt |
| Logo und Bilder | Werden aus den privaten Buckets entfernt; technische Nachkontrolle anhand der Betriebs-ID |
| Laufender Löschvorgang | Status und mögliche Fehler durch die Administration geprüft |

**Wichtig:** Eine Löschung kann nicht rückgängig gemacht werden. Vorher benötigte Informationen sichern. Bei Problemen den Administrator kontaktieren.
$skhelp$, updated_at=now()
WHERE slug='profile' AND position('[SK-0311]' in body)=0;

UPDATE sk_internal.help_chapters
SET body=body || E'\n\n' || $skhelp$## Löschung nachprüfen [SK-0311]

| Kontrolle | Empfehlung |
|---|---|
| Betrieb und Mitglieder | Keine zugehörigen Zeilen mehr |
| Auth-Konto | Kein zugehöriger Login mehr |
| Bilder | Beide Medien-Buckets mit der vorab notierten Business-UUID prüfen |
| Fehlgeschlagener Lauf | Status in Admin → Datenschutz prüfen und geregelten Wiederanlauf verwenden |

Eine Suche nach dem Firmennamen im Bildpfad allein genügt **nicht**, weil Dateien nach UUID gespeichert werden.

![Screenshot: Löschung kontrollieren](screenshot:admin-loeschkontrolle-01)$skhelp$, updated_at=now()
WHERE slug='admin-review' AND position('[SK-0311]' in body)=0;

COMMIT;
