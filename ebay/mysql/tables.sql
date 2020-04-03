
use autosEbay;

start transaction;

select 'avgItem';
drop table if exists avgItem;
create table avgItem as
select 
      verkaeufer, 
      angebotstyp, 
      fahrzeugtyp, 
      erstzulassungsjahr, 
      modell, 
      marke, 
      count(*) as cnt, 
      max(preis) as maxPreis, 
      min(preis) as minPreis, 
      avg(preis) as avgPreis,
      sqrt(variance(preis)) as sdPreis
      from items 
          where preis > 0 
           and nichtReparierterSchaden = 'nein'
         group by 
            verkaeufer, 
            angebotstyp, 
            fahrzeugtyp, 
            erstzulassungsjahr, 
            modell, 
            marke
         having count(*) > 2 
         order by erstzulassungsjahr desc, min(preis) asc, count(*) desc;

select 'vSummary';

drop table if exists vSummary;
create table vSummary as
select 
        avg(preis) as avg_preis,
        sqrt(variance(preis)) as sd_preis,
        avg(anzahlBilder) as avg_anzahlBilder,
        sqrt(variance(anzahlBilder)) as sd_anzahlBilder,
        avg(erstzulassungsjahr) as avg_erstzulassungsjahr,
        sqrt(variance(erstzulassungsjahr)) as sd_erstzulassungsjahr,
        avg(kilometerstand) as avg_kilometerstand,
        sqrt(variance(kilometerstand)) as sd_kilometerstand,
        avg(datediff(curdate(),str_to_date(erstellungsdatum, '%Y-%m-%d'))) as avg_tageerstellt,
        sqrt(variance(datediff(curdate(),str_to_date(erstellungsdatum, '%Y-%m-%d')))) as sd_tageerstellt,
        avg(leistungPS) as avg_leistungPS,
        sqrt(variance(leistungPS)) as sd_leistungPS
        from items where preis > 0;


select 'vNorm';

drop table if exists vNorm;
create table vNorm as
select i.hash,
       i.url,
       (leistungPS-avg_leistungPS)/sd_leistungPS as leistungPS,
       (preis - avg_preis)/sd_preis as preis,
       (anzahlBilder - avg_anzahlBilder)/sd_AnzahlBilder as anzahlBilder,
       (i.erstzulassungsjahr - avg_erstzulassungsjahr)/sd_erstzulassungsjahr as erstzulassungsjahr,
       (kilometerstand - avg_kilometerstand)/sd_kilometerstand as kilometerstand,
       (datediff(curdate(),str_to_date(erstellungsdatum, '%Y-%m-%d')) - avg_tageerstellt) / sd_tageerstellt as tageerstellt
     from items i, vSummary s;


select 'vScore';

drop table if exists vScore;
create table vScore as
  select hash,
         url,
         leistungPS,
         preis,
         anzahlBilder,
         erstzulassungsjahr,
         kilometerstand,
         tageerstellt,
         (0.5*anzahlBilder+2*erstzulassungsjahr+leistungPS ) - (4*preis+3*tageerstellt+kilometerstand) as score
         from vNorm;
              

select 'vInteressant';

drop table if exists vInteressant;
create table vInteressant as
select i.url,
       i.preis,
       i.marke,
       i.modell,
       i.getriebe,
       i.kraftstoffart,
       cnt
  from items i, avgItem v
       #, item_lof l
       where
         #i.hash = l.hash and
         i.preis <= 2000 
         and i.erstzulassungsjahr >= 2001
         and i.preis > 0 
         and i.anzahlBilder > 0
         and i.nichtReparierterSchaden = 'nein' and
         v.verkaeufer = i.verkaeufer and
         v.angebotstyp = i.angebotstyp and
         v.fahrzeugtyp = i.fahrzeugtyp and
         v.erstzulassungsjahr = i.erstzulassungsjahr and
         v.modell = i.modell and
         v.marke = i.marke and
         i.nichtReparierterSchaden = 'nein' and
         v.avgPreis-v.sdPreis > i.preis
         and i.spider = 'ebay_lm50'
         #and i.hash = s.hash
         and v.sdPreis > 0
         and i.isDeleted = 0
       order by preis asc, cnt desc;

select 'vTageOnline';

drop table if exists vTageOnline;
create table vTageOnline as
   select 
          marke,
          modell,
          fahrzeugtyp,
          getriebe,
          kraftstoffart,
          erstzulassungsjahr,
          kilometerstand,
          anzahlBilder,
          preis,
          datediff(zuletztgesehen,erstellungsdatum) as tageOnline 
           from items
             where isDeleted = 1
;


select 'vAvgTageOnline';

drop table if exists vAvgTageOnline;
create table vAvgTageOnline as
select marke,
       modell,
       fahrzeugtyp,
       getriebe,
       kraftstoffart,
       erstzulassungsjahr, 
       count(*) as cnt, 
       avg(kilometerstand) as avgKilometerstand,
       sqrt(variance(kilometerstand)) as sdKilometerstand,
       min(preis) as minPreis,
       max(preis) as maxPreis,
       median(preis) as medianPreis,
       avg(preis) as avgPreis, 
       sqrt(variance(preis)) as sdPreis,
       min(tageOnline) as minTageOnline,
       median(tageOnline) as medianTageOnline,
       max(tageOnline) as maxTageOnline,
       avg(tageOnline) as avgTageOnline,
       sqrt(variance(tageOnline)) as sdTageOnline,
       min(anzahlBilder) as minAnzahlBilder,
       median(anzahlBilder) as medianAnzahlBilder,
       max(anzahlBilder) as maxAnzahlBilder,
       avg(anzahlBilder) as avgAnzahlBilder,
       sqrt(variance(anzahlBilder)) as sdAnzahlBilder
          from vTageOnline 
             where erstzulassungsjahr between 1900 and 2015
             and preis between 50 and 50000
             group by marke,
                      modell,
                      fahrzeugtyp,
                      getriebe, 
                      kraftstoffart,
                      erstzulassungsjahr 
             having count(*) > 5
       order by 
           marke,
           modell,
           fahrzeugtyp,
           getriebe,
           kraftstoffart,
           erstzulassungsjahr;

