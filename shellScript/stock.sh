#!/bin/sh
#  Author: Gavin.Ke
#  Time: 2009/03/30 

TMP_FILE="/tmp/local_avg.tmp"
TMP_CORP_FILE="/tmp/local_corp.tmp"
LIST_FILE="~/config/stockList"

show5ma=0

useage() {
	echo -e "Useage: ${0##*/} [-m] [-h] [-l stock list]"
	echo -e ""
	echo -e "  -m: show 5ma"
	echo -e "  -h: display this help message"
	echo -e ""
}

while getopts "ml:h" OPTION
do
	case ${OPTION} in
		m)
			show5ma=1
			shift
			;;
		h)
			useage
			exit 0
			;;
		l)
			stock_list=${OPTARG}
			;;
	esac
done

if [ -z "$stock_list" ] ; then
	# set default value
	stock_list=`sed -n "1 p" $LIST_FILE`
	if [ $? -ne 0 ] ; then
		exit
	fi
fi

function get_string_line()
{
	line=`grep -n "$1" $2 |cut -d : -f 1`
}

function find_corp() {
	local testing
	testing=$(grep "$1" $TMP_CORP_FILE 2> /dev/null)
	if [ "$testing" != "" ]; then
		buy_sell=`echo $testing | cut -d ' ' -f 2`
	else
		wget http://211.72.248.20//z/zc/zcl/zcl_$1.asp.htm -O req_stk -q
		iconv -f big5 -t utf-8 req_stk -o req_stk_UTF-8
		get_string_line "合計買賣超" req_stk_UTF-8
		buy_sell=`sed -n "$(($line+4)) p" req_stk_UTF-8 | cut -d '>' -f 2 | cut -d '<' -f 1 | sed -e "s/,//"`
		echo $1 $buy_sell >> $TMP_CORP_FILE
	fi
	alert_corp=$(echo \"$buy_sell\" | grep "-" )
}

function get_5ma()
{
	local testing today day1 day2 day3 day4 day5 latest
	testing=$(grep $1 $TMP_FILE 2> /dev/null)   # 偵測看 該檔股票 在否？
	today=`date +%e`
	if [ $show5ma != 0 ]; then
		if [ "$testing" != "" ]; then
			day1=`echo $testing | cut -d ' ' -f 2`
			day2=`echo $testing | cut -d ' ' -f 3`
			day3=`echo $testing | cut -d ' ' -f 4`
			day4=`echo $testing | cut -d ' ' -f 5`
			day5=`echo $testing | cut -d ' ' -f 6`
			latest=`echo $testing | cut -d ' ' -f 8`
		else
			#wget http://www.google.com/finance/historical?q=TPE:$1 -O TMP2 -q
			wget http://64.233.183.105/finance/historical?q=TPE:$1 -O TMP2 -q -t 2 -T 3
			exist=$(grep "<div>Historical prices" TMP2)
			if [ "$exist" == "" ]; then
				echo $1 0 0 0 0 0 0 0 0 0 >> $TMP_FILE
			else
				testing=$(grep "Watch this stock" TMP2)   # 偵測看 Watch this stock 在否？
				get_string_line "<th class=\\\"bb lm\\\">Date" TMP2
				start_line=$line
				end_line=$(($start_line + 6 + 7*5))
				if [ "$testing" != "" ]; then
					sed -n "$start_line,$end_line p" TMP2 | iconv -f big5 -t utf-8 -o TMP_aveg
				else
					sed -n "$start_line,$end_line p" TMP2 | iconv -f big5 -t utf-8 -o TMP_aveg
				fi
				latest=`sed -n "8 p" TMP_aveg | cut -d ' ' -f 3 | cut -d ',' -f 1`
				day1=`sed -n "12 p" TMP_aveg | cut -d '>' -f 2`
				day2=`sed -n "19 p" TMP_aveg | cut -d '>' -f 2`
				day3=`sed -n "26 p" TMP_aveg | cut -d '>' -f 2`
				day4=`sed -n "33 p" TMP_aveg | cut -d '>' -f 2`
				day5=`sed -n "40 p" TMP_aveg | cut -d '>' -f 2`
				echo $1 $day1 $day2 $day3 $day4 $day5 $latest >> $TMP_FILE
			fi
		fi
	fi
	
	#echo $1 $day1 $day2 $day3 $day4 $day5 $latest
	if [ "$exist" == "" -o "$day1" == "0" ]; then
		ma5="N/A"
	else
		if [ "$latest" != "$today" ]; then
			ma5=$(echo "scale=2; ($value+$day1+$day2+$day3+$day4)/5" | bc)
		else
			ma5=$(echo "scale=2; ($day1+$day2+$day3+$day4+$day5)/5" | bc)
		fi
	fi
}

function request() {
	#wget http://tw.stock.yahoo.com/q/q?s=$1 -O TmpWebFile -q
	wget  http://119.160.244.28/q/q?s=$1 -O TmpWebFile -q -t 2 -T 3
	if [ $? != "0" ]; then
		echo "No internet response"
		return 1
	fi
	
	# get stock data and translate file encoding type from Big5 to UTF-8
	get_string_line "/pf/pfsel?stocklist=$1" TmpWebFile
	start_line=$(($line+2))
	end_line=$(($start_line+14))
	sed -n "$start_line,$end_line p" TmpWebFile | iconv -f big5 -t utf-8 -o TmpWebFile_UTF-8
	if [ $? == "1" ]; then
		echo "sed fail"
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
	pre_amount=`sed -n "6 p" TmpWebFile_UTF-8 | cut -d '>' -f 2 | cut -d '<' -f 1`

	get_5ma $1 $value
	find_corp $1

	printf "  %4s  %8s  %6s  " $1 $name $value
	if [ -z "$diff_sign" ]; then
		if [ $show5ma != 0 ]; then
			printf "%6s  %6s  %6s  %6s\n" $diff_value $stock_amount $ma5 $buy_sell
		else
			printf "%6s  %6s  %6s\n" $diff_value $stock_amount $buy_sell
		fi
	else
		if [ "$diff_sign" == "△" ]; then
			printf "%s%s%5s%s  " ${redf} $diff_sign $diff_value ${reset}
		elif [ "$diff_sign" == "▲" ]; then
			printf "%s%s%s%5s%s  " ${redb} ${whitef} $diff_sign $diff_value ${reset}
		elif [ "$diff_sign" == "▽" ]; then
			printf "%s%s%5s%s  " ${greenf} $diff_sign $diff_value ${reset}
		elif [ "$diff_sign" == "▼" ]; then
			printf "%s%s%s%5s%s  " ${greenb} ${blackf} $diff_sign $diff_value ${reset}
		fi
		if [ $show5ma != 0 ]; then
			printf "%6s  %6s  %6s\n" $stock_amount $ma5 $buy_sell
		else
			printf "%6s  %6s\n" $stock_amount $buy_sell
		fi
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

function extra_info()
{
	wget http://60.250.19.201/chinese/3/7_12_3.asp -O extra_info -q	#http://www.taifex.com.tw/chinese/3/7_12_3.asp
	iconv -f big5 -t utf-8 extra_info -o extra_info_UTF-8
	testing=$(grep -n "查無資料" extra_info_UTF-8)
	if [ "$testing" == "" ]; then
		line=`grep -n "外資及陸資" extra_info_UTF-8 | sed -n "1 p" | cut -d ':' -f 1`
		fex=`sed -n "$(($line+20)) p" extra_info_UTF-8 | cut -d '>' -f 3 | cut -d '<' -f 1`
		printf "期貨外資:%6s口\n" $fex
	fi
	rm -f extra_info extra_info_UTF-8
}

function credit()
{
	wget http://119.160.244.28/d/i/credit.html -O credit -q	#http://tw.stock.yahoo.com/d/i/credit.html
	iconv -f big5 -t utf-8 credit -o credit_UTF-8
	line=`grep -n "資 料 日 期" credit_UTF-8 | sed -n "1 p" | cut -d ':' -f 1`
	
	credit_money_diff=`sed -n "$(($line+10)) p" credit_UTF-8 | cut -d '>' -f 2 | cut -d '<' -f 1`
	credit_money=`sed -n "$(($line+11)) p" credit_UTF-8 | cut -d '>' -f 2 | cut -d '<' -f 1`
	minus_money=$(echo \"$credit_money_diff\" | grep "-" )
	credit_money_diff=$(echo $credit_money_diff | sed "s/-//g" )
	
	credit_share_diff=`sed -n "$(($line+12)) p" credit_UTF-8 | cut -d '>' -f 2 | cut -d '<' -f 1`
	credit_share=`sed -n "$(($line+13)) p" credit_UTF-8 | cut -d '>' -f 2 | cut -d '<' -f 1`
	minus_share=$(echo \"$credit_share_diff\" | grep "-" )
	credit_share_diff=$(echo $credit_share_diff | sed "s/-//g" )
	
	if [ "$minus_money" == "" ]; then
		printf "餘資:%10s億  %s△ %s億%s\n" $credit_money ${redf} $credit_money_diff ${reset}
	else
		printf "餘資:%10s億  %s▽ %s億%s\n" $credit_money ${greenf} $credit_money_diff ${reset}
	fi

	if [ "$minus_share" == "" ]; then
		printf "餘券:%10s張  %s△ %s張%s\n" $credit_share ${redf} $credit_share_diff ${reset}
	else
		printf "餘券:%10s張  %s▽ %s張%s\n" $credit_share ${greenf} $credit_share_diff ${reset}
	fi
	
	rm -f credit credit_UTF-8
}

# =================== Main ===================
# save temp file to /tmp
cd /tmp

# check default gateway
default=`route -n | grep -e "^0.0.0.0"`
if [ $? == "1" ]; then
	echo "No internet connection!"
	exit
fi
default_ip=${default:9:20}

#if [ $default_ip == "10.58.85.253" ] ; then
#	echo "gateway" $default_ip "is internal network!"
#	exit
#fi

rm -f $TMP_FILE
rm -f $TMP_CORP_FILE
initializeANSI

credit
extra_info

while :
do
	echo `date +%r`
	time=`date +%H%M`
	#wget http://tw.stock.yahoo.com -O TmpStock -q
	wget http://119.160.244.28 -O TmpStock -q -t 2 -T 3

	if [ $? != 0 ]; then
		echo "No internet response"
		sleep 120
		continue
	fi

	get_string_line "http://tw.rd.yahoo.com/referurl/stock/index/index_chart/tw/tse_quote" TmpStock
	start_line=$line
	sed -n "$start_line p" TmpStock | iconv -f big5 -t utf-8 -o TmpStock_UTF-8
	stockvalue=`cut -d '>' -f 7 TmpStock_UTF-8 | cut -d '<' -f 1`
	total_diff=`cut -d '>' -f 11 TmpStock_UTF-8 | cut -d '<' -f 1`
	value_diff=`cut -d '>' -f 15 TmpStock_UTF-8 | cut -d '<' -f 1`
	amount=`cut -d '>' -f 18 TmpStock_UTF-8 | cut -d '<' -f 1`
	printf "加權指數:%8s  %s%4s  成交量:%s\n" $stockvalue $total_diff $value_diff $amount | sed "s/        .*//"
	if [ $show5ma != 0 ]; then
		printf "  股號    股名    價位    漲跌  成交量     MA5    法人\n"
		printf "  ======================================================\n"
	else
		printf "  股號    股名    價位    漲跌   成交量   法人\n"
		printf "  ==============================================\n"
	fi

	# send request for stock value of list
	for stock_id in $stock_list
	do
		request $stock_id
		if [ $? == "1" ]; then
			break
		fi
	done

	# remove temporary files
	rm -f TmpWebFile TmpWebFile_UTF-8 TmpStock TmpStock_UTF-8 TMP2 TMP_aveg req_stk req_stk_UTF-8
	
	# finish at 13:30
	if [ $time -ge 1335 ]; then
		echo "Time is up."
		break
	fi
	sleep 120
done



