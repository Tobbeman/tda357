CREATE OR REPLACE FUNCTION check_road() RETURNS TRIGGER AS $$

BEGIN

	IF(TG_OP = 'INSERT') THEN

		IF(SELECT EXISTS(SELECT 1 FROM ROADS WHERE
				(((fromcountry = NEW.fromcountry AND fromarea = NEW.fromarea) AND (tocountry = NEW.tocountry AND toarea = NEW.toarea))
					OR
				((fromcountry = NEW.tocountry AND fromarea = NEW.toarea) AND (tocountry = NEW.fromcountry AND toarea = NEW.fromarea)))
					AND
				(ownercountry = NEW.ownercountry AND ownerpersonnumber = NEW.ownerpersonnumber)
		)) THEN
			RAISE EXCEPTION 'Owner owns a road between these areas already'
				USING HINT = '';
		END IF;

		--Check if the player is at the right location
		IF(SELECT EXISTS(SELECT 1 FROM Persons WHERE
			(country = NEW.ownercountry AND personnumber = NEW.ownerpersonnumber)
			AND
			((locationarea = NEW.fromarea AND locationcountry = NEW.fromcountry)
			OR
			(locationarea = NEW.toarea AND locationcountry = NEW.tocountry)
		)
		)) THEN
      --RAISE EXCEPTION 'OWNER';
		ELSE
			RAISE EXCEPTION 'The buyer of the road must be at the area of construction';
		END IF;

		--Check persons budget and throw exception if its to low
		IF((SELECT budget FROM Persons WHERE personnumber = NEW.ownerpersonnumber AND country = NEW.ownercountry) < getval('roadprice')) THEN
			RAISE EXCEPTION 'The buyer of the road can not afford the road'
				USING HINT = '';
		END IF;

		RETURN NEW;
	END IF;



	--DELETE BOTH WAYS
	IF(TG_OP = 'DELETE') THEN
		--CHECK IF THE WAY IS CORRECT
		IF(
			ownercountry = OLD.ownercountry AND ownerpersonnumber = OLD.ownerpersonnumber
			AND
			OLD.fromcountry = fromcountry AND OLD.fromarea = fromarea AND OLD.tocountry = tocountry AND OLD.toarea = toarea
			)THEN
				RETURN OLD;
		END IF;

		--DELETE THE OTHER WAY IF THE FIRST IS NOT FOUND
		DELETE FROM Roads WHERE ownercountry = OLD.ownercountry AND ownerpersonnumber = OLD.ownerpersonnumber AND OLD.tocountry = fromcountry AND OLD.toarea = fromarea AND OLD.fromcountry = tocountry AND OLD.fromarea = toarea;
	END IF;

	-- TODO
	--IF(TG_OP = 'UPDATE') THEN
		--IF(	OLD.fromcountry != NEW.fromcountry OR
		--	OLD.tocountry != NEW.tocountry OR
		--	OLD.ownercountry != NEW.ownercountry OR
		--	OLD.ownerpersonnumber != NEW.owner.personnumber) THEN
		--		RAISE EXCEPTION 'Cannot change owner/directions on a road'
		--END IF;
		--RETURN NEW;
	--END IF;


END;

$$ LANGUAGE 'plpgsql';

DROP TRIGGER IF EXISTS check_road ON Roads;
CREATE TRIGGER check_road BEFORE INSERT OR UPDATE ON Roads
    FOR EACH ROW EXECUTE PROCEDURE check_road();


------------------------------------------------ PERSON-------------------------------------------------

CREATE OR REPLACE FUNCTION check_person() RETURNS TRIGGER AS $$
DECLARE
	minroadtax integer;
	numHotels integer;
	moved boolean = false;
BEGIN

  IF(SELECT EXISTS(SELECT country,name FROM Areas WHERE country=NEW.locationcountry AND name = NEW.locationarea))THEN
  ELSE
  	IF (SELECT EXISTS(SELECT ownercountry,ownerpersonnumber FROM Roads
  		WHERE ((fromarea = NEW.locationarea AND fromcountry = NEW.locationcountry) OR (toarea = NEW.locationarea AND tocountry = NEW.locationcountry)) AND (ownercountry = NEW.country AND ownerpersonnumber = NEW.personnumber )))
  		THEN
  		--UPDATE Persons SET locationarea = NEW.locationarea, locationcountry = NEW.locationcountry
  				--WHERE country = NEW.country AND personnumber = NEW.personnumber;
  				moved = true;

  	ELSIF(SELECT EXISTS(SELECT roadtax FROM Roads
  		WHERE  (fromarea = NEW.locationarea AND fromcountry = NEW.locationcountry) OR (toarea = NEW.locationarea AND tocountry = NEW.locationcountry)
  		ORDER BY roadtax ASC)LIMIT 1) THEN
  			NEW.budget = NEW.budget - roadtax;
  			moved = true;
  	ELSE
  		RAISE EXCEPTION 'No road to destination';

  	END IF;

  	--Check hotel--
  	IF(moved) THEN
  			--Check hotel--
  			IF(SELECT EXISTS(SELECT COUNT(Hotels.name) INTO numHotels  FROM Hotels
  				WHERE locationcountry = NEW.locationcountry AND locationname = NEW.locationarea
  				))THEN
  					NEW.budget = NEW.budget + (getval('cityvisit')/numHotels);
  			END IF;
  	END IF;
  END IF;
	RETURN NEW;
END;

$$ LANGUAGE 'plpgsql';

DROP TRIGGER IF EXISTS check_person ON Persons;
CREATE TRIGGER check_person BEFORE UPDATE ON Persons
    FOR EACH ROW EXECUTE PROCEDURE check_person();

--------------------------------------------HOTELS------------------------------------------
CREATE OR REPLACE FUNCTION check_hotel() RETURNS TRIGGER AS $$

BEGIN
	IF(TG_OP = 'INSERT') THEN
		--Check that the player buying do not own an hotel in the same area--
		IF EXISTS(SELECT name FROM Hotels WHERE ownercountry = NEW.ownercountry AND ownerpersonnumber = NEW.ownerpersonnumber AND locationname = NEW.locationname AND locationcountry = NEW.locationcountry)THEN
		RAISE EXCEPTION 'haha';
		ELSE
			UPDATE Persons SET budget = budget - getval('hotelprice') WHERE country = NEW.ownercountry AND personnumber = NEW.ownerpersonnumber;
		END IF;
	END IF;

	IF(TG_OP = 'UPDATE') THEN
		--Check that locaion does not change--
		IF NOT EXISTS(SELECT name FROM Hotels WHERE locationname = NEW.locationname AND locationcountry = NEW.locationcountry AND name = NEW.name)THEN
			RAISE EXCEPTION 'Hotel does not exist!';
		END IF;
	END IF;

	IF(TG_OP = 'UPDATE') THEN
		--Update persons budget
		UPDATE Persons SET budget = budget + (getval('hotelprice') * getval('hotelrefund')) WHERE country = NEW.ownercountry AND personnumber = NEW.ownerpersonnumber;
	END IF;

	RETURN NEW;
END;

$$ LANGUAGE 'plpgsql';

DROP TRIGGER IF EXISTS check_hotel ON Hotels;
CREATE TRIGGER check_hotel BEFORE INSERT OR UPDATE OR DELETE ON Hotels
    FOR EACH ROW EXECUTE PROCEDURE check_hotel();
