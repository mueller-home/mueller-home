-- 0.33.1.8.4: Dokumentation. Zwei UPDATEs und EIN abschliessender SELECT.
BEGIN;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$d$
## 0.33.1.8.4 – Medien pro Betrieb im Mehrbetriebs-Kontext
«Meine Betriebe» bietet pro zugeordnetem Betrieb den separaten Dialog «Logo & Bilder». Er verwendet die bereits bestehenden, betriebs-ID-bezogenen Supabase-Storage-Methoden und ihre serverseitigen Policies; keine neuen Rechte oder Datenbankfunktionen. Logo: 2 MB, Betriebsbilder 1–5: 5 MB, JPG/PNG/WebP. Upload/Entfernen erfolgt explizit und sofort, unabhängig vom privaten Stammdatenentwurf. Bei eingereichten/gesperrten Betrieben nur lesend. Die alte Profilseite bleibt für Freischaltung, juristische Änderungsanträge, Löschanträge und ihre Altpfade vorläufig vorhanden. Release 0.33.1.8.3: 6/6 Retests bestanden. 0.33.1.8.4: produktiver Medien-Retest ausstehend.
$d$,updated_at=now() WHERE slug='concept' AND position('## 0.33.1.8.4 – Medien pro Betrieb' IN body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n'||$d$
## 0.33.1.8.4 – Status
Medienfunktion in «Meine Betriebe» pro Betriebs-ID aufgenommen; bestehendes Storage-Berechtigungsmodell unverändert. Noch offen: Freischaltungs-Einreichung, sensible Änderungsanträge, Löschanträge in neuen Kontext umführen; Legacy-Live-Auto-Save erst dann entfernen. Testen: Logo, 5 Bilder, Ersetzen, Entfernen, mehrere Betriebe, Rechte bei submitted, altes Profil weiterhin funktionsfähig.
$d$,updated_at=now() WHERE slug='status' AND position('## 0.33.1.8.4 – Status' IN body)=0;
COMMIT;
SELECT slug,updated_at FROM sk_internal.project_doc_chapters WHERE slug IN ('concept','status') ORDER BY slug;
