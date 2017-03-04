--Create Table--
DROP TABLE IF EXISTS Roads CASCADE;
DROP TABLE IF EXISTS Hotels CASCADE;
DROP TABLE IF EXISTS Persons CASCADE;
DROP TABLE IF EXISTS Cities CASCADE;
DROP TABLE IF EXISTS Towns CASCADE;
DROP TABLE IF EXISTS Areas CASCADE;
DROP TABLE IF EXISTS Countries CASCADE;

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
--Create Views--
DROP VIEW IF EXISTS NextMoves;
CREATE VIEW NextMoves AS
SELECT persons.country, persons.personnumber, A1.country AS currentCountry, A1.name AS currentArea, A2.country AS validCountry, A2.name AS validArea, roads.roadtax
FROM persons, areas A1, areas A2, roads
WHERE persons.locationcountry = A1.country AND persons.locationarea = A1.name AND roads.fromcountry = A1.country AND roads.fromarea = A1.name AND roads.tocountry = A2.country AND roads.toarea = A2.name AND roads.roadtax < persons.budget;

DROP VIEW IF EXISTS AssetSummery;
CREATE VIEW AssertSummery AS
SELECT p.country, p.personnumber, p.budget, (SELECT COUNT(hotels.name) * getval('hotelprice') FROM hotels WHERE hotels.ownercountry = p.country AND hotels.ownerpersonnumber = p.personnumber) + (SELECT COUNT(roads.roadtax) * getval('roadprice') FROM roads WHERE roads.ownercountry = p.country AND roads.ownerpersonnumber = p.personnumber) AS assets, (SELECT COUNT(hotels.name) * getval('hotelprice') * getval('hotelrefund') FROM hotels WHERE hotels.ownercountry = p.country AND hotels.ownerpersonnumber = p.personnumber) AS reclaimable
FROM persons p;
--end Create Views--
--Create Triggers--
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

		IF(SELECT EXISTS(SELECT 1 FROM Persons WHERE
			(
       ((country = NEW.ownercountry AND personnumber = NEW.ownerpersonnumber)
				AND
				(
					(locationcountry = NEW.tocountry AND locationarea = NEW.toarea)
					AND
					(locationcountry = NEW.fromcountry AND locationarea = NEW.fromarea)
				))
        OR
        (country = ' ' AND personnumber = ' ')
			)
			)) THEN
      ELSE
				RAISE EXCEPTION 'The buyer of the road must be at the area of construction'
					USING HINT = '';
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

--end Create Triggers--
--Fill database--

--MUST HAVE--
INSERT INTO Countries VALUES (' ') ;
INSERT INTO Areas VALUES (' ', ' ', 1) ;
INSERT INTO Persons VALUES ( ' ' , ' ' , 'The Government' , ' ' , ' ' , 100000) ;
--Generic--
INSERT INTO Countries VALUES ('Sweden');

INSERT INTO Areas VALUES ( 'Sweden' , 'Gothenburg' , 491630) ;
INSERT INTO Areas VALUES ( 'Sweden' , 'Stockholm' , 1006024) ;
INSERT INTO Areas VALUES ( 'Sweden' , 'Visby' , 20000) ;

INSERT INTO Cities VALUES ( 'Sweden' , 'Gothenburg' , 250) ;
INSERT INTO Cities VALUES ( 'Sweden' , 'Stockholm' , 500) ;
INSERT INTO Cities VALUES ( 'Sweden' , 'Visby' , 125) ;

INSERT INTO Persons VALUES ( 'Sweden' , '940606-6952' , 'Tobias Laving' , 'Sweden' , 'Gothenburg' , 100000);
INSERT INTO Persons VALUES ( 'Sweden' , '970221-4555' , 'Daniel Laving' , 'Sweden' , 'Stockholm' , 100000);

INSERT INTO Hotels VALUES('Hotel', 'Sweden', 'Gothenburg', 'Sweden', '940606-6952');
INSERT INTO Hotels VALUES('Hotel', 'Sweden', 'Stockholm', 'Sweden', '940606-6952');
INSERT INTO Hotels VALUES('Hotel', 'Sweden', 'Gothenburg', 'Sweden', '970221-4555');
INSERT INTO Hotels VALUES('Hotel', 'Sweden', 'Stockholm', 'Sweden', '970221-4555');
INSERT INTO Hotels VALUES('Hotel', 'Sweden', 'Visby', 'Sweden', '970221-4555');

INSERT INTO Roads VALUES ('Sweden', 'Gothenburg', 'Sweden', 'Stockholm', ' ', ' ', 10);
INSERT INTO Roads VALUES ('Sweden', 'Gothenburg', 'Sweden', 'Stockholm', 'Sweden', '940606-6952', 15);
INSERT INTO Roads VALUES ('Sweden', 'Stockholm', 'Sweden', 'Visby', 'Sweden', '940606-6952', 15);



--end Fill database--
