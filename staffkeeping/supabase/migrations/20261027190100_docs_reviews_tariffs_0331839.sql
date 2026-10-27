-- StaffKeeping 0.33.1.8.39: Projektdokumentation und Benutzerhandbuch.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$doc$
## 0.33.1.8.39 – Mehrkriterienbewertungen und Tarifvorlagen
Bewertungen: Nach beidseitig bestätigtem Abschluss drei Kriterien (Kommunikation, Zuverlässigkeit, Zusammenarbeit; je 1–5). Gesamtbewertung als gerundeter Mittelwert in bestehendem Sternefeld. Historische Einzel-Stern-Bewertungen bleiben ohne Kriterienwerte erhalten. Kommentare freiwillig. Sichtbarkeit entsprechend bisherigem 14-Tage-/Gegenbewertungsmodell; die Betriebsreputation ist für freigeschaltete Mitglieder im Inseratdetail ab drei öffentlich sichtbaren Bewertungen sichtbar; die Moderation bleibt offen.
Administration: Neue Ansicht «Tarife und Preise» für Administratoren; Classic, Flex und einmalige Aufnahmegebühr in CHF bearbeitbar. Speicherung in sk_internal.subscription_tariffs, jede tatsächliche Preisänderung in subscription_tariff_audit. Keine rückwirkende Vertragsänderung, da noch keine echten Verträge angelegt werden. Preisvorlagen sind keine Kauf-, Rechnung-, Stripe- oder Abo-Sperrfunktion. Stripe, Steuer-/Vertragsregeln und produktiver Zahlungseinzug sind offene, gesondert abzusichernde Entwicklungsblöcke.
$doc$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.8.39 – Mehrkriterienbewertungen' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$doc$
## 0.33.1.8.39 – Prüfstand
Neue Bewertungs-RPC und Admin-Tarif-RPC implementiert, aber produktive Migration und Browser-/Berechtigungs-Retests offen. Handbuch aktualisiert, sofern passende vorhandene Kapitel vorhanden sind. Echte Abo-Käufe, Dashboard-Aboanzeige, Rechnungen, Kündigungen, Webhooks, E-Mail-Automatisierung und Abo-Sperre weiterhin offen. Keine Zahlungsaktivierung in dieser Version.
$doc$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.8.39 – Prüfstand' IN body)=0;
UPDATE sk_internal.help_chapters SET body=$help$
# Bewertungen

## Zusammenarbeit nach drei Kriterien bewerten
Nach dem von beiden Betrieben bestätigten Abschluss findest du unter «Bewertungen» offene Bewertungen. Beurteile Kommunikation, Zuverlässigkeit und Zusammenarbeit jeweils mit 1–5 Sternen. Ein Kommentar ist freiwillig. StaffKeeping berechnet automatisch die Gesamtbewertung. Bestehende ältere Gesamtbewertungen bleiben als solche gekennzeichnet. Die Bewertung der Gegenseite wird nach deren Abgabe oder spätestens 14 Tage nach Abschluss sichtbar.
$help$,updated_at=now()
WHERE (lower(coalesce(page_key,'')) LIKE '%review%' OR lower(coalesce(page_key,'')) LIKE '%bewert%')
 AND position('## Zusammenarbeit nach drei Kriterien bewerten' IN body)=0;
INSERT INTO sk_internal.help_chapters(slug,title,body,section,page_key,audience,status,position)
VALUES('admin-pricing-help','Tarife und Preise',
$help$# Tarife und Preise

Unter **Administration → Tarife und Preise** können Administratoren die Preisvorlagen für **Classic**, **Flex** und die einmalige **Aufnahmegebühr** in CHF bearbeiten. Nach «Speichern» ist der neue Preis hinterlegt; jede Änderung wird protokolliert. Bei einem späteren produktiven Abo-Kauf muss der zu diesem Zeitpunkt gültige Preis verbindlich zum Vertrag gespeichert werden. Frühere Verträge werden nicht automatisch umgestellt.

**Wichtig:** Online-Kauf, Rechnungen, Zahlungen und Abo-Sperren sind in dieser Version noch nicht aktiv.$help$,
'Administration','admin-pricing','admin','published',105)
ON CONFLICT(slug) DO UPDATE SET body=EXCLUDED.body,title=EXCLUDED.title,status=EXCLUDED.status,updated_at=now();
COMMIT;
