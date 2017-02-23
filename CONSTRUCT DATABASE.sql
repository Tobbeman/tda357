--Create Table--
DROP TABLE IF EXISTS Roads CASCADE;
DROP TABLE IF EXISTS Hotels CASCADE;
DROP TABLE IF EXISTS Persons CASCADE;
DROP TABLE IF EXISTS Cities CASCADE;
DROP TABLE IF EXISTS Towns CASCADE;
DROP TABLE IF EXISTS Areas CASCADE;
DROP TABLE IF EXISTS Countries CASCADE;

create table Countries(
  name character varying (80) PRIMARY KEY
);
create table Areas(
  country character varying (80) REFERENCES countries(name),
  name character varying (80),
  population integer CHECK (population > 0),
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
  visitbonus integer CHECK (visitbonus >= 0),
  FOREIGN KEY (country,name) REFERENCES areas(country,name),
  PRIMARY KEY (country,name)
);
create table Persons(
  country character varying (80) REFERENCES countries(name),
  personnumber char (11) CHECK (personnumber ~ '[0-9]{6}-[0-9]{4}' OR personnumber = ' '),
  name character varying (80),
  locationcountry character varying (80),
  locationarea character varying (80),
  budget numeric CHECK (budget >= 0),
  FOREIGN KEY (locationcountry,locationarea) REFERENCES areas(country,name),
  PRIMARY KEY (country,personnumber)
);
create table Hotels(
  name character varying (80),
  locationcountry character varying (80),
  locationname character varying (80),
  ownercountry character varying (80),
  ownerpersonnumber character varying (13),
  FOREIGN KEY (locationcountry,locationname) REFERENCES cities(country,name),
  FOREIGN KEY (ownercountry,ownerpersonnumber) REFERENCES persons(country,personnumber),
  PRIMARY KEY (locationcountry,locationname,ownercountry,ownerpersonnumber )
);
create table Roads(
  fromcountry character varying (80),
  fromarea character varying (80),
  tocountry character varying (80),
  toarea character varying (80),
  ownercountry character varying (80),
  ownerpersonnumber character varying (13),
  roadtax numeric CHECK (roadtax >= 0),
  FOREIGN KEY (fromcountry,fromarea) REFERENCES areas(country,name),
  FOREIGN KEY (tocountry,toarea) REFERENCES areas(country,name),
  FOREIGN KEY (ownercountry,ownerpersonnumber) REFERENCES persons(country,personnumber),
  PRIMARY KEY (fromcountry,fromarea,tocountry,toarea, ownercountry, ownerpersonnumber)
);
--end Create Table--
--Create Views--
DROP VIEW IF EXISTS NextMoves;
CREATE VIEW NextMoves AS
SELECT persons.country, persons.personnumber, A1.country AS currentCountry, A1.name AS currentArea, A2.country AS validCountry, A2.name AS validArea, roads.roadtax
FROM persons, areas A1, areas A2, roads
WHERE persons.locationcountry = A1.country AND persons.locationarea = A1.name AND roads.fromcountry = A1.country AND roads.fromarea = A1.name AND roads.tocountry = A2.country AND roads.toarea = A2.name AND roads.roadtax < persons.budget;
--end Create Views--
--Fill database--

--MUST HAVE--
INSERT INTO Countries VALUES (' ') ;
INSERT INTO Areas VALUES (' ', ' ', 1) ;
INSERT INTO Persons VALUES ( ' ' , ' ' , 'The Government' , ' ' , ' ' , 100000) ;
--Generic--
INSERT INTO Countries VALUES ('Sweden');

INSERT INTO Areas VALUES ( 'Sweden' , 'Gothenburg' , 491630) ;
INSERT INTO Areas VALUES ( 'Sweden' , 'Stockholm' , 1006024) ;
INSERT INTO Areas VALUES ( 'Sweden' , 'Visby' , 20000) ;

INSERT INTO Cities VALUES ( 'Sweden' , 'Gothenburg' , 250) ;
INSERT INTO Cities VALUES ( 'Sweden' , 'Stockholm' , 500) ;
INSERT INTO Cities VALUES ( 'Sweden' , 'Visby' , 125) ;

INSERT INTO Persons VALUES ( 'Sweden' , '940606-6952' , 'Tobias Laving' , 'Sweden' , 'Gothenburg' , 100000);
INSERT INTO Persons VALUES ( 'Sweden' , '970221-4555' , 'Daniel Laving' , 'Sweden' , 'Stockholm' , 100000);

INSERT INTO Hotels VALUES('Hotel', 'Sweden', 'Gothenburg', 'Sweden', '940606-6952');
INSERT INTO Hotels VALUES('Hotel', 'Sweden', 'Stockholm', 'Sweden', '940606-6952');
INSERT INTO Hotels VALUES('Hotel', 'Sweden', 'Gothenburg', 'Sweden', '970221-4555');
INSERT INTO Hotels VALUES('Hotel', 'Sweden', 'Stockholm', 'Sweden', '970221-4555');
INSERT INTO Hotels VALUES('Hotel', 'Sweden', 'Visby', 'Sweden', '970221-4555');

INSERT INTO Roads VALUES ('Sweden', 'Gothenburg', 'Sweden', 'Stockholm', ' ', ' ', 10);
INSERT INTO Roads VALUES ('Sweden', 'Gothenburg', 'Sweden', 'Stockholm', 'Sweden', '940606-6952', 15);
--INSERT INTO Roads VALUES ('Sweden', 'Stockholm', 'Sweden', 'Gothenburg', 'Sweden', '940606-6952', 15);



--end Fill database--



