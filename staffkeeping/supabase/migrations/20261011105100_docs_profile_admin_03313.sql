-- StaffKeeping 0.33.1.3 – bestehende zentrale Dokumentation und Handbuch ergänzen.
-- ZWEI UPDATE-Anweisungen in EINER Transaktion, abschliessend EIN Kontroll-SELECT.
-- Supabase zeigt je nach Ansicht nur das letzte Resultset deutlich an.
BEGIN;
UPDATE sk_internal.project_doc_chapters
SET body=body || E'\n\n' || $note$
## StaffKeeping 0.33.1.3 – Betriebsbearbeitung und kompakte Administration
Ist-Zustand nach Umsetzung (Live-Test noch offen): Profil → Mein Profil enthält persönlichen Zugang; Profil → Meine Betriebe zeigt je Betrieb zwei getrennte Statusangaben auf Deutsch und öffnet über „Betriebsprofil bearbeiten“ eine eindeutig nach Betriebs-ID gebundene Maske. Freigegebene Betriebe: branchenspezifische und Kontakt-/Adress-Stammdaten können durch berechtigte Owner geändert werden; Firmenname, UID und Land bleiben geschützt und müssen über den bestehenden Änderungsprüfungsprozess bearbeitet werden. Bei zur Nachbesserung zurückgegebenen Zusatzbetrieben sind alle notwendigen Standort- und Stammdaten zugänglich; erneutes Einreichen setzt nur den ausgewählten Betrieb auf submitted und erzeugt ein neues Admin-Ereignis. Während submitted ist die Bearbeitung gesperrt. Bei Änderungen an der geographischen Adresse werden die bisherigen Standortkoordinaten ungültig gesetzt und müssen neu ermittelt werden. Der eigene Betrieb wird immer serverseitig über business_id + owner-Membership + bestätigtes auth-Konto geprüft. Admin → Betriebe: manuelle Kundenkonto-Stufe-2-Freigaben erscheinen in einer kompakten Tabelle mit Konto, Status, Gültigkeit, Grund und Aktionen. Admin-Privilegien bleiben von Betriebsprivilegien getrennt; Stufe-2-Sperre noch nicht aktiviert.
Zu testen: (1) Profile beider eigener Betriebe eindeutig laden, (2) freigegebenes Profil ändern und Reload, (3) bei Nachbesserung Adresse/PLZ/Ort korrigieren und wieder einreichen, (4) submitted sperrt Bearbeitung, (5) keine fremden Änderungen über RPC, (6) Koordinaten nach Adressänderung zurücksetzen, (7) Statusübersetzungen und Tabellenmobilansicht, (8) befristete manuelle Freigaben und Widerruf unverändert, (9) Abo-Sperre bleibt inaktiv. Änderungen sind bis zum Browser- und Supabase-Livetest als implementiert, nicht als bestanden eingestuft.
$note$,updated_at=now()
WHERE slug='concept' AND position('## StaffKeeping 0.33.1.3 – Betriebsbearbeitung und kompakte Administration' IN body)=0;
UPDATE sk_internal.help_chapters
SET body=body || E'\n\n' || $note$
## Meine Betriebe und Kundenkonten · 0.33.1.3
Unter Profil → Meine Betriebe das gewünschte Betriebsprofil öffnen. Die Bearbeitung ist an die Betriebs-ID gebunden. Bei Nachbesserungsanforderungen von Annette lassen sich nun auch PLZ, Ort, Strasse, Hausnummer, Land und weitere Stammdaten korrigieren und erneut einreichen. Während der Prüfung ist das Profil gesperrt. Bereits freigegebene Betriebe können übliche Kontakt- und Standortangaben aktualisieren; geschützte Identitätsangaben bedürfen weiterhin einer separaten Prüfung. Die Statusanzeigen sind deutsch. Die Adminkundenkonten erscheinen in einer kompakten Tabelle; blaue Bearbeitungs- und rote Widerrufsaktion zeigen beim Mouseover einen Hilfetext. Die manuelle Stufe-2-Freigabe gilt noch nicht als aktive Abo-Sperre. Screenshot-Platzhalter: ![Betriebsprofil bearbeiten](screenshot:profil-betrieb-bearbeiten-03313) ![Kundenkonten kompakt](screenshot:admin-kundenkonten-tabelle-03313)
$note$,updated_at=now()
WHERE page_key='my-listings' AND position('## Meine Betriebe und Kundenkonten · 0.33.1.3' IN body)=0;
COMMIT;
SELECT '0.33.1.3 Dokumentations- und Handbuchergänzung verarbeitet' AS result;
