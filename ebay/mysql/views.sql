
use autosEbay;

drop view if exists avgItem;
create view avgItem as
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

drop view if exists vSummary;
create view vSummary as
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


drop view if exists vNorm;
create view vNorm as
select i.hash,
       i.url,
       (leistungPS-avg_leistungPS)/sd_leistungPS as leistungPS,
       (preis - avg_preis)/sd_preis as preis,
       (anzahlBilder - avg_anzahlBilder)/sd_AnzahlBilder as anzahlBilder,
       (i.erstzulassungsjahr - avg_erstzulassungsjahr)/sd_erstzulassungsjahr as erstzulassungsjahr,
       (kilometerstand - avg_kilometerstand)/sd_kilometerstand as kilometerstand,
       (datediff(curdate(),str_to_date(erstellungsdatum, '%Y-%m-%d')) - avg_tageerstellt) / sd_tageerstellt as tageerstellt
     from items i, vSummary s;


drop view if exists vScore;
create view vScore as
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
              

drop view if exists vInteressant;
create view vInteressant as
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

drop view if exists vTageOnline;
create view vTageOnline as
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


drop view if exists vAvgTageOnline;
create view vAvgTageOnline as
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


drop view if exists vInteressantTageOnline;
create view vInteressantTageOnline as
select i.url,
       i.preis,
       concat(v.minPreis,'-',round(v.medianPreis),'-',v.maxPreis) as dPreis,
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
         i.erstzulassungsjahr >= 2000 
         and i.preis > 0
         and i.anzahlBilder > 0
         and i.nichtReparierterSchaden = 'nein' and
         v.fahrzeugtyp = i.fahrzeugtyp and
         v.erstzulassungsjahr = i.erstzulassungsjahr and
         v.kraftstoffart = i.kraftstoffart and
         v.modell = i.modell and
         v.marke = i.marke and
         v.getriebe = i.getriebe and
         i.nichtReparierterSchaden = 'nein' and
         i.preis <= v.medianPreis and
         abs(v.avgKilometerstand-i.kilometerstand) < 4*v.sdKilometerstand and
         datediff(i.zuletztgesehen,i.erstellungsdatum) <= 2*v.medianTageOnline and
         i.spider = 'ebay_lm50' and
         #and i.hash = s.hash
         i.isDeleted = 0
       order by (i.preis-v.medianPreis)/v.medianPreis*(pMarke*pModell*pFahrzeugtyp*pGetriebe*pKraftstoffart*pErstzulassungsjahr) asc;

drop view if exists vZuletztgesehen;
create view vZuletztgesehen as
select url,preis,zuletztgesehen from items where isDeleted = 0 order by zuletztgesehen asc limit 20;


drop view if exists vSpider;
create view vSpider as
select spider,isDeleted, count(*) as cnt from items group by spider,isDeleted;


drop view if exists vPMarke;
create view vPMarke as
 select marke,sum(cnt)/( select sum(cnt) from vAvgTageOnline ) as pMarke from vAvgTageOnline group by marke;

drop view if exists vPModell;
create view vPModell as
 select modell, sum(cnt)/( select sum(cnt) from vAvgTageOnline) as pModell from vAvgTageOnline group by modell;

drop view if exists vPFahrzeugtyp;
create view vPFahrzeugtyp as
 select fahrzeugtyp, sum(cnt)/( select sum(cnt) from vAvgTageOnline) as pFahrzeugtyp from vAvgTageOnline group by fahrzeugtyp;

drop view if exists vPGetriebe;
create view vPGetriebe as
 select getriebe, sum(cnt)/( select sum(cnt) from vAvgTageOnline) as pGetriebe from vAvgTageOnline group by getriebe;

drop view if exists vPKraftstoffart;
create view vPKraftstoffart as
 select kraftstoffart, sum(cnt)/( select sum(cnt) from vAvgTageOnline) as pKraftstoffart from vAvgTageOnline group by kraftstoffart;

drop view if exists vPErstzulassungsjahr;
create view vPErstzulassungsjahr as
 select erstzulassungsjahr, sum(cnt)/( select sum(cnt) from vAvgTageOnline) as pErstzulassungsjahr from vAvgTageOnline group by erstzulassungsjahr;


drop view if exists vPAvgTageOnline;
create view vPAvgTageOnline as
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




select erstzulassungsjahr+ (erstzulassungsmonat-1)/12 as jahr, 
       avg(preis) as preis 
       from items where 
                erstzulassungsjahr > 1950 
                and erstzulassungsjahr <= 2015 
                and preis between 100 and 30000 
                and erstzulassungsmonat between 1 and 12 
             group by erstzulassungsjahr, erstzulassungsmonat 
        order by erstzulassungsjahr+ (erstzulassungsmonat-1)/12 asc;
