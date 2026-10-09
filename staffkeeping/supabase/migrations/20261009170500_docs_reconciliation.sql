-- StaffKeeping 0.27.1 – Abgleich Originalkonzept v2.2 in bestehender EINZIGER Projektdoku.
-- Genau eine Transaktion; zwei UPDATE-Anweisungen; KEINE SELECT-Resultsets.
-- Setzt 20261009164500_admin_project_docs.sql (0.27) voraus.
-- Keine Duplikate: marker verhindert erneutes Anhaengen.
BEGIN;
DO $migration$
DECLARE
  v_missing text[];
BEGIN
  SELECT array_agg(req.slug) INTO v_missing
    FROM (VALUES ('concept'), ('issues')) AS req(slug)
    WHERE NOT EXISTS (SELECT 1 FROM sk_internal.project_doc_chapters c WHERE c.slug=req.slug);
  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION '0.27 nicht vollständig installiert; fehlende Kapitel: %', v_missing;
  END IF;
END;
$migration$;
UPDATE sk_internal.project_doc_chapters SET body = body || '

## Quellenabgleich Original-Migrationskonzept v2.2 (09.10.2026; Release 0.27.1)
Diese Übersicht ist eine Bestandsaufnahme der Themen des unveränderten Originalkonzepts, keine pauschale Übernahme früherer technischer Annahmen. **Führend sind die aktuellen Kapitel dieser Admin-Dokumentation.**
- Original Kapitel 01–04: Ausgangslage, Supabase-/GitHub-Zielarchitektur, Tabellenmodell (Betriebe, Inserate, Chats, Nachrichten, Bewertungen, Merkliste, Abonnements) und RLS. Aktuelle Umsetzung und Differenzen im Kapitel Auth & Datenmodell; nicht implementierte Teile bleiben Anforderungen.
- Original 05–07: Registrierung, Workflows/Edge Functions und Postmark. Aktuell: Registrierung, E-Mail-Bestätigung, Admin-Freigabe und Passwort-Reset implementiert; übrige Nachrichten-Workflows separat testen/umsetzen.
- Original 08: Google-Geocoding, Kartenanzeige und geografische Umkreissuche sind konzeptionelle Anforderungen; keine bestätigte Live-Implementierung.
- Original 09: Stripe-Abrechnung ausdrücklich zurückgestellt; der Originaltext beschreibt einen Entwurf, keinen Ist-Zustand.
- Original 10 und 13: Hosting, Besitzübergabe an Annette, Design-System und zentrale CSS-Regeln. Gültige Festlegungen in den aktuellen Architektur-/Regel-/Übergabekapiteln.
- Original 11: Bubble-Datenübernahme ist historischer Plan; neu beschlossen: keine Bubble-Produktivdatenmigration, Testdaten neu aufbauen.
- Original 12: historischer Phasenplan; tatsächliche Entwicklung nach aktuellem Status und Aufgaben.
- Original MASKE-Kapitel: Login/Marktplatz, Profil, eigene Inserate, Inseratdetails samt Disclaimer, Nachrichten, Bewertungen und Admin (Betriebe, Inserate, Impact). Bei jedem Modul gegen fachliche Abläufe abgleichen; derzeit sind mehrere Masken nur Design-Demos.
- Original 21: technische Diskrepanzen und ungeklärte Fachfragen – einzeln in **Aufgaben & offene Fragen** geprüft, nicht ungeprüft als neue Spezifikation übernommen.
Historische Quelle: privater Bucket `sk-project-docs`, unverändertes Original v2.2, von Admin → Projektdoku aus aufrufbar. In dieser Arbeitsdokumentation nur Abgleich und verbindliche Entscheidungen; kein zweites HTML/Markdown als lebende Fassung.
', updated_at=now() WHERE slug='concept' AND position('## Quellenabgleich Original-Migrationskonzept v2.2' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body = body || '

## Offene Original-Fragen / Abgleich v2.2 (0.27.1)
**Offen – fachlich verifizieren, nicht als implementiert markieren:** Inserat-Statuswerte (inkl. Gesperrt), Conversation-Felder (initiator/recipient versus participant1/participant2), Nachrichtenfeld (body/content) und ungelesene Nachrichten, Kommentar-Zeichenlimit für Bewertungen (300 im Original-Handbuch), Zeitpunkt der Bewertungsfreigabe, Titel-Feld bei Inseraten, BusinessImage-Datenstruktur, Popup- versus Seitenlösung bei Inseratserstellung, Abo-Anzeige und noch ausstehende Stripe-Geschäftsregeln.
**Offen – Geschäftsentscheidungen:** Kulanzfrist bei Zahlungsausfall (7 Tage im Original nur provisorisch), Verlängerung des Classic-Abos, CHF/EUR, Mehrsprachigkeit, Freigabedauer, endgültige CI/Logo/Schrift und Annette-Freigabe der Navigation.
**Noch nicht umgesetzt/live zu verifizieren:** Geocoding/Google Maps/Umkreissuche, Persistenz Inserate/Messaging/Reviews, Disclaimer, E-Mail-Benachrichtigungen, Live-Impact-Kennzahlen und Stripe. Historische Bubble-Datenübernahme dagegen **bewusst verworfen**; kein Migrationsauftrag.
**UI-Fix 0.27.1 implementiert, Browser-Test offen:** Projektdoku nur als Admin-Untertab; Impact zeigt dieselben vier Admin-Tabs; Datei-Input überdeckt Schliessen nicht; Hover/Fokus und Medien-Uploads live prüfen.
**Öffentliche Alt-Dokumente:** `staffkeeping/docs/*.md` und gegebenenfalls `README.md` können auf GitHub Pages öffentlich erreichbar sein. Nach bestätigtem DB-Import und gesicherter Quelle über das beigefügte Cleanup-Skript aus Git entfernen. Bis dahin ist die öffentliche Bereinigung ausdrücklich **nicht abgeschlossen**.
', updated_at=now() WHERE slug='issues' AND position('## Offene Original-Fragen / Abgleich v2.2' IN body)=0;
COMMIT;
