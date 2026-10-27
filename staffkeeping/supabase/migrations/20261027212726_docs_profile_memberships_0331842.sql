BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$txt$
## 0.33.1.8.42 – Profilgebundene Mitgliedschaften
Verbindliche Entscheidung: Mitgliedschaft ausschliesslich pro auth.users-Profil, nie automatisch pro Betrieb. Mehrere Betriebe eines Profils können über dieselbe Mitgliedschaft arbeiten, erfordern weiterhin jeweils ausdrückliche Betriebsfreigabe. Bei verlangter separater Mitgliedschaft ist ein separates Benutzerprofil anzulegen. Bestehende historische customer_accounts-Zuordnungen werden nicht automatisch zusammengeführt oder migriert.
Neue Tabellen sk_internal.profile_memberships, profile_manual_access und Audit; RPCs sk_my_membership, sk_admin_profile_memberships, sk_admin_set_profile_manual_access. Keine Zahlungsabbuchungen, kein Stripe-Checkout und keine Abo-Sperre in dieser Version. Tarife administrierbar über bestehende Tarifverwaltung. Manuelle Profilfreigabe unabhängig von Betriebsfreigabe.
$txt$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.8.42 – Profilgebundene Mitgliedschaften' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$txt$
## 0.33.1.8.42 – Prüfstand
Profilmitgliedschaftsgrundlage und Verwaltung manueller Freigaben implementiert, aber SQL-/Browser-/Berechtigungs-Retest offen. Stripe-Schlüssel, Checkout, Webhooks, Rechnung, Kündigung, Vertragsparameter (MWST, Mindestlaufzeit, Aufnahmegebühr) sowie produktive Sperrregeln fehlen und müssen vor Aktivierung vollständig geprüft werden. Bestehende Betriebsfreigaben bleiben manuell, die bisherige Zahlungssperre bleibt ausgeschaltet.
$txt$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.8.42 – Prüfstand' IN body)=0;
COMMIT;
