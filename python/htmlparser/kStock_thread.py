# -*- coding: utf-8 -*-

""" Arthor: Krammer, Gavin.Ke """

import urllib
import string
import re
import os
import HTMLParser
from datetime import date

import Queue
import thread
import time

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

# 控制輸出順序
totalNumber = 1
indexChanged = 0

today = date.today()
stockList = []
queue = Queue.Queue()

class DbgLock:
	def __init__(self, name):  
		self.lock = thread.allocate_lock()  
		self.name = name  

	def acquire(self):  
		self.lock.acquire()  
#		print ":: Thread %d Locking %s" % (thread.get_ident(), self.name)  

	def release(self):  
#		print ":: Thread %d Releasing %s" % (thread.get_ident(), self.name)  
		self.lock.release()  

	def locked(self):  
		return self.lock.locked()

taskqueue_lock = DbgLock("taskqueue")
data_lock = DbgLock("data")

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
				for c in ('big5','big5hkscs', 'utf-8', 'gbk', 'gb2312') :
					try:
						self.stockname = self.stockname.decode(c)
						return
					except Exception, e :
						#print "[%s%s%s], codec can't decode with %s!" % ( redf, e, reset, c )
						pass
				# can't be decode...
				self.stockname = "XXXXXX"

	def unknown_decl(self, data):
		pass


def OSPrint(LinuxFormat, MSFormat):
	if os.name == "posix" :
		print LinuxFormat
	else :
		print MSFormat


""" ===========   get_one_stock()  =========== """

"""
  @historyPrice :  過去四天的收盤價，不包含今天
  @stock :  股號
"""
def get_4ma(historyPrice, stock):
	n, todayFlag = 0, -1
	DayFormat = "%s, %s" %(today.day, today.year)	# 30, 2010

	#URL = "http://www.google.com/finance/historical?q=TPE:"+str(stock)
	URL = "http://64.233.183.105/finance/historical?q=TPE:"+str(stock)
	GoogleWeb = urllib.urlopen(URL)
	webContent = GoogleWeb.read()
	GoogleWeb.close()

	for line in webContent.splitlines():
		if todayFlag == -1 and string.find(line, '<td class="lm">') >= 0 :	# date
			if string.find(line, DayFormat) >= 0 :
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
	#print u'%s %s %s' % (Parser.price, Parser.stockname, Parser.diff)
	return Parser.price, Parser.stockname, Parser.diff


"""
  @count :  輸出的順序
"""
def sequentialize( count ):
	global totalNumber

	for i in range(100):
		if totalNumber != count:
			time.sleep(0.05)
		else :
			break
	totalNumber += 1

"""
  @index :  是投信(1)還是自營(2)
  @count :  輸出的順序
  @stock :  股號

  @return :  if error occur...
"""
def get_one_stock( index, count, stock ):
	global totalNumber, indexChanged
	historyPrice = []

	get_4ma( historyPrice, stock )
	(price, stockName, todayDiff) = get_today_price( stock )

	if historyPrice == []:
		print "Error!! historyPrice == [], stock = %d" % stock
		sequentialize(count)
		return
	if float(price) == 0:
		print "Error!! price == 0, stock = %d" % stock
		sequentialize(count)
		return

	if len(historyPrice) < 4 :
		ma5 = 0
	else :
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
			todayDiff = redb + whitef + todayDiff + reset
		elif todayDiff[0] == u"▽" :
			todayDiff = greenf + todayDiff + reset
		elif todayDiff[0] == u"▼" :
			todayDiff = greenb + blackf + todayDiff + reset

	sequentialize(count)

	if float(price)>=ma5 and diffp <= 2:
		data_lock.acquire()
		if index == 2 and indexChanged == 0 :
			print "-" * 50
			OSPrint("投信:", "2:")
			indexChanged = 1

		rank = stockList[count-1][1]
		totalAmount = stockList[count-1][4]
		divisor = stockList[count-1][5]
		"""
		@rank :  買超排行
		@totalAmount :  5日買賣超總和
		@divisor :  5日賣超所佔的百分比
		"""
		print u" %2d  - %6d  %s%s  %6s  %5s | %6.2f %6d %5.2f%%" % (rank, stock, " "*(3-len(stockName))*2, stockName, price, todayDiff, ma5, totalAmount, divisor*100)
		data_lock.release()




""" ===========   get_list()  =========== """

