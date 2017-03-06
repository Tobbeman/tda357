

ROLLBACK;


BEGIN TRANSACTION;
--SETUP
INSERT INTO Countries VALUES ( 'testCountry1') ;
INSERT INTO Areas VALUES ( 'testCountry1' , 'testCity1' , 491630) ;
INSERT INTO Areas VALUES ( 'testCountry1' , 'testCity2', 1337) ;

INSERT INTO Cities VALUES ('testCountry1' , 'testCity1', 491630);
INSERT INTO Persons VALUES ('testCountry1', '123456-1234', 'Fisken allan', 'testCountry1', 'testCity1', 99999999);


--TEST

INSERT INTO Roads VALUES ('testCountry1', 'testCity1', 'testCountry1', 'testCity2', 'testCountry1' , '123456-1234', 15);

DELETE FROM Roads WHERE (fromarea = 'testCity2' AND fromcountry = 'testCountry1' AND toarea = 'testCity1' AND tocountry = 'testCountry1' AND ownerpersonnumber = '123456-1234' AND ownercountry = 'testCountry1');

IF(SELECT EXISTS(SELECT * FROM ROADS WHERE ownercountry = testCountry1))
	RAISE EXCEPTION 'Road was not deleted';
END IF;



ROLLBACK;
END
