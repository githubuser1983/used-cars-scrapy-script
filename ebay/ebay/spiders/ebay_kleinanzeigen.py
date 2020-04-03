import zlib,re

def parseExtParams(t1):
   return t1[t1.find("extParams"):t1.find("rectangleBannerOpts")]


def parseDescription(t1):
   return re.compile('<p id="viewad-description-text" class="text-force-linebreak" itemprop="description">.+</p>').findall(t1)[0]


def parse(t1):
   return parseExtParams(t1)+parseDescription(t1)[0]
