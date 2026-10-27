-- Benutzerhandbuch: nur redaktionelle Workflow-Kapitel veröffentlichen.
-- Zeitstempel der Datei: 27.10.2026 21:16:28 CET (Europe/Zurich).
-- Bestehende ältere Kapitel werden auf Entwurf gesetzt, NICHT gelöscht.
-- Administrations-Hilfekapitel bleiben unangetastet.
BEGIN;

INSERT INTO sk_internal.help_chapters (slug,title,body,section,page_key,audience,status,position) VALUES ($flow_0$sk-guide-start$flow_0$,$flow_0$Registrieren und anmelden$flow_0$,$flow_0$# Wie registriere ich mich und melde mich an?

1. Öffne StaffKeeping und wähle die Registrierung.
2. Gib deine persönlichen Angaben und deine E-Mail-Adresse ein und lege dein Passwort fest.
3. Schliess die Registrierung ab und bestätige deine E-Mail-Adresse, wenn du dazu aufgefordert wirst.
4. Melde dich mit deinen Zugangsdaten an.
5. Erfasse anschliessend deinen ersten Betrieb und reiche ihn zur Freigabe ein.

Nach der Anmeldung führt dich «Meine Übersicht» zu deinen wichtigsten Aufgaben. Über dein Profil verwaltest du deine persönlichen Angaben. Wenn du für mehrere Betriebe tätig bist, nutzt du weiterhin dasselbe Benutzerkonto.

![registrierung 01](screenshot:registrierung-01)
![dashboard uebersicht 01](screenshot:dashboard-uebersicht-01)$flow_0$,$flow_0$Einstieg$flow_0$,$flow_0$dashboard$flow_0$,'business','published',10) ON CONFLICT (slug) DO UPDATE SET title=EXCLUDED.title,body=EXCLUDED.body,section=EXCLUDED.section,page_key=EXCLUDED.page_key,audience=EXCLUDED.audience,status=EXCLUDED.status,position=EXCLUDED.position,updated_at=now();

INSERT INTO sk_internal.help_chapters (slug,title,body,section,page_key,audience,status,position) VALUES ($flow_1$sk-guide-businesses$flow_1$,$flow_1$Einen Betrieb erfassen und freigeben lassen$flow_1$,$flow_1$# Wie erfasse ich meinen Betrieb?

1. Öffne «Meine Betriebe» und beginne die Erfassung eines neuen Betriebs.
2. Trage Betriebsname, Kontakt- und Adressangaben ein.
3. Prüfe den Standort auf der Karte. Falls erforderlich, setze den Marker an die richtige Position und bestätige ihn.
4. Wenn du noch nicht alle Angaben hast, wähle «Entwurf speichern». Über «Entwurf fortsetzen» kannst du später weiterarbeiten.
5. Kontrolliere die vollständigen Angaben und wähle «Betrieb zur Prüfung erfassen».
6. Verfolge den Genehmigungsstatus unter «Meine Betriebe». Nach der Freigabe kannst du den Betrieb für deine Aktivitäten verwenden.

Jeder Betrieb wird einzeln geprüft. Die Freigabe eines Betriebs gilt nicht automatisch für andere Betriebe desselben Benutzers.

**Mit mehreren Betrieben arbeiten:** Wenn du mehrere freigegebene Betriebe hast, wähle den «Aktiven Betrieb» im Header. Er dient unter anderem als Ausgangspunkt der Umkreissuche und wird bei neuen Inseraten und Kontaktaufnahmen vorausgewählt. Bei genau einem freigegebenen Betrieb erfolgt die Auswahl automatisch.

![meine betriebe 01](screenshot:meine-betriebe-01)
![aktiver betrieb 01](screenshot:aktiver-betrieb-01)$flow_1$,$flow_1$Erste Schritte$flow_1$,$flow_1$my-businesses$flow_1$,'business','published',20) ON CONFLICT (slug) DO UPDATE SET title=EXCLUDED.title,body=EXCLUDED.body,section=EXCLUDED.section,page_key=EXCLUDED.page_key,audience=EXCLUDED.audience,status=EXCLUDED.status,position=EXCLUDED.position,updated_at=now();