"""
  @stockNumber :  股號
  @index :  1 代表自營商，2 代表投信
  @totalAmount :  買超總量

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
				# 新股票可能不到五日交易日
				try:
					foreignSum += float(re.sub(r".*>(-?\d*)<.*", r"\1", line))
				except Exception, e :
					#print "[%s%s%s] %s is less than 5 trade day!" % ( redf, e, reset, stockNumber )
					pass

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
	global data_lock

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
				divisor = float(sellSum)/int(buySum)

				if divisor < 0.1 :
					addIntoList1 = 1
					totalAmount = int(re.sub(r".*>(&nbsp;)?(\d*),?(\d*)<.*", r"\2\3", line))

		if addIntoList1 == 1 :
			addIntoList2, addIntoList3 = check_amount( stockNumber, index, totalAmount )

			if addIntoList2 == 1 and addIntoList3 == 1 :
				data_lock.acquire()
				stockList.append( (index, counter, stockNumber, totalAmount, totalAmount, divisor) )
				data_lock.release()

			# reset flag
			addIntoList1 = 0

"thread func, check the URL and get the list"
def thread_func(URL, index):
	#global taskqueue_lock

	try:
		while True:
			#taskqueue_lock.acquire()
			count = queue.get()
			#taskqueue_lock.release()

			#print "Thread %d got work to do: %s" % (thread.get_ident(), URL)
			get_list( URL, index )

			queue.task_done()
			thread.exit()

	except Exception, e:
		print "thread_func: Thread %d is *CRASHED*!" % (thread.get_ident(), )
		queue.task_done()
		thread.exit()

"thread func, get the stock price and print the target list"
def thread_func2(arg):
	#global taskqueue_lock

	try:
		while True:
			#taskqueue_lock.acquire()
			(index, count, number) = queue.get()
			#taskqueue_lock.release()

			#print "Thread %d got work to do: %s" % (thread.get_ident(), URL)
			get_one_stock(index, count, number)

			queue.task_done()
			thread.exit()

	except Exception, e:
		print "thread_func2: Thread %d is *CRASHED*!" % (thread.get_ident(), )
		queue.task_done()
		thread.exit()

""" ===========   main  =========== """
def main():
	global queue, totalNumber
	#global ending_flag

	OSPrint("加入 自營商 投信 買超名單...", "Add list...")

	# start working threads
	#for i in xrange(2):
	#	thread.start_new_thread(thread_func, (None,))
	# 上市自營商買超5日排行
	#URL = "http://jsjustweb.jihsun.com.tw/z/zg/zg_DB_0_5.djhtm"
	# TODO change thread to threading. We need a method to check when the thread finish it's job...
	thread.start_new_thread(thread_func, ("http://211.72.248.20/z/zg/zg_DB_0_5.djhtm", 1))
	#thread.start_new_thread(thread_func, ("http://211.72.248.20/z/zg/zg_DB_0_-1.djhtm", 1))
	# 上市投信買超5日排行
	#URL = "http://jsjustweb.jihsun.com.tw/z/zg/zg_DD_0_5.djhtm"
	thread.start_new_thread(thread_func, ("http://211.72.248.20/z/zg/zg_DD_0_5.djhtm", 2))
	#thread.start_new_thread(thread_func, ("http://211.72.248.20/z/zg/zg_DD_0_-1.djhtm", 2))

	queue.put(1)
	queue.put(2)

	# wait the jobs finish
	queue.join()
	"""if 1:
		print "Waiting for all thread to terminate..."
		try:
			ending_flag = True
			while threadcount:
				print threadcount
				time.sleep(1)
		except KeyboardInterrupt:
			print "OK, OK, I'll terminate immediatly..."
			sys.exit(1)
	"""

	OSPrint("檢查5日均線...", "Check 5MA...")
	print "=" * 50
	OSPrint("自營:", "1:")

	""" 4. 與5日均線差小於1％ """
	if len(stockList) != 0 :
		count = 0
		stockList.sort()
		for (index, rank, number, totalAmount, totalAmount, divisor) in stockList:
			count += 1
			queue.put([index, count, int(number)])
			thread.start_new_thread(thread_func2, (None,))
			#get_one_stock(index, count, int(number))

		# wait the jobs finish
		queue.join()
		print "=" * 50

	if os.name == "nt" :
		raw_input("Done. Press any key...")


if __name__ == "__main__":
	main()

