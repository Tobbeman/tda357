DROP VIEW IF EXISTS NextMoves;
CREATE VIEW NextMoves AS
SELECT persons.country, persons.personnumber, A1.country AS currentCountry, A1.name AS currentArea, A2.country AS validCountry, A2.name AS validArea, roads.roadtax
FROM persons, areas A1, areas A2, roads
WHERE persons.locationcountry = A1.country AND persons.locationarea = A1.name AND roads.fromcountry = A1.country AND roads.fromarea = A1.name AND roads.tocountry = A2.country AND roads.toarea = A2.name AND roads.roadtax < persons.budget;
GROUP BY persons.ownercountry, persons.ownerpersonnumber

--USAGE: SELECT * FROM NextMoves--

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
SELECT persons.country, persons.personnumber, persons.budget, hotelassets.value--, roadassets.value
FROM persons NATURAL JOIN hotelassets
GROUP BY persons.country, persons.personnumber, hotelassets.value--, roadassets.value
 
