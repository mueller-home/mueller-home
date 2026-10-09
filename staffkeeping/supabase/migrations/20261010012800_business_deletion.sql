-- StaffKeeping 0.31: kontrollierter Datenlebenszyklus, Löschanträge und Datenschutz-Handbuch
-- Voraussetzung: alle Migrationen bis einschliesslich 0.30
-- Eine Transaktion; mehrere DDL/DML/CREATE FUNCTION, keine separaten SELECT-Resultsets.
-- Ausführung durch SQL-Editor als privilegierter DB-Operator.
BEGIN;
CREATE TABLE IF NOT EXISTS sk_internal.business_deletion_requests (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 business_id uuid REFERENCES public.sk_businesses(id) ON DELETE SET NULL,
 business_name text NOT NULL,
 requested_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
 request_type text NOT NULL CHECK(request_type IN ('owner','admin_exception')),
 reason text NOT NULL DEFAULT '',
 status text NOT NULL DEFAULT 'requested' CHECK(status IN ('requested','approved','processing','database_removed','completed','failed','cancelled')),
 approved_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
 approved_at timestamptz,
 auth_user_ids uuid[] NOT NULL DEFAULT '{}',
 processing_at timestamptz,
 error_detail text,
 created_at timestamptz NOT NULL DEFAULT now(),
 finished_at timestamptz
);
CREATE UNIQUE INDEX IF NOT EXISTS sk_deletion_one_active_per_business
 ON sk_internal.business_deletion_requests(business_id)
 WHERE status IN ('requested','approved','processing','database_removed','failed');
REVOKE ALL ON sk_internal.business_deletion_requests FROM PUBLIC,anon,authenticated;

CREATE OR REPLACE FUNCTION public.sk_request_my_business_deletion(p_confirm_name text,p_reason text DEFAULT '')
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE b public.sk_businesses%ROWTYPE; v_id uuid; v_fast boolean;
BEGIN
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Anmeldung erforderlich' USING ERRCODE='42501'; END IF;
 SELECT x.* INTO b FROM public.sk_businesses x JOIN public.sk_business_members m ON m.business_id=x.id
 WHERE m.user_id=auth.uid() AND m.role='owner'::public.sk_member_role FOR UPDATE OF x;
 IF NOT FOUND THEN RAISE EXCEPTION 'Nur der Firmeninhaber darf die Löschung beantragen' USING ERRCODE='42501'; END IF;
 IF btrim(coalesce(p_confirm_name,'')) IS DISTINCT FROM b.company_name THEN RAISE EXCEPTION 'Firmenname zur Bestätigung stimmt nicht überein' USING ERRCODE='22023'; END IF;
 IF EXISTS(SELECT 1 FROM sk_internal.staff_admins WHERE user_id=auth.uid()) THEN RAISE EXCEPTION 'Administratorkonten dürfen nicht über eine Betriebslöschung entfernt werden' USING ERRCODE='42501'; END IF;
 IF EXISTS(SELECT 1 FROM sk_internal.business_deletion_requests WHERE business_id=b.id AND status IN ('requested','approved','processing','database_removed','failed')) THEN
  RAISE EXCEPTION 'Es gibt bereits einen offenen Löschvorgang'; END IF;
 -- Eine nicht eingereichte Registrierung darf unmittelbar durch den Eigentümer beendet werden.
 v_fast:=b.status='Ausstehend' AND b.review_state IN ('draft','changes_requested');
 INSERT INTO sk_internal.business_deletion_requests(business_id,business_name,requested_by,request_type,reason,status,approved_at)
 VALUES(b.id,b.company_name,auth.uid(),'owner',left(btrim(coalesce(p_reason,'')),2000),CASE WHEN v_fast THEN 'approved' ELSE 'requested' END,
 CASE WHEN v_fast THEN now() ELSE NULL END) RETURNING id INTO v_id;
 IF v_fast THEN UPDATE public.sk_businesses SET status='Gesperrt',updated_at=now() WHERE id=b.id; END IF;
 INSERT INTO sk_internal.admin_events(business_id,kind,title,detail)
 VALUES(b.id,'deletion_requested','Löschung beantragt',CASE WHEN v_fast THEN 'Registrierung abgebrochen' ELSE 'Freigegebener Betrieb: Admin-Prüfung erforderlich' END);
 RETURN jsonb_build_object('id',v_id,'status',CASE WHEN v_fast THEN 'approved' ELSE 'requested' END,'immediate',v_fast);
