from twisted.enterprise import adbapi
import datetime,logging,os
import MySQLdb.cursors, MySQLdb
import getpass

class SQLStorePipeline(object):

    def __init__(self):
        mysqlUser = "orges"
        mysqlDb = "autosEbay"
        mysqlPw = getpass.getpass(prompt="Mysql-Pw for user '%s': " % mysqlUser)
        self.dbpool = adbapi.ConnectionPool('MySQLdb', db=mysqlDb, user=mysqlUser, passwd=mysqlPw, cursorclass=MySQLdb.cursors.DictCursor, charset='utf8', use_unicode=True)
        #pass
        self.myhashes = set([])
        thisfilepath = os.path.dirname(__file__)
        logging.basicConfig(filename=os.path.join(thisfilepath,"log.txt"), level=logging.DEBUG, format = '%(asctime)s %(message)s')


    def process_item(self, item, spider):
        # run db query in thread pool
        print 'process item:----------------------'
        print item
        if item['hash'] in self.myhashes:
          print "item already seen"
        else:
          print "item not seen"
          self.myhashes.add(item['hash'])
          query = self.dbpool.runInteraction(self._insert, item)
          query.addErrback(self.handle_error)
           

        return item

    def _insert(self, tx, item):
        #tx.execute("select name from application where name = %s", (self.safeValue(item['package']), ))
        #result = tx.fetchone()
        #if result:
        #    print 'exist --- ' + self.safeValue(item['package'])
        #else:
        if item['isDeleted'] == '1':
          originalUrl = item['originalUrl']
          query = "update items set isDeleted = 1 where url = '%s';" % originalUrl
          tx.execute(query)
          
        else:
          fieldsOfItem = item.fields.keys()
          #foI = ",".join([eval( ("self.safeValue(item['%s'])" % field) ) for field in fieldsOfItem])
          st = []
          fieldsOfItem.remove('originalUrl') # exclude this field which will not be written to db
          for field in fieldsOfItem:
            x = item[field]
            st.append(x)
          print st
          values = "'" + "','".join(st) + "'"
          columns = ",".join(fieldsOfItem)
          query = "insert into items (%s) values (%s) on duplicate key update zuletztgesehen='%s',preis='%s',erstzulassungsjahr='%s';" % (columns, values,item['zuletztgesehen'],item['preis'],item['erstzulassungsjahr'])
          print query        
          tx.execute(query)

    def safeValue(self,value):
        if value == [] :
            return ''
        else :
            return value[0].encode("utf-8")

    def handle_error(self, e):
        print e
        logging.info(e)