INSERT INTO sk_internal.help_chapters (slug,title,body,section,page_key,audience,status,position) VALUES ($flow_2$sk-guide-create-listing$flow_2$,$flow_2$Ein Inserat erstellen und veröffentlichen$flow_2$,$flow_2$# Wie erstelle ich ein Inserat?

1. Stelle sicher, dass dein Betrieb freigegeben ist. Bei mehreren Betrieben wählst du zuerst den passenden aktiven Betrieb.
2. Öffne «Meine Inserate» und beginne die Erfassung eines neuen Inserats.
3. Wähle, ob du Personal suchst oder Personal anbietest, und ergänze Titel, Kategorie und Beschreibung.
4. Gib den Zeitraum sowie die zutreffenden Rahmenbedingungen ein, beispielsweise die Unterkunft.
5. Kontrolliere alle Angaben. Speichere einen privaten Entwurf, wenn du später weiterarbeiten möchtest.
6. Reiche das vollständige Inserat zur Veröffentlichung ein beziehungsweise veröffentliche es über die dafür vorgesehene Aktion.
7. Prüfe unter «Meine Inserate», ob das Inserat mit dem richtigen Status erscheint.

Ein Inserat bleibt deinem ausgewählten Betrieb zugeordnet. Vor einer Vergabe kannst du es im Rahmen der angebotenen Aktionen bearbeiten oder inaktiv setzen. Sobald es vergeben oder die Zusammenarbeit abgeschlossen ist, sind seine Inhalte schreibgeschützt.

![inserat erfassen 01](screenshot:inserat-erfassen-01)
![meine inserate 01](screenshot:meine-inserate-01)$flow_2$,$flow_2$Inserate$flow_2$,$flow_2$my-listings$flow_2$,'business','published',30) ON CONFLICT (slug) DO UPDATE SET title=EXCLUDED.title,body=EXCLUDED.body,section=EXCLUDED.section,page_key=EXCLUDED.page_key,audience=EXCLUDED.audience,status=EXCLUDED.status,position=EXCLUDED.position,updated_at=now();

INSERT INTO sk_internal.help_chapters (slug,title,body,section,page_key,audience,status,position) VALUES ($flow_3$sk-guide-market$flow_3$,$flow_3$Passende Inserate finden$flow_3$,$flow_3$# Wie finde ich ein passendes Inserat?

1. Öffne «Marktplatz».
2. Suche nach einem Stichwort oder grenze die Ergebnisse nach Inserattyp, Kategorie, Datum und Unterkunft ein.
3. Für eine Umkreissuche wählst du den passenden aktiven Betrieb. Dessen Standort ist der Ausgangspunkt für den Radius.
4. Wechsle zwischen «Liste» und «Karte», um die Ergebnisse zu vergleichen.
5. Öffne ein Inserat, um Beschreibung, Zeitraum und weitere Informationen anzusehen.
6. Wenn das Angebot zu deinem Bedarf passt, nimm über «Kontakt aufnehmen» Verbindung auf.

Die Kartenmarker zeigen ungefähre Positionen. Inserate ohne bestätigten Standort findest du weiterhin in der Listenansicht.

![marktplatz liste 01](screenshot:marktplatz-liste-01)
![marktplatz karte 01](screenshot:marktplatz-karte-01)$flow_3$,$flow_3$Marktplatz$flow_3$,$flow_3$market$flow_3$,'business','published',40) ON CONFLICT (slug) DO UPDATE SET title=EXCLUDED.title,body=EXCLUDED.body,section=EXCLUDED.section,page_key=EXCLUDED.page_key,audience=EXCLUDED.audience,status=EXCLUDED.status,position=EXCLUDED.position,updated_at=now();

