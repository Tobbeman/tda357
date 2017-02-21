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

