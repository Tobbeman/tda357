

ROLLBACK;


BEGIN TRANSACTION;
--SETUP
INSERT INTO Countries VALUES ( 'testCountry1') ;
INSERT INTO Areas VALUES ( 'testCountry1' , 'testCity1' , 491630) ;
INSERT INTO Areas VALUES ( 'testCountry1' , 'testCity2', 1337) ;

INSERT INTO Cities VALUES ('testCountry1' , 'testCity1', 491630);
INSERT INTO Persons VALUES ('testCountry1', '123456-1234', 'Fisken allan', 'testCountry1', 'testCity1', 99999999);


INSERT INTO Persons VALUES ('testCountry1', '123456-4321', 'Fisken allan', 'testCountry1', 'testCity1', 99999999);


--TEST

INSERT INTO Hotels VALUES ('hotelname', 'testCountry1', 'testCity1', 'testCountry1', '123456-1234' );

INSERT INTO Hotels VALUES ('hotelname', 'testCountry1', 'testCity1', 'testCountry1', '123456-1234' );



ROLLBACK;
END