INSERT INTO sk_internal.help_chapters (slug,title,body,section,page_key,audience,status,position) VALUES ($flow_4$sk-guide-searches$flow_4$,$flow_4$Eine Suche speichern und Treffer verfolgen$flow_4$,$flow_4$# Wie speichere ich eine Suche?

1. Stelle im Marktplatz die Filter so ein, wie du sie künftig wiederverwenden möchtest.
2. Wähle «Suche speichern» und vergib einen aussagekräftigen Namen.
3. Entscheide, ob du bei neuen passenden Inseraten per E-Mail benachrichtigt werden möchtest.
4. Öffne eine gespeicherte Suche, um dieselben Filter erneut anzuwenden.
5. Bearbeite, benenne sie um oder lösche sie, wenn sich dein Bedarf ändert.

Bei einer Umkreissuche bleibt der beim Speichern gewählte Ausgangsbetrieb mit der Suche verbunden. Ein späterer Wechsel des aktiven Betriebs verändert diese Suche nicht.

![gespeicherte suchen 01](screenshot:gespeicherte-suchen-01)$flow_4$,$flow_4$Marktplatz$flow_4$,$flow_4$saved-searches$flow_4$,'business','published',50) ON CONFLICT (slug) DO UPDATE SET title=EXCLUDED.title,body=EXCLUDED.body,section=EXCLUDED.section,page_key=EXCLUDED.page_key,audience=EXCLUDED.audience,status=EXCLUDED.status,position=EXCLUDED.position,updated_at=now();

INSERT INTO sk_internal.help_chapters (slug,title,body,section,page_key,audience,status,position) VALUES ($flow_5$sk-guide-chat$flow_5$,$flow_5$Mit einem anderen Betrieb Kontakt aufnehmen$flow_5$,$flow_5$# Wie nehme ich Kontakt zu einem Inserat auf?

1. Öffne das Inserat, das dich interessiert.
2. Wähle «Kontakt aufnehmen». Wenn du mehrere berechtigte Betriebe hast, prüfe den ausgewählten Absenderbetrieb.
3. Formuliere deine erste Nachricht direkt auf der Inseratseite und sende sie ab.
4. Öffne «Nachrichten», um die Antwort zu lesen und das Gespräch fortzusetzen. Neue Nachrichten erscheinen automatisch.
5. Über «Zum Inserat» kannst du die Angaben erneut ansehen, auch wenn das Inserat nach einer angenommenen Vergabe nicht mehr öffentlich erscheint.

Besteht bereits eine Unterhaltung zu diesem Inserat, führt «Zum Chat» zum bestehenden Gespräch. In der Nachrichtenübersicht erscheinen normalerweise aktive Unterhaltungen. Archivierte Gespräche öffnest du über den entsprechenden Link. Bei mehreren Betrieben kannst du die Unterhaltungen nach deinem Betrieb filtern.

![nachrichten aktiv 01](screenshot:nachrichten-aktiv-01)$flow_5$,$flow_5$Zusammenarbeit$flow_5$,$flow_5$messages$flow_5$,'business','published',60) ON CONFLICT (slug) DO UPDATE SET title=EXCLUDED.title,body=EXCLUDED.body,section=EXCLUDED.section,page_key=EXCLUDED.page_key,audience=EXCLUDED.audience,status=EXCLUDED.status,position=EXCLUDED.position,updated_at=now();

INSERT INTO sk_internal.help_chapters (slug,title,body,section,page_key,audience,status,position) VALUES ($flow_6$sk-guide-awards$flow_6$,$flow_6$Ein Inserat vergeben oder eine Vergabe annehmen$flow_6$,$flow_6$# Wie vereinbare ich eine Zusammenarbeit?

**Wenn du das Inserat erstellt hast:**

1. Öffne die Unterhaltung mit dem Betrieb, mit dem du zusammenarbeiten möchtest.
2. Wähle «Inserat an diesen Betrieb vergeben».
3. Warte, bis der angefragte Betrieb das Angebot annimmt oder ablehnt.
4. Sobald die Vergabe angenommen wurde, ist das Inserat nicht mehr im öffentlichen Marktplatz sichtbar. Der gemeinsame Chat bleibt für Absprachen offen.

**Wenn du Interesse an einem Inserat hast:**

1. Öffne die entsprechende Unterhaltung.
2. Prüfe das Vergabeangebot und die Inseratdetails.
3. Wähle «Annehmen» oder «Ablehnen».
4. Nach der Annahme findest du das Inserat unter «Meine Inserate» → «Als Partner» in «Zusammenarbeit läuft».

Andere Unterhaltungen zu einem vergebenen Inserat werden archiviert. Das vergebene Inserat bleibt für die beteiligten Betriebe lesbar, kann aber nicht mehr bearbeitet werden.

![vergabe anbieten 01](screenshot:vergabe-anbieten-01)
![vergabe annehmen 01](screenshot:vergabe-annehmen-01)
![als partner 01](screenshot:als-partner-01)$flow_6$,$flow_6$Zusammenarbeit$flow_6$,$flow_6$messages$flow_6$,'business','published',70) ON CONFLICT (slug) DO UPDATE SET title=EXCLUDED.title,body=EXCLUDED.body,section=EXCLUDED.section,page_key=EXCLUDED.page_key,audience=EXCLUDED.audience,status=EXCLUDED.status,position=EXCLUDED.position,updated_at=now();

