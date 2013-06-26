# -*- coding: utf-8 -*-

#krammer
#main start

import urllib
import string

import First5DB
import price

nice_stock = []

nice_stock = First5DB.get_db_nice_stock()

print "-" * 30
#my_stock = [2344, 9907, 6120, 3006, 1312]
#f.seek(0)
#my_stock = f.readlines()

for i in nice_stock:
	price.get_one_stock(int(i))

#f.close()