END;$fn$;

CREATE OR REPLACE FUNCTION public.sk_admin_request_exceptional_deletion(p_business_id uuid,p_confirm_name text,p_reason text)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE b public.sk_businesses%ROWTYPE; v_id uuid;
BEGIN
 IF NOT public.sk_is_admin() THEN RAISE EXCEPTION 'Nur Administratoren' USING ERRCODE='42501'; END IF;
 SELECT * INTO b FROM public.sk_businesses WHERE id=p_business_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Betrieb nicht gefunden'; END IF;
 -- Ein jemals freigegebener Betrieb ist KEIN einfacher Ausnahmelöschfall.
 IF b.status='Freigeschaltet' OR b.review_state='approved' OR b.reviewed_at IS NOT NULL THEN
  RAISE EXCEPTION 'Bereits freigegebene Betriebe nur auf Löschantrag des Eigentümers entfernen' USING ERRCODE='42501'; END IF;
 IF btrim(coalesce(p_confirm_name,'')) IS DISTINCT FROM b.company_name THEN RAISE EXCEPTION 'Betriebsname stimmt nicht überein'; END IF;
 IF char_length(btrim(coalesce(p_reason,'')))<12 THEN RAISE EXCEPTION 'Begründung mit mindestens 12 Zeichen erforderlich'; END IF;
 IF EXISTS(SELECT 1 FROM sk_internal.business_deletion_requests WHERE business_id=b.id AND status IN ('requested','approved','processing','database_removed','failed')) THEN
  RAISE EXCEPTION 'Bereits offener Löschvorgang'; END IF;
 IF EXISTS(SELECT 1 FROM public.sk_business_members m JOIN sk_internal.staff_admins a ON a.user_id=m.user_id WHERE m.business_id=b.id) THEN
  RAISE EXCEPTION 'Ein Administratorkonto ist mit diesem Betrieb verknüpft' USING ERRCODE='42501'; END IF;
 INSERT INTO sk_internal.business_deletion_requests(business_id,business_name,requested_by,request_type,reason,status,approved_by,approved_at)
 VALUES(b.id,b.company_name,auth.uid(),'admin_exception',left(p_reason,2000),'approved',auth.uid(),now()) RETURNING id INTO v_id;
 UPDATE public.sk_businesses SET status='Gesperrt',updated_at=now() WHERE id=b.id;
 RETURN v_id;
END;$fn$;

CREATE OR REPLACE FUNCTION public.sk_admin_decide_deletion(p_request_id uuid,p_approve boolean,p_reason text DEFAULT '')
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE r sk_internal.business_deletion_requests%ROWTYPE;
BEGIN
 IF NOT public.sk_is_admin() THEN RAISE EXCEPTION 'Nur Administratoren' USING ERRCODE='42501'; END IF;
 SELECT * INTO r FROM sk_internal.business_deletion_requests WHERE id=p_request_id AND status='requested' FOR UPDATE;
 IF NOT FOUND OR r.request_type<>'owner' THEN RAISE EXCEPTION 'Kein offener Eigentümer-Löschantrag'; END IF;
 IF p_approve THEN
  UPDATE sk_internal.business_deletion_requests SET status='approved',approved_by=auth.uid(),approved_at=now() WHERE id=r.id;
  UPDATE public.sk_businesses SET status='Gesperrt',updated_at=now() WHERE id=r.business_id;
 ELSE
  IF length(btrim(coalesce(p_reason,'')))<5 THEN RAISE EXCEPTION 'Begründung für Rückfrage/Ablehnung erforderlich'; END IF;
  UPDATE sk_internal.business_deletion_requests SET status='cancelled',reason=left(coalesce(reason,'')||E'\nAdmin-Rückmeldung: '||p_reason,2000),finished_at=now(),approved_by=auth.uid() WHERE id=r.id;
 END IF;
