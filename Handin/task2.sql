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
  population integer CHECK (population > 0) NOT NULL,
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
  visitbonus NUMERIC CHECK (visitbonus >= 0) NOT NULL,
  FOREIGN KEY (country,name) REFERENCES areas(country,name),
  PRIMARY KEY (country,name)
);
create table Persons(
  country character varying (80) REFERENCES countries(name),
  personnummer char(13) CHECK (personnummer ~ '[0-9]{8}-[0-9]{4}' OR personnummer = ''),
  name character varying (80) NOT NULL,
  locationcountry character varying (80) NOT NULL,
  locationarea character varying (80) NOT NULL,
  budget numeric CHECK (budget >= 0) NOT NULL,
  FOREIGN KEY (locationcountry,locationarea) REFERENCES areas(country,name),
  PRIMARY KEY (country,personnummer)
);
create table Hotels(
  name character varying (80) NOT NULL,
  locationcountry character varying (80),
  locationname character varying (80),
  ownercountry character varying (80),
  ownerpersonnummer character varying (13),
  FOREIGN KEY (locationcountry,locationname) REFERENCES cities(country,name),
  FOREIGN KEY (ownercountry,ownerpersonnummer) REFERENCES persons(country,personnummer),
  PRIMARY KEY (locationcountry,locationname,ownercountry,ownerpersonnummer )
);
create table Roads(
  fromcountry character varying (80),
  fromarea character varying (80),
  tocountry character varying (80),
  toarea character varying (80),
  ownercountry character varying (80),
  ownerpersonnummer character varying (13),
  roadtax NUMERIC CHECK (roadtax >= 0) NOT NULL,
  FOREIGN KEY (fromcountry,fromarea) REFERENCES areas(country,name),
  FOREIGN KEY (tocountry,toarea) REFERENCES areas(country,name),
  FOREIGN KEY (ownercountry,ownerpersonnummer) REFERENCES persons(country,personnummer),
  PRIMARY KEY (fromcountry,fromarea,tocountry,toarea, ownercountry, ownerpersonnummer)
);

CREATE OR REPLACE FUNCTION getCheapestRoadTax(pnr text, country text, locationarea text, locationcountry text, destarea text, destcountry text) RETURNS NUMERIC AS $$
DECLARE
rtax NUMERIC;
BEGIN
    SELECT roadtax INTO rtax FROM Roads WHERE((fromcountry = locationcountry AND fromarea = locationArea AND tocountry = destcountry AND toarea = destarea)
    OR(tocountry = locationcountry AND toarea = locationArea AND fromcountry = destcountry AND fromarea = destarea))
    AND (pnr != ownerpersonnummer OR country != ownercountry) ORDER BY roadtax ASC LIMIT 1;

    RAISE EXCEPTION '%',rtax;
    IF EXISTS(SELECT * FROM Roads WHERE(fromcountry = locationcountry AND fromarea = locationArea AND tocountry = destcountry AND toarea = destarea)
    OR(tocountry = locationcountry AND toarea = locationArea AND fromcountry = destcountry AND fromarea = destarea))THEN
      IF rtax IS NOT NULL THEN
        RETURN rtax;
      ELSE
        RETURN 0;
      END IF;
    END IF;
    RETURN NULL;
END
$$ LANGUAGE 'plpgsql' ;


--end Create Table--
--Create Views--
DROP VIEW IF EXISTS NextMoves;
CREATE VIEW NextMoves AS
SELECT persons.country AS personcountry, persons.personnummer, A1.country AS Country, A1.name AS Area, A2.country AS destCountry, A2.name AS destArea, CASE WHEN (roads.ownerpersonnummer = persons.personnummer AND roads.ownercountry = persons.country) THEN '0' ELSE roads.roadtax END AS cost
FROM persons, areas A1, areas A2, roads
WHERE persons.locationcountry = A1.country AND persons.locationarea = A1.name AND (persons.personnummer != '' OR persons.country != '') AND
((roads.fromcountry = A1.country AND roads.fromarea = A1.name AND roads.tocountry = A2.country AND roads.toarea = A2.name AND roads.roadtax <= persons.budget)
OR
(roads.fromcountry = A2.country AND roads.fromarea = A2.name AND roads.tocountry = A1.country AND roads.toarea = A1.name AND roads.roadtax <= persons.budget));

