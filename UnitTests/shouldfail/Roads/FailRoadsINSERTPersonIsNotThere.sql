
  
  
 
ROLLBACK;
  
BEGIN TRANSACTION;
 --Setup
INSERT INTO Countries VALUES ( 'testCountry1') ;
INSERT INTO Areas VALUES ( 'testCountry1' , 'testCity1' , 491630) ;
INSERT INTO Areas VALUES ( 'testCountry1' , 'testCity2', 1337) ;
INSERT INTO Areas VALUES ( 'testCountry1' , 'testCity3', 141524334) ;


INSERT INTO Persons VALUES ('testCountry1', '123456-1234', 'Fisken allan', 'testCountry1', 'testCity3', 99999999);
--TEST

INSERT INTO Roads Values ('testCountry1', 'testCity1', 'testCountry1', 'testCity2', 'testCountry1', '123456-1234', 123);

ROLLBACK;
END

