# Supabase · StaffKeeping (Version 0.19)

**Status: vorbereitet, NICHT in Supabase ausgeführt.** Vor produktivem Einsatz Sicherheits-/RLS-Tests durchführen. Kein echtes Login in der Anwendung vorhanden.

## Voraussetzungen

1. Eigenes, neues Supabase-Projekt für StaffKeeping erstellen (Benutzer hat Region Zürich ausgewählt); organisatorische Übergabe an Annette später klären.
2. In Supabase Auth E-Mail-Bestätigung einschalten. Die Frontend-URLs/Redirects erst für den tatsächlichen GitHub-Pages-Pfad konfigurieren (nicht raten).
3. **Vor dem SQL-Ausführen:** In Supabase SQL Editor bestätigen, dass der Ausführungsnutzer der privilegierte Projektoperator ist; die `SECURITY DEFINER`-Funktionen müssen einem dafür geeigneten Eigentümer gehören.
4. Im SQL-Editor **eine Datei mit vielen SQL-Statements** ausführen: `migrations/20261009120000_auth_foundation.sql`. Das Skript ist eine Transaktion (`BEGIN`/`COMMIT`). Supabase zeigt je nach Editoransicht nicht alle Zwischenergebnisse; dieses Skript liefert keine SELECT-Resultsets. Vor Ausführung prüfen, dass es im richtigen Projekt ist. Beim Fehler: Transaktion wird abgebrochen, Fehlertext sichern und nicht Teilstücke blind wiederholen.
5. In **Database → Schemas / API settings** sicherstellen, dass `sk_internal` NICHT unter den exponierten API-Schemas aufgeführt ist (nur `public` für diese erste Etappe). SQL gewährt `anon` und `authenticated` kein USAGE auf `sk_internal`.
6. **Keine** `service_role`- oder Supabase-Secret-Keys in `index.html`, `scripts/` oder `docs/` schreiben. Im Frontend wird später ausschliesslich URL + Publishable Key verwendet.
7. Projektbackup und ausgeführte Migrationsdatei im Git beibehalten. Nach dem Ausführen Schema/RLS prüfen.

## Tabellen

- `public.sk_businesses`: Stammdaten sowie Freigabestatus (anfänglich `Ausstehend`).
- `public.sk_business_members`: Auth-Benutzer → Unternehmen, zunächst ein Unternehmen je Benutzer; Rolle `owner`/`member` als spätere Erweiterungsmöglichkeit.
- `sk_internal.staff_admins`: StaffKeeping-Systemadministratoren; nur per privilegierter SQL-Verwaltung.
- `sk_internal.business_status_audit`: protokollierte Freigabe- und Sperränderungen.

Das Präfix `sk_` verhindert unbeabsichtigte Namenskollisionen. Es ist eine **bewusste Abweichung** vom Bubble-Entwurf `businesses.id = auth.uid()`; die Trennung Benutzer/Firma muss vor Produktivbetrieb fachlich bestätigt werden.

## Öffentliche Schnittstellen für den nächsten Release

| Funktion | Wer? | Zweck |
|---|---|---|
| `sk_register_business(...)` | angemeldet, E-Mail bestätigt | registriert Firma plus Eigentümer-Zuordnung; Status bleibt `Ausstehend` |
| `sk_is_admin()` | angemeldet | eigene Systemadministrator-Berechtigung abfragen |
| `sk_is_approved_member(uuid)` | angemeldet | Freigabe der eigenen Firma prüfen |
| `sk_admin_set_business_status(uuid, sk_business_status)` | ausschliesslich StaffKeeping-Admin | Freigabe/Sperre setzen und protokollieren |

**Wichtig:** Im Browser gibt es bewusst *keine* Schreibberechtigung auf Tabellen, auch nicht für Admins. Änderungen erfolgen über streng geprüfte RPCs. Ein normal angemeldeter Benutzer kann lediglich seine Firmen-/Mitgliedschaftszeilen lesen; ein Systemadministrator kann alle Unternehmen lesen.

## Ersten StaffKeeping-Administrator festlegen

**Erst nachdem** ein entsprechender Benutzer über Supabase Auth existiert und seine E-Mail bestätigt ist: UUID in Supabase Auth → Users ablesen und im SQL-Editor **manuell** als privilegierter Betreiber ausführen:

```sql
INSERT INTO sk_internal.staff_admins(user_id)
VALUES ('UUID-DES-BESTAETIGTEN-ADMIN-USERS'::uuid);
```

Kein öffentlich zugänglicher Bootstrap-Endpunkt, keine Adminrolle aus E-Mail-Text/Frontend/Metadaten. Der Benutzer kann auch ohne Firmenzuordnung Admin sein.

## Sicherheits- und Funktionstests (noch NICHT ausgeführt)

- [ ] Projekt frisch, vollständige Migration ohne Fehler ausgeführt.
- [ ] `sk_internal` nicht im Supabase Data API exposed schemas.
- [ ] Anonym: kein `SELECT` auf `sk_businesses`, `sk_business_members` und kein RPC-Zugriff.
- [ ] E-Mail nicht bestätigt: `sk_register_business` abgewiesen.
- [ ] Bestätigter User A: Registrierung einmal möglich, neuer Betrieb `Ausstehend`; zweites Mal abgewiesen.
- [ ] User A: eigene Firma und Mitgliedschaft lesbar; fremde Firma B nicht.
- [ ] User A: direkter INSERT/UPDATE/DELETE auf Firmen-/Mitgliedschaftstabellen abgewiesen.
- [ ] User A: `sk_admin_set_business_status` abgewiesen.
- [ ] Admin: Betriebe lesen, Status ändern, Audit-Eintrag sichtbar für DB-Betreiber.
- [ ] Gesperrte/unfreigeschaltete Firma: `sk_is_approved_member` liefert `false`.
- [ ] RLS für Inserate und Chats wird in späteren Releases **zusätzlich** implementiert; noch keine solchen produktiven Tabellen anlegen.

**Kein Freigabe- oder Deployment-Erfolg ist bisher nachgewiesen.**

## Architekturgrenze 0.19
Die Datenbank ist **nicht automatisch durch diese Datei deployt**. GitHub Pages liefert gegenwärtig weiterhin den Demo-Prototyp. Neue Unternehmen, Benutzer und Inserate werden erst in 0.20 und Folgereleases als neue Testdatensätze erstellt; **keine bestehenden Unternehmen oder Nutzer aus Bubble migrieren**. Eine leere Datenbank wird nicht künstlich mit Unternehmensdaten befüllt.

## Verifikation nach dem Einspielen
Im Supabase Table Editor kontrollieren: `sk_businesses`, `sk_business_members`, jeweils RLS = ON; internes Schema nicht exponiert. SQL-Konsole liefert bei diesem Skript keine separaten SELECT-Resultsets. Individuelle Sicherheitsprüfungen und der erste Admin-UUID-Eintrag sind getrennte, spätere Schritte.
