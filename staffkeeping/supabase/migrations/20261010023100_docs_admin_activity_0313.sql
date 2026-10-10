-- StaffKeeping 0.31.3 – ausschliesslich die vorhandene zentrale Doku/Handbuch ergänzen.
-- Transaktion mit UPDATEs; keine SELECT-Resultsets.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $doc$
## Admin-Cockpit 0.31.3: Entscheidungsaufgaben und Informationen

| Ereignis | Behandlung |
|---|---|
| Registrierung eingereicht | Admin-Freigabe oder Nachbesserung erforderlich |
| Änderung Firmenname, Land, USt-ID | Gesonderter Änderungsantrag, Admin-Entscheidung |
| Löschantrag | Im Datenschutzbereich entscheiden; niemals über Sammelaktion erledigen |
| Adresse/Standort geändert | Information; darf als gelesen markiert werden |
| Kontakt/Profil geändert | Information; darf als gelesen markiert werden |
| Logo/Bilder geändert | Information; darf als gelesen markiert werden |

Die RPC `sk_admin_resolve_normal_events()` verarbeitet nur `profile_changed`, `location_changed`, `media_changed`. `sk_admin_resolve_event()` ist ebenfalls auf diese Ereignisse beschränkt. Die Datenbankabfrage liefert den Firmennamen mit; bei gelöschtem Betrieb steht ein eindeutiger Hinweis. Mehrere gleichartige Meldungen innerhalb von fünf Minuten werden nur in der Oberfläche gruppiert, der zugrunde liegende Auditverlauf bleibt erhalten. Dashboard-Zähler: offene Informationsmeldungen statt sämtlicher Prüfaufträge. Zugangsstatus und Registrierungsprüfung bleiben in der Betriebsliste getrennte Spalten. Ein historisches Freigabedatum wird nur aus tatsächlich vorhandenen `business_status_audit`-Einträgen übernommen, sonst weiterhin „Datum nicht erfasst“.
$doc$,updated_at=now() WHERE slug='concept' AND position('## Admin-Cockpit 0.31.3:' in body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $doc$
## StaffKeeping 0.31.3

Admin-Dashboard: Prüfaufträge von Informationsmeldungen getrennt, Firmenname sichtbar, normale Ereignisse einzeln oder gesammelt als gelesen markierbar, protokollierte Informationen nur visuell gruppiert. Betriebsliste: „Zugangsstatus“ und „Registrierungsprüfung“. Migration ergänzt bestehende RPCs und Administratorfunktionen; echte historische Freigabezeiten werden nur bei vorhandenen Audit-Einträgen übernommen. Browser-/RLS-Livetests noch offen.
$doc$,updated_at=now() WHERE slug='history' AND position('## StaffKeeping 0.31.3' in body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body || E'\n\n' || $doc$
## Zu testen: Dashboard 0.31.3

1. Informationsmeldung enthält Betrieb und richtigen Zeitpunkt.
2. Gleichartige Meldungen desselben Betriebs innerhalb von fünf Minuten erscheinen gruppiert; Aktivitätenprotokoll bleibt vollständig.
3. „Alle Aktivitäten als gelesen markieren“ quittiert nur Profil-/Medien-/Standortmeldungen.
4. Eingereichte Registrierung, Lösch- und Änderungsantrag bleiben nach Sammelaktion offen.
5. RPCs verweigern Nicht-Admins Zugriff; Einzelquittierung kann keinen Prüfauftrag schliessen.
6. Verwaister/gelöschter Betrieb zeigt keine falsche Öffnen-Aktion.
7. Alte Freigaben ohne echten Prüfzeitpunkt zeigen weiterhin „Datum nicht erfasst“.
$doc$,updated_at=now() WHERE slug='tests' AND position('## Zu testen: Dashboard 0.31.3' in body)=0;
UPDATE sk_internal.help_chapters SET body=body || E'\n\n' || $doc$
## Admin-Dashboard: Prüfen oder nur lesen?

| Was ist passiert? | Aktion |
|---|---|
| Neue Registrierung | Betrieb prüfen und entscheiden |
| Firmenname, Land oder USt-ID beantragt | Änderungsantrag genehmigen oder ablehnen |
| Betrieb beantragt Löschung | In **Datenschutz** bearbeiten |
| Profil, Standort oder Medien geändert | Zur Kenntnis nehmen oder als gelesen markieren |

Der Button **„Alle Aktivitäten als gelesen markieren“** betrifft ausschliesslich die normalen Informationen. Er kann weder Registrierungen noch Änderungs- oder Löschanträge erledigen. Jede Meldung zeigt ihren Betrieb, soweit dieser noch existiert.

![Admin-Dashboard mit Aktivitäten und Prüfaufträgen](screenshot:admin-dashboard-aktivitaeten-01)
$doc$,updated_at=now() WHERE page_key IN ('admin-home','admin-activity') AND position('## Admin-Dashboard: Prüfen oder nur lesen?' in body)=0;
UPDATE sk_internal.help_chapters SET body=body || E'\n\n' || $doc$
## Zugangsstatus und Registrierungsprüfung

| Anzeige | Bedeutung |
|---|---|
| Zugangsstatus | Ob der Betrieb aktuell Zugang zum Marktplatz hat |
| Registrierungsprüfung | Ob der Antrag im Entwurf, eingereicht, zur Nachbesserung oder freigegeben ist |

Beide Spalten bleiben sichtbar. Der Prüfzeitpunkt wird nur angezeigt, wenn er tatsächlich erfasst ist.
$doc$,updated_at=now() WHERE page_key='admin-businesses' AND position('## Zugangsstatus und Registrierungsprüfung' in body)=0;
COMMIT;
