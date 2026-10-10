-- StaffKeeping 0.31.1 – OPTIONALE LESENDE Prüfabfrage für private Betriebsmedien.
-- Die Query gibt EIN Resultset zurück und verändert keine Daten.
-- Erkennt nur Dateien in den beiden derzeit verwendeten Betriebsmedien-Buckets.
-- Prüft, ob der erste Pfadteil wie eine UUID aussieht und ob es den Betrieb noch gibt.
-- Wenn die konkrete gelöschte UUID bekannt ist, in WHERE ergänzen und gezielt prüfen.
WITH media AS (
 SELECT o.bucket_id, o.name, split_part(o.name,'/',1) AS business_prefix, o.created_at
 FROM storage.objects o
 WHERE o.bucket_id IN ('sk-business-logos','sk-business-photos')
), checked AS (
 SELECT m.*, CASE WHEN business_prefix ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
   THEN EXISTS (SELECT 1 FROM public.sk_businesses b WHERE b.id::text=m.business_prefix)
   ELSE NULL END AS business_exists
 FROM media m
)
SELECT bucket_id, name, business_prefix, created_at,
 CASE WHEN business_exists THEN 'Betrieb vorhanden'
      WHEN business_exists IS FALSE THEN 'Möglicher verwaister Medienpfad – manuell prüfen'
      ELSE 'Kein UUID-Pfad – manuell prüfen' END AS bewertung
FROM checked
WHERE business_exists IS DISTINCT FROM TRUE
ORDER BY bucket_id,name;
-- 0 Zeilen = keine auffälligen Medienpfade im aktuellen Datenbestand;
-- NICHT ein rückwirkender Beweis für die vollständige Löschung des konkreten Testbetriebs.
