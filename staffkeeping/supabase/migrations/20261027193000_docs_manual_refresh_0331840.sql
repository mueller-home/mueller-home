-- StaffKeeping 0.33.1.8.40: Handbuch und Projektdokumentation, keine Fachschemaänderungen.
BEGIN;
INSERT INTO sk_internal.help_chapters (slug,title,body,section,page_key,audience,status,position) VALUES ($sk40$sk-guide-overview$sk40$,$sk40$Meine Übersicht$sk40$,$sk40$# Meine Übersicht

Nach der Anmeldung zeigt «Meine Übersicht» deine wichtigsten Aufgaben und Aktivitäten. Wähle eine Kachel oder einen Eintrag unter «Aktuelles und Aufgaben», um direkt zum entsprechenden Bereich zu gelangen.

Die Zahl ungelesener Nachrichten wird bei geöffneter Übersicht automatisch aktualisiert. Hinweise auf den Abschluss einer Zusammenarbeit erscheinen erst, wenn das Bis-Datum des Inserats erreicht ist.

![Meine Übersicht mit Kacheln und Aufgaben](screenshot:dashboard-uebersicht-01)$sk40$,$sk40$Einstieg$sk40$,$sk40$dashboard$sk40$,'business','published',10) ON CONFLICT (slug) DO UPDATE SET title=EXCLUDED.title,body=EXCLUDED.body,section=EXCLUDED.section,page_key=EXCLUDED.page_key,audience=EXCLUDED.audience,status=EXCLUDED.status,position=EXCLUDED.position,updated_at=now();
INSERT INTO sk_internal.help_chapters (slug,title,body,section,page_key,audience,status,position) VALUES ($sk40$sk-guide-businesses$sk40$,$sk40$Meine Betriebe und aktiver Betrieb$sk40$,$sk40$# Meine Betriebe verwalten

Unter «Meine Betriebe» siehst du den Genehmigungsstatus deiner Betriebe. Neue Betriebe werden erst nach ausdrücklicher Einreichung zur Prüfung an die Administration übermittelt.

Mit «Entwurf speichern» kannst du unvollständige Angaben privat sichern. Über «Entwurf fortsetzen» arbeitest du später weiter. «Schliessen» verlässt das Formular; das X bietet bei ungesicherten Änderungen die Wahl zwischen Weiterbearbeiten und Verwerfen.

Wenn du mehrere freigegebene Betriebe hast, kannst du im Header den **aktiven Betrieb** wählen. Bei nur einem Betrieb erfolgt die Auswahl automatisch, ohne sichtbares Feld. Der aktive Betrieb dient beispielsweise als Ausgangspunkt der Umkreissuche und als vorausgewählter Absender im Chat. Eine gespeicherte Umkreissuche behält den Betrieb, mit dem sie gespeichert wurde.

![Meine Betriebe mit Entwurf und Status](screenshot:meine-betriebe-01)

![Auswahl des aktiven Betriebs](screenshot:aktiver-betrieb-01)$sk40$,$sk40$Betriebe$sk40$,$sk40$my-businesses$sk40$,'business','published',20) ON CONFLICT (slug) DO UPDATE SET title=EXCLUDED.title,body=EXCLUDED.body,section=EXCLUDED.section,page_key=EXCLUDED.page_key,audience=EXCLUDED.audience,status=EXCLUDED.status,position=EXCLUDED.position,updated_at=now();
INSERT INTO sk_internal.help_chapters (slug,title,body,section,page_key,audience,status,position) VALUES ($sk40$sk-guide-market$sk40$,$sk40$Marktplatz und Karte$sk40$,$sk40$# Inserate im Marktplatz finden

Im Marktplatz suchst du nach passenden Inseraten. Du kannst beispielsweise nach Stichwort, Inserattyp, Kategorie, Unterkunft oder Umkreis filtern. Bei der Umkreissuche wird der Standort des passenden aktiven Betriebs verwendet.

Mit «Liste» und «Karte» wechselst du zwischen den beiden Darstellungen. Die Kartenpositionen sind ungefähre Standorte. Inserate ohne bestätigten Standort können weiterhin in der Liste erscheinen.

Siehst du bei einem Inserat «Zum Chat», besteht für deinen Benutzer bereits eine zugängliche Unterhaltung. Über das Inserat kannst du den betreffenden Betrieb kontaktieren.

![Marktplatz in Listenansicht](screenshot:marktplatz-liste-01)

![Marktplatz in Kartenansicht](screenshot:marktplatz-karte-01)$sk40$,$sk40$Marktplatz$sk40$,$sk40$market$sk40$,'business','published',30) ON CONFLICT (slug) DO UPDATE SET title=EXCLUDED.title,body=EXCLUDED.body,section=EXCLUDED.section,page_key=EXCLUDED.page_key,audience=EXCLUDED.audience,status=EXCLUDED.status,position=EXCLUDED.position,updated_at=now();
INSERT INTO sk_internal.help_chapters (slug,title,body,section,page_key,audience,status,position) VALUES ($sk40$sk-guide-searches$sk40$,$sk40$Gespeicherte Suchen$sk40$,$sk40$# Suchen speichern und wieder öffnen

Stelle zuerst die gewünschten Marktplatzfilter ein. Wähle danach «Suche speichern» und gib der Suche einen Namen. Gespeicherte Suchen kannst du später öffnen, ändern oder löschen.

Du kannst die Option «E-Mail bei neuen Treffern» vormerken. **Automatische Trefferprüfung und E-Mail-Versand sind derzeit noch nicht freigeschaltet.** Durch das Aktivieren dieser Option werden noch keine Benachrichtigungen verschickt.

Eine gespeicherte Umkreissuche ist an ihren gewählten Ausgangsbetrieb gebunden. Ein späterer Wechsel des aktiven Betriebs verändert den gespeicherten Ausgangspunkt nicht.

![Gespeicherte Suchen und E-Mail-Option](screenshot:gespeicherte-suchen-01)$sk40$,$sk40$Marktplatz$sk40$,$sk40$saved-searches$sk40$,'business','published',40) ON CONFLICT (slug) DO UPDATE SET title=EXCLUDED.title,body=EXCLUDED.body,section=EXCLUDED.section,page_key=EXCLUDED.page_key,audience=EXCLUDED.audience,status=EXCLUDED.status,position=EXCLUDED.position,updated_at=now();
INSERT INTO sk_internal.help_chapters (slug,title,body,section,page_key,audience,status,position) VALUES ($sk40$sk-guide-listings$sk40$,$sk40$Meine Inserate$sk40$,$sk40$# Eigene Inserate verwalten

Unter «Meine Inserate» findest du deine Inserate und privaten Entwürfe. Inaktive Inserate stehen in einer eigenen Gruppe unter «Private Entwürfe».

Im Bereich «Als Partner» werden zugeteilte Zusammenarbeiten getrennt angezeigt: zuerst **«Zusammenarbeit läuft»**, darunter **«Zusammenarbeit abgeschlossen»**. Über «Zum Chat» öffnest du die dazugehörige Unterhaltung.

Bei einem Inserat mit Chatverlauf führt das Entfernen zur Deaktivierung statt zum endgültigen Löschen. Vergebene und abgeschlossene Inserate bleiben lesbar, können aber nicht mehr bearbeitet werden.

![Eigene Inserate und Entwürfe](screenshot:meine-inserate-01)

![Partner-Inserate nach Zusammenarbeit gruppiert](screenshot:als-partner-01)$sk40$,$sk40$Inserate$sk40$,$sk40$my-listings$sk40$,'business','published',50) ON CONFLICT (slug) DO UPDATE SET title=EXCLUDED.title,body=EXCLUDED.body,section=EXCLUDED.section,page_key=EXCLUDED.page_key,audience=EXCLUDED.audience,status=EXCLUDED.status,position=EXCLUDED.position,updated_at=now();
INSERT INTO sk_internal.help_chapters (slug,title,body,section,page_key,audience,status,position) VALUES ($sk40$sk-guide-chat$sk40$,$sk40$Nachrichten und Chat$sk40$,$sk40$# Nachrichten austauschen

Öffne ein Inserat und wähle «Kontakt aufnehmen». Die erste Nachricht schreibst du direkt im Inserat. Falls du mehrere berechtigte Betriebe hast, kann der Absenderbetrieb gewählt werden.

In «Nachrichten» siehst du standardmässig die aktiven Unterhaltungen. Neue Nachrichten erscheinen bei geöffnetem Nachrichtenfenster automatisch; du musst die Seite nicht neu laden. Ungelesene Nachrichten sind gekennzeichnet.

Über «Zum Inserat» öffnest du das zugehörige Inserat. Auch nach einer angenommenen Vergabe ist das Inserat für die beteiligten Betriebe weiterhin lesbar.

Beide Seiten dürfen eine Unterhaltung abschliessen. Abgeschlossene oder archivierte Unterhaltungen werden nur über den Archivlink angezeigt, sofern solche vorhanden sind. Beim normalen Wechsel zu «Nachrichten» wird wieder die aktive Ansicht geöffnet.

![Aktive Unterhaltung im Nachrichtenbereich](screenshot:nachrichten-aktiv-01)$sk40$,$sk40$Kommunikation$sk40$,$sk40$messages$sk40$,'business','published',60) ON CONFLICT (slug) DO UPDATE SET title=EXCLUDED.title,body=EXCLUDED.body,section=EXCLUDED.section,page_key=EXCLUDED.page_key,audience=EXCLUDED.audience,status=EXCLUDED.status,position=EXCLUDED.position,updated_at=now();
INSERT INTO sk_internal.help_chapters (slug,title,body,section,page_key,audience,status,position) VALUES ($sk40$sk-guide-awards$sk40$,$sk40$Vergaben und Zusammenarbeit$sk40$,$sk40$# Ein Inserat vergeben

Der Inserateigner kann im Chat dem gewünschten Betrieb die Vergabe anbieten. Der Interessent nimmt das Angebot ausdrücklich an oder lehnt es ab.

Nach der Annahme ist das Inserat nicht mehr öffentlich im Marktplatz sichtbar. Für die beiden Partner bleibt es lesbar; der gemeinsame Chat bleibt für Absprachen offen. Die übrigen Interessenten-Chats werden archiviert.

Nach dem tatsächlichen Ende bestätigen beide Betriebe unabhängig voneinander den Abschluss. Die Aufgabe zur Abschlussbestätigung erscheint in «Meine Übersicht» erst ab dem Bis-Datum des Inserats. Sobald beide bestätigt haben, kann die Zusammenarbeit bewertet werden.

![Vergabeangebot im Chat](screenshot:vergabe-anbieten-01)

![Vergabeangebot beantworten](screenshot:vergabe-annehmen-01)$sk40$,$sk40$Zusammenarbeit$sk40$,$sk40$partnerships$sk40$,'business','published',70) ON CONFLICT (slug) DO UPDATE SET title=EXCLUDED.title,body=EXCLUDED.body,section=EXCLUDED.section,page_key=EXCLUDED.page_key,audience=EXCLUDED.audience,status=EXCLUDED.status,position=EXCLUDED.position,updated_at=now();
INSERT INTO sk_internal.help_chapters (slug,title,body,section,page_key,audience,status,position) VALUES ($sk40$sk-guide-reviews$sk40$,$sk40$Bewertungen$sk40$,$sk40$# Zusammenarbeit bewerten

Nach dem beidseitig bestätigten Abschluss kannst du deinen Partnerbetrieb bewerten. Öffne «Bewertungen» oder nutze den entsprechenden Einstieg nach der Abschlussbestätigung.

Vergib für **Kommunikation**, **Zuverlässigkeit** und **Zusammenarbeit** jeweils 1 bis 5 Sterne. Ein schriftlicher Kommentar ist freiwillig. StaffKeeping berechnet die Gesamtbewertung aus den drei Kriterien.

Pro Betrieb und Zusammenarbeit ist nur eine Bewertung möglich. Die Gegenbewertung wird nach ihrer Abgabe oder spätestens 14 Tage nach Abschluss sichtbar. Im Inseratdetail kann die Bewertung des Betriebs angezeigt werden; ein Durchschnitt erscheint erst bei mindestens drei veröffentlichten Bewertungen.

![Bewertungsformular mit drei Kriterien](screenshot:bewertung-erfassen-01)

![Betriebsbewertung im Inseratdetail](screenshot:betriebsbewertung-01)$sk40$,$sk40$Zusammenarbeit$sk40$,$sk40$reviews$sk40$,'business','published',80) ON CONFLICT (slug) DO UPDATE SET title=EXCLUDED.title,body=EXCLUDED.body,section=EXCLUDED.section,page_key=EXCLUDED.page_key,audience=EXCLUDED.audience,status=EXCLUDED.status,position=EXCLUDED.position,updated_at=now();
INSERT INTO sk_internal.help_chapters (slug,title,body,section,page_key,audience,status,position) VALUES ($sk40$sk-guide-membership$sk40$,$sk40$Mitgliedschaft und Preise$sk40$,$sk40$# Mitgliedschaft und Preise

Dein Betrieb wird erst nach der Prüfung durch die Administration freigegeben. Die Freigabe eines Betriebs gilt nicht automatisch für andere Betriebe, die du ebenfalls verwaltest.

**Abo-Kauf, Online-Zahlung, automatische Rechnungsstellung, Kündigung und Ablaufhinweise sind derzeit noch nicht verfügbar.** Die Tarife werden von der Administration vorbereitet. Aus diesem Handbuch entsteht keine Zahlungspflicht.

Bei Fragen zur Mitgliedschaft wende dich an die StaffKeeping-Administration.

![Genehmigungsstatus eines Betriebs](screenshot:betriebsstatus-01)$sk40$,$sk40$Konto$sk40$,$sk40$profile$sk40$,'business','published',90) ON CONFLICT (slug) DO UPDATE SET title=EXCLUDED.title,body=EXCLUDED.body,section=EXCLUDED.section,page_key=EXCLUDED.page_key,audience=EXCLUDED.audience,status=EXCLUDED.status,position=EXCLUDED.position,updated_at=now();
INSERT INTO sk_internal.help_chapters (slug,title,body,section,page_key,audience,status,position) VALUES ($sk40$sk-guide-help$sk40$,$sk40$Hilfe verwenden$sk40$,$sk40$# Hilfe und Benutzerhandbuch

Über «Hilfe» öffnest du das vollständige Benutzerhandbuch mit Suchfunktion. «Hilfe zur Seite» zeigt eine Anleitung zur aktuell geöffneten Ansicht.

Die Anleitungen erklären die Bedienung. Wenn eine Funktion als noch nicht verfügbar beschrieben ist, kann sie derzeit nicht genutzt werden.

![Benutzerhandbuch mit Kapiteln](screenshot:hilfe-handbuch-01)$sk40$,$sk40$Hilfe$sk40$,$sk40$help$sk40$,'business','published',100) ON CONFLICT (slug) DO UPDATE SET title=EXCLUDED.title,body=EXCLUDED.body,section=EXCLUDED.section,page_key=EXCLUDED.page_key,audience=EXCLUDED.audience,status=EXCLUDED.status,position=EXCLUDED.position,updated_at=now();
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$sk40$## Dokumentations- und Hilfeabgleich 0.33.1.8.40 (27.10.2026)
Benutzerhandbuch und kontextbezogene Hilfe für Dashboard, Betriebe, Marktplatz/Karte, gespeicherte Suchen, Inserate/Partner, Chat, Vergaben, Bewertungen und Mitgliedschaft als eigenständige veröffentlichte Kapitel aktualisiert. Screenshots via bestehendem sk-help-images-Bucket und `screenshot:<id>`-Platzhalter. Redaktionelle Motiv-/Pfadliste unter staffkeeping/handbuch/SCREENSHOTS.md. Keine Fachlogikänderung und keine neue produktive Zahlungsfunktion.$sk40$, updated_at=now() WHERE slug=$sk40$concept$sk40$ AND position($sk40$## Dokumentations- und Hilfeabgleich 0.33.1.8.40 (27.10.2026)$sk40$ IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$sk40$## Dokumentationsstand 0.33.1.8.40 (27.10.2026)
Dokumentationsmigration vorbereitet; Ausführung in Supabase und Sichtprüfung der Kapitel/Hilfe zur Seite noch offen. 0.33.1.8.39: Mehrkriterienbewertungen und Admin-Tarifvorlagen technisch vorbereitet, produktive Abnahme noch nicht vollständig belegt. Noch offen: Abo-Kauf, Stripe, Rechnungen, Kündigung, Abo-Sperre, automatischer E-Mail-Versand für gespeicherte Suchen, Chat-E-Mails, Sicherheits- und Regressionstests, produktive Maps-ID für Annette/Patrick, Moderation von Bewertungen, Vergabe-Aufhebung. Keine Screenshot-Dateien enthalten; alle Plätze müssen mit echten, bereinigten Screenshots gefüllt werden.$sk40$, updated_at=now() WHERE slug=$sk40$status$sk40$ AND position($sk40$## Dokumentationsstand 0.33.1.8.40 (27.10.2026)$sk40$ IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$sk40$## 0.33.1.8.40 – Redaktionsaktualisierung (27.10.2026)
Einmalige Neuordnung der Benutzerhilfe mit beschreibenden Screenshot-Platzhaltern. Nur Dokumentationsmigration und redaktionelle Dateien; kein Eingriff in die Website-Funktionalität.$sk40$, updated_at=now() WHERE slug=$sk40$history$sk40$ AND position($sk40$## 0.33.1.8.40 – Redaktionsaktualisierung (27.10.2026)$sk40$ IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$sk40$## Dokumentationstest 0.33.1.8.40
1. SQL erfolgreich und idempotent ausführen. 2. Handbuch öffnen; Kapitel auffindbar, alle Texte Deutsch (Schweiz). 3. Kontext «Hilfe zur Seite» für Dashboard, Marktplatz, Nachrichten, Inserate, Bewertungen prüfen. 4. Bei Screenshot-Upload slug/image-id-Dateinamen beachten, keine echten Personendaten abbilden. 5. Noch nicht realisierte Abo- und Mailfunktionen werden ausdrücklich als nicht verfügbar bezeichnet. 6. Altinhalte auf überholte Darstellungen prüfen und redaktionell bereinigen.$sk40$, updated_at=now() WHERE slug=$sk40$tests$sk40$ AND position($sk40$## Dokumentationstest 0.33.1.8.40$sk40$ IN body)=0;
COMMIT;
