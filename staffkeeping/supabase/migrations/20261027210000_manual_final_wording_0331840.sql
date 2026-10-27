-- StaffKeeping: redaktionelle Korrektur Handbuch 0.33.1.8.40. Keine Änderungen an der Fachlogik.

BEGIN;

UPDATE sk_internal.help_chapters SET body=$skmanual$# Suchen speichern und wieder öffnen

Stelle zuerst die gewünschten Marktplatzfilter ein. Wähle danach «Suche speichern» und gib der Suche einen Namen. Gespeicherte Suchen kannst du später öffnen, ändern oder löschen.

Aktiviere bei einer gespeicherten Suche «E-Mail bei neuen Treffern», wenn du über neu passende Inserate informiert werden möchtest. Über die Einstellungen der Suche kannst du die Benachrichtigung jederzeit wieder deaktivieren.

Eine gespeicherte Umkreissuche ist an ihren gewählten Ausgangsbetrieb gebunden. Ein späterer Wechsel des aktiven Betriebs verändert den gespeicherten Ausgangspunkt nicht.

![Gespeicherte Suchen und E-Mail-Option](screenshot:gespeicherte-suchen-01)$skmanual$, updated_at=now() WHERE slug='sk-guide-searches';

UPDATE sk_internal.help_chapters SET body=$skmanual$# Mitgliedschaft und Preise

Dein Betrieb wird erst nach der Prüfung durch die Administration freigegeben. Die Freigabe eines Betriebs gilt nicht automatisch für andere Betriebe, die du ebenfalls verwaltest.

Die Mitgliedschaft ist einem Betrieb zugeordnet. Wenn du mehrere Betriebe verwaltest, gelten die Mitgliedschaft und die vereinbarten Konditionen für jeden Betrieb separat.

Informiere dich über die angebotenen Tarife und Konditionen. Für Fragen zu Preisen, Rechnungen, Laufzeit oder Kündigung wende dich an die StaffKeeping-Administration.

![Genehmigungsstatus eines Betriebs](screenshot:betriebsstatus-01)$skmanual$, updated_at=now() WHERE slug='sk-guide-membership';

UPDATE sk_internal.help_chapters SET body=$skmanual$# Hilfe und Benutzerhandbuch

Über «Hilfe» öffnest du das vollständige Benutzerhandbuch mit Suchfunktion. «Hilfe zur Seite» zeigt eine Anleitung zur aktuell geöffneten Ansicht.

Wähle das passende Kapitel oder verwende die Suche, um eine Anleitung zu finden.

![Benutzerhandbuch mit Kapiteln](screenshot:hilfe-handbuch-01)$skmanual$, updated_at=now() WHERE slug='sk-guide-help';

UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$note$## Redaktionelle Handbuchkorrektur 0.33.1.8.40 (27.10.2026)
Benutzerhilfe formuliert den Soll-Ablauf ohne Test-, Demo-, Entwicklungs- oder Versionshinweise. Die tatsächlichen offenen Funktionen bleiben weiterhin in der internen Statusdokumentation; diese Korrektur aktiviert keine Abonnements oder E-Mails.$note$,updated_at=now() WHERE slug='status' AND position('## Redaktionelle Handbuchkorrektur 0.33.1.8.40' IN body)=0;

COMMIT;
