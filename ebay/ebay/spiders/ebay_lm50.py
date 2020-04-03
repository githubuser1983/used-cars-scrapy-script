import scrapy

from ebay.items import ebayKleinanzeige
from ebay_kleinanzeigen import *
import hashlib,datetime
from ebay_spider import EbaySpider

class EbaySpider(EbaySpider):
  name = "ebay_lm50"
  start_urls = [
      #"http://www.ebay-kleinanzeigen.de/s-autos/anbieter:privat/anzeige:angebote/c216" # alle neuesten wagen
      #"http://www.ebay-kleinanzeigen.de/s-anzeige/weite-info/381706488-216-4311" # test
      "http://www.ebay-kleinanzeigen.de/s-autos/65549/anbieter:privat/anzeige:angebote/c216l4376r50" # lm 50 km umgebung
  ]

