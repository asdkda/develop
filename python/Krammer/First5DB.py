# -*- coding: utf-8 -*-

import urllib
import string

stock = []

#krammer
def get_today( URL ):
    i, j, start, name = 0, 0, 0, 0

    import HTMLParser       
    class WeaterHTMLParser(HTMLParser.HTMLParser):
        def handle_data(self, data):  
            data = data.strip()
            self.v = data
        def unknown_decl(self, data):    
             pass  

    Parser = WeaterHTMLParser()
    weatherWeb = urllib.urlopen(URL)  
    webContent = weatherWeb.read()#.decode('big5')  
    weatherWeb.close()
    for line in webContent.splitlines():
        start = string.find( line, 'GenLink2stk')
        if  start >= 0:
            if line[20] == "'":
                i, j = 0, 1

            name = line[start + 15: start + 19]
            #
            #print line.decode('utf-8')
            
        if string.find(line, '<td class="t3n1">') >= 0:
            if string.find( line, ';0.00') >= 0:
                continue
            i = i + 1
            if i == 3:
                Parser.feed(line)
                if j and len(Parser.v) < 3:
                    if name not in stock:
                        stock.append(name)
            if i == 4:
                i, j = 0, 0

    Parser.close()
    return stock

# 去抓網站 買超前5名 的股號
def get_db_nice_stock():
    #URL = "http://jsjustweb.jihsun.com.tw/z/zg/zg_DB_0_5.djhtm"
    URL = "http://211.72.248.20/z/zg/zg_DB_0_5.djhtm"
    get_today( URL )
    #URL = "http://jsjustweb.jihsun.com.tw/z/zg/zg_DD_0_5.djhtm"
    URL = "http://211.72.248.20/z/zg/zg_DD_0_5.djhtm"
    stock = get_today( URL )
#    nice_stock.sort()
    print stock

    return stock

	#寫到檔案裡
#    for x in nice_stock:
#        f.write(x)
#        f.write('\n')