INSERT INTO sk_internal.help_chapters (slug,title,body,section,page_key,audience,status,position) VALUES ($flow_7$sk-guide-completion$flow_7$,$flow_7$Eine Zusammenarbeit abschliessen$flow_7$,$flow_7$# Wie schliesse ich eine Zusammenarbeit ab?

1. Führe die vereinbarte Zusammenarbeit durch und nutze den gemeinsamen Chat für organisatorische Absprachen.
2. Nach dem Ende der Zusammenarbeit öffnest du die zugehörige Unterhaltung.
3. Wähle «Zusammenarbeit abgeschlossen» beziehungsweise «Abschluss der Zusammenarbeit bestätigen».
4. Die andere Seite bestätigt den Abschluss unabhängig davon ebenfalls.
5. Sobald beide Bestätigungen vorliegen, gilt die Zusammenarbeit als abgeschlossen; anschliessend kannst du den Partner bewerten.

Die Aufgabe zur Abschlussbestätigung erscheint in «Meine Übersicht» ab dem Bis-Datum des Inserats. Eine Bestätigung bedeutet nicht automatisch, dass du mit der Leistung zufrieden warst: Dafür steht die separate Bewertung zur Verfügung.

Abgeschlossene Zusammenarbeiten findest du unter «Meine Inserate» → «Als Partner» in «Zusammenarbeit abgeschlossen». Die Unterhaltung bleibt im Archiv lesbar.

![abschluss bestaetigen 01](screenshot:abschluss-bestaetigen-01)$flow_7$,$flow_7$Zusammenarbeit$flow_7$,$flow_7$messages$flow_7$,'business','published',80) ON CONFLICT (slug) DO UPDATE SET title=EXCLUDED.title,body=EXCLUDED.body,section=EXCLUDED.section,page_key=EXCLUDED.page_key,audience=EXCLUDED.audience,status=EXCLUDED.status,position=EXCLUDED.position,updated_at=now();

INSERT INTO sk_internal.help_chapters (slug,title,body,section,page_key,audience,status,position) VALUES ($flow_8$sk-guide-reviews$flow_8$,$flow_8$Einen Partner bewerten und Bewertungen ansehen$flow_8$,$flow_8$# Wie bewerte ich eine Zusammenarbeit?

1. Warte, bis beide Betriebe den Abschluss der Zusammenarbeit bestätigt haben.
2. Öffne die Bewertungsaufgabe oder wechsle zu «Meine Bewertungen».
3. Bewerte **Kommunikation**, **Zuverlässigkeit** und **Zusammenarbeit** jeweils mit 1 bis 5 Sternen.
4. Ergänze auf Wunsch einen sachlichen Kommentar.
5. Prüfe deine Angaben und sende die Bewertung ab.

Die Gesamtbewertung ergibt sich aus den drei Kriterien. Bewertungen gehören zum betreffenden Betrieb und beziehen sich auf bestätigte Zusammenarbeiten. Die Bewertung der Gegenseite wird sichtbar, sobald beide bewertet haben oder die vorgesehene Frist abgelaufen ist.

Im Inserat beziehungsweise im Betriebsprofil kannst du die Rückmeldungen anderer Mitglieder zum Betrieb ansehen. Ein öffentlicher Durchschnitt wird erst ab einer ausreichenden Anzahl veröffentlichter Bewertungen angezeigt.

![bewertung erfassen 01](screenshot:bewertung-erfassen-01)
![betriebsbewertung 01](screenshot:betriebsbewertung-01)$flow_8$,$flow_8$Zusammenarbeit$flow_8$,$flow_8$reviews$flow_8$,'business','published',90) ON CONFLICT (slug) DO UPDATE SET title=EXCLUDED.title,body=EXCLUDED.body,section=EXCLUDED.section,page_key=EXCLUDED.page_key,audience=EXCLUDED.audience,status=EXCLUDED.status,position=EXCLUDED.position,updated_at=now();

