# -*- coding: utf-8 -*-

import urllib
import string

#krammer
def get_4ma(a0, n0, stock):
    #URL = "http://www.google.com/finance/historical?q=TPE:2449"
    URL = "http://www.google.com/finance/historical?q=TPE:"+str(stock)
    weatherWeb = urllib.urlopen(URL)  
    webContent = weatherWeb.read()  
    weatherWeb.close() 
    for line in webContent.splitlines():
        if string.find(line, 'class="rgt"') >= 0:
            a0.append(line[16:])
            n0 = n0 + 1
        if string.find(line, '<td class="rgt rm">') >= 0:
            if line[19:] == "0":
                for i in range(4):
                    del a0[n0]
                    n0 = n0 - 1
        if n0 == 15:
            break

def get_today_price(name, stock):      
    import HTMLParser       
    class WeaterHTMLParser(HTMLParser.HTMLParser):
        def handle_data(self, data):  
            data = data.strip()
            self.weather = []
            self.weather.append(data)     
        def unknown_decl(self, data):    
             pass  

    Parser = WeaterHTMLParser()
    #URL = "http://tw.stock.yahoo.com/q/q?s=2449"
    #URL = "http://tw.stock.yahoo.com/q/q?s="+str(stock)
    URL = "http://119.160.244.28/q/q?s="+str(stock)
    weatherWeb = urllib.urlopen(URL)  
    webContent = weatherWeb.read()#.decode('big5')  
    weatherWeb.close()
    for line in webContent.splitlines():
        if string.find(line, '<td align="center" bgcolor="#FFFfff" nowrap><b>') >= 0:
            Parser.feed(line)
            break
    Parser.close()
    return Parser.weather

def get_one_stock(stock):
    n0 = -1
    a0 = []
    t0 = []
    ma5 = 0
    name = ""
    diff = 0
    diffp = 0 #persentage of diff

    get_4ma( a0, n0, stock )
    t0 = get_today_price( name, stock )
    if a0 == []:
        print "Error!! a0 == [], stock = %d" % stock
        return
    if t0[0] == 0:
        print "Error!! t0 == 0, stock = %d" % stock
        return
    #print stock
    #print a0[3]+a0[7]+a0[11]+a0[15]
    #print t0[0]
    ma5 = (float(a0[3]) + float(a0[7]) + float(a0[11]) + float(a0[15]) + float(t0[0]))/5
    diff = float(t0[0]) - ma5
    diffp = float(diff*100)/float(t0[0])
    if float(t0[0])>=ma5 and diffp <= 1:
#        print str(stock)+" today = "+str(t0[0])+", 5MA = "+str(ma5)+", diff = "+str(diff)+", diffp = "+str(diffp)+"%"
        print "%d  today = %5s, 5MA = %.2f, diff = %.2f, diffp = %.3f%s" % (stock, t0[0], ma5, diff, diffp, "%")
    


