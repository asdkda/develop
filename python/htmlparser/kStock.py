# -*- coding: utf-8 -*-

""" Arthor: Krammer, Gavin.Ke """

import urllib
import string
import re
import os
import HTMLParser
from datetime import date

# 更改顯示色彩
if os.name == "posix" :
	esc=""
	redf=esc+"[31m"
	redb=esc+"[41m"
	greenf=esc+"[32m"
	greenb=esc+"[42m"
	whitef=esc+"[37m"
	blackf=esc+"[30m"
	reset=esc+"[0m"

today = date.today()
stockList = []

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
			self.stockname = attrs.pop()[1]
			if isinstance(self.stockname, unicode) :
				print "unicode"
			else:
				self.stockname = self.stockname.decode('big5')
#			print self.stockname
#			self.stockname = attrs.pop()[1].decode('big5')
#			print "%s" % self.stockname

	def unknown_decl(self, data):
		pass


""" ===========   get_one_stock()  =========== """

"""
  @historyPrice :  過去四天的收盤價，不包含今天
  @stock :  股號
"""
gDayFormat = "%s, %s" %(today.day, today.year)	# 30, 2010
def get_4ma(historyPrice, stock):
	n, todayFlag = 0, -1

	#URL = "http://www.google.com/finance/historical?q=TPE:"+str(stock)
	URL = "http://64.233.183.105/finance/historical?q=TPE:"+str(stock)
	GoogleWeb = urllib.urlopen(URL)
	webContent = GoogleWeb.read()
	GoogleWeb.close()

	for line in webContent.splitlines():
		if todayFlag == -1 and string.find(line, '<td class="lm">') >= 0 :	# date
			if string.find(line, gDayFormat) >= 0 :
				todayFlag = 1
			else :
				todayFlag = 0

		elif string.find(line, 'class="rgt"') >= 0 :	# price
			n += 1

			if n % 4 == 0 :
				if todayFlag == 1 :
					n = 0
					todayFlag = 0
					continue

				historyPrice.append(line[16:])

				if n == 16:
					break

		"""
		if string.find(line, '<td class="rgt rm">') >= 0:
			if line[19:] == "0":
				for i in range(4):
					del historyPrice[n]
					n = n - 1
		"""


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
def get_one_stock( rank, stock):
	historyPrice = []
	tuple1 = ()

	get_4ma( historyPrice, stock )
	tuple1 = get_today_price( stock )
	price, stockName, todayDiff = tuple1[0], tuple1[1], tuple1[2]

	if historyPrice == []:
		print "Error!! historyPrice == [], stock = %d" % stock
		return
	if float(price) == 0:
		print "Error!! price == 0, stock = %d" % stock
		return

	#print stock
	#print historyPrice[0]+historyPrice[1]+historyPrice[2]+historyPrice[3]
	ma5 = (float(historyPrice[0]) + float(historyPrice[1]) + float(historyPrice[2]) + float(historyPrice[3]) + float(price))/5
	diff = float(price) - ma5
	diffp = float(diff*100)/float(price) #persentage of diff


	if todayDiff == "0.00" :
		if os.name == "nt" :
			todayDiff = "  0.00"
		else :
			todayDiff = " 0.00"
	elif len(todayDiff) == 4 :
		todayDiff = todayDiff + " "

	if os.name == "posix" :
		if todayDiff[0] == u"△" :
			todayDiff = redf + todayDiff + reset
		elif todayDiff[0] == u"▲" :
			todayDiff = redf + whitef + todayDiff + reset
		elif todayDiff[0] == u"▽" :
			todayDiff = greenf + todayDiff + reset
		elif todayDiff[0] == u"▼" :
			todayDiff = greenf + blackf + todayDiff + reset

	if float(price)>=ma5 and diffp <= 1:
		print u" %2d  - %5d  %s%s  %6s  %5s | %5.2f %5.2f%s" % (rank, stock, " "*(3-len(stockName))*2, stockName, price, todayDiff, ma5, diffp, "%")


""" ===========   get_list()  =========== """

"""
  @stockNumber :  股號
  @index :  1 代表自營商，2 代表投信

  @return :  (addIntoList2, addIntoList3)
"""
def check_amount( stockNumber, index, totalAmount ):
	foreignFlag, foreignSum = 0, 0
	sellFlag, sellDay = 0, 0
	counter = 0
	addIntoList2, addIntoList3 = 0, 0
	lineNumber = ()

	if index == 1 :
		lineNumber = (12, 19, 26, 33, 40)
	elif index == 2 :
		lineNumber = (8, 13, 18, 23, 28)

#	URL = http://jsjustweb.jihsun.com.tw//z/zc/zcl/zcl_" + stockNumber + ".asp.htm"
	requestURL = "http://211.72.248.20//z/zc/zcl/zcl_" + stockNumber + ".asp.htm"
	AmountWeb = urllib.urlopen(requestURL)
	AmountwebContent = AmountWeb.read()
	AmountWeb.close()

	for line in AmountwebContent.splitlines():