DROP VIEW IF EXISTS Nxt;
CREATE VIEW Nxt AS
SELECT persons.country AS personcountry, persons.personnummer, A1.country AS Country, A1.name AS Area, A2.country AS destCountry, A2.name AS destArea, roads.roadtax AS cost
FROM persons, areas A1, areas A2, roads
WHERE persons.locationcountry = A1.country AND persons.locationarea = A1.name AND (persons.personnummer != '' OR persons.country != '') AND (SELECT getCheapestRoadTax(persons.personnummer,persons.country,A1.name,A1.country,A2.name,A2.country)!=NULL);

DROP VIEW IF EXISTS AssetSummary;
CREATE VIEW AssetSummary AS
SELECT p.country, p.personnummer, p.budget, (SELECT COUNT(hotels.name) * getval('hotelprice') FROM hotels WHERE hotels.ownercountry = p.country AND hotels.ownerpersonnummer = p.personnummer) + (SELECT COUNT(roads.roadtax) * getval('roadprice') FROM roads WHERE roads.ownercountry = p.country AND roads.ownerpersonnummer = p.personnummer) AS assets, (SELECT COUNT(hotels.name) * getval('hotelprice') * getval('hotelrefund') FROM hotels WHERE hotels.ownercountry = p.country AND hotels.ownerpersonnummer = p.personnummer) AS reclaimable
FROM persons p
WHERE (p.personnummer != '' AND p.country != '');
--end Create Views--


--Create Triggers--
CREATE OR REPLACE FUNCTION check_road() RETURNS TRIGGER AS $$
DECLARE
tempA text;
tempC text;
BEGIN

  IF(TG_OP = 'INSERT') THEN

--Check if buyer is the government--
  IF(NEW.ownercountry = '' AND NEW.ownerpersonnummer = '')THEN
    RETURN NEW;
  END IF;

--Check that the to and from is not the same
  IF(NEW.fromarea = NEW.toarea AND NEW.fromcountry = NEW.tocountry)THEN
    RAISE EXCEPTION 'Cannot build an road with the same from as to';
  END IF;

