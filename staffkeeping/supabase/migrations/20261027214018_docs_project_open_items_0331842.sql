-- StaffKeeping: zentraler Projektstand und offene Aufgaben (intern, nicht Benutzerhandbuch)
-- Ergänzung zur zuletzt bereitgestellten Version 0.33.1.8.42; kein Schema-/Anwendungscode.
BEGIN;
UPDATE sk_internal.project_doc_chapters
SET body = body || E'\n\n' || $skstatus$
## Projektübergabe und offene Aufgaben – 27.10.2026
Zuletzt bereitgestellt: 0.33.1.8.42 (Profilmitgliedschaft). Installation und produktiver Retest sind noch nicht bestätigt. Bereits gemeldete Einzeltests ersetzen keinen vollständigen Regressionstest. Diese Aufgabenübersicht bleibt ausschliesslich in der zentralen internen Projektdokumentation; keine zweite externe Aufgabenliste führen.

### Unmittelbarer Retest
- 0.33.1.8.42 installieren und tatsächlichen Versionsstand kontrollieren; drei enthaltene Migrationen in Reihenfolge ausführen.
- Profil ohne manuelle Freigabe anlegen: Ursprung automatisch/manuell angelegter Altfreigaben prüfen. Historische betriebsbezogene Stufe-2-Freigaben nicht pauschal als bezahlte Profilmitgliedschaften übernehmen.
- Profil mit mehreren Betrieben, aktiver Betrieb, getrennte Betriebsprüfung und Benutzerberechtigungen testen.
- Manuelle Profilfreigabe durch Administrator erteilen, befristen, widerrufen; Adminberechtigungen prüfen.
- Mitgliedschafts-/Tarifanzeige, Tarifänderungsprotokoll und die Abwesenheit von Zahlungsabbuchung beziehungsweise Abo-Sperre prüfen.

### Priorität A – vor produktivem Zahlungsstart
- Stripe-Zugangsdaten bei Annette anfordern; Geheimnisse nur serverseitig in Supabase speichern, niemals im ZIP, Browser oder Chat.
- Stripe-Testmodus: Checkout pro Benutzerprofil, signierte Webhooks und idempotente Verarbeitung, Rechnung/Beleg, automatische Verlängerung, Zahlungsfehler, Kündigung, Tarifwechsel und Testfälle umsetzen.
- Vertragliche Konditionen von Annette/Patrick festlegen: Classic/Flex, Aufnahmegebühr, Mindestlaufzeit, Zahlungsintervall, MWST, Kündigung, Kulanz und Regeln nach Zahlungsverzug. Tarife bleiben durch berechtigte Administratoren veränderbar; bestehende Verträge nicht rückwirkend ändern.
- Serverseitige Abo-Sperren erst nach erfolgreichem Test und ausdrücklicher Freigabe aktivieren; bestehende Kunden bis dahin nicht ungewollt sperren.
- **Produktivbetrieb / Weiterentwicklung nach Go-live**: getrennte Entwicklungs-, Staging- und Produktionsumgebung; Datenbankmigrationen versioniert und möglichst rückwärtskompatibel (Expand–Migrate–Contract); richtige Reihenfolge von Schema-, Code- und Funktionsfreigaben; Backup/PITR und Wiederherstellung regelmässig testen; produktive Daten niemals mit Testdaten überschreiben; RLS- und Rollenprüfung; Monitoring, Fehlerprotokollierung, Release-Abnahme, Website-Rollback und korrigierende Folgemigrationen statt ungetestetem SQL-Rollback; Wartungsfenster und Recovery-Ziele vereinbaren. Vor Go-live mit Annette/Patrick entscheiden.

### Priorität B – noch offene Geschäftsabläufe
- Gespeicherte Suchen zweimal täglich serverseitig prüfen; E-Mail-Einwilligung, Duplikatschutz, feste Ausgangsbetriebs-Zuordnung und neue Treffer im Dashboard integrieren; Postmark/Cron und früheren HTTP-403-Fehler prüfen.
- E-Mail-Benachrichtigungen für neue Chatnachrichten optional und mit Schutz vor E-Mail-Flut.
- Dashboard: Suchtreffer, Betriebsfreigaben/Ablehnungen, Mitgliedschaft, Rechnungen, Ablauferinnerungen ergänzen.
- Vergabe aufheben / vorzeitigen Abbruch modellieren; Bewertungsbeanstandungen und Moderation durch Administration ergänzen.
- Kartenmarker bei gleicher Position gruppieren; produktive Google-Maps-Map-ID durch Annette/Patrick erstellen und DEMO_MAP_ID ablösen.

### Priorität C – Qualität und Organisation
- Administratorenverwaltung über geschützte Benutzeroberfläche ergänzen; Profil-Legacy-Doppelungen bereinigen.
- Endbenutzerhandbuch ausschliesslich workfloworientiert halten: keine Versionsnummern, Entwicklungs-/Demohinweise oder internen Kapitelcodes; doppelte Alt-Kapitel überprüfen; Screenshot-Aufträge ausführen.
- Offene Alttests zu Betriebsanträgen, Löschanträgen und Auto-Save-Timeout sowie vollständige Regression von Inseraten, Vergaben, Chats, Abschlüssen und Bewertungen nachholen.
- Serverseitige Negativtests für fremde Betriebs-/Entwurfs-IDs, RPC, RLS, Rollenwechsel, Datenänderung und später Stripe-Webhooks.
- Sichtbare Texte vollständig in Deutsch (Schweiz) überprüfen.
$skstatus$, updated_at=now()
WHERE slug='status'
  AND position('## Projektübergabe und offene Aufgaben – 27.10.2026' IN body)=0;

UPDATE sk_internal.project_doc_chapters
SET body = body || E'\n\n' || $skconcept$
## Verbindliche Architektur- und Dokumentationsregeln (Bestätigung 27.10.2026)
Mitgliedschaft gehört zum Benutzerprofil (auth.users.id), nicht zum Betrieb. Betriebsfreigaben sind unabhängig und benötigen Genehmigung; bei eigenständiger Mitgliedschaft eines Betriebs wird ein zusätzliches Profil benötigt. Die Abo-Sperre bleibt bis zur freigegebenen Stripe-Integration ausgeschaltet. Aktiver Betrieb ist Arbeitskontext, keine Berechtigung; Betriebswahl nur bei mehreren freigegebenen Betrieben sichtbar. Gespeicherte Umkreissuchen behalten ihren Ausgangsbetrieb.
Vergebene und abgeschlossene Inserate sind schreibgeschützt; Inserate mit Chatverläufen werden statt endgültigem Löschen deaktiviert und Chats archiviert. Vergabe, beidseitiger Abschluss und Bewertung sind getrennte Vorgänge. Mitgliedschaft, E-Mail-Automation und Go-live-Prozesse nicht als produktiv abgenommen bezeichnen, solange Tests fehlen.
Dokumentations-Single-Source-of-Truth: offene Aufgaben, Entscheidungen, Status und Übergaben gehören in sk_internal.project_doc_chapters; Benutzerhandbuch bleibt getrennt und erklärt ausschliesslich Endbenutzer-Workflows. Keine externen parallelen Aufgabenlisten. Jede SQL-Migration im Update-ZIP unter staffkeeping/supabase/migrations/ mit tatsächlichem Erstellungszeitstempel Europe/Zurich; bereits ausgeführte Migrationen nicht nachträglich ändern.
$skconcept$, updated_at=now()
WHERE slug='concept'
  AND position('## Verbindliche Architektur- und Dokumentationsregeln (Bestätigung 27.10.2026)' IN body)=0;
COMMIT;
