import scrapy

from ebay.items import ebayKleinanzeige
from ebay_kleinanzeigen import *
import hashlib,datetime

class EbaySpider(scrapy.Spider):
  name = "ebay"
  allowed_domains = ["www.ebay-kleinanzeigen.de"]
  #start_urls = [
      #"http://www.ebay-kleinanzeigen.de/s-autos/anbieter:privat/anzeige:angebote/c216" # alle neuesten wagen
      #"http://www.ebay-kleinanzeigen.de/s-autos/65549/anbieter:privat/anzeige:angebote/c216l4376r50" # lm 50 km umgebung
      #"http://www.ebay-kleinanzeigen.de/s-autos/limburg/anbieter:privat/anzeige:angebote/c216l4376r20" # limburg und umgebung 20 km alle von privat
      #"http://www.ebay-kleinanzeigen.de/s-autos/65549/anbieter:privat/anzeige:angebote/c216l4376r20+autos.typ_s:kleinwagen" # limburg und umgebung alle von privat, kleinwagen
      #"http://www.ebay-kleinanzeigen.de/s-autos/65549/anbieter:privat/anzeige:angebote/c216l4376r20+autos.typ_s:limousine" # wie oben, nur limousine
      #"http://www.ebay-kleinanzeigen.de/s-autos/frankfurt-%28main%29/anbieter:privat/anzeige:angebote/c216l4292" # nur frankfurt
  #]

  download_delay = 0.5

  baseUrl = "http://www.ebay-kleinanzeigen.de"

  rename = { 'Marke' : 'marke',
             'Angebotstyp': 'angebotstyp',
             'Erstzulassungsmonat' : 'erstzulassungsmonat',
             'Nicht_reparierter_Schaden' : 'nichtReparierterSchaden',
             'Kraftstoffart': 'kraftstoffart',
             'Leistung__PS_' : 'leistungPS',
             'Erstzulassungsjahr' : 'erstzulassungsjahr',
             'Kilometerstand':'kilometerstand',
             'abtest':'abtest',
             'Verkaeufer':'verkaeufer',
             'Getriebe':'getriebe',
             'kw':'kw',
             'Preis':'preis',
             'Modell':'modell',
             'Fahrzeugtyp':'fahrzeugtyp'
            }

  def isDeleted(self,response):
    return 1*(response.url.find("DELETED_AD")>0)

  def parse(self, response):
    #filename = response.url.split("/")[-2] + '.html'
    #with open(filename, 'wb') as f:
    #  f.write(response.body)
    #print ">>>>>>%s" % response.url
    if not self.isDeleted(response): # url is not from a deleted item
      if response.url.find('/s-anzeige')>0: # this response comes from a url which is an item
        yield scrapy.Request(response.url, callback=self.parse_item)
      else: # this is a listing of items:
        for rs in re.compile('href="/s-anzeige/[^"]*">').findall(response.body):
          link = rs[6:rs.find('">')]
          url = self.baseUrl+link
          yield scrapy.Request(url, callback=self.parse_item)
        for link in response.xpath('/html/body/div[1]/div[3]/div[1]/div[5]/div/div/div[2]/a/@href').extract():
          url = self.baseUrl+link
          yield scrapy.Request(url, callback=self.parse)
    else: # url is from a deleted item:
      item = ebayKleinanzeige()
      item['isDeleted'] = '1'
      item['originalUrl'] = response.meta['redirect_urls'][0]
      item['hash'] = hashlib.md5(item['originalUrl']).hexdigest() # hack here, we do not need hash any further
      yield item

  def parse_item(self,response):
    print response
    item = ebayKleinanzeige()
    item['url'] = response.url
    item['responseCompressed'] = ''#zlib.compress(response.body,9)
    item['extParams'] = parseExtParams(response.body)
    item['hash'] = hashlib.md5(response.url).hexdigest()
    item['dateCrawled'] = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    dt = re.compile('<dd class="attributelist--value">(\d\d\.\d\d\.\d\d\d\d)</dd>').findall(response.body)[0]
    item['erstellungsdatum'] = datetime.datetime.strptime(dt,"%d.%m.%Y").strftime("%Y-%m-%d")
    item['anzahlBilder'] = "%s" % (len(re.compile('data-imgsrc="http://i.ebayimg.com/00/s').findall(response.body))/2)
    item['plz'] = re.compile('"plz": "(\d+)",').findall(response.body)[0]
    item['spider'] = self.name
    item['zuletztgesehen'] = item['dateCrawled']
    item['isDeleted'] = "%s" %  ( 1*(response.url.find("DELETED_AD")>0) )
    if response.meta.has_key('redirect_urls'):
      item['originalUrl'] = response.meta['redirect_urls'][0]
    else:
      item['originalUrl'] = item['url']
    ep = item['extParams']
    d = eval(ep[ep.find("{")-1:ep.find("}")+1])
    for k in self.rename.keys():
      if d.has_key(k):
        item[self.rename[k]] = d[k]
      else:
        item[self.rename[k]] = ''
    # kleinwagen,2003,manuell,60,2_reihe,198000,12,benzin,peugeot,nein : reihenfolge kann sich der attribute kann sich aendern
    try:
      attr = re.compile('attributes:"([a-zA-Z0-9_\,]+)"').findall(response.body)[0]
      item['erstzulassungsjahr'] = [t for t in re.compile('"(\d\d\d\d)\,|\,(\d\d\d\d)"|\,(\d\d\d\d)\,').findall(attr)[0] if len(t) == 4][0] #ueberschreiben falls moeglich
      print ">>>> erstzulassungsjahr = %s" % item['erstzulassungsjahr']
      print ">>>> attr = %s" % attr
    except:
      item['erstzulassungsjahr'] = d['Erstzulassungsjahr']
    try:
      item['preis'] = re.compile('itemprop="price" content="(\d+)\.\d+" />').findall(response.body)[0] # preis ueberschreiben falls moeglich
    except:
      try:
        item['preis'] = d['Preis']
      except:
        item['preis'] = '0'
    item['lengthDescription'] = "%s" % len(response.xpath('/html/body/div[1]/section[1]/section/section/article/section[2]/section/p').extract()[0]) # description ueberschreiben falls moeglich

    yield item