--Check if the player already owns an road at this location
    IF(SELECT EXISTS(SELECT 1 FROM Roads WHERE
        (((fromcountry = NEW.fromcountry AND fromarea = NEW.fromarea) AND (tocountry = NEW.tocountry AND toarea = NEW.toarea))
          OR
        ((fromcountry = NEW.tocountry AND fromarea = NEW.toarea) AND (tocountry = NEW.fromcountry AND toarea = NEW.fromarea)))
          AND
        (ownercountry = NEW.ownercountry AND ownerpersonnummer = NEW.ownerpersonnummer)
    )) THEN
      RAISE EXCEPTION 'Owner owns a road between these areas already';
    END IF;

    --Check if the player is at the right location
    IF(SELECT EXISTS(SELECT 1 FROM Persons WHERE
      (country = NEW.ownercountry AND personnummer = NEW.ownerpersonnummer)
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
    IF((SELECT budget FROM Persons WHERE personnummer = NEW.ownerpersonnummer AND country = NEW.ownercountry) < getval('roadprice')) THEN
      RAISE EXCEPTION 'The buyer of the road can not afford the road';
    END IF;

    UPDATE Persons SET budget = budget - getval('roadprice') WHERE personnummer = NEW.ownerpersonnummer AND country = NEW.ownercountry;

    --NEW.roadtax = getval('roadtax');
    RETURN NEW;
  END IF;



  IF(TG_OP = 'UPDATE') THEN
  --Check that the road can't be moved or renamed--
    IF(  OLD.fromcountry != NEW.fromcountry OR
      OLD.tocountry != NEW.tocountry OR
      OLD.ownercountry != NEW.ownercountry OR
      OLD.ownerpersonnummer != NEW.ownerpersonnummer) THEN
        RAISE EXCEPTION 'Cannot change owner/directions on a road';
    END IF;
    RETURN NEW;
  END IF;


END;

$$ LANGUAGE 'plpgsql';

DROP TRIGGER IF EXISTS check_road ON Roads;
CREATE TRIGGER check_road BEFORE INSERT OR UPDATE ON Roads
    FOR EACH ROW EXECUTE PROCEDURE check_road();


------------------------------------------------ PERSON-------------------------------------------------

CREATE OR REPLACE FUNCTION check_person() RETURNS TRIGGER AS $$
DECLARE
  lowestRoadTax NUMERIC;
  vownercountry TEXT;
  vownerpnr TEXT;
  numHotels integer;
  moved boolean = false;
BEGIN
    --SELECT roadtax INTO minroadtax FROM Roads
    --WHERE  (fromarea = NEW.locationarea AND fromcountry = NEW.locationcountry) OR (toarea = NEW.locationarea AND tocountry = NEW.locationcountry) AND (ownercountry != NEW.country AND ownerpersonnummer != NEW.personnummer)
    --ORDER BY roadtax ASC LIMIT 1;


    --Check that the player is not traveling to itself
    IF EXISTS (SELECT * FROM Persons WHERE personnummer = NEW.personnummer AND country = NEW.country AND locationarea = NEW.locationarea AND locationcountry = NEW.locationcountry) THEN
    ELSE
      --Check if player owns road to location--
      IF (SELECT EXISTS(SELECT * FROM Roads
        WHERE ((fromarea = NEW.locationarea AND fromcountry = NEW.locationcountry) OR (toarea = NEW.locationarea AND tocountry = NEW.locationcountry) OR (toarea = NEW.locationarea AND fromcountry = NEW.locationcountry) OR (fromarea = NEW.locationarea AND tocountry = NEW.locationcountry)) AND (ownercountry = NEW.country AND ownerpersonnummer = NEW.personnummer )))
        THEN
        moved = true;
      --Check if there is an road to location--
      ELSIF EXISTS (SELECT * FROM NextMoves WHERE NEW.budget >= cost AND personcountry = NEW.country AND personnummer = NEW.personnummer AND Country = OLD.locationcountry AND Area = OLD.locationarea AND destCountry = NEW.locationcountry AND destArea = NEW.locationarea) THEN
          SELECT ownercountry INTO vownercountry FROM ROADS WHERE ((fromcountry = OLD.locationcountry AND tocountry = NEW.locationcountry) OR (tocountry = OLD.locationcountry AND fromcountry = NEW.locationcountry))AND((fromarea = OLD.locationarea AND toarea = NEW.locationarea) OR (toarea = OLD.locationarea AND fromarea = NEW.locationarea)) ORDER BY roadtax ASC LIMIT 1;
          SELECT ownerpersonnummer INTO vownerpnr FROM ROADS WHERE ((fromcountry = OLD.locationcountry AND tocountry = NEW.locationcountry) OR (tocountry = OLD.locationcountry AND fromcountry = NEW.locationcountry))AND((fromarea = OLD.locationarea AND toarea = NEW.locationarea) OR (toarea = OLD.locationarea AND fromarea = NEW.locationarea)) ORDER BY roadtax ASC LIMIT 1;
          SELECT roadtax INTO lowestRoadTax FROM ROADS WHERE ((fromcountry = OLD.locationcountry AND tocountry = NEW.locationcountry) OR (tocountry = OLD.locationcountry AND fromcountry = NEW.locationcountry))AND((fromarea = OLD.locationarea AND toarea = NEW.locationarea) OR (toarea = OLD.locationarea AND fromarea = NEW.locationarea)) ORDER BY roadtax ASC LIMIT 1;
          --SELECT ownerpersonnummer INTO vownerpnr FROM ROADS WHERE ((fromarea = NEW.locationarea AND fromcountry = NEW.locationcountry) OR (toarea = NEW.locationarea AND tocountry = NEW.locationcountry) OR (toarea = NEW.locationarea AND fromcountry = NEW.locationcountry) OR (fromarea = NEW.locationarea AND tocountry = NEW.locationcountry)) ORDER BY roadtax ASC LIMIT 1;
          --SELECT roadtax INTO lowestRoadTax FROM Roads WHERE ((fromarea = NEW.locationarea AND fromcountry = NEW.locationcountry) OR (toarea = NEW.locationarea AND tocountry = NEW.locationcountry) OR (toarea = NEW.locationarea AND fromcountry = NEW.locationcountry) OR (fromarea = NEW.locationarea AND tocountry = NEW.locationcountry)) ORDER BY roadtax ASC LIMIT 1;
          NEW.budget = NEW.budget - lowestRoadTax;
          UPDATE Persons SET budget = budget + lowestRoadTax  WHERE country = vownercountry AND personnummer = vownerpnr;
          moved = true;
      ELSIF EXISTS (SELECT * FROM ROADS WHERE NEW.budget < roadtax AND ((fromarea = NEW.locationarea AND fromcountry = NEW.locationcountry) OR (toarea = NEW.locationarea AND tocountry = NEW.locationcountry) OR (toarea = NEW.locationarea AND fromcountry = NEW.locationcountry) OR (fromarea = NEW.locationarea AND tocountry = NEW.locationcountry))) THEN
        RAISE EXCEPTION 'No road that the player can afford';
      ELSE
        RAISE EXCEPTION 'No road to destination';
      END IF;


      --Check hotel--
      IF(moved = TRUE) THEN
        --RAISE exception 'HEllo';
        SELECT COUNT(Hotels.name) INTO numHotels  FROM Hotels
        WHERE locationcountry = NEW.locationcountry AND locationname = NEW.locationarea;
          --Check hotel--
          IF (numHotels > 0) THEN

              IF((NEW.budget - getval('cityvisit') < 0))THEN
                RAISE EXCEPTION 'The player cannot afford to visit this city';
              END IF;

              NEW.budget = NEW.budget - getval('cityvisit') + (getval('cityvisit')/numHotels);

              UPDATE Persons p SET budget = budget + (getval('cityvisit')/numHotels) WHERE
              (p.personnummer != NEW.personnummer OR p.country != NEW.country)
              AND
              p.personnummer = (SELECT ownerpersonnummer FROM Hotels WHERE locationname = NEW.locationarea AND locationcountry = NEW.locationcountry AND p.country = ownercountry AND p.personnummer = ownerpersonnummer)
              AND
              p.country = (SELECT ownercountry FROM Hotels WHERE locationname = NEW.locationarea AND locationcountry = NEW.locationcountry AND p.personnummer = ownerpersonnummer AND p.country = ownercountry);
              --AND p.personnummer != NEW.personnummer AND p.country != NEW.country;
              --This person
              --raise exception '%', NEW.budget;
          END IF;
          IF EXISTS (SELECT visitbonus FROM Cities WHERE name = NEW.locationarea AND country = NEW.locationcountry)THEN
            NEW.budget = (NEW.budget + (SELECT visitbonus FROM Cities WHERE name = NEW.locationarea AND country = NEW.locationcountry));
            UPDATE cities SET visitbonus = 0 WHERE name = NEW.locationarea AND country = NEW.locationcountry;
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
    IF EXISTS(SELECT name FROM Hotels WHERE ownercountry = NEW.ownercountry AND ownerpersonnummer = NEW.ownerpersonnummer AND locationname = NEW.locationname AND locationcountry = NEW.locationcountry)THEN
      RAISE EXCEPTION 'The player already owns an hotel in this area';
      ELSE
      UPDATE Persons SET budget = budget - getval('hotelprice') WHERE country = NEW.ownercountry AND personnummer = NEW.ownerpersonnummer;
    END IF;
  END IF;

  IF(TG_OP = 'UPDATE') THEN
    --Check that locaion does not change--
    IF NOT EXISTS(SELECT name FROM Hotels WHERE locationname = NEW.locationname AND locationcountry = NEW.locationcountry AND name = NEW.name)THEN
      RAISE EXCEPTION 'Hotel cannot be moved';
    END IF;
  END IF;

  IF(TG_OP = 'DELETE') THEN
    --Update persons budget
    UPDATE Persons SET budget = budget + (getval('hotelprice') * getval('hotelrefund')) WHERE country = OLD.ownercountry AND personnummer = OLD.ownerpersonnummer;
    RETURN OLD;
  END IF;

  RETURN NEW;
END;

$$ LANGUAGE 'plpgsql';

DROP TRIGGER IF EXISTS check_hotel ON Hotels;
CREATE TRIGGER check_hotel BEFORE INSERT OR UPDATE OR DELETE ON Hotels
    FOR EACH ROW EXECUTE PROCEDURE check_hotel();

--end Create Triggers--

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

-- the assert function is for the unit tests
CREATE OR REPLACE FUNCTION assert(x numeric, y numeric) RETURNS void AS $$
BEGIN
    IF NOT (SELECT trunc(x, 2) = trunc(y, 2))
    THEN
        RAISE 'assert(%=%) failed (up to 2 decimal places, checked with trunc())!', x, y;
    END IF;
    RETURN;
END
$$ LANGUAGE 'plpgsql' ;

CREATE OR REPLACE FUNCTION assert(x text, y text) RETURNS void AS $$
BEGIN
    IF NOT (SELECT x = y)
    THEN
        RAISE 'assert(%=%) failed!', x, y;
    END IF;
    RETURN;
END
$$ LANGUAGE 'plpgsql' ;


--end Fill database--
