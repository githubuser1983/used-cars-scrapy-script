
use autosEbay;

drop view if exists avgItem;

create view avgItem as
select 
      verkaeufer, 
      angebotstyp, 
      fahrzeugtyp, 
      erstzulassungsjahr, 
      getriebe, 
      modell, 
      kraftstoffart, 
      marke, 
      nichtReparierterSchaden, 
      count(*) as cnt, 
      max(preis) as maxPreis, 
      min(preis) as minPreis, 
      avg(preis) as avgPreis
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
       cnt,
       score
  from items i, avgItem v, vScore s where
         i.preis <= 3000 
         and i.erstzulassungsjahr >= 2005 
         and i.preis > 0 
         and i.anzahlBilder > 0
         and i.nichtReparierterSchaden = 'nein' and
         v.verkaeufer = i.verkaeufer and
         v.angebotstyp = i.angebotstyp and
         v.fahrzeugtyp = i.fahrzeugtyp and
         v.erstzulassungsjahr = i.erstzulassungsjahr and
         v.modell = i.modell and
         v.marke = i.marke and
         v.nichtReparierterSchaden = i.nichtReparierterSchaden and
         v.minPreis = i.preis
         and i.spider = 'ebay_lm100'
         and i.hash = s.hash
       order by score desc;