##		""" 2. 賣超超過一天 """
##		if sellFlag == 0 :
##			if index == 1 and string.find(line, '<td class="t10" colspan="5">') >= 0 :
##				if string.find(line.decode('big5'), u'自營商買賣超') >= 0:
##					sellFlag = 1
##			elif index == 2 and string.find(line, '<td class="t10" colspan="3">') >= 0 :
##				if string.find(line.decode('big5'), u'投信買賣超') >= 0:
##					sellFlag = 1
##
##		elif sellFlag == 1 :
##			counter += 1
##			if counter in lineNumber :
##				line = re.sub(r",", "", line)
##				if float(re.sub(r".*>(-?\d*)<.*", r"\1", line)) < 0 :
##					sellDay += 1
##			if counter == lineNumber[4] :  # stop parse html
##				sellFlag = 0
##				break

		""" 3. 外資五天總和賣超不大於買超總量的10% """
		if foreignFlag == 0 and string.find(line, '<td class="t10" colspan="4">') >= 0:
			if string.find(line.decode('big5'), u'外資買賣超') >= 0:
				foreignFlag = 1

		elif foreignFlag == 1 :
			counter += 1
			if counter == 11 or counter == 17 or counter == 23 or counter == 29 or counter == 35 :
				line = re.sub(r",", "", line)
				foreignSum += float(re.sub(r".*>(-?\d*)<.*", r"\1", line))

			if counter == 35 :
				""" debug
				print line
				print re.sub(r".*>(-?\d*)<.*", r"\1", line)
				print "sum = %.0f" % foreignSum
				"""
				foreignFlag, counter = 0, 0


#	if sellDay <= 1 :
#		addIntoList2 = 1
	addIntoList2 = 1

	if foreignSum > 0 or totalAmount*0.1 > abs(foreignSum) :
		addIntoList3 = 1

	return addIntoList2, addIntoList3


"""
  @requestURL :  買超排行的URL
  @index :  1 代表自營商，2 代表投信
"""
def get_list( requestURL, index ):
	counter, i, stockFlag = 0, 0, 0
	buySum, sellSum, totalAmount = 0, 0, 0
	addIntoList1, addIntoList2, addIntoList3 = 0, 0, 0

	ListWeb = urllib.urlopen(requestURL)
	webContent = ListWeb.read()
	ListWeb.close()

	for line in webContent.splitlines():
		if string.find( line, 'oAddCheckbox') >= 0:
			counter += 1

		# stock number
		if  stockFlag == 0 and string.find( line, 'GenLink2stk') >= 0:
			stockNumber = re.sub(r".*\D(\d{4,6}).*", r"\1", line)
			stockFlag = 1

		""" 1. 5日賣出張數不得超過買入張數的特定%數張 """
		if stockFlag == 1 and string.find(line, '<td class="t3') >= 0:
			i += 1
			if i < 4 :
				continue
			elif i == 4 :
				buySum = re.sub(r".*>(&nbsp;)?(\d*),?(\d*)<.*", r"\2\3", line)
			elif i == 5 :
				sellSum = re.sub(r".*>(&nbsp;)?(\d*),?(\d*)<.*", r"\2\3", line)
			elif i == 6 :
				# reset flag
				i, stockFlag = 0, 0
				multiplier = 0
				IbuySum = int(buySum)

				if IbuySum >= 10000 :
					multiplier = 0.01
				elif IbuySum >= 5000 and IbuySum < 10000 :
					multiplier = 0.05
				elif IbuySum < 5000 :
					multiplier = 0.1

				if IbuySum*multiplier > int(sellSum) :
					addIntoList1 = 1
					totalAmount = re.sub(r".*>(&nbsp;)?(\d*),?(\d*)<.*", r"\2\3", line)

		if addIntoList1 == 1 :
			addIntoList2, addIntoList3 = check_amount( stockNumber, index, int(totalAmount) )

			if addIntoList2 == 1 and addIntoList3 == 1 :
				stockList.append((counter, stockNumber))

			# reset flag
			addIntoList1 = 0



""" ===========   main  =========== """

if os.name == "posix" :
	print "加入 自營商 投信 買超名單..."
else :
	print "Add list..."
# 上市自營商買超5日排行
#URL = "http://jsjustweb.jihsun.com.tw/z/zg/zg_DB_0_5.djhtm"
URL = "http://211.72.248.20/z/zg/zg_DB_0_5.djhtm"
get_list( URL, 1 )

# 上市投信買超5日排行
#URL = "http://jsjustweb.jihsun.com.tw/z/zg/zg_DD_0_5.djhtm"
URL = "http://211.72.248.20/z/zg/zg_DD_0_5.djhtm"
get_list( URL, 2 )

#print stockList
#print "-" * 30


if os.name == "posix" :
	print "檢查5日均線..."
else :
	print "Check 5MA..."

""" 4. 與5日均線差小於1％ """
for (rank, number) in stockList:
	get_one_stock(rank, int(number))

#if os.name == "nt" :
#	raw_input("Done. Press any key...")

