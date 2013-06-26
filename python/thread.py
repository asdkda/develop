#!/usr/bin/python
# -*- coding: utf-8 -*-
import Queue
import threading
import os, sys, glob

queue = Queue.Queue()

def Processlet():
	while True:
		# 抓put()進來的東西
		fileobj = queue.get()
		if fileobj != None :
			print 'Processing: ' + fileobj
			# thread結束
			queue.task_done()
		else :
			queue.task_done()

dir = glob.glob(sys.argv[1] + '/*.py')
for f in dir:
	print f
	#要給thread的參數
	queue.put(f)


#要開幾個thread
for i in range(2):
	t = threading.Thread(target=Processlet)
	t.setDaemon(True)
	t.start()

#等待thread都跑完
queue.join()
print "after join"


