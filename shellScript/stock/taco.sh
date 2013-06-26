#!/bin/sh
#  Author: Ethan.Yang
#  Time: 2010/07/09 

#http://jsjustweb.jihsun.com.tw/z/zg/zgk_D_0_5.djhtm  // 外資
#http://jsjustweb.jihsun.com.tw/z/zg/zgk_DD_0_5.djhtm  // 投信
#http://jsjustweb.jihsun.com.tw/z/zg/zgk_DB_0_5.djhtm  //自營商
#http://jsjustweb.jihsun.com.tw//z/zc/zcl/zcl_1477.asp.htm  //股號

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

function request() {
#	wget http://jsjustweb.jihsun.com.tw//z/zc/zcl/zcl_$1.asp.htm -O rec_stk -q
#	wget http://jsjustweb.jihsun.com.tw//z/zc/zcl/zcl_1477.asp.htm -O rec_stk -q
	wget http://211.72.248.20//z/zc/zcl/zcl_$1.asp.htm -O rec_stk -q

	local line flag sellvalue foreign1 foreign2 foreign3 foreign4 foreign5 foreign_total name value diff_string
	local diff_sign diff_value stock_amount exist testing
	#外資
	line=`grep -n "<td class=\"t10\" colspan=\"4\">" rec_stk | sed -n "1 p" | cut -d ':' -f 1`
	sed -n "$line,+36 p" rec_stk | iconv -f big5 -t utf-8 -o foreign_buy

	#投信
	if [ "$2" == "1" ]; then
		line=`grep -n "<td class=\"t10\" colspan=\"3\">" rec_stk | sed -n "1 p" | cut -d ':' -f 1`
		sed -n "$line,+30 p" rec_stk | iconv -f big5 -t utf-8 -o domestic_buy

		flag=$((`grep -n "t3r1" domestic_buy | wc -l`))
		if [ $flag -ge 2 ]; then
#			printf "$1:賣超超過一天\n"
			return  # 投信賣超超過一天, 忽略
		else
			line=`grep -n "AS$1" domestic_UTF-8 | sed -n "1 p" | cut -d ':' -f 1`
			sellvalue=`sed -n "$(($line+9)) p" domestic_UTF-8 | cut -d ';' -f 2 | cut -d '<' -f 1 | sed -e "s/,//"`
			if [ $sellvalue -gt 100 ]; then
#				printf "$1:賣超$sellvalue, 忽略\n"
				return  # 投信賣超一天, 但是超過100張, 忽略
			fi
#			printf "$1:賣超$sellvalue "
		fi
	else	#自營商
		line=`grep -n "<td class=\"t10\" colspan=\"5\">" rec_stk | sed -n "1 p" | cut -d ':' -f 1`
		sed -n "$line,+42 p" rec_stk | iconv -f big5 -t utf-8 -o self_buy

		flag=$((`grep -n "t3r1" self_buy | wc -l`))
		if [ $flag -ge 2 ]; then
#			printf "$1:賣超超過一天\n"
			return  # 自營商賣超超過一天, 忽略
		else
			line=`grep -n "AS$1" self_UTF-8 | sed -n "1 p" | cut -d ':' -f 1`
			sellvalue=`sed -n "$(($line+9)) p" self_UTF-8 | cut -d ';' -f 2 | cut -d '<' -f 1 | sed -e "s/,//"`
			if [ $sellvalue -gt 100 ]; then
#				printf "$1:賣超$sellvalue, 忽略\n"
				return  # 自營商賣超一天, 但是超過100張, 忽略
			fi
#			printf "$1:賣超$sellvalue "
		fi
	fi

	foreign1=`sed -n "12 p" foreign_buy | cut -d '>' -f 2 | cut -d '<' -f 1 | sed -e "s/,//"`
	foreign2=`sed -n "18 p" foreign_buy | cut -d '>' -f 2 | cut -d '<' -f 1 | sed -e "s/,//"`
	foreign3=`sed -n "24 p" foreign_buy | cut -d '>' -f 2 | cut -d '<' -f 1 | sed -e "s/,//"`
	foreign4=`sed -n "30 p" foreign_buy | cut -d '>' -f 2 | cut -d '<' -f 1 | sed -e "s/,//"`
	foreign5=`sed -n "36 p" foreign_buy | cut -d '>' -f 2 | cut -d '<' -f 1 | sed -e "s/,//"`

	foreign_total=$(($foreign1+$foreign2+$foreign3+$foreign4+$foreign5));
	if [ $foreign_total -lt 0 ]; then
#		printf "外資五天總和賣超, 忽略\n"
		return  # 外資五天總和賣超, 忽略
	fi
#	printf "${stk_recommend[$i]}\n"


	wget http://119.160.244.28/q/q?s=$1 -O PRICE -q    #抓取現在價位
#	wget http://119.160.244.28/q/q?s=1477 -O PRICE -q    #抓取現在價位
	sed -n "225,239 p" PRICE | iconv -f big5 -t utf-8 -o PRICE_UTF-8
	name=`grep "stkname" PRICE_UTF-8 | cut -d '"' -f 4`
	value=`sed -n "1 p" PRICE_UTF-8 | cut -d '>' -f 3 | cut -d '<' -f 1`
	diff_string=`sed -n "4 p" PRICE_UTF-8 | cut -d '>' -f 3`
	diff_sign=`echo $diff_string | sed "s/\([0-9]*\(\.[0-9]*\)*\)//g"`
	diff_value=`echo $diff_string | sed -e "s/^[^0-9]//"`
	stock_amount=`sed -n "5 p" PRICE_UTF-8 | cut -d '>' -f 2 | cut -d '<' -f 1`
	rm -f PRICE
	rm -f PRICE_UTF-8

	wget http://72.14.203.147/finance/historical?q=TPE:$1 -O MA5 -q	#抓取MA5
#	wget http://72.14.203.147/finance/historical?q=TPE:1477 -O MA5 -q	#抓取MA5
	exist=$(grep "<div>Historical prices" MA5)
	if [ "$exist" != "" ]; then
		testing=$(grep "Watch this stock" MA5)   # 偵測看 Watch this stock 在否？
		if [ "$testing" != "" ]; then
			sed -n "210,266 p" MA5 | iconv -f big5 -t utf-8 -o MA5_aveg
		else
			sed -n "209,265 p" MA5 | iconv -f big5 -t utf-8 -o MA5_aveg
		fi
		ave1=`sed -n "1 p" MA5_aveg | cut -d '>' -f 2`
		ave2=`sed -n "8 p" MA5_aveg | cut -d '>' -f 2`
		ave3=`sed -n "15 p" MA5_aveg | cut -d '>' -f 2`
		ave4=`sed -n "22 p" MA5_aveg | cut -d '>' -f 2`
	fi
	rm -f MA5
	rm -f MA5_aveg

	if [ "$exist" == "" ]; then
		day5="N/A"
	else
		day5=$(echo "scale=3; $value+$ave1+$ave2+$ave3+$ave4" | bc)
		day5=$(echo "scale=2; $day5/5" | bc)

		testing=$(echo "scale=2; $value-$day5" | bc)
		percent=$(echo "scale=5; $testing/$day5" | bc)
		testing=$(echo "scale=3; $percent - 0.010" | bc)
		alert5=$(echo $testing | grep "-" )

		if [ "$alert5" == "" ]; then
#			printf "五日線以上\n"
			return;			
		else
			alert5=$(echo $percent | grep "-" )
			if [ "$alert5" == "" ]; then
				printf "  %4s  " $1
				percent=$(echo "scale=2; $percent * 100 / 1" | bc) # scale只對除法有效
			else	#五日線之下, 忽略
#				percent=$(echo $percent | sed -e "s/-//" )
#				percent=$(echo "scale=3; $percent * 100" | bc)
#				percent="-$percent"
#				printf "五日線之下\n"
				return;
			fi
			percent="$percent%"
		fi
	fi

	if [ -z "$diff_sign" ]; then	#平盤
		printf "%8s  %6s   %5s  %6s  %6s  %5s\n" $name $value $diff_value $stock_amount $day5 $percent
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
		printf "%6s  %6s  %5s\n" $stock_amount $day5 $percent
	fi
}

