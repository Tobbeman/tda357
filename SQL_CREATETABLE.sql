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
  personnumber char (11) CHECK (personnumber ~ '[0-9]{6}-[0-9]{4}') OR personnumber = ' '),
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

