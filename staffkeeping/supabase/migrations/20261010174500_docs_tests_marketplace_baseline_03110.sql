-- StaffKeeping 0.31.10: ONLY update existing central project chapters and existing help chapters.
-- 9 UPDATE statements in one transaction; final SELECT reports matching chapter counts.
-- No schema, RLS, business, authentication, listing or message changes.
BEGIN;

UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $d$## Verifizierter Teststand 10.10.2026 (StaffKeeping 0.31.9)

- Registrierung inklusive E-Mail-Bestätigung sowie vollständiger Ablauf mit Nachbesserung, erneuter Einreichung und Genehmigung: vom Betreiber mehrfach erfolgreich getestet.
- Deutsche Supabase-Auth-Registrierungs-E-Mail nach Vorlagenanpassung beim getesteten iCloud-Empfänger im Posteingang; zuvor englische Standardvorlage im Spam. Keine allgemeine Zustellgarantie.
- Genehmigungs- und Nachbesserungs-Mail: über Cron / Edge Function / Postmark verarbeitet, in der Outbox jeweils `sent`, `attempts=1`, beim Testempfänger im Posteingang angekommen. Cron-403 wurde als `token_mismatch` diagnostiziert und nach Angleichung der beiden Cron-Secrets behoben.
- Vollständige Betriebslöschung inkl. Erkennung einer bereits geöffneten Sitzung: vom Betreiber erfolgreich getestet.
- Zusätzlicher Alt-JWT-Test: Die REST-GET-Abfrage auf `sk_business_members` gab vor der vollständigen Löschung genau die eigene Mitgliedschaft zurück, unmittelbar danach mit unverändertem JWT `[]`. RLS auf `sk_businesses` und `sk_business_members` aktiv; beide SELECT-Policies wurden eingesehen. Keine verwaisten Mitgliedschaften in den zum Testzeitpunkt geprüften Tabellen. **Dies belegt nur den getesteten REST-Endpunkt und ersetzt kein Audit sämtlicher RPCs, Storage-Policies und Funktionen.**
$d$, updated_at=now() WHERE slug='tests' AND position('## Verifizierter Teststand 10.10.2026 (StaffKeeping 0.31.9)' in body)=0;

UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $d$## Marktplatz – geprüfter Ist-Zustand (Codebasis 0.31.9)

**Hinweis:** Die registrierungsbezogene Supabase-Infrastruktur ist real; der Inserate-/Kontakt-Bereich ist weiterhin eine UI-Demo. Nicht als produktiv behaupten.

**Inserat erstellen:** Formular für Typ, Kategorie, Titel, Beschreibung, Zeitraum, Rahmenbedingungen, Unterkunft und Sprachen vorhanden. `save-demo-listing` speichert im Array `ownListings` im Browser-Arbeitsspeicher. Ort wird als `city: 'Demo-Ort'` fest gesetzt; die Beschreibung, Rahmenbedingungen, Unterkunft und Sprachen werden nicht vollständig in den Datensatz übernommen. Kein Insert in eine Inserats-Tabelle. Nach Neuladen nicht dauerhaft vorhanden. Bearbeiten, Aktiv/Inaktiv, Vergeben und Löschen ändern ausschliesslich das lokale Array.

**Inserate suchen:** Vier fest hinterlegte Datensätze im Array `listings`. Funktionsfähige clientseitige Filter nach Suchtext, Typ, Branche, Unterkunft und einem vereinfachten Startdatum; Merkliste ebenfalls nur im Arbeitsspeicher. Filter «Umkreis» ist visuell vorhanden, wird von der Filterfunktion nicht ausgewertet. Die Kartenansicht ist keine produktive Inserat-Geosuche. Echte von Betrieben erstellte Inserate gelangen nicht in die Suchliste.

**Auf Inserat antworten / Nachrichten:** Detailansicht und Disclaimer-Checkbox sind vorhanden. «Kontakt aufnehmen» setzt den aktiven Chat auf den ersten Demo-Eintrag und öffnet die Chat-Oberfläche, ohne einen betriebsspezifischen Kontakt anzulegen. Vorbelegte Beispiel-Konversationen (`chats`); Texteingaben nur im Arbeitsspeicher, keine dauerhafte Datenbank-Nachricht, keine Benachrichtigung und keine tatsächliche Gegenseite.

**Admin → Inserate:** Filter und Statuswechsel nur für Demo-Datensätze; dauerhafte Moderation noch nicht vorhanden.

**Nächste fachliche Reihenfolge:** (1) echtes Inserats-Datenmodell mit RLS, Betriebseigentum, Ort aus Betriebsprofil und optional abweichendem Einsatzort; (2) Erstellen/Bearbeiten/Löschen und Statuswechsel mit Supabase-Persistenz; (3) Suche/Filter/Detail für reale freigegebene Inserate; (4) Kontaktanfrage/Antwort mit zwei Betrieben, RLS und persistenter Konversation; (5) End-to-End-Test mit zwei freigegebenen Betrieben. Öffentliche Adressanzeige nur nach Datenschutzregeln.
$d$,updated_at=now() WHERE slug='concept' AND position('## Marktplatz – geprüfter Ist-Zustand (Codebasis 0.31.9)' in body)=0;

UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $d$## Meilenstein 10.10.2026 – Registrierung abgenommen, Marktplatz noch Demo

