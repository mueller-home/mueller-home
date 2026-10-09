# Beschlossene Architektur- und Produktentscheidungen

- StaffKeeping ist ausschließlich die App; bestehende Landingpage separat.
- GitHub Pages ist öffentlich erreichbar; geschützte Inhalte erfordern echte Supabase-Berechtigungen.
- Unternehmen registrieren sich selbst und warten auf Adminfreigabe.
- Admin darf Chatverläufe vollständig lesen und gegebenenfalls außerhalb der App eingreifen.
- Keine Ende-zu-Ende- oder zusätzliche Feldverschlüsselung geplant; Standardverschlüsselung, Supabase Auth, serverseitige Berechtigungen und RLS.
- Nur benötigte Stammdaten aus Bubble migrieren; übrige Einträge sind Testdaten.
- Corporate Design aus Migrationskonzept, Hellblau vorläufig `#159FD4`; Original-Logo/Schrift noch offen.
- Styles ausschließlich zentrale CSS-Dateien.
- Projektübergabe und Dokumentation werden mit jedem Release gepflegt.
- ZIP-Regeln gelten verbindlich; `_bubble` bleibt Git-ignoriert.

- **Präzisierung 0.19:** Aus Bubble werden **keinerlei bestehende Unternehmen oder Benutzer** übernommen; neue Daten werden ausschliesslich als frische Testdaten erzeugt. Optionale allgemeine Stammdaten bleiben gesondert zu beurteilen.
- Erstes Schema trennt Unternehmen von `auth.users`; aktive Firma muss von Administrator freigegeben sein.
- Interne Administrator- und Auditdaten im nicht exponierten Schema `sk_internal`. Keine frei wählbaren Admin-Rollen im Frontend.

- **Übergabe an Annette (09.10.2026):** Bestehendes GitHub-Repository, Supabase-Projekt und Postmark-Verwaltung in Annettes Verantwortung übertragen; bisheriger Entwickler bleibt zusätzlicher Admin. Google-Maps-Key ist bereits über Annette eingerichtet. App-Domain und Mail-Absender später auf Annettes Vorgaben umstellen. Transferfähigkeit und Providerrollen erst noch überprüfen; keine Durchführung behaupten.


## 0.20
Kein Magic-Link-Zwang beim Login, sondern E-Mail/Passwort. Registrierungen mit Bestätigung und anschliessendem RPC; Status Ausstehend. Mailversand produktiv mit eigenem SMTP/Postmark; bestehender Administrator über auth.users-ID kontrolliert vergeben.
