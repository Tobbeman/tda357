CREATE OR REPLACE FUNCTION check_road() RETURNS TRIGGER AS $$

BEGIN

	IF(TG_OP = 'INSERT') THEN
		--Check if another road does not go the other way--
		IF(SELECT EXISTS(SELECT 1 FROM Roads WHERE Roads.fromcountry = NEW.tocountry AND Roads.fromarea = NEW.toarea AND Roads.ownercountry = NEW.ownercountry AND Roads.ownerpersonnumber = NEW.ownerpersonnumber)) THEN
			RAISE EXCEPTION 'Road exists in the reverse direction.'
				USING HINT = '';
		END IF;
		--Check if the player is at the area--
		IF(SELECT EXISTS(SELECT 1 FROM Persons WHERE Persons.locationcountry = NEW.fromcountry AND Persons.locationarea = NEW.locationarea AND Persons.country = NEW.ownercountry AND Persons.personnumber = NEW.ownerpersonnumber)) THEN
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