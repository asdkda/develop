#!/bin/sh
#  Author: Gavin.Ke
#  Update Time: 2009/05/18

function request() {
	# get web data
	#wget http://tw.stock.yahoo.com/q/q?s=$1 -O TmpWebFile -q
	wget  http://119.160.244.28/q/q?s=$1 -O TmpWebFile -q
	# get stock data and translate file encoding type form Big5 to UTF-8
	sed -n "225,239 p" TmpWebFile | iconv -f big5 -t utf-8 -o TmpWebFile_UTF-8

	name=`grep "stkname" TmpWebFile_UTF-8 | cut -d '"' -f 4`
	# 成交值
	value=`sed -n "1 p" TmpWebFile_UTF-8 | cut -d '>' -f 3 | cut -d '<' -f 1`
	# 成交量
	volume=`sed -n "5 p" TmpWebFile_UTF-8 | cut -d '>' -f 2 | cut -d '<' -f 1`
	# 漲跌量
	diff_sign=`sed -n "4 p" TmpWebFile_UTF-8 | cut -d '>' -f 3 | sed "s/\([0-9]*\.[0-9]*\)//g"`
	diff_value=`sed -n "4 p" TmpWebFile_UTF-8 | cut -d '>' -f 3 | sed -e "s/[^0-9]\([0-9]*\.[0-9]*\)/\1/g"`

	if [ -z "$diff_sign" ]; then
		printf "  %4s  %8s  %6s   %6s  %7s" $1 $name $value $diff_value $volume
	else
		printf "  %4s  %8s  %6s  %s%6s  %7s" $1 $name $value $diff_sign $diff_value $volume
	fi
	
	printf "\n"
}

# check default gateway
default=`route -n | grep -e "^0.0.0.0"`
default_ip=${default:9:20}

if [ $default_ip == "10.58.85.253" ] ; then
	echo "gateway" $default_ip "is internal network!"
	exit
fi

# get target stock list
stock_list=$@
if [ -z "$stock_list" ] ; then
	# set default value
	stock_list="2448 2458 2520 1723 2382 3231 2548 5483 2409 2308 3034 3062 2545 2499 2330 2384 2376"
fi

# request time
echo `date | sed -e "s/.*[ ]\([0-9]*:[0-9]*:[0-9]*\).*/\1/"`

#wget http://tw.stock.yahoo.com -O TmpWebFile -q
wget http://119.160.244.28 -O TmpWebFile -q
sed -n "206 p" TmpWebFile | iconv -f big5 -t utf-8 -o TmpWebFile_UTF-8
stockvalue=`sed -n "1 p" TmpWebFile_UTF-8 | cut -d '>' -f 7 | cut -d '<' -f 1`
total_diff=`sed -n "1 p" TmpWebFile_UTF-8 | cut -d '>' -f 11 | cut -d '<' -f 1`
value_diff=`sed -n "1 p" TmpWebFile_UTF-8 | cut -d '>' -f 15 | cut -d '<' -f 1`
amount=`sed -n "1 p" TmpWebFile_UTF-8 | cut -d '>' -f 18 | cut -d '<' -f 1`
printf "加權指數:%8s  %s%4s  成交量:%s" $stockvalue $total_diff $value_diff $amount
printf "\n"

# send request for stock value of list
for stock_id in $stock_list
do
	request $stock_id
done

# remove temporary files
rm -f TmpWebFile TmpWebFile_UTF-8




