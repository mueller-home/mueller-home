-- StaffKeeping 0.33.1.1: profile navigation and safe business-profile separation.
-- Two UPDATE statements inside one transaction; final SELECT is the single result set.
BEGIN;
UPDATE sk_internal.project_doc_chapters
SET body = body || E'\n\n' || $note$
## StaffKeeping 0.33.1.1 – Profil und Betriebe sauber getrennt
Im Hauptmenü gibt es nur „Profil“. Untertabs: „Mein Profil“ (persönlicher Login; derzeit lesende E-Mail-Anzeige) und „Meine Betriebe“ (eigene Betriebszuordnungen, zusätzliche Betriebe beantragen). Das „Betriebsprofil“ wird aus der Betriebsliste geöffnet und enthält ausschliesslich betriebliche Stammdaten, Standort, Medien und den betriebsbezogenen Löschantrag. Die persönliche Login-E-Mail darf nicht mit der Kontaktadresse eines Betriebs verwechselt werden. Bei mehreren Betrieben wird das alte Profilformular absichtlich nicht zum Speichern angeboten, bis alle Lade- und Speicherfunktionen mit expliziter Betriebs-ID arbeiten. Keine Datenbank- oder Auth-Rollenänderung durch diesen UI-Release.
Testfälle: Hauptmenü Profil und beide Untertabs; bisheriges Einzelbetriebsprofil bleibt bearbeitbar; mehrere Betriebe werden aufgelistet, ohne falsches Profil editierbar zu machen; neuer Betrieb weiterhin einzeln freizugeben; Seiten-Refresh auf #account und #my-businesses; Admin ohne Betrieb darf keine Betriebsaktionen durchführen. Folgeschritt: explizit betriebsbezogene Profil-RPCs und Mitarbeiterrollen.
$note$, updated_at = now()
WHERE slug = 'concept' AND position('## StaffKeeping 0.33.1.1 – Profil und Betriebe sauber getrennt' IN body) = 0;

UPDATE sk_internal.help_chapters
SET body = body || E'\n\n' || $note$
## Profil, Meine Betriebe und Betriebsprofil · 0.33.1.1
Öffne im Hauptmenü „Profil“. Unter „Mein Profil“ siehst du deine persönliche Login-Adresse. Unter „Meine Betriebe“ siehst du die Betriebe, für die du berechtigt bist, und kannst „Weiteren Betrieb hinzufügen“ wählen. Ein zusätzlicher Betrieb benötigt eine eigene Freigabe von Annette. Das Betriebsprofil ist die betriebliche Stammdatenansicht. Bei nur einem Betrieb kannst du es aus der Betriebsliste öffnen. Bei mehreren Betrieben wird die bisherige, nicht eindeutig adressierte Bearbeitung aus Sicherheitsgründen vorübergehend gesperrt, bis die eindeutige Auswahl je Betriebs-ID umgesetzt ist. Kontolöschung eines Betriebs gehört zum Betriebsprofil, nicht zu „Mein Profil“.
$note$, updated_at = now()
WHERE page_key = 'my-listings' AND position('## Profil, Meine Betriebe und Betriebsprofil · 0.33.1.1' IN body) = 0;
COMMIT;
SELECT '0.33.1.1 Profildokumentation aktualisiert' AS result;
