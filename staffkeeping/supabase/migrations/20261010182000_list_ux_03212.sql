-- StaffKeeping 0.32.1.2 – UI-Regeln eigene Inserate, keine Datenaenderung.
-- 2 UPDATE-Anweisungen in einer Transaktion; danach 1 Kontroll-SELECT.
BEGIN;
UPDATE sk_internal.project_doc_chapters
SET body=body || E'\n\n' || $d$## Inseratsliste: Aktionen, Status und Kommunikation (0.32.1.2)
In Meine Inserate besitzen die drei Symbolaktionen Bearbeiten, Aktivieren/Deaktivieren und dauerhaft Loeschen jeweils einen sichtbaren Mouse-over-Hilfetext (title) und ein barrierearmes aria-label. Symbole sind funktionsbezogen gefaerbt: Bearbeiten blau, Statuswechsel ockerfarben, Loeschen rot; aktiver Inseratsstatus gruen, inaktiver grau. Farben ergaenzen Text und Status, ersetzen sie nicht.
Kommunikationspartner werden in 0.32.1.2 noch NICHT angezeigt. Der bestehende Reiter Als Partner und die Nachrichtenansicht sind noch Demo/Platzhalter. Mit der spaeteren echten Kontakt-/Chat-Funktion sollen Partner pro Inserat mit Betriebsname, Anfrage-/Gespraechsstatus und Link zum Chat sichtbar werden. Datenschutz und RLS vor Implementierung definieren. Keine Demo-Partner als echte Kontakte darstellen.
$d$,updated_at=now()
WHERE slug='concept' AND position('## Inseratsliste: Aktionen, Status und Kommunikation (0.32.1.2)' in body)=0;
UPDATE sk_internal.help_chapters
SET body=body || E'\n\n' || $h$## Aktionen und Status (0.32.1.2)
Unter Meine Inserate: Blaues Stift-Symbol bearbeitet, ockerfarbenes Kreissymbol aktiviert bzw. deaktiviert und rotes X loescht das Inserat nach Bestaetigung. Beim Zeigen mit der Maus erscheint ein Hilfetext. Der Status Aktiv wird gruen, Inaktiv grau angezeigt. Kommunikationspartner und Chats werden erst nach der Anbindung einer echten Antwortfunktion je Inserat sichtbar; momentan kein produktiver Chat.
$h$,updated_at=now()
WHERE page_key='my-listings' AND position('## Aktionen und Status (0.32.1.2)' in body)=0;
COMMIT;
SELECT 'Inseratslisten-UX 0.32.1.2 dokumentiert' AS status;
