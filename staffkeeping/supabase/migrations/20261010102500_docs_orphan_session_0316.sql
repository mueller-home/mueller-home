-- StaffKeeping 0.31.6: project documentation and integrated handbook ONLY.
-- One transaction, four UPDATE statements, no standalone SELECT result sets.
BEGIN;
UPDATE sk_internal.project_doc_chapters
SET body=body || E'\n\n' || $d$## Auth-Sitzungen nach Kontolöschung (0.31.6)

| Zustand | Verhalten |
|---|---|
| Gültiger Benutzer und gültige Session | Session bleibt erhalten, normale Anmeldung |
| `auth.users`-Benutzer nach Löschung nicht mehr vorhanden | Nur projektspezifische lokale Supabase-Session bereinigen; Login/Registrierung erlauben |
| Netzwerkfehler oder temporäre Supabase-Störung | Kein automatischer Logout; Fehler sichtbar machen |
| Registrierung nach Kontolöschung | Alte Session nicht für `sk_register_business` verwenden |
| Passwort-Wiederherstellung | Recovery-Modus und Bestätigungsablauf bleiben erhalten |

Technik: `getUser()` authentifiziert gegen Supabase. Nur explizites `user_not_found` oder `User from sub claim in JWT does not exist` löst die lokale Bereinigung aus. Der Session-Schlüssel ist auf dieses Supabase-Projekt begrenzt; allgemeine Browserdaten bleiben unberührt. Es wird kein Server-Service-Key im Browser eingesetzt.
$d$, updated_at=now()
WHERE slug='auth' AND position('## Auth-Sitzungen nach Kontolöschung (0.31.6)' in body)=0;
UPDATE sk_internal.project_doc_chapters
SET body=body || E'\n\n' || $d$## Abnahme 0.31.6 – verwaiste Auth-Sitzung

1. Nach Löschung eines Testkontos im bisherigen Browser erneute Registrierung starten: kein `User from sub claim in JWT does not exist`.
2. Neuen Auth-Benutzer bestätigen, Unternehmen anlegen und Anmeldung testen.
3. Gültiges anderes Konto neu laden: bleibt angemeldet.
4. Simulierten Netzwerkfehler testen: gültige Session darf nicht gelöscht werden.
5. Passwort-Reset und Recovery-Link testen: keine Regression.
6. Browser Zurück/Vorwärts und Hilfe bei gültiger Session prüfen.

**Stand:** Implementiert; Live-Tests stehen aus. Test Registrierung 2.0 im privaten Fenster und neue Audit-Ereignisse wurden vom Nutzer zuvor positiv bestätigt.
$d$, updated_at=now()
WHERE slug='tests' AND position('## Abnahme 0.31.6 – verwaiste Auth-Sitzung' in body)=0;
UPDATE sk_internal.project_doc_chapters
SET body=body || E'\n\n' || $d$## Release 0.31.6

Gezielte Behandlung einer verwaisten lokalen Supabase-Anmeldung nach Kontolöschung. Bei ausdrücklich nicht mehr vorhandenem Benutzer wird die lokale Session bereinigt; bei transienten Fehlern bleibt sie erhalten. Versionsanzeige und Asset-Version der Auth-Datei nachgeführt. **Live-Abnahme offen.**
$d$, updated_at=now()
WHERE slug='history' AND position('## Release 0.31.6' in body)=0;
UPDATE sk_internal.help_chapters
SET body=body || E'\n\n' || $d$## Anmeldung nach einer Kontolöschung

Wenn ein Benutzerkonto vollständig gelöscht wurde, ist eine eventuell noch im Browser gespeicherte Anmeldung nicht mehr gültig. StaffKeeping erkennt dies und bietet wieder die normale Anmeldung oder Registrierung an.

| Situation | Was tun? |
|---|---|
| Konto gelöscht und neue Registrierung gewünscht | Registrierungsformular erneut öffnen |
| Passwort vergessen, Konto existiert weiterhin | „Passwort vergessen“ verwenden |
| Vorübergehender Netzwerkfehler | Verbindung prüfen und Seite erneut laden; nicht automatisch ein neues Konto anlegen |

![Anmeldung nach einer Kontolöschung](screenshot:login-nach-loeschung-0316)
$d$, updated_at=now()
WHERE page_key IN ('login','register','profile')
  AND position('## Anmeldung nach einer Kontolöschung' in body)=0;
COMMIT;
