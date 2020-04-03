import scrapy

from ebay.items import ebayKleinanzeige
from ebay_kleinanzeigen import *
import hashlib,datetime
from ebay_spider import EbaySpider
import MySQLdb

class EbaySpider(EbaySpider):
  name = "ebay_checkIsDeleted"
  download_delay = 0.01
  def start_requests(self):
    conn = MySQLdb.connect(
                user='orges',
                passwd='123',
                db='autosEbay',
                host='0.0.0.0',
                charset="utf8",
                use_unicode=True
                )
    cursor = conn.cursor()
    cursor.execute(
            'select url from items where isDeleted = 0 order by zuletztgesehen asc limit 2000;'
            #'select url from vInteressantTageOnline;'
            #'select url from items;"# where url = "http://www.ebay-kleinanzeigen.de/s-anzeige/seat-leon-cupra-tdi/383851714-216-4678 ";'
    )
    rows = cursor.fetchall()
    for row in rows:
      yield self.make_requests_from_url(row[0])


