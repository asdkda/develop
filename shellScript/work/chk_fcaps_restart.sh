#!/bin/bash

DAEMON="fcapsd"
count=0
dead=0
waitTime=30
exit=1
startTime=10

killDaemon="killall -q daemon_monitor udhcpc wpa_supplicant wvdial fcapsd fcaps_cmd mobilityd platformd gpsd"

function processExist()
{
	processExistCount=$2
	pgrep $1 > /dev/null 2>&1
	if [ $? == 0 ]; then
		echo "`date`  $1 is alive, wait 2 sec."
		processExistCount=$((processExistCount+1))
		sleep 2
		if [ $processExistCount == 15 ]; then
			echo "processExist: processExistCount = $processExistCount, exit"
			exit
		fi
		processExist $1 $processExistCount
	fi
}

function startTest()
{
	for (( i=1; i<=30; i=i+1 ))
	do
		#vconfig add eth1 $i
		ifconfig eth1.$i up
		ifconfig eth1.$i 192.168.1.$i
	done
	sleep 2
}

function endTest()
{
	for (( i=1; i<=30; i=i+1 ))
	do
		#ifconfig eth1.$i down
		vconfig rem eth1.$i
	done
}

function restart()
{
	echo "killall all daemon"
	eval "$killDaemon"
	sleep 4
	processExist "fcapsd" 0
	processExist "platformd" 0
	processExist "daemon_monitor" 0
	
	rm -f /core.*
	#if [ "x$(/bin/ls /core.* 2>/dev/null)" != "x" ]; then
	#	#killall daemon_monitor fcapsd
	#	echo "[E] Killall all -> Have core dump files"
	#	exit
	#fi
	#ps

	endTest
	
	#rm -rf /etc.non-volatile/fcaps/* 
	# remove log
	rm -f /var/log/fcaps/* /var/log/fcaps_cmd.log /var/log/messages /var/log/lilee.log
	echo "start daemon_monitor"
	/opt/lilee/sbin/daemon_monitor
}

function chkFcapsdStarted()
{
	ret=`fcaps_cmd '' show-run-config`
	#echo "$ret"
	if [ "$ret" = "The system is not ready" ]; then
		return 1
	fi
	if [ "$ret" = "Command failed because fcpasd didn't exist" ]; then
		return 2
	fi
	return 0
}

function chkFcapsdDead()
{
	for daemon in daemon_monitor fcapsd platformd ; do 
		pid=$(pgrep $daemon)
		if [ "x$pid" = "x" ]; then
			dead=$((dead+1))
			echo "`date`  Daemon $daemon is dead, count is $dead. Restart services"
			if [ $exit == 1 ]; then
				exit
			fi
			break
		fi
	done
		
	ps | grep -v "grep" | grep "fcapsd -r" > /dev/null 2>&1
	if [ $? == 0 ]; then
		dead=$((dead+1))
		echo "`date`  $DAEMON is restart, count is $dead. Restart services"
		if [ $exit == 1 ]; then
			exit
		fi
	fi
	
	if [ "x$(/bin/ls /core.* 2>/dev/null)" != "x" ]; then
		#killall daemon_monitor fcapsd
		echo "[E] Have core dump files"
		exit
	fi
}
#trap "echo 'Loop $count, dead $dead'; exit" SIGINT SIGTERM

ulimit -c unlimited
restart

while [ true ]
do
	count=$((count+1))
	echo ""
	echo "`date`  **** Loop $count BEG, dead $dead ****"
	sleep $startTime

	for (( i=1; i<=$waitTime; i=i+1 ))
	do
		chkFcapsdDead
		
		# check if fcapsd finish init
		chkFcapsdStarted
		if [ $? == 0 ]; then
			# check all event processed
#			startTest
			processExist "fcaps_cmd" 0
			i=999
		else
			sleep 1
		fi
	done
	
	echo "`date`  **** Loop $count END, dead $dead ****"
	restart
done


