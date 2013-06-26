#!/bin/sh
#  Author: Gavin.Ke
#  Time: 2009/03/30 

TMP_FILE="/tmp/local_avg.tmp"

function request() {
	# get web data
	#wget http://tw.stock.yahoo.com/q/q?s=$1 -O TmpWebFile -q
	wget  http://119.160.244.28/q/q?s=$1 -O TmpWebFile -q -t 2 -T 3
	if [ $? != "0" ]; then
		echo No internet response
		return 1
	fi
	
	# get stock data and translate file encoding type from Big5 to UTF-8
	sed -n "225,239 p" TmpWebFile | iconv -f big5 -t utf-8 -o TmpWebFile_UTF-8
	if [ $? == "1" ]; then
		echo No internet response
		return 1
	fi

	name=`grep "stkname" TmpWebFile_UTF-8 | cut -d '"' -f 4`
	# 成交值
	value=`sed -n "1 p" TmpWebFile_UTF-8 | cut -d '>' -f 3 | cut -d '<' -f 1`
	# 漲跌量
	diff_string=`sed -n "4 p" TmpWebFile_UTF-8 | cut -d '>' -f 3`
	diff_sign=`echo $diff_string | sed "s/\([0-9]*\(\.[0-9]*\)*\)//g"`
	diff_value=`echo $diff_string | sed -e "s/^[^0-9]//"`
	# 成交量
	stock_amount=`sed -n "5 p" TmpWebFile_UTF-8 | cut -d '>' -f 2 | cut -d '<' -f 1`

	testing=$(grep "$1" $TMP_FILE 2> /dev/null)   # 偵測看 該檔股票 在否？
	if [ "$testing" != "" ]; then
		ave1=`echo $testing | cut -d ' ' -f 2`
		ave2=`echo $testing | cut -d ' ' -f 3`
		ave3=`echo $testing | cut -d ' ' -f 4`
		ave4=`echo $testing | cut -d ' ' -f 5`
		ave5=`echo $testing | cut -d ' ' -f 6`
		ave6=`echo $testing | cut -d ' ' -f 7`
		ave7=`echo $testing | cut -d ' ' -f 8`
		ave8=`echo $testing | cut -d ' ' -f 9`
		ave9=`echo $testing | cut -d ' ' -f 10`
	else
		#wget http://www.google.com/finance/historical?q=TPE:$1 -O TMP2 -q
		wget http://64.233.183.105/finance/historical?q=TPE:$1 -O TMP2 -q -t 2 -T 3
		exist=$(grep "<div>Historical prices" TMP2)
		if [ "$exist" == "" ]; then
			echo $1 0 0 0 0 0 0 0 0 0 >> $TMP_FILE
		else
			testing=$(grep "Watch this stock" TMP2)   # 偵測看 Watch this stock 在否？
			if [ "$testing" != "" ]; then
				sed -n "210,266 p" TMP2 | iconv -f big5 -t utf-8 -o TMP_aveg
			else
				sed -n "209,265 p" TMP2 | iconv -f big5 -t utf-8 -o TMP_aveg
			fi
			ave1=`sed -n "1 p" TMP_aveg | cut -d '>' -f 2`
			ave2=`sed -n "8 p" TMP_aveg | cut -d '>' -f 2`
			ave3=`sed -n "15 p" TMP_aveg | cut -d '>' -f 2`
			ave4=`sed -n "22 p" TMP_aveg | cut -d '>' -f 2`
			ave5=`sed -n "29 p" TMP_aveg | cut -d '>' -f 2`
			ave6=`sed -n "36 p" TMP_aveg | cut -d '>' -f 2`
			ave7=`sed -n "43 p" TMP_aveg | cut -d '>' -f 2`
			ave8=`sed -n "50 p" TMP_aveg | cut -d '>' -f 2`
			ave9=`sed -n "57 p" TMP_aveg | cut -d '>' -f 2`
			echo $1 $ave1 $ave2 $ave3 $ave4 $ave5 $ave6 $ave7 $ave8 $ave9 >> $TMP_FILE
		fi
	fi
	
	if [ "$exist" == "" ] || [ "$ave1" == "0" ]; then
		day5="N/A"
#		day10="N/A"
		printf "  %4s  " $1
	else
		day5=$(echo "scale=2; $value+$ave1+$ave2+$ave3+$ave4" | bc)
		day5=$(echo "scale=2; $day5/5" | bc)
#		day10=$(echo "scale=2; $value+$ave1+$ave2+$ave3+$ave4+$ave5+$ave6+$ave7+$ave8+$ave9" | bc)
#		day10=$(echo "scale=2; $day10/10" | bc)

		testing=$(echo "scale=2; $value-$day5" | bc)
		alert5=$(echo \"$testing\" | grep "-" )

#		testing=$(echo "scale=2; $value-$day10" | bc)
#		alert10=$(echo \"$testing\" | grep "-" )

#		if [ "$alert10" != "" ]; then
#			printf "  %s%4s%s  " ${redb} $1 ${reset}
#		elif [ "$alert5" != "" ]; then
		if [ "$alert5" != "" ]; then
			printf "  %s%s%4s%s  " ${yellowb} ${blackf} $1 ${reset}
		else
			printf "  %4s  " $1
		fi
	fi

	if [ -z "$diff_sign" ]; then
#		printf "%8s  %6s   %5s  %6s  %6s  %6s\n" $name $value $diff_value $stock_amount $day5 $day10
		printf "%8s  %6s   %5s  | %6s  %6s\n" $name $value $diff_value $stock_amount $day5
	else
		printf "%8s  %6s  " $name $value
		if [ "$diff_sign" == "△" ]; then
			printf "%s%s%5s%s  " ${redf} $diff_sign $diff_value ${reset}
		elif [ "$diff_sign" == "▲" ]; then
			printf "%s%s%s%5s%s  " ${redb} ${whitef} $diff_sign $diff_value ${reset}
		elif [ "$diff_sign" == "▽" ]; then
			printf "%s%s%5s%s  " ${greenf} $diff_sign $diff_value ${reset}
		elif [ "$diff_sign" == "▼" ]; then
			printf "%s%s%s%5s%s  " ${greenb} ${blackf} $diff_sign $diff_value ${reset}
		fi
#		printf "%6s  %6s  %6s\n" $stock_amount $day5 $day10
		printf "| %6s  %6s\n" $stock_amount $day5
	fi
}

function initializeANSI()
{
  esc=""

  blackf="${esc}[30m";   redf="${esc}[31m";    greenf="${esc}[32m"
  yellowf="${esc}[33m"   bluef="${esc}[34m";   purplef="${esc}[35m"
  cyanf="${esc}[36m";    whitef="${esc}[37m"
  
  blackb="${esc}[40m";   redb="${esc}[41m";    greenb="${esc}[42m"
  yellowb="${esc}[43m"   blueb="${esc}[44m";   purpleb="${esc}[45m"
  cyanb="${esc}[46m";    whiteb="${esc}[47m"

  boldon="${esc}[1m";    boldoff="${esc}[22m"
  italicson="${esc}[3m"; italicsoff="${esc}[23m"
  ulon="${esc}[4m";      uloff="${esc}[24m"
  invon="${esc}[7m";     invoff="${esc}[27m"

  reset="${esc}[0m"
}

# check default gateway
default=`route -n | grep -e "^0.0.0.0"`
if [ $? == "1" ]; then
	echo "No internet connection!"
	exit
fi
default_ip=${default:9:20}

if [ $default_ip == "10.58.85.253" ] ; then
	echo "gateway" $default_ip "is internal network!"
	exit
fi

stock_list=$@
if [ -z "$stock_list" ] ; then
	# set default value
	#echo "Usage: sh stock.sh <stock_id> ..."
	#echo "Example: sh stock.sh 0050 2330"
	stock_list="2457 2206 1215 1419 1717 2201 4930 1477 2448 3062"
	#exit
fi

rm -f $TMP_FILE
initializeANSI

while :
do
	echo `uptime | cut -d ' ' -f 2`
	#wget http://tw.stock.yahoo.com -O TmpStock -q
	wget http://119.160.244.28 -O TmpStock -q -t 2 -T 3
	if [ $? != 0 ]; then
		echo No internet response
		sleep 120
		continue
	fi

	sed -n "206 p" TmpStock | iconv -f big5 -t utf-8 -o TmpStock_UTF-8
	stockvalue=`sed -n "1 p" TmpStock_UTF-8 | cut -d '>' -f 7 | cut -d '<' -f 1`
	total_diff=`sed -n "1 p" TmpStock_UTF-8 | cut -d '>' -f 11 | cut -d '<' -f 1`
	value_diff=`sed -n "1 p" TmpStock_UTF-8 | cut -d '>' -f 15 | cut -d '<' -f 1`
	amount=`sed -n "1 p" TmpStock_UTF-8 | cut -d '>' -f 18 | cut -d '<' -f 1`
	printf "加權指數:%8s  %s%4s  成交量:%s\n" $stockvalue $total_diff $value_diff $amount | sed "s/        .*//"
	#printf "  股號    股名    價位    漲跌   成交量    MA5    MA10\n"

	# send request for stock value of list
	for stock_id in $stock_list
	do
		request $stock_id
		if [ $? == "1" ]; then
			break
		fi
		# remove temporary files
		rm -f TmpWebFile TmpWebFile_UTF-8 TmpStock TmpStock_UTF-8 TMP2 TMP_aveg
	done
	#printf "======================================================\n"
	printf "===================================================\n"
	sleep 120
done

#read -p "Press any key to exit..." end


