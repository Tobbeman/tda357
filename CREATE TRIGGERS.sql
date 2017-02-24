CREATE OR REPLACE FUNCTION check_road() RETURNS TRIGGER AS $$

BEGIN

	IF(TG_OP = 'INSERT') THEN
		
		IF(SELECT EXISTS(SELECT 1 FROM ROADS WHERE
			(
				((fromcountry = NEW.fromcountry AND fromarea = NEW.fromarea) AND (tocountry = NEW.tocountry AND toarea = NEW.toarea)) 
					OR
				((fromcountry = NEW.tocountry AND fromarea = NEW.toarea) AND (tocountry = NEW.fromcountry AND toarea = NEW.fromarea))
			)	
				AND
			(ownercountry = NEW.ownercountry AND ownerpersonnumber = NEW.ownerpersonnumber) 
		)) THEN
			RAISE EXCEPTION 'Owner owns a road between these areas already'
				USING HINT = '';
		END IF;
			
		--	OLD ONE
		--Check if another road does not go the other way--
		--IF(SELECT EXISTS(SELECT 1 FROM Roads WHERE Roads.fromcountry = NEW.tocountry AND Roads.fromarea = NEW.toarea AND Roads.ownercountry = NEW.ownercountry AND Roads.ownerpersonnumber = NEW.ownerpersonnumber)) THEN
		--	RAISE EXCEPTION 'Road exists in the reverse direction.'
		--		USING HINT = '';
		--END IF;
		
		--Check if the player is at the area--
		IF(SELECT EXISTS(SELECT 1 FROM Persons WHERE
			(
			(country = NEW.ownercountry AND personnumber = NEW.ownerpersonnumber)
			AND
			(
				(locationcountry != NEW.tocountry OR locationarea != NEW.toarea)
				AND
				(locationcountry != NEW.fromcountry OR locationarea != NEW.fromarea)
			)
			)
			)) THEN
				RAISE EXCEPTION 'The buyer of the road must be at the area of construction'
					USING HINT = '';
		END IF;
		
		-- OLD ONE
		--IF(SELECT EXISTS(SELECT 1 FROM Persons WHERE 
		--locationcountry = NEW.fromcountry AND locationarea = NEW.fromarea AND country = NEW.ownercountry AND personnumber = NEW.ownerpersonnumber)) THEN
		--	RAISE EXCEPTION 'The buyer of the road must be at the area of construction'
		--		USING HINT = '';
		--END IF;
		
		--Check persons budget and throw exception if its to low
		--TODO
		
		
		--Dont need this one
		--INSERT INTO Roads VALUES(NEW.fromcountry, NEW.fromarea, NEW.tocountry, NEW.toarea, NEW.ownercountry, NEW.ownerpersonnumber, NEW.roadtax);
		RETURN NEW;
	END IF;
	
	
	-- TODO
	--IF(TG_OP = 'DELETE') THEN
		--RAISE EXCEPTION 'DEL, %, %', OLD.tocountry, OLD.toarea; 
		--DELETE FROM Roads WHERE Roads.fromcountry = OLD.tocountry AND Roads.fromarea = OLD.toarea AND Roads.ownercountry = OLD.ownercountry AND Roads.ownerpersonnumber = OLD.ownerpersonnumber;
		----DELETE FROM Roads WHERE Roads.fromcountry = OLD.fromcountry AND Roads.fromarea = OLD.fromarea AND Roads.tocountry = OLD.tocountry AND Roads.toarea = OLD.toarea AND Roads.ownercountry = OLD.ownercountry AND Roads.ownerpersonnumber = OLD.ownerpersonnumber;
		--RETURN OLD;
	--END IF;
	
	
	
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
	
	
	---------------------------ROAD DELETE-----------------------------------
	------------DONT KNOW IF WE SHOULD DO AFTER INSTEAD OF REPLACING...------
CREATE OR REPLACE FUNCTION delete_road() RETURNS TRIGGER AS $$

BEGIN
	
	
END;

$$ LANGUAGE 'plpgsql';

DROP TRIGGER IF EXISTS delete_road ON Roads; 
CREATE TRIGGER delete_road INSTEAD OF DELETE ON Roads
    FOR EACH ROW EXECUTE PROCEDURE delete_road();
	
------------------------------------------------ PERSON-------------------------------------------------

CREATE OR REPLACE FUNCTION check_person() RETURNS TRIGGER AS $$
DECLARE
	minroadtax integer;
	numHotels integer;
	moved boolean = false;
BEGIN
	
	IF (SELECT EXISTS(SELECT ownercountry,ownerpersonnumber FROM Roads 
		WHERE ((fromarea = NEW.locationarea AND fromcountry = NEW.locationcountry) OR (toarea = NEW.locationarea AND tocountry = NEW.locationcountry)) AND (ownercountry = NEW.country AND ownerpersonnumber = NEW.personnumber )))
		THEN
		--UPDATE Persons SET locationarea = NEW.locationarea, locationcountry = NEW.locationcountry
				--WHERE country = NEW.country AND personnumber = NEW.personnumber;
				moved = true;
	
	ELSIF(SELECT EXISTS(SELECT roadtax INTO minroadtax FROM Roads 
		WHERE  (fromarea = NEW.locationarea AND fromcountry = NEW.locationcountry) OR (toarea = NEW.locationarea AND tocountry = NEW.locationcountry)
		ORDER BY roadtax ASC)LIMIT 1) THEN
			NEW.budget = NEW.budget - minroadtax;
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
		IF NOT EXISTS(SELECT name FROM Hotels WHERE ownercountry = NEW.ownercountry AND ownerpersonnumber = NEW.ownerpersonnumber AND locationarea = NEW.locationarea AND locationcountry = NEW.locationcountry)THEN
			UPDATE Persons SET budget = budget - getval('hotelprice') WHERE country = NEW.country AND personnumber = NEW.ownerpersonnumber;
		END IF;
	END IF;
	
	IF(TG_OP = 'UPDATE') THEN
		--Check that locaion does not change--
		IF NOT EXISTS(SELECT name FROM Hotels WHERE locationarea = NEW.locationarea AND locationcountry = NEW.locationcountry AND name = NEW.name)THEN
			RAISE EXCEPTION 'Hotel does not exist!';
		END IF;
	END IF;
	
	IF(TG_OP = 'UPDATE') THEN
		--Update persons budget
		UPDATE Persons SET budget = budget + getval('hotelprice') * getval('hotelrefund') WHERE country = OLD.country AND personnumber = OLD.ownerpersonnumber;
		END IF;
	END IF;
	
	RETURN NEW;
END;

$$ LANGUAGE 'plpgsql';

DROP TRIGGER IF EXISTS check_hotel ON Hotels; 
CREATE TRIGGER check_hotel BEFORE INSERT OR UPDATE OR DELETE ON Hotels
    FOR EACH ROW EXECUTE PROCEDURE check_hotel();