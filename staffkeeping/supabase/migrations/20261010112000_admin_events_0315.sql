-- StaffKeeping 0.31.5 – audit field names, historical deletion closure.
-- Creates/updates functions; no standalone SELECT result sets.
BEGIN;
CREATE OR REPLACE FUNCTION sk_internal.log_profile_changes()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $fn$
DECLARE profile_fields text[]:=ARRAY[]::text[];
        location_fields text[]:=ARRAY[]::text[];
BEGIN
 IF OLD.status <> 'Freigeschaltet' OR NEW.status <> 'Freigeschaltet' THEN RETURN NEW; END IF;
 IF OLD.industry IS DISTINCT FROM NEW.industry THEN profile_fields:=array_append(profile_fields,'Branche'); END IF;
 IF OLD.postal_code IS DISTINCT FROM NEW.postal_code THEN location_fields:=array_append(location_fields,'PLZ'); END IF;
 IF OLD.city IS DISTINCT FROM NEW.city THEN location_fields:=array_append(location_fields,'Ort'); END IF;
 IF OLD.contact_name IS DISTINCT FROM NEW.contact_name THEN profile_fields:=array_append(profile_fields,'Ansprechpartner'); END IF;
 IF OLD.contact_email IS DISTINCT FROM NEW.contact_email THEN profile_fields:=array_append(profile_fields,'Kontakt-E-Mail'); END IF;
 IF OLD.contact_phone IS DISTINCT FROM NEW.contact_phone THEN profile_fields:=array_append(profile_fields,'Telefon'); END IF;
 IF OLD.description IS DISTINCT FROM NEW.description THEN profile_fields:=array_append(profile_fields,'Beschreibung'); END IF;
 IF OLD.email_notifications_enabled IS DISTINCT FROM NEW.email_notifications_enabled THEN profile_fields:=array_append(profile_fields,'Benachrichtigungseinstellung'); END IF;
 IF OLD.show_street_address IS DISTINCT FROM NEW.show_street_address THEN profile_fields:=array_append(profile_fields,'Sichtbarkeit Strassenadresse'); END IF;
 IF OLD.street IS DISTINCT FROM NEW.street THEN location_fields:=array_append(location_fields,'Strasse'); END IF;
 IF OLD.house_number IS DISTINCT FROM NEW.house_number THEN location_fields:=array_append(location_fields,'Hausnummer'); END IF;
 IF OLD.address_extra IS DISTINCT FROM NEW.address_extra THEN location_fields:=array_append(location_fields,'Adresszusatz'); END IF;
 IF OLD.latitude IS DISTINCT FROM NEW.latitude OR OLD.longitude IS DISTINCT FROM NEW.longitude THEN location_fields:=array_append(location_fields,'Kartenposition'); END IF;
 IF OLD.location_source IS DISTINCT FROM NEW.location_source THEN location_fields:=array_append(location_fields,'Art der Standortermittlung'); END IF;
 IF cardinality(profile_fields)>0 THEN
  INSERT INTO sk_internal.admin_events(business_id,kind,title,detail)
  VALUES(NEW.id,'profile_changed','Profilangaben geändert',array_to_string(profile_fields,', '));
 END IF;
 IF cardinality(location_fields)>0 THEN
  INSERT INTO sk_internal.admin_events(business_id,kind,title,detail)
  VALUES(NEW.id,'location_changed','Standortangaben geändert',array_to_string(location_fields,', '));
 END IF;
 RETURN NEW;
END;$fn$;
-- Any deletion alert tied to a still-existing business is resolved only if the
-- associated deletion request was explicitly completed. Fully deleted businesses
-- cascade their admin_events automatically via the existing foreign key.
UPDATE sk_internal.admin_events e
SET resolved_at=COALESCE(r.finished_at,now()), resolved_by=r.approved_by
FROM sk_internal.business_deletion_requests r
WHERE e.business_id=r.business_id AND e.kind='deletion_requested'
  AND e.resolved_at IS NULL AND r.status='completed';
-- No replacement of sk_deletion_complete(): the existing ON DELETE CASCADE on
-- admin_events removes these notifications with their business automatically.
COMMIT;
