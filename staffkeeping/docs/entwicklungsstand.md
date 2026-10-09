# Entwicklungsstand

**Version 0.18 – 09.10.2026:** Designprototyp, ohne echte Datenbank/Authentifizierung.

## Demonstrierbare UI-Masken
Login, Registrierung, Passwort-Reset, Freigabe ausstehend, Marktplatz, Profil, Meine Inserate, Inseratdetails, Nachrichten, Bewertungen, Admin-Betriebe, Admin-Inserate, Impact-Dashboard, Admin-Projektdokumentation.

## Nicht implementiert
Supabase-Projekt und Schema, Auth und Freigabe, serverseitige Rollen/RLS, sichere Originaldokumentauslieferung, Datenspeicherung, Mail, Maps, Zahlungen, reale Admin-Aktionen. Demo-Daten und Demo-Aktionen nicht produktiv.

## Nächste Etappe
Design und App-Navigation mit Annette abnehmen; Bubble-Daten-/Workflow-Audit; Datenmodell und Berechtigungen definieren; Supabase-Sicherheitsgrundlage erstellen.

## Zuletzt bekannte Einschränkungen
Navigationskorrektur 0.17 statisch geprüft, Benutzer-Retest noch nicht bestätigt. In 0.18 ist die Projektdokumentation öffentlichkeitsfähig gekürzt, die vollständige Originaldatei bleibt lokal bis geschütztes Backend existiert.

## Version 0.19 – vorbereitet, NICHT ausgeführt
SQL-Basismigration für Unternehmen, Firmenmitgliedschaften, Backend-Administratoren, Auditlog, RLS und definierte RPCs erstellt. Kein Supabase-Deployment nachgewiesen; GitHub-Pages-Anwendung bleibt Demo. Installation und Sicherheitsprüfung stehen aus. Nächste Stufe 0.20: echte Auth-Verbindung und Registrierung erst nach erfolgreich verifiziertem Schema.

## Version 0.19.1 – dokumentiert (09.10.2026)
Übergabeplanung für Annette in `docs/uebergabe-annette.md` aufgenommen und in der Demo-Admin-Ansicht ergänzt. Keine Datenbankänderung, keine echte Auth-Anbindung, kein Infrastrukturtransfer. SQL-Stand 0.19 unverändert: **vorbereitet, nicht ausgeführt**. Nächster technischer Schritt: Supabase-Schema im richtigen Projekt kontrolliert installieren und RLS testen; danach echte Registrierung/Login.


## Stand 0.20 (Auth-Integration vorbereitet)
- Das Supabase-Schema 0.19 wurde vom Benutzer in StaffKeeping ausgeführt; RLS, Policies, RPC-Ausführungsrechte und interne Adminrechte durch SQL-Abfragen überprüft.
- Erster Administrator in sk_internal.staff_admins angelegt.
- 0.20: echte E-Mail/Passwort-Anmeldung, Signup, Bestätigung/Registrierungs-RPC, Session und Admin-Betriebsstatus in JavaScript implementiert. **Live-End-to-End-Test ausstehend; Konfiguration noch leer.**
- Inserate, Nachrichten, Profiländerungen und Bewertungen weiterhin Demo. Original-Projektdokumente noch nicht geschützt online eingebunden.
