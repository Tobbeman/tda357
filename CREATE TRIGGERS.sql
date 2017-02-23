CREATE OR REPLACE FUNCTION check_road() RETURNS TRIGGER AS $$

BEGIN

	IF(TG_OP = 'INSERT') THEN
		--Check if another road does not go the other way--
		IF(SELECT EXISTS(SELECT 1 FROM Roads WHERE Roads.fromcountry = NEW.tocountry AND Roads.fromarea = NEW.toarea AND Roads.ownercountry = NEW.ownercountry AND Roads.ownerpersonnumber = NEW.ownerpersonnumber)) THEN
			RAISE EXCEPTION 'Road exists in the reverse direction.'
				USING HINT = '';
		END IF;
		--Check if the player is at the area--
		IF(SELECT EXISTS(SELECT 1 FROM Persons WHERE locationcountry = NEW.fromcountry AND locationarea = NEW.fromarea AND country = NEW.ownercountry AND personnumber = NEW.ownerpersonnumber)) THEN
			RAISE EXCEPTION 'The buyer of the road must be at the area of construction'
				USING HINT = '';
		END IF;
		INSERT INTO Roads VALUES(NEW.fromcountry, NEW.fromarea, NEW.tocountry, NEW.toarea, NEW.ownercountry, NEW.ownerpersonnumber, NEW.roadtax);
		RETURN NEW;
	END IF;

	IF(TG_OP = 'DELETE') THEN
		RAISE EXCEPTION 'DEL, %, %', OLD.tocountry, OLD.toarea; 
		DELETE FROM Roads WHERE Roads.fromcountry = OLD.tocountry AND Roads.fromarea = OLD.toarea AND Roads.ownercountry = OLD.ownercountry AND Roads.ownerpersonnumber = OLD.ownerpersonnumber;
		--DELETE FROM Roads WHERE Roads.fromcountry = OLD.fromcountry AND Roads.fromarea = OLD.fromarea AND Roads.tocountry = OLD.tocountry AND Roads.toarea = OLD.toarea AND Roads.ownercountry = OLD.ownercountry AND Roads.ownerpersonnumber = OLD.ownerpersonnumber;
		RETURN OLD;
	END IF;

END;

$$ LANGUAGE 'plpgsql';

DROP TRIGGER IF EXISTS check_road ON Roads; 
CREATE TRIGGER check_road BEFORE INSERT OR UPDATE OR DELETE ON Roads
    FOR EACH ROW EXECUTE PROCEDURE check_road();
	
------------------------------------------------ PERSON-------------------------------------------------

CREATE OR REPLACE FUNCTION check_person() RETURNS TRIGGER AS $$
DECLARE
	minroadtax integer;
	numHotels integer;
BEGIN
	
	IF(SELECT EXISTS(SELECT ownercountry,ownerpersonnumber FROM Roads 
		WHERE ((fromarea = NEW.locationarea AND fromcountry = NEW.locationcountry) OR (toarea = NEW.locationarea AND tocountry = NEW.locationcountry)) AND (ownercountry = NEW.country AND ownerpersonnumber = NEW.personnumber )))
		THEN
		UPDATE Persons SET locationarea = NEW.locationarea, locationcountry = NEW.locationcountry
				WHERE country = NEW.country AND personnumber = NEW.personnumber;
				RAISE EXCEPTION 'KEkKKKEKEKEKKDKE'
				USING HINT = '';
				RETURN NEW;
	END IF;
	
	IF(SELECT EXISTS(SELECT roadtax INTO minroadtax FROM Roads 
		WHERE  (fromarea = NEW.locationarea AND fromcountry = NEW.locationcountry) OR (toarea = NEW.locationarea AND tocountry = NEW.locationcountry)
		ORDER BY roadtax ASC)LIMIT 1) THEN
			--Travel--
			UPDATE Persons SET locationarea = NEW.locationarea, locationcountry = NEW.locationcountry, budget = budget-getval("KEK")
				WHERE country = NEW.country AND locationarea = NEW.locationarea;
			
			--Check hotel--
			IF(SELECT EXISTS(SELECT COUNT(Hotels.name) INTO numHotels  FROM Hotels
				WHERE locationcountry = NEW.locationcountry AND locationname = NEW.locationarea
				))THEN
				
				
			END IF;
				
	
	END IF;
	

END;

$$ LANGUAGE 'plpgsql';

DROP TRIGGER IF EXISTS check_person ON Persons; 
CREATE TRIGGER check_person BEFORE UPDATE ON Persons
    FOR EACH ROW EXECUTE PROCEDURE check_person();