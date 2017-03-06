

--Create Table--
DROP TABLE IF EXISTS Roads CASCADE;
DROP TABLE IF EXISTS Hotels CASCADE;
DROP TABLE IF EXISTS Persons CASCADE;
DROP TABLE IF EXISTS Cities CASCADE;
DROP TABLE IF EXISTS Towns CASCADE;
DROP TABLE IF EXISTS Areas CASCADE;
DROP TABLE IF EXISTS Countries CASCADE;
DROP TABLE IF EXISTS Constants CASCADE;

create table Countries(
  name character varying (80) PRIMARY KEY
);
create table Areas(
  country character varying (80) REFERENCES countries(name),
  name character varying (80),
  population integer CHECK (population > 0),
  PRIMARY KEY (country,name)
);
create table Towns(
  country character varying (80),
  name character varying (80),
  FOREIGN KEY (country,name) REFERENCES areas(country,name),
  PRIMARY KEY (country,name)
);
create table Cities(
  country character varying (80),
  name character varying (80),
  visitbonus integer CHECK (visitbonus >= 0),
  FOREIGN KEY (country,name) REFERENCES areas(country,name),
  PRIMARY KEY (country,name)
);
create table Persons(
  country character varying (80) REFERENCES countries(name),
  personnumber char (11) CHECK (personnumber ~ '[0-9]{6}-[0-9]{4}' OR personnumber = ' '),
  name character varying (80),
  locationcountry character varying (80),
  locationarea character varying (80),
  budget numeric CHECK (budget >= 0),
  FOREIGN KEY (locationcountry,locationarea) REFERENCES areas(country,name),
  PRIMARY KEY (country,personnumber)
);
create table Hotels(
  name character varying (80),
  locationcountry character varying (80),
  locationname character varying (80),
  ownercountry character varying (80),
  ownerpersonnumber character varying (13),
  FOREIGN KEY (locationcountry,locationname) REFERENCES cities(country,name),
  FOREIGN KEY (ownercountry,ownerpersonnumber) REFERENCES persons(country,personnumber),
  PRIMARY KEY (locationcountry,locationname,ownercountry,ownerpersonnumber )
);
create table Roads(
  fromcountry character varying (80),
  fromarea character varying (80),
  tocountry character varying (80),
  toarea character varying (80),
  ownercountry character varying (80),
  ownerpersonnumber character varying (13),
  roadtax numeric CHECK (roadtax >= 0),
  FOREIGN KEY (fromcountry,fromarea) REFERENCES areas(country,name),
  FOREIGN KEY (tocountry,toarea) REFERENCES areas(country,name),
  FOREIGN KEY (ownercountry,ownerpersonnumber) REFERENCES persons(country,personnumber),
  PRIMARY KEY (fromcountry,fromarea,tocountry,toarea, ownercountry, ownerpersonnumber)
);
--end Create Table--


--MUST HAVE--
INSERT INTO Countries VALUES (' ') ;
INSERT INTO Areas VALUES (' ', ' ', 1) ;
INSERT INTO Persons VALUES ( ' ' , ' ' , 'The Government' , ' ' , ' ' , 100000) ;

------------------------------------------------
------------------------VIEWS-------------------
------------------------------------------------

DROP VIEW IF EXISTS HotelAssets CASCADE;
CREATE VIEW HotelAssets AS
SELECT persons.country, persons.personnumber, COUNT(hotels.name) AS ownedHotels, COUNT(hotels.name) * getval('hotelprice') AS Value 
FROM hotels, persons
WHERE hotels.ownercountry = persons.country AND hotels.ownerpersonnumber = persons.personnumber
GROUP BY persons.country,persons.personnumber;

DROP VIEW IF EXISTS RoadAssets CASCADE;
CREATE VIEW RoadAssets AS
SELECT persons.country, persons.personnumber, COUNT(roads.roadtax) AS ownedRoads, COUNT(roads.roadtax) * getval('roadprice') AS Value 
FROM roads, persons
WHERE roads.ownercountry = persons.country AND roads.ownerpersonnumber = persons.personnumber
GROUP BY persons.country, persons.personnumber;

DROP VIEW IF EXISTS AssetSummery;
CREATE VIEW AssertSummery AS
SELECT p.country, p.personnumber, p.budget, (SELECT COUNT(hotels.name) * getval('hotelprice') FROM hotels WHERE hotels.ownercountry = p.country AND hotels.ownerpersonnumber = p.personnumber) + (SELECT COUNT(roads.roadtax) * getval('roadprice') FROM roads WHERE roads.ownercountry = p.country AND roads.ownerpersonnumber = p.personnumber) AS assets, (SELECT COUNT(hotels.name) * getval('hotelprice') * getval('hotelrefund') FROM hotels WHERE hotels.ownercountry = p.country AND hotels.ownerpersonnumber = p.personnumber) AS reclaimable
FROM persons p --NATURAL JOIN hotelassets
--GROUP BY persons.country, persons.personnumber, hotelassets.value--, roadassets.value
 ;
-----------------------------------------------------------------------------------------
----------------------------TRIGGERS-----------------------------------------------------
-----------------------------------------------------------------------------------------
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
	
	RETURN NEW;
END;

$$ LANGUAGE 'plpgsql';

DROP TRIGGER IF EXISTS check_hotel ON Hotels; 
CREATE TRIGGER check_hotel BEFORE INSERT OR UPDATE OR DELETE ON Hotels
    FOR EACH ROW EXECUTE PROCEDURE check_hotel();
	
	
	
	--------------------------------------------------------------------
	---------------------------CONSTANTS--------------------------------
	--------------------------------------------------------------------
	
	
CREATE TABLE Constants(
    name TEXT PRIMARY KEY,
    value NUMERIC NOT NULL
);

INSERT INTO Constants VALUES('roadprice', 456.9);
INSERT INTO Constants VALUES('hotelprice', 789.2);
INSERT INTO Constants VALUES('roadtax', 13.5);
INSERT INTO Constants VALUES('hotelrefund', 0.50);
INSERT INTO Constants VALUES('cityvisit', 102030.3);

CREATE OR REPLACE FUNCTION getval(qname TEXT) RETURNS NUMERIC AS $$
DECLARE
    xxx NUMERIC;
BEGIN
    xxx := (SELECT value FROM Constants WHERE name = qname);
    RETURN xxx;
END
$$ LANGUAGE 'plpgsql' ;


	
	
	
	
