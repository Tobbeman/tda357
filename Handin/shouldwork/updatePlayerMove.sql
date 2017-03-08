ROLLBACK;


BEGIN TRANSACTION;
--SETUP
INSERT INTO Countries VALUES ( 'testCountry1') ;
INSERT INTO Areas VALUES ( 'testCountry1' , 'testCity1' , 491630) ;
INSERT INTO Areas VALUES ( 'testCountry1' , 'testCity2', 1337) ;
INSERT INTO Areas VALUES ( 'testCountry1' , 'testCity3', 1337) ;

INSERT INTO Cities VALUES ('testCountry1' , 'testCity1', 491630);
INSERT INTO Persons VALUES ('testCountry1', '123456-1234', 'Fisken allan', 'testCountry1', 'testCity1', 99999999);

INSERT INTO Roads VALUES ('testCountry1', 'testCity1', 'testCountry1', 'testCity2', 'testCity1' , '123456-1234', 15);


--TEST

UPDATE Persons SET locationarea = 'testCity1' WHERE country != ' ';
UPDATE Persons SET locationarea = 'testCity2' WHERE country != ' ';

--TEST--

ROLLBACK;
