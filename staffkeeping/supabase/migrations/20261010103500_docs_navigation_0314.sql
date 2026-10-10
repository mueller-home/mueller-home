-- StaffKeeping 0.31.4: existing central documentation and handbook only.
-- Several UPDATE statements in one transaction, no SELECT resultsets.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $d$
## Navigation und Hilfe 0.31.4

| Situation | Darstellung |
|---|---|
| Menü hat ausreichend Platz | Menüpunkte einzeilig nebeneinander |
| Menü hat zu wenig Platz | Ganze Menüpunkte dürfen auf die nächste Navigationszeile wechseln |
| Angemeldeter Betrieb öffnet Hilfe | Betriebsnavigation bleibt sichtbar |
| Administrator öffnet Hilfe | Admin-Navigation bleibt sichtbar |
| Gast öffnet Hilfe | Öffentliche Navigation wird angezeigt |

Der Menüpunkt heisst „Hilfe zur Seite“. Hilfeseiten sind öffentlich erreichbar, dürfen aber niemals die aktuell authentifizierte Navigation in die Gastnavigation verwandeln. Änderung betrifft nur Frontend-Anzeige, keine neue Autorisierungsregel.
$d$,updated_at=now() WHERE slug='concept' AND position('## Navigation und Hilfe 0.31.4' in body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $d$
## StaffKeeping 0.31.4

Navigation: einzeilige Menüpunkte, bei Platzmangel Umbruch ganzer Elemente auf mehrere Reihen. Beschriftung „Hilfe zur Seite“. Hilfeansicht behält für angemeldete Betriebe und Administratoren die passende Navigation. Keine Änderung an Authentifizierung oder Datenbankschema. Browser-Tests noch ausstehend.
$d$,updated_at=now() WHERE slug='history' AND position('## StaffKeeping 0.31.4' in body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $d$
## Zu testen: Navigation 0.31.4

1. Angemeldeter Betrieb: Hilfe öffnen, alle bisherigen Betriebsmenüpunkte bleiben sichtbar.
2. Administrator: Hilfe öffnen, Admin-Menüpunkt bleibt sichtbar.
3. Abgemeldeter Benutzer: Hilfe zeigt nur Gastnavigation.
4. Breite Desktop- und schmale Fenster: kein Menülabel bricht innerhalb eines Buttons um.
5. Navigation zu Hilfe und zurück funktioniert ohne unerwarteten Logout; Seitenhilfe zeigt das richtige Kapitel.
6. Änderung von Unternehmensprofil vor Navigation weiterhin speichern.
$d$,updated_at=now() WHERE slug='tests' AND position('## Zu testen: Navigation 0.31.4' in body)=0;
UPDATE sk_internal.help_chapters SET body=body || E'\n\n' || $d$
## Navigation und Hilfe

Über **Hilfe** öffnen Sie das vollständige Benutzerhandbuch. Über **Hilfe zur Seite** sehen Sie die Anleitung zur aktuell geöffneten Seite. Wenn Sie angemeldet sind, bleiben Ihre normalen Menüpunkte auch beim Öffnen des Handbuchs sichtbar. Bei wenig Platz verteilt sich die Navigation auf mehrere Zeilen.

![Navigation mit Handbuch und Seitenhilfe](screenshot:hilfe-navigation-01)
$d$,updated_at=now() WHERE page_key='help' AND position('## Navigation und Hilfe' in body)=0;
COMMIT;