END;$fn$;

CREATE OR REPLACE FUNCTION public.sk_my_business_deletion_status() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $fn$
DECLARE v_id uuid;
BEGIN
 SELECT business_id INTO v_id FROM public.sk_business_members WHERE user_id=auth.uid() AND role='owner'::public.sk_member_role;
 IF v_id IS NULL THEN RETURN NULL; END IF;
 RETURN (SELECT jsonb_build_object('id',id,'status',status,'created_at',created_at,'request_type',request_type)
 FROM sk_internal.business_deletion_requests WHERE business_id=v_id ORDER BY created_at DESC LIMIT 1);
END;$fn$;

CREATE OR REPLACE FUNCTION public.sk_admin_deletion_queue() RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $fn$
BEGIN
 IF NOT public.sk_is_admin() THEN RAISE EXCEPTION 'Nur Administratoren' USING ERRCODE='42501'; END IF;
 RETURN coalesce((SELECT jsonb_agg(jsonb_build_object('id',r.id,'business_id',r.business_id,'business_name',r.business_name,
 'status',r.status,'request_type',r.request_type,'reason',r.reason,'created_at',r.created_at,'error_detail',r.error_detail)
 ORDER BY r.created_at DESC) FROM (SELECT * FROM sk_internal.business_deletion_requests ORDER BY created_at DESC LIMIT 100)r),'[]'::jsonb);
END;$fn$;

CREATE OR REPLACE FUNCTION public.sk_can_execute_business_deletion(p_request_id uuid) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $fn$
 SELECT EXISTS(SELECT 1 FROM sk_internal.business_deletion_requests r
 LEFT JOIN public.sk_business_members m ON m.business_id=r.business_id AND m.user_id=auth.uid() AND m.role='owner'::public.sk_member_role
 WHERE r.id=p_request_id AND r.status IN ('approved','processing','failed','database_removed')
 AND (public.sk_is_admin() OR (r.request_type='owner' AND r.approved_by IS NULL AND m.user_id IS NOT NULL)));
$fn$;

-- Die folgenden 4 RPCs dürfen AUSSCHLIESSLICH vom Edge-Function-Service-Role-Key ausgeführt werden.
CREATE OR REPLACE FUNCTION public.sk_deletion_prepare(p_request_id uuid) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE r sk_internal.business_deletion_requests%ROWTYPE; v_users uuid[];
BEGIN
 IF auth.role()<>'service_role' THEN RAISE EXCEPTION 'Nur Backend-Service' USING ERRCODE='42501'; END IF;
 SELECT * INTO r FROM sk_internal.business_deletion_requests WHERE id=p_request_id FOR UPDATE;
 IF NOT FOUND OR r.status NOT IN ('approved','failed','processing','database_removed') THEN RAISE EXCEPTION 'Löschauftrag nicht ausführbar'; END IF;
 IF r.status='processing' AND r.processing_at>now()-interval '5 minutes' THEN RAISE EXCEPTION 'Löschvorgang läuft bereits'; END IF;
 IF r.status='database_removed' THEN RETURN jsonb_build_object('stage','database_removed','business_id',NULL,'users',r.auth_user_ids); END IF;
 IF r.business_id IS NULL THEN RAISE EXCEPTION 'Datenbankstand inkonsistent'; END IF;
 SELECT coalesce(array_agg(m.user_id),'{}'::uuid[]) INTO v_users FROM public.sk_business_members m WHERE m.business_id=r.business_id;
 IF EXISTS(SELECT 1 FROM unnest(v_users) AS member_ids(user_id) JOIN sk_internal.staff_admins a ON a.user_id=member_ids.user_id) THEN
  RAISE EXCEPTION 'Administratorkonto darf nicht gelöscht werden' USING ERRCODE='42501'; END IF;
 UPDATE sk_internal.business_deletion_requests SET status='processing',processing_at=now(),auth_user_ids=v_users,error_detail=NULL WHERE id=r.id;
 UPDATE public.sk_businesses SET status='Gesperrt' WHERE id=r.business_id;
 RETURN jsonb_build_object('stage','processing','business_id',r.business_id,'users',v_users);
