# -*- coding: utf-8 -*-

""" Arthor: Gavin.Ke """

import urllib
import string
import re
import os
import HTMLParser
from datetime import date
from termcolor import colored


# scan the stock list file
fileName = "/root/workspace/stockList"
while True:
	try:
		stockFile = open(fileName, "r")
		break
	except IOError:
		print "Oops!  That was no such file [%s].  Please check ..." % fileName
		exit()

file_content_list = stockFile.readlines()
stock_list = file_content_list[0].strip()
stockFile.close()

stockList = string.split(stock_list, " ")
unBuyStockList = string.split(stock_list, " ")

today = date.today()


class YahooHTMLParser(HTMLParser.HTMLParser):
	def handle_data(self, data):
		data = data.strip()		# 拿掉字首及字尾的空白

		if re.search(r"^[0-9]", data) and data != "0.00":
			self.price = ""
			self.price = data
		else:
			self.diff = ""
			self.diff = data.decode('big5')

	def handle_starttag(self, tag, attrs):
		if tag == "input" :
#			print u'%s' % attrs
			self.stockname = ""
			self.stockname = attrs.pop()[1].decode('big5')

	def unknown_decl(self, data):
		pass


"""
  @historyPrice :  過去四天的收盤價，不包含今天
  @stock :  股號
"""
gDayFormat = "%s, %s" %(today.day, today.year)	# 30, 2010

"""
  @stock :  股號

  @return :  (Parser.price, Parser.stockname, Parser.diff)
             今天的股價，股名，漲跌
"""
def get_today_price( stock ):
	Parser = YahooHTMLParser()

	#URL = "http://tw.stock.yahoo.com/q/q?s="+str(stock)
	URL = "http://119.160.244.28/q/q?s="+str(stock)
	YahooWeb = urllib.urlopen(URL)
	webContent = YahooWeb.read()
	YahooWeb.close()

	for line in webContent.splitlines():
		if string.find(line, '<td align="center" bgcolor="#FFFfff" nowrap><b>') >= 0:
			Parser.feed(line)
		elif string.find(line, '<td align="center" bgcolor="#FFFfff" nowrap><font color=#ff0000>') >= 0:
			Parser.feed(line)
		elif string.find(line, '<td align="center" bgcolor="#FFFfff" nowrap><font color=#000000>') >= 0:
			Parser.feed(line)
		elif string.find(line, '<td align="center" bgcolor="#FFFfff" nowrap><font color=#009900>') >= 0:
			Parser.feed(line)
		elif string.find(line, 'stkname') >= 0:
			Parser.feed(line)
			break

	Parser.close()
#	print u'%s %s %s' % (Parser.price, Parser.stockname, Parser.diff)
	return Parser.price, Parser.stockname, Parser.diff


"""
  @stock :  股號

  @return :  if error occur...
"""
def get_one_stock(stock):
	tuple1 = ()

	tuple1 = get_today_price( stock )
	price, stockName, todayDiff = tuple1[0], tuple1[1], tuple1[2]

	if float(price) == 0:
		print "Error!! price == 0, stock = %d" % stock
		return


	if todayDiff == "0.00" :
		if os.name == "nt" :
			todayDiff = "  0.00"
		else :
			todayDiff = " 0.00"
	elif len(todayDiff) == 4 :
		todayDiff = todayDiff + " "

	if os.name == "posix" :
		if todayDiff[0] == u"△" :
			todayDiff = colored(todayDiff, 'red')
		elif todayDiff[0] == u"▲" :
			todayDiff = colored(todayDiff, on_color='on_red')
		elif todayDiff[0] == u"▽" :
			todayDiff = colored(todayDiff, 'green')
		elif todayDiff[0] == u"▼" :
			todayDiff = colored(todayDiff, on_color='on_green')

	print u"  %5d  %s%s  %6s  %5s" % (stock, " "*(3-len(stockName))*2, stockName, price, todayDiff)


"""
  @requestURL :  買超排行的URL
"""
def check_list( requestURL ):
	counter, i, stockFlag = 0, 0, 0
#	name, price, diff = "", "", ""

	ListWeb = urllib.urlopen(requestURL)
	webContent = ListWeb.read()
	ListWeb.close()

	for line in webContent.splitlines():
		# date
		if string.find( line, '<div class="t11">') >= 0:
			date = re.sub(r".*>(.*)<.*", r"\1", line).decode('big5')
			print "  %s %s %s  %s   %s" % (date, " "*27, u"五日買", u"五日賣", u"總量")

		if string.find( line, 'oAddCheckbox') >= 0:
			counter += 1

		# stock number
		if  stockFlag == 0 and string.find( line, 'GenLink2stk') >= 0:
			stockNumber = re.sub(r".*\D(\d{4,6}).*", r"\1", line)
			if stockNumber in stockList :
				stockFlag = 1
				name = re.sub(r".*'(.*)'\);", r"\1", line).decode('big5')

		if stockFlag == 1 and stockNumber in unBuyStockList :
			del unBuyStockList[unBuyStockList.index(stockNumber)]

		if stockFlag == 1 and string.find(line, '<td class="t3') >= 0:
			i += 1
			if i == 1 :
				price = re.sub(r".*>(&nbsp;)?(.*)<.*", r"\2", line)

			elif i == 2 :
				diff = re.sub(r".*>(.*)<.*", r"\1", line)
				diff = re.sub(r"&nbsp;", r"", diff)
				if diff.find('+') >= 0 :
					diff = colored(diff, 'red')
				elif diff.find('-') >= 0 :
					diff = colored(diff, 'green')
	  			else :
					diff = " " + diff

			elif i == 3 :
				ratio = re.sub(r".*>(&nbsp;)?(.*)<.*", r"\2", line)
				if len(ratio) == 5 :
					ratio = " " + ratio
					

			elif i == 4 :
				buy = re.sub(r".*>(&nbsp;)?(.*)<.*", r"\2", line)

			elif i == 5 :
				sell = re.sub(r".*>(&nbsp;)?(.*)<.*", r"\2", line)

			elif i == 6 :
				total = re.sub(r".*>(&nbsp;)?(.*)<.*", r"\2", line)

				# reset flag
				i, stockFlag = 0, 0

				sellSum = re.sub(r".*>(&nbsp;)?(.*)<.*", r"\2", line)
				print "%2d - %s %s%s  %s  %s  %s | %6s  %6s  %6s" % (counter, stockNumber, " "*(3-len(name))*2, name, price, diff, ratio, buy, sell, total)


""" ===========   main  =========== """

print stockList

if os.name == "posix" :
	print "檢查 自營商 買超名單..."
else :
	print "Check list..."
# 上市自營商買超5日排行
#URL = "http://jsjustweb.jihsun.com.tw/z/zg/zg_DB_0_5.djhtm"
URL = "http://211.72.248.20/z/zg/zg_DB_0_5.djhtm"
check_list( URL )
print "-"*30

if os.name == "posix" :
	print "檢查 投信 買超名單..."
else :
	print "Check list..."
# 上市投信買超5日排行
#URL = "http://jsjustweb.jihsun.com.tw/z/zg/zg_DD_0_5.djhtm"
URL = "http://211.72.248.20/z/zg/zg_DD_0_5.djhtm"
check_list( URL )
print "="*30

if os.name == "posix" :
	print "列出未買超名單..."
else :
	print "Show un-buy list..."

for x in unBuyStockList :
	get_one_stock(int(x))





