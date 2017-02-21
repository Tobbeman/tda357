DROP VIEW IF EXISTS NextMoves;
CREATE VIEW NextMoves AS
SELECT persons.country, persons.personnumber, A1.country AS currentCountry, A1.name AS currentArea, A2.country AS validCountry, A2.name AS validArea, roads.roadtax
FROM persons, areas A1, areas A2, roads
WHERE persons.locationcountry = A1.country AND persons.locationarea = A1.name AND roads.fromcountry = A1.country AND roads.fromarea = A1.name AND roads.tocountry = A2.country AND roads.toarea = A2.name AND roads.roadtax < persons.budget;
GROUP BY persons.ownercountry, persons.ownerpersonnumber

--USAGE: SELECT * FROM NextMoves--

DROP VIEW IF EXISTS HotelAssets;
CREATE VIEW HotelAssets AS
SELECT hotels.ownercountry, hotels.ownerpersonnumber, COUNT(hotels.name) AS ownedHotels
FROM hotels
GROUP BY hotels.ownercountry,hotels.ownerpersonnumber;

DROP VIEW IF EXISTS RoadAssets;
CREATE VIEW RoadAssets AS
SELECT roads.ownercountry, roads.ownerpersonnumber, COUNT(roads.roadtax) AS ownedRoads
FROM roads
GROUP BY roads.ownercountry, roads.ownerpersonnumber;

DROP VIEW IF EXISTS AssetSummery;
CREATE VIEW AssertSummery AS
SELECT persons.country, persons.personnumber, persons.budget, (hotelassets.ownedhotels*getval('hotelprice') + roadassets.ownedroads*getval('roadprice')) AS assets
FROM persons, hotelassets, roadassets
GROUP BY persons.country, persons.personnumber, assets;
 