END;$fn$;

CREATE OR REPLACE FUNCTION public.sk_deletion_remove_database(p_request_id uuid) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE r sk_internal.business_deletion_requests%ROWTYPE;
BEGIN
 IF auth.role()<>'service_role' THEN RAISE EXCEPTION 'Nur Backend-Service' USING ERRCODE='42501'; END IF;
 SELECT * INTO r FROM sk_internal.business_deletion_requests WHERE id=p_request_id AND status='processing' FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Löschvorgang nicht vorbereitet'; END IF;
 DELETE FROM public.sk_businesses WHERE id=r.business_id;
 UPDATE sk_internal.business_deletion_requests SET status='database_removed',processing_at=now() WHERE id=r.id;
END;$fn$;

CREATE OR REPLACE FUNCTION public.sk_deletion_complete(p_request_id uuid) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
BEGIN
 IF auth.role()<>'service_role' THEN RAISE EXCEPTION 'Nur Backend-Service' USING ERRCODE='42501'; END IF;
 UPDATE sk_internal.business_deletion_requests SET status='completed',finished_at=now(),processing_at=NULL,error_detail=NULL,
 business_name='Gelöschter Betrieb',reason='',auth_user_ids='{}'::uuid[]
 WHERE id=p_request_id AND status='database_removed';
 IF NOT FOUND THEN RAISE EXCEPTION 'Löschung nicht vollständig'; END IF;
END;$fn$;

CREATE OR REPLACE FUNCTION public.sk_deletion_failed(p_request_id uuid,p_error text) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
BEGIN
 IF auth.role()<>'service_role' THEN RAISE EXCEPTION 'Nur Backend-Service' USING ERRCODE='42501'; END IF;
 UPDATE sk_internal.business_deletion_requests SET
 status=CASE WHEN status='database_removed' THEN 'database_removed' ELSE 'failed' END,
 processing_at=NULL,error_detail=left(p_error,400) WHERE id=p_request_id AND status IN ('processing','database_removed');
END;$fn$;

