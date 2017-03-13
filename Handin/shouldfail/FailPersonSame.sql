



ROLLBACK;

BEGIN TRANSACTION;
 --Setup
INSERT INTO Countries VALUES ( 'testCountry1') ;
INSERT INTO Areas VALUES ( 'testCountry1' , 'testCity1' , 491630) ;
INSERT INTO Areas VALUES ( 'testCountry1' , 'testCity2', 1337) ;




INSERT INTO Persons VALUES ('testCountry1', '11123456-1234', 'Fisken allan', 'testCountry1', 'testCity1', 99999999);

INSERT INTO Persons VALUES ('testCountry1', '11123456-1234', 'Fisken allan', 'testCountry1', 'testCity1', 99999999);

ROLLBACK;

END
