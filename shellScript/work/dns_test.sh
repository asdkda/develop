#!/bin/sh

i=0
sp=0
server=192.168.1.1

for((i=0 ; i<2 ; i++))
do
	nslookup yahoo.com.tw $server
		sleep $sp
	nslookup es.wikipedia.org $server
		sleep $sp
	nslookup en.wikipedia.org $server
		sleep $sp
	nslookup uk.wikipedia.org $server
		sleep $sp
	nslookup zh.wikipedia.org $server
		sleep $sp
	nslookup ja.wikipedia.org $server
		sleep $sp
	nslookup bs.wikipedia.org $server
		sleep $sp
	nslookup de.wikipedia.org $server
		sleep $sp
	nslookup fi.wikipedia.org $server
		sleep $sp
	nslookup eu.wikipedia.org $server
		sleep $sp
	nslookup als.wikipedia.org $server
		sleep $sp
	nslookup simple.wikipedia.org $server
		sleep $sp
	nslookup ar.wikipedia.org $server
		sleep $sp
	nslookup id.wikipedia.org $server
		sleep $sp
	nslookup ms.wikipedia.org $server
		sleep $sp
	nslookup bpy.wikipedia.org $server
		sleep $sp
	nslookup et.wikipedia.org $server
		sleep $sp
	nslookup bg.wikipedia.org $server
		sleep $sp
	nslookup ca.wikipedia.org $server
		sleep $sp
	nslookup cs.wikipedia.org $server
		sleep $sp
	nslookup da.wikipedia.org $server
		sleep $sp
	nslookup el.wikipedia.org $server
		sleep $sp
	nslookup eo.wikipedia.org $server
		sleep $sp
	nslookup fa.wikipedia.org $server
		sleep $sp
	nslookup fr.wikipedia.org $server
		sleep $sp
	nslookup gl.wikipedia.org $server
		sleep $sp
	nslookup hr.wikipedia.org $server
		sleep $sp
	nslookup is.wikipedia.org $server
		sleep $sp
	nslookup it.wikipedia.org $server
		sleep $sp
	nslookup he.wikipedia.org $server
		sleep $sp
	nslookup ka.wikipedia.org $server
		sleep $sp
	nslookup ko.wikipedia.org $server
		sleep $sp
	nslookup lb.wikipedia.org $server
		sleep $sp
	nslookup lt.wikipedia.org $server
		sleep $sp
	nslookup hu.wikipedia.org $server
		sleep $sp
	nslookup nl.wikipedia.org $server
		sleep $sp
	nslookup no.wikipedia.org $server
		sleep $sp
	nslookup nn.wikipedia.org $server
		sleep $sp
	nslookup pl.wikipedia.org $server
		sleep $sp
	nslookup pt.wikipedia.org $server
		sleep $sp
	nslookup ro.wikipedia.org $server
		sleep $sp
	nslookup ru.wikipedia.org $server
		sleep $sp
	nslookup sk.wikipedia.org $server
		sleep $sp
	nslookup sl.wikipedia.org $server
		sleep $sp
	nslookup sr.wikipedia.org $server
		sleep $sp
	nslookup sv.wikipedia.org $server
		sleep $sp
	nslookup vo.wikipedia.org $server
		sleep $sp
	nslookup tr.wikipedia.org $server
		sleep $sp
	nslookup meta.wikipedia.org $server
		sleep $sp
	nslookup new.twtraffic.com.tw $server
		sleep $sp
	nslookup www.cwb.gov.tw $server
		sleep $sp
	nslookup www.eslitebooks.com $server
		sleep $sp
	nslookup blog.pixnet.net $server
		sleep $sp
	nslookup tw.news.yahoo.com $server
		sleep $sp
	nslookup tw.sports.yahoo.com $server
		sleep $sp
	nslookup tw.stock.yahoo.com $server
		sleep $sp

done