REVOKE ALL ON FUNCTION public.sk_deletion_prepare(uuid),public.sk_deletion_remove_database(uuid),public.sk_deletion_complete(uuid),public.sk_deletion_failed(uuid,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.sk_deletion_prepare(uuid),public.sk_deletion_remove_database(uuid),public.sk_deletion_complete(uuid),public.sk_deletion_failed(uuid,text) TO service_role;
GRANT EXECUTE ON FUNCTION public.sk_request_my_business_deletion(text,text),public.sk_my_business_deletion_status(),public.sk_can_execute_business_deletion(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.sk_admin_request_exceptional_deletion(uuid,text,text),public.sk_admin_decide_deletion(uuid,boolean,text),public.sk_admin_deletion_queue() TO authenticated;


-- Laufende Löschanträge dürfen nicht versehentlich durch Admin-Freigabe reaktiviert werden.
CREATE OR REPLACE FUNCTION sk_internal.block_deleting_business_reactivation() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
BEGIN
 IF NEW.status='Freigeschaltet' AND OLD.status IS DISTINCT FROM NEW.status AND
 EXISTS(SELECT 1 FROM sk_internal.business_deletion_requests r WHERE r.business_id=OLD.id
 AND r.status IN ('requested','approved','processing','database_removed','failed')) THEN
  RAISE EXCEPTION 'Offener Löschvorgang: Betrieb darf nicht freigeschaltet werden' USING ERRCODE='42501';
 END IF;
 RETURN NEW;
END;$fn$;
DROP TRIGGER IF EXISTS sk_deletion_block_reactivation ON public.sk_businesses;
CREATE TRIGGER sk_deletion_block_reactivation BEFORE UPDATE OF status ON public.sk_businesses
FOR EACH ROW EXECUTE FUNCTION sk_internal.block_deleting_business_reactivation();

-- Bestehende EINZIGE zentrale Projektdoku: gezielt Kapitel ergänzen, nicht überschreiben.
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n## 0.31 · Betriebslöschung und Datenlebenszyklus [SK-031]\n\n| Fall | Berechtigung | Vorgehen |\n|---|---|---|\n| Betrieb sperren | Admin | Zugang deaktivieren, Daten erhalten |\n| Registrierungsentwurf abbrechen | Inhaber | Bestätigen, kontrolliert löschen |\n| Aktiver Betrieb möchte löschen | Inhaber beantragt, Admin prüft | Sperren, offene Vorgänge prüfen, Löschlauf starten |\n| Admin-Ausnahmefall | Admin, nur nie freigegebenes Konto | Begründung und Namensbestätigung |\n| Freigegebener Betrieb ohne Eigentümerantrag | Admin | Sperren, nicht direkt löschen |\n\nDie ausführende Edge Function entfernt private Medien aus beiden Buckets, danach Betriebsdatensätze und verknüpfte Auth-Benutzer. Zwischen Schritten sind Wiederholungen möglich; Status und Fehler werden intern protokolliert; nach Abschluss werden Name, Begründung und Benutzer-IDs aus dem Löschprotokoll entfernt. Gemeinsame produktive Nachrichten, Inserate, Bewertungen und rechtliche Aufbewahrungsfristen müssen VOR Einführung dieser Module in die Löschprüfung einbezogen werden.\n' ,updated_at=now()
WHERE slug='concept' AND position('[SK-031]' in body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n## 0.31 · Abnahme Löschfunktionen [SK-031]\n\n| Test | Erwartung | Status |\n|---|---|---|\n| Entwurf durch Inhaber löschen | Profil, Medien, Auth entfernt | Zu testen |\n| Aktiven Betrieb löschen beantragen | Admin-Prüfung erforderlich | Zu testen |\n| Admin löscht freigegebenen Betrieb ohne Antrag | Verboten | Zu testen |\n| Admin löscht nie freigegebenen Testbetrieb | Nur mit Grund und Bestätigung | Zu testen |\n| Abbruch im Löschprozess | Erneuter Lauf ohne Datenverlust anderer Firmen | Zu testen |\n| Fremde Rollen / RPC | Zugriff verweigert | Zu testen |\n| Admin sieht Löschanträge | Liste und Entscheidung | Zu testen |\n' ,updated_at=now()
WHERE slug='tests' AND position('[SK-031]' in body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n## 0.31 [SK-031]\nBetriebsdaten-Lebenszyklus: Löschanträge, adminseitige Prüfung, Ausnahmebehandlung nie freigegebener Registrierungen, Edge Function für Storage/DB/Auth, internes Protokoll. Implementiert, Live-Abnahme ausstehend.\n',updated_at=now()
WHERE slug='history' AND position('[SK-031]' in body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n## 0.31 · Offene Punkte [SK-031]\n- Löschablauf mit zweitem Betrieb und Auth-/Medienberechtigungen live testen.\n- Vor Einführung echter Inserate, Nachrichten, Zahlungen oder Bewertungen deren Referenzen, Aufbewahrungs- und Anonymisierungsregeln in der Löschroutine ergänzen.\n- Prüfen, wie bereits vorhandene Admin-Auditdaten datensparsam archiviert werden.\n',updated_at=now()
WHERE slug='issues' AND position('[SK-031]' in body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n## 0.31 · Datenschutzstatus [SK-031]\nLöschprozess implementiert. Supabase-Migration, Edge-Function-Deployment und Ende-zu-Ende-Abnahme stehen aus. Keine produktive Löschung vor erfolgreichem Test aller Stufen.\n',updated_at=now()
WHERE slug='status' AND position('[SK-031]' in body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n## 0.31 · Verbindliche Löschregeln [SK-031]\nLöschfunktionen ausschliesslich über überprüfte RPCs und die Edge Function; kein Browser-Direkt-DELETE. Admins sperren aktive Unternehmen, endgültige Löschung grundsätzlich nur nach Inhaberauftrag. Abweichung nur für nie freigegebene Fehl-/Testregistrierung nach überprüfter Begründung. Löschen ist kein Auto-Save-Vorgang. Migrationen niemals löschen. Bei künftig neuen Datentypen Löschpfad und Handbuch zwingend aktualisieren.\n',updated_at=now()
WHERE slug='rules' AND position('[SK-031]' in body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n## 0.31 · Entscheidung [SK-031]\nDie Sperrfunktion bleibt von endgültiger Löschung getrennt. Admin kann freigegebene Betriebe nicht ohne Inhaberauftrag löschen. Der Inhaber kann seine Registrierung abbrechen; aktive Betriebe stellen einen geprüften Löschantrag. Ausführung sperrt den Betrieb, entfernt Medien und persönliche Datensätze und löscht zugeordnete Auth-Konten; gemeinsame Fremddaten sind später gesondert zu prüfen.\n',updated_at=now()
WHERE slug='decisions' AND position('[SK-031]' in body)=0;
UPDATE sk_internal.project_doc_chapters SET body=body||E'\n\n## 0.31 · Übergabehinweis [SK-031]\nDie Edge Function `sk-delete-business` muss im Supabase-Projekt bereitgestellt werden. Service-Role-Key bleibt ausschliesslich serverseitig; API-Test vor produktiver Nutzung. Löschanträge in sk_internal.business_deletion_requests.\n',updated_at=now()
WHERE slug='handoff' AND position('[SK-031]' in body)=0;

-- Handbuch direkt in der App – bestehende Kapitel erweitern, keine Parallelkopien.
UPDATE sk_internal.help_chapters SET body=body||E'\n\n## Konto und Daten löschen [SK-031]\n\nUnter **Profil → Konto & Datenschutz** kann der Firmeninhaber die Löschung seines Unternehmens beantragen. Gib zur Bestätigung den genauen Firmennamen ein.\n\n| Situation | Was passiert? |\n|---|---|\n| Registrierung noch nicht eingereicht | Konto und Registrierung können direkt gelöscht werden |\n| Profil in Prüfung oder Betrieb bereits aktiv | Der Administrator prüft den Löschantrag |\n| Löschung genehmigt | Betrieb gesperrt, Bilder und Konto werden kontrolliert gelöscht |\n| Löschvorgang fehlschlägt | Der Vorgang bleibt sichtbar und kann erneut ausgeführt werden |\n\n**Achtung:** Die endgültige Löschung kann nicht rückgängig gemacht werden.\n\n![Screenshot: Konto und Datenschutz](screenshot:profil-datenschutz-01)\n',updated_at=now()
WHERE slug='profile' AND position('[SK-031]' in body)=0;
UPDATE sk_internal.help_chapters SET body=body||E'\n\n## Löschanträge und Ausnahmelöschung [SK-031]\n\nUnter **Admin → Datenschutz** kannst du Löschanträge prüfen und nach einer Bestätigung ausführen.\n\n| Fall | Admin-Aktion |\n|---|---|\n| Betrieb sperren | Zugang unter Betriebe deaktivieren |\n| Eigentümer möchte Konto löschen | Antrag prüfen, genehmigen oder zurückweisen |\n| Nie freigegebener Test-/Fehlbetrieb | Begründete Ausnahmelöschung möglich |\n| Bereits freigegebener Betrieb ohne Löschauftrag | Keine Sofortlöschung |\n\n**Vor Löschung:** Prüfe offene Geschäftsvorgänge und gesetzliche Aufbewahrungspflichten. Aktuelle Inserate/Chats sind noch Demo; spätere produktive Module müssen eigene Löschregeln erhalten.\n\n![Screenshot: Admin Datenschutz](screenshot:admin-datenschutz-01)\n',updated_at=now()
WHERE slug='admin-review' AND position('[SK-031]' in body)=0;
COMMIT;
