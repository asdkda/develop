#!/usr/bin/python
# -*- coding: utf-8 -*-

import threading
import time
 
class Test(threading.Thread):
    def __init__(self, num):
        threading.Thread.__init__(self)
        self._run_num = num
 
    def run(self):
        global count, mutex
        threadname = threading.currentThread().getName()
 
        for x in xrange(0, int(self._run_num)):
            mutex.acquire()
            count = count + 1
            mutex.release()
            print threadname, x, count
            time.sleep(1)
 
if __name__ == '__main__':
    global count, mutex
    threads = []
    num = 4
    count = 1
    # 創建鎖
    mutex = threading.Lock()
    # 創建線程對象
    for x in xrange(0, num):
        threads.append(Test(10))
    # 啟動線程
    for t in threads:
        t.start()
    # 等待子線程結束
    for t in threads:
        t.join()