Mehrfach erfolgreiche Registrierung/Review/Nachbesserung/Genehmigung, Mailzustellung und vollständige Betriebslöschung inkl. UI-Sitzungsprüfung bestätigt. Alt-JWT-GET auf Mitgliedschaft nach Löschung ergab `[]` (punktueller Nachweis, kein vollständiger Endpunkt-Audit). Nächste Hauptphase: reale Inserate, Suche und Antworten; vorhandene Marktplatz-UI verwendet derzeit lokale Demo-Arrays. Kein produktives Inserats-Backend aus dieser Codebasis nachgewiesen.
$d$,updated_at=now() WHERE slug='status' AND position('## Meilenstein 10.10.2026 – Registrierung abgenommen, Marktplatz noch Demo' in body)=0;

UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $d$## 0.31.10 – Dokumentationsabgleich (10.10.2026)

Dokumentations-Update ohne Laufzeitänderung. Verifizierte Registrierungstests, Postmark-/Cron-Abnahme, Betriebslöschung und punktuellen JWT/RLS-Test erfasst; Marktplatz-Ist-Zustand (Inserate, Suche, Antworten) gegenüber Demo-Code offen ausgewiesen.
$d$,updated_at=now() WHERE slug='history' AND position('## 0.31.10 – Dokumentationsabgleich (10.10.2026)' in body)=0;

UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $d$## Marktplatz Phase 0.32 – priorisierte Aufgaben

P1: Persistente Inserate inkl. Standort, Eigentümerschaft, Prüfung und RLS; Demo-Daten nicht als echte Datensätze präsentieren. P2: Reale Suche und Filter nur nach sichtbaren Inseraten. P3: Antworten / Anfragen und Nachrichten zwischen realen Betrieben persistent, mit Berechtigungen und nachvollziehbaren Statuswechseln. P4: Prüfen aller serverseitigen RPC-/Storage-/JWT-Pfade. P5: Google Maps `google.maps.Marker` auf unterstützte API umstellen. Jede Phase mit Zwei-Betriebe-Tests und Dokumentationspflege.
$d$,updated_at=now() WHERE slug='issues' AND position('## Marktplatz Phase 0.32 – priorisierte Aufgaben' in body)=0;

UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $d$## Zu testen – Marktplatz mit echten Betrieben

- Betrieb A erstellt Personalgesuch, Ort entspricht dem Profil, nach Neuladen und in frischer Sitzung sichtbar.
- Betrieb B findet es über Suche/Filter/Detail; Betrieb A sieht eigene Änderungen; unberechtigte Benutzer können nichts ändern.
- Betrieb B antwortet; nur die beiden berechtigten Betriebe sehen dieselbe persistente Konversation; Nachrichten bleiben nach Reload erhalten.
- Schliessen, deaktivieren, löschen, moderieren, Löschung eines Betriebs und Freigaben über API/RLS testen.
- Demo-Daten dürfen weder als echte Inserate erscheinen noch als echte Nachrichten interpretiert werden.
**Stand 0.31.9:** Diese Marktplatz-Tests können noch nicht als bestanden gelten.
$d$,updated_at=now() WHERE slug='tests' AND position('## Zu testen – Marktplatz mit echten Betrieben' in body)=0;

UPDATE sk_internal.help_chapters SET body=body || E'\n\n' || $h$## Aktueller Funktionsstand: Inserate erstellen

Das Formular ist in Version 0.31.9 ein Prototyp. Ein Klick auf «Demo-Inserat übernehmen» speichert nur temporär im geöffneten Browser; nach Neuladen ist der Eintrag weg. Der Ort «Demo-Ort» ist fest hinterlegt. Noch keine echte Veröffentlichung im Marktplatz. Die produktive Funktion folgt in der Marktplatzphase 0.32.

![Screenshot: Formular Neues Inserat](screenshot:marketplace-inserat-erstellen-032)
$h$,updated_at=now() WHERE page_key IN ('my-listings') AND position('## Aktueller Funktionsstand: Inserate erstellen' in body)=0;

UPDATE sk_internal.help_chapters SET body=body || E'\n\n' || $h$## Aktueller Funktionsstand: Inserate suchen

Die Suchergebnisse basieren in Version 0.31.9 auf vier Beispieldatensätzen. Text-, Typ-, Branchen-, Unterkunfts- und Datumsfilter demonstrieren die Bedienung. Die Umkreisauswahl filtert noch keine realen Inserate; neue Inserate anderer Betriebe werden hier noch nicht geladen. Die Merkliste ist nicht dauerhaft gespeichert.

![Screenshot: Marktplatzsuche](screenshot:marketplace-suchen-032)
$h$,updated_at=now() WHERE page_key IN ('market') AND position('## Aktueller Funktionsstand: Inserate suchen' in body)=0;

UPDATE sk_internal.help_chapters SET body=body || E'\n\n' || $h$## Aktueller Funktionsstand: Auf Inserat antworten

Die Schaltfläche «Kontakt aufnehmen» führt nach Bestätigung des Hinweises derzeit zu einer Beispiel-Konversation, nicht zu einer Anfrage beim Inserateigentümer. Im Chat eingegebene Nachrichten werden nicht dauerhaft gespeichert oder an einen anderen Betrieb zugestellt. Für echte Anfragen erst die Marktplatzphase 0.32 abwarten.

![Screenshot: Kontaktaufnahme und Nachrichten](screenshot:marketplace-antwort-032)
$h$,updated_at=now() WHERE page_key IN ('detail','messages') AND position('## Aktueller Funktionsstand: Auf Inserat antworten' in body)=0;

COMMIT;

-- Read-only verification: number of existing matching documentation/help chapters.
SELECT
 (SELECT count(*) FROM sk_internal.project_doc_chapters WHERE slug IN ('concept','status','history','issues','tests')) AS projektkapitel,
 (SELECT count(*) FROM sk_internal.help_chapters WHERE page_key IN ('my-listings','market','detail','messages')) AS handbuchkapitel;