initializeANSI

printf "接收資料...."
#wget http://jsjustweb.jihsun.com.tw/z/zg/zgk_DD_0_5.djhtm -O Fund_domestic -q
#wget http://jsjustweb.jihsun.com.tw/z/zg/zgk_DB_0_5.djhtm -O Fund_self -q
wget http://211.72.248.20/z/zg/zg_DD_0_5.djhtm -O Fund_domestic -q
wget http://211.72.248.20/z/zg/zg_DB_0_5.djhtm -O Fund_self -q
#wget http://jsjustweb.jihsun.com.tw/z/zg/zgk_D_0_5.djhtm -O Fund_foreign -q
printf "done!\n"

sed -n "71,939 p" Fund_domestic | iconv -f big5 -t utf-8 -o domestic_UTF-8
grep "GenLink2stk" domestic_UTF-8 > domestic_stk
sed -n "71,939 p" Fund_self | iconv -f big5 -t utf-8 -o self_UTF-8
grep "GenLink2stk" self_UTF-8 > self_stk
#sed -n "68,655 p" Fund_foreign | iconv -f big5 -t utf-8 -o foreign_UTF-8
#grep "javascript:Link2Stk" foreign_UTF-8 > foreign_stk

init_line=1
printf "加入投信買超名單...\n"
for ((i=0; i<50; i++)); do
	temp=`sed -n "$init_line p" domestic_stk | sed -e "s/.*[^0-9]\([0-9]\{4,6\}\).*/\1/g"`
	name="$name $temp"
	request $temp 1	# $2為1 表示投信
	init_line=$(($init_line+1))
done
stk_recommend=($name)
rm -f Fund_domestic
rm -f domestic_UTF-8
rm -f domestic_stk

#stk_len=${#stk_recommend[@]}
#printf "總共$stk_len\n"
init_line=1
printf "加入自營商買超名單...\n"
for ((i=0; i<50; i++)); do
	flag="0"
	temp=`sed -n "$init_line p" self_stk | sed -e "s/.*[^0-9]\([0-9]\{4,6\}\).*/\1/g"`
	for ((j=0; j<50 ; j++)); do
		if [ "$temp" != "${stk_recommend[$j]}" ]; then	#投信名單已有, 忽略
			continue
		else
			flag="1"
			break
		fi
	done
	if [ "$flag" != "1" ]; then
#		name="$name $temp"
#		stk_recommend=($name)
#		stk_len=$(($stk_len+1));
		request $temp 2	# $2為2 表示自營商
	fi
	init_line=$(($init_line+1))
done

rm -f Fund_self
rm -f self_UTF-8
rm -f self_stk
rm -f rec_stk
rm -f domestic_buy
rm -f foreign_buy
rm -f self_buy

#printf "$name\n $stk_len\n"

