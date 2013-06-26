#!/bin/bash

count=0
dead=0
tmp=/tmp/aaa

/etc/init.d/modules stop

while [ true ]
do
	count=$((count+1))
	echo ""
	echo "`date`  **** Loop $count, dead $dead ****"
	
	/etc/init.d/modules start
	ifconfig wifi0 up; wlanconfig wlan0 create wlandev wifi0 wlanmode ap; sleep 7;  ifconfig wlan0 up ; sleep 6 ; ifconfig wlan0 down ; sleep 7; wlanconfig wlan0 destroy &
	
	sleep 2
	top -n 1 | grep syslogd | grep -v grep > $tmp
	#cat $tmp
	cpu=`cat $tmp | cut -d '%' -f 2 | sed -e s/\ *//`
	#echo $cpu
	if [ $cpu -gt 10 ]; then
		echo bad...
		dead=$((dead+1))
	fi
	
	/etc/init.d/modules stop
	
	echo "`date`  **** Loop $count END ****"
done


