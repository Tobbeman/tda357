CREATE OR REPLACE FUNCTION failRoadsIdentical() RETURNS boolean AS $$ 



BEGIN TRANSACTION;




	--Setup
	INSERT INTO Countries VALUES ( 'testCountry1') ;
	INSERT INTO Areas VALUES ( 'testCountry1' , 'testCity1' , 491630) ;
	INSERT INTO Areas VALUES ( 'testCountry1' , 'testCity2', 1337) ;
	INSERT INTO Cities VALUES ('testCountry1', 'testCity1', 400);
	INSERT INTO Towns VALUES ( 'testCountry1' , 'testCity2') ;
	INSERT INTO Persons VALUES ('testCountry1', '123456-1234', 'Fisken allan', 'testCountry1', 'testCity1', 99999999);

	--Test
	INSERT INTO Roads Values ('testCountry1', 'testCity1', 'testCountry1', 'testCity2', 'testCountry1', '123456-1234', 123);
	INSERT INTO Roads Values ('testCountry1', 'testCity1', 'testCountry1', 'testCity2', 'testCountry1', '123456-1234', 123);
		EXCEPTION WHEN OTHER
			BEGIN
			END
		
	--Reset

	DELETE FROM Roads WHERE Roads.toCountry = 'testCountry1';
	DELETE FROM Persons WHERE Persons.personnumber = '123456-1234';
	DELETE FROM Cities WHERE Cities.country = 'testCountry1';
	DELETE FROM Towns WHERE Towns.country = 'testCountry1';
	DELETE FROM Areas WHERE Areas.country = 'testCountry1';
	DELETE FROM Countries WHERE Countries.name = 'testCountry1';


ROLLBACK;

	RETURN;
$$ LANGUAGE plpgsql;









CREATE OR REPLACE FUNCTION failRoadsIdentical()
RETURNS boolean AS $result$
  DECLARE
    result 	boolean;
	
  BEGIN TRANSACTION;
   
	--Setup
	INSERT INTO Countries VALUES ( 'testCountry1') ;
	INSERT INTO Areas VALUES ( 'testCountry1' , 'testCity1' , 491630) ;
	INSERT INTO Areas VALUES ( 'testCountry1' , 'testCity2', 1337) ;
	INSERT INTO Cities VALUES ('testCountry1', 'testCity1', 400);
	INSERT INTO Towns VALUES ( 'testCountry1' , 'testCity2') ;
	INSERT INTO Persons VALUES ('testCountry1', '123456-1234', 'Fisken allan', 'testCountry1', 'testCity1', 99999999);
	
	
	--Test
	INSERT INTO Roads Values ('testCountry1', 'testCity1', 'testCountry1', 'testCity2', 'testCountry1', '123456-1234', 123);
	INSERT INTO Roads Values ('testCountry1', 'testCity1', 'testCountry1', 'testCity2', 'testCountry1', '123456-1234', 123);
	EXCEPTION WHEN OTHER
			BEGIN
			result := false;
			END
	
	ROLLBACK;
	RETURN result
  END; 
  $funcResult$ LANGUAGE plpgsql;

  
  
  
BEGIN TRANSACTION;
 --Setup
INSERT INTO Countries VALUES ( 'testCountry1') ;
INSERT INTO Areas VALUES ( 'testCountry1' , 'testCity1' , 491630) ;
INSERT INTO Areas VALUES ( 'testCountry1' , 'testCity2', 1337) ;
INSERT INTO Cities VALUES ('testCountry1', 'testCity1', 400);
INSERT INTO Towns VALUES ( 'testCountry1' , 'testCity2') ;
INSERT INTO Persons VALUES ('testCountry1', '123456-1234', 'Fisken allan', 'testCountry1', 'testCity1', 99999999);
--TEST
INSERT INTO Roads Values ('testCountry1', 'testCity1', 'testCountry1', 'testCity2', 'testCountry1', '123456-1234', 123);


INSERT INTO Roads Values ('testCountry1', 'testCity1', 'testCountry1', 'testCity2', 'testCountry1', '123456-1234', 123);
EXCEPTION
	WHEN * THEN	
		ROLLBACK TRANSACTION;	

ROLLBACK;
  
  
  
 
BEGIN TRANSACTION;
	 --Setup
	INSERT INTO Countries VALUES ( 'testCountry1') ;
	INSERT INTO Areas VALUES ( 'testCountry1' , 'testCity1' , 491630) ;
	INSERT INTO Areas VALUES ( 'testCountry1' , 'testCity2', 1337) ;
	INSERT INTO Cities VALUES ('testCountry1', 'testCity1', 400);
	INSERT INTO Towns VALUES ( 'testCountry1' , 'testCity2') ;
	INSERT INTO Persons VALUES ('testCountry1', '123456-1234', 'Fisken allan', 'testCountry1', 'testCity1', 99999999);
	
	--Test
	INSERT INTO Roads Values ('testCountry1', 'testCity1', 'testCountry1', 'testCity2', 'testCountry1', '123456-1234', 123);
	INSERT INTO Roads Values ('testCountry1', 'testCity1', 'testCountry1', 'testCity2', 'testCountry1', '123456-1234', 123);
		EXCEPTION WHEN OTHERS THEN
			ROLLBACK;
		
		END;
	
	ROLLBACK;
END;
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  

  
  
BEGIN TRANSACTION;
 --Setup
INSERT INTO Countries VALUES ( 'testCountry1') ;
INSERT INTO Areas VALUES ( 'testCountry1' , 'testCity1' , 491630) ;
INSERT INTO Areas VALUES ( 'testCountry1' , 'testCity2', 1337) ;
INSERT INTO Cities VALUES ('testCountry1', 'testCity1', 400);
INSERT INTO Towns VALUES ( 'testCountry1' , 'testCity2') ;
INSERT INTO Persons VALUES ('testCountry1', '123456-1234', 'Fisken allan', 'testCountry1', 'testCity1', 99999999);
--TEST
INSERT INTO Roads Values ('testCountry1', 'testCity1', 'testCountry1', 'testCity2', 'testCountry1', '123456-1234', 123);
INSERT INTO Roads Values ('testCountry1', 'testCity1', 'testCountry1', 'testCity2', 'testCountry1', '123456-1234', 123);
	EXCEPTION WHEN OTHERS THEN 
		ROLLBACK;
	END;
ROLLBACK;
END

