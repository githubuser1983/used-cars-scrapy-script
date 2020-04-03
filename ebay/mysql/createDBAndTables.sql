drop database if exists autosEbay;

create database autosEbay;

use autosEbay;

drop table if exists items;
create table items(
  url varchar(1000) not null,
  responseCompressed longblob not null,
  lengthDescription integer,
  extParams varchar(1000) not null,
  hash varchar(255) not null,
  dateCrawled datetime not null,
  kw varchar(1000),
  verkaeufer varchar(30),
  angebotstyp varchar(30),
  preis integer not null,
  abtest varchar(30),
  fahrzeugtyp varchar(30),
  erstzulassungsjahr integer,
  getriebe varchar(30),
  leistungPS integer,
  modell varchar(30),
  kilometerstand integer,
  erstzulassungsmonat integer,
  kraftstoffart varchar(30),
  marke varchar(30),
  nichtReparierterSchaden varchar(30),
  erstellungsdatum datetime,
  anzahlBilder integer,
  plz varchar(20),
  spider varchar(30),
  zuletztgesehen datetime,
  isDeleted boolean,
  primary key (hash)
);


drop table if exists mlmodell;
create table mlmodell(
  erstelltAm datetime,
  pickleModell longblob,
  name varchar(100),
  anzahlItems integer,
  primary key (name, erstelltAm)
);