select 'vPMarke';

drop table if exists vPMarke;
create table vPMarke as
 select marke,sum(cnt)/( select sum(cnt) from vAvgTageOnline ) as pMarke from vAvgTageOnline group by marke;

select 'vPModell';

drop table if exists vPModell;
create table vPModell as
 select modell, sum(cnt)/( select sum(cnt) from vAvgTageOnline) as pModell from vAvgTageOnline group by modell;


select 'vPFahrzeugtyp';

drop table if exists vPFahrzeugtyp;
create table vPFahrzeugtyp as
 select fahrzeugtyp, sum(cnt)/( select sum(cnt) from vAvgTageOnline) as pFahrzeugtyp from vAvgTageOnline group by fahrzeugtyp;


select 'vPGetriebe';

drop table if exists vPGetriebe;
create table vPGetriebe as
 select getriebe, sum(cnt)/( select sum(cnt) from vAvgTageOnline) as pGetriebe from vAvgTageOnline group by getriebe;

select 'vPKraftstoffart';

drop table if exists vPKraftstoffart;
create table vPKraftstoffart as
 select kraftstoffart, sum(cnt)/( select sum(cnt) from vAvgTageOnline) as pKraftstoffart from vAvgTageOnline group by kraftstoffart;

select 'vPErstzulasszungsjahr';

drop table if exists vPErstzulassungsjahr;
create table vPErstzulassungsjahr as
 select erstzulassungsjahr, sum(cnt)/( select sum(cnt) from vAvgTageOnline) as pErstzulassungsjahr from vAvgTageOnline group by erstzulassungsjahr;

select 'vPAvgTageOnline';

drop table if exists vPAvgTageOnline;
create table vPAvgTageOnline as
select vato.*,
       pMarke,
       pModell,
       pFahrzeugtyp,
       pGetriebe,
       pKraftstoffart,
       pErstzulassungsjahr
       from vAvgTageOnline vato
              left join vPMarke vpma on vato.marke = vpma.marke
              left join vPModell vpmo on vato.modell = vpmo.modell
              left join vPFahrzeugtyp vpf on vato.fahrzeugtyp = vpf.fahrzeugtyp
              left join vPGetriebe vpg on vato.getriebe = vpg.getriebe
              left join vPKraftstoffart vpk on vato.kraftstoffart = vpk.kraftstoffart
              left join vPErstzulassungsjahr vpe on vato.erstzulassungsjahr = vpe.erstzulassungsjahr;

select 'vInteressantTageOnline';

drop table if exists vInteressantTageOnline;
create table vInteressantTageOnline as
select i.url,
       i.preis,
       concat(greatest(v.minPreis,round(v.medianPreis-3*v.sdPreis)),'-',round(v.medianPreis),'-',least(v.maxPreis,round(v.medianPreis+3*v.sdPreis))) as dPreis,
       i.erstzulassungsjahr as bjahr,
       concat(v.minTageOnline,'-',round(v.medianTageOnline),'-',v.maxTageOnline) as dTageOnline,
       i.marke,
       i.modell,
       i.getriebe,
       i.kraftstoffart,
       i.fahrzeugtyp,
       datediff(i.zuletztgesehen,i.erstellungsdatum) as tageOnline,
       cnt
  from items i, vPAvgTageOnline v
       #, item_lof l
       where
         #i.hash = l.hash and
         i.preis > 50 and
         #i.erstzulassungsjahr >= 2000 and
         i.preis > 0 
         #and i.anzahlBilder > 0
         and i.nichtReparierterSchaden = 'nein' and
         v.fahrzeugtyp = i.fahrzeugtyp and
         v.erstzulassungsjahr = i.erstzulassungsjahr and
         v.kraftstoffart = i.kraftstoffart and
         v.modell = i.modell and
         v.marke = i.marke and
         v.getriebe = i.getriebe and
         i.nichtReparierterSchaden = 'nein' and
         i.preis < v.medianPreis-1000 and
         abs(v.avgKilometerstand-i.kilometerstand) < 4*v.sdKilometerstand and
         datediff(i.zuletztgesehen,i.erstellungsdatum) <= 2*v.medianTageOnline and
         i.spider = 'ebay_lm50' and
         #and i.hash = s.hash
         i.isDeleted = 0
       order by (i.preis-v.medianPreis)/v.medianPreis*(1/(tageOnline+1)*pMarke*pModell*pFahrzeugtyp*pGetriebe*pKraftstoffart*pErstzulassungsjahr) asc;

select 'vZuletztgesehen';

drop table if exists vZuletztgesehen;
create table vZuletztgesehen as
select url,preis,zuletztgesehen from items where isDeleted = 0 order by zuletztgesehen asc limit 20;


select 'vSpider';

drop table if exists vSpider;
create table vSpider as
select spider,isDeleted, count(*) as cnt from items group by spider,isDeleted;


commit;