INSERT INTO sk_internal.help_chapters (slug,title,body,section,page_key,audience,status,position) VALUES ($flow_9$sk-guide-listings$flow_9$,$flow_9$Bestehende Inserate und Partnerschaften verwalten$flow_9$,$flow_9$# Wie behalte ich meine Inserate im Blick?

1. Öffne «Meine Inserate».
2. Prüfe die aktiven Inserate und bearbeite sie bei Bedarf.
3. Setze ein Inserat inaktiv, wenn es vorübergehend nicht mehr angeboten werden soll.
4. Führe unter «Private Entwürfe» noch nicht veröffentlichte Inserate weiter.
5. Öffne «Inaktive Inserate», um deaktivierte Inserate einzusehen und gegebenenfalls wieder zu aktivieren.
6. Wechsle zu «Als Partner», um angenommene Vergaben und abgeschlossene Zusammenarbeiten zu sehen.

Ein Inserat mit vorhandenen Unterhaltungen wird beim Entfernen inaktiv gesetzt; die Gesprächsverläufe bleiben erhalten und werden archiviert. Vergebene oder abgeschlossene Inserate sind schreibgeschützt und bleiben für die beteiligten Betriebe einsehbar.

![meine inserate 01](screenshot:meine-inserate-01)
![als partner 01](screenshot:als-partner-01)$flow_9$,$flow_9$Inserate$flow_9$,$flow_9$my-listings$flow_9$,'business','published',100) ON CONFLICT (slug) DO UPDATE SET title=EXCLUDED.title,body=EXCLUDED.body,section=EXCLUDED.section,page_key=EXCLUDED.page_key,audience=EXCLUDED.audience,status=EXCLUDED.status,position=EXCLUDED.position,updated_at=now();

INSERT INTO sk_internal.help_chapters (slug,title,body,section,page_key,audience,status,position) VALUES ($flow_10$sk-guide-overview$flow_10$,$flow_10$Aufgaben und Nachrichten im Blick behalten$flow_10$,$flow_10$# Wie nutze ich meine persönliche Übersicht?

1. Öffne nach der Anmeldung «Meine Übersicht».
2. Prüfe, ob ungelesene Nachrichten oder offene Vergabeangebote vorhanden sind.
3. Klicke unter «Aktuelles und Aufgaben» auf eine Meldung, um direkt zur betreffenden Unterhaltung oder Zusammenarbeit zu gelangen.
4. Kontrolliere deine Inserate und die Genehmigungsstände deiner Betriebe.
5. Öffne offene Bewertungen, sobald eine Zusammenarbeit abgeschlossen wurde.

Die Zahl ungelesener Nachrichten aktualisiert sich während der Nutzung der Übersicht. Die Aufgabe zur Abschlussbestätigung erscheint ab dem Bis-Datum des Inserats.

![dashboard uebersicht 01](screenshot:dashboard-uebersicht-01)$flow_10$,$flow_10$Alltag$flow_10$,$flow_10$dashboard$flow_10$,'business','published',110) ON CONFLICT (slug) DO UPDATE SET title=EXCLUDED.title,body=EXCLUDED.body,section=EXCLUDED.section,page_key=EXCLUDED.page_key,audience=EXCLUDED.audience,status=EXCLUDED.status,position=EXCLUDED.position,updated_at=now();

