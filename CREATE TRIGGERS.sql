CREATE OR REPLACE FUNCTION check_road() RETURNS TRIGGER AS $$

BEGIN

	IF(TG_OP = 'INSERT') THEN
		--Check if another road does not go the other way--
		IF(SELECT * FROM Roads WHERE Roads.fromcountry = NEW.tocountry AND Roads.fromarea = NEW.toarea AND Roads.ownercountry = NEW.ownercountry AND Roads.ownerpersonnumber = NEW.personnumber) IS NOT NULL THEN
			RAISE EXCEPTION 'Road exists in the reverse direction.'
				USING HINT = '';
		END IF;
		--Check if the player is at the area--
		IF(SELECT * FROM Persons WHERE Persons.locationcountry = NEW.fromcountry AND Persons.locationarea = NEW.locationarea AND Persons.country = NEW.ownercountry AND Persons.personnumber = NEW.ownerpersonnumber) IS NULL THEN
			RAISE EXCEPTION 'The buyer of the road must be at the area of construction'
				USING HINT = '';
		END IF;
		INSERT INTO Roads VALUES(NEW.fromcountry, NEW.fromarea, NEW.tocountry, NEW.toarea, NEW.ownercountry, NEW.ownerpersonnumber, NEW.roadtax);
	END IF;

	IF(TG_OP = 'DELETE') THEN
	END IF;

END;

$$ LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION check_road() RETURNS TRIGGER AS $$

BEGIN

END;

$$ LANGUAGE 'plpgsql';

DROP TRIGGER IF EXISTS check_road ON Roads; 
CREATE TRIGGER check_road BEFORE INSERT OR UPDATE OR DELETE ON Roads
    FOR EACH ROW EXECUTE PROCEDURE check_road();