INSERT INTO sk_internal.help_chapters (slug,title,body,section,page_key,audience,status,position) VALUES ($flow_11$sk-guide-membership$flow_11$,$flow_11$Mitgliedschaft und Preise verstehen$flow_11$,$flow_11$# Wie verwalte ich meine Mitgliedschaft?

1. Erfasse deinen Betrieb und warte auf dessen Freigabe.
2. Informiere dich über die angebotenen Tarife und Konditionen.
3. Wähle den gewünschten Tarif und prüfe die angezeigten Vertragsinformationen.
4. Behalte deine Mitgliedschaft sowie ihre Laufzeit und die dazugehörigen Unterlagen im Blick.
5. Bei Fragen zu Rechnung, Laufzeit oder Kündigung wende dich an die StaffKeeping-Administration.

Mitgliedschaften sind betriebsbezogen. Wenn du mehrere Betriebe verwaltest, können diese unterschiedliche Mitgliedschaften und Konditionen haben.

![betriebsstatus 01](screenshot:betriebsstatus-01)$flow_11$,$flow_11$Konto$flow_11$,$flow_11$my-businesses$flow_11$,'business','published',120) ON CONFLICT (slug) DO UPDATE SET title=EXCLUDED.title,body=EXCLUDED.body,section=EXCLUDED.section,page_key=EXCLUDED.page_key,audience=EXCLUDED.audience,status=EXCLUDED.status,position=EXCLUDED.position,updated_at=now();

INSERT INTO sk_internal.help_chapters (slug,title,body,section,page_key,audience,status,position) VALUES ($flow_12$sk-guide-help$flow_12$,$flow_12$Hilfe finden$flow_12$,$flow_12$# Wo finde ich Hilfe?

1. Öffne «Hilfe», wenn du einen gesamten Ablauf nachlesen möchtest.
2. Wähle ein Thema wie «Betrieb erfassen», «Inserat erstellen» oder «Kontakt aufnehmen».
3. Nutze «Hilfe zur Seite», wenn du Unterstützung zu deinem gerade geöffneten Bereich suchst.
4. Kehre nach dem Lesen zur jeweiligen Tätigkeit zurück.

![hilfe handbuch 01](screenshot:hilfe-handbuch-01)$flow_12$,$flow_12$Alltag$flow_12$,$flow_12$help$flow_12$,'business','published',130) ON CONFLICT (slug) DO UPDATE SET title=EXCLUDED.title,body=EXCLUDED.body,section=EXCLUDED.section,page_key=EXCLUDED.page_key,audience=EXCLUDED.audience,status=EXCLUDED.status,position=EXCLUDED.position,updated_at=now();


-- Ältere Benutzerhandbuch-Kapitel nicht mehr neben den neuen Workflows anzeigen.
-- Archivierte Texte bleiben über die Handbuchverwaltung für Administratoren erhalten.
UPDATE sk_internal.help_chapters
SET status = 'draft', updated_at = now()
WHERE audience IN ('business','public')
  AND status = 'published'
  AND slug NOT IN (
    'sk-guide-start',
    'sk-guide-businesses',
    'sk-guide-create-listing',
    'sk-guide-market',
    'sk-guide-searches',
    'sk-guide-chat',
    'sk-guide-awards',
    'sk-guide-completion',
    'sk-guide-reviews',
    'sk-guide-listings',
    'sk-guide-overview',
    'sk-guide-membership',
    'sk-guide-help'
  );

-- Einheitliche Reihenfolge der Workflow-Kapitel, unabhängig vom bisherigen Altbestand.
-- Diese Kapitel stehen in genau der Reihenfolge ihrer alltäglichen Nutzung.
UPDATE sk_internal.project_doc_chapters
SET body = body || E'\n\n' || $note$
## Benutzerhandbuch: konsolidierte Workflow-Fassung
Es sind ausschliesslich die 13 aktuellen Benutzer-Workflows veröffentlicht. Ältere öffentliche und Mitglieder-Hilfekapitel wurden reversibel auf «Entwurf» gestellt, nicht gelöscht. Die Administrationshilfe bleibt unverändert. Keine sichtbaren Release-Bezeichnungen, SK-Kürzel oder technischen Entwicklungsstände im Benutzerhandbuch. Neue Funktionsanleitungen werden künftig in den bestehenden Workflow-Kapiteln gepflegt statt zusätzliche parallele Kapitel zu veröffentlichen.
$note$, updated_at=now()
WHERE slug='status'
  AND position('## Benutzerhandbuch: konsolidierte Workflow-Fassung' IN body)=0;

COMMIT;
