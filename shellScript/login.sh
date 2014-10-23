#!/bin/bash

source ~/config/config.sh
TOP=`dirname $0`
TCL_SRC=`readlink -f $TOP/../tcl`

# set default value for each variable
USER="admin"
PASSWORD=$ADMIN_PW
COS_PASSWORD=""
IP="10.2.10.100"
PROTO="ssh"
TYPE="ptc"
PORT=""
ACTION=""
DEFAULT_ROOT_PASSWD=$LILEE_PW
DEFAULT_ROOT_PASSWD2=$ROOT_PW
ECHO=""

DEBUG_PATH=""
DEBUG_CDL=0

usage() {
	echo -e "Usage: ${0##*/} [-s] [-u name] [-p passwd] [--port port] [-i ip] [-I ip] [-a action]"
	echo -e "       ${0##*/} -h"
	echo -e ""
	echo -e "Options:"
	echo -e "  -s: telnet login"
	echo -e "  -u: user name, default: $USER, predefined: rootd, console"
	echo -e "  -p: user password, default: $PASSWORD"
	echo -e "  -i: device IP, default: $IP"
	echo -e "  -I: device IP 10.2.10.x"
	echo -e "  -h: display this help message"
	echo -e ""
	echo -e "action:"
	echo -e "  upgrade"
	echo -e "    -t: device type, default: $TYPE"
	echo -e "    -c: echo command"
	echo -e "  debug"
	echo -e "    -d: debug so"
	echo -e "    --cdl: debug with cdl"
	echo -e "  test"
#	echo -e ""
#	echo -e "  Use admin:admin telnet login remote device(10.2.10.100) by default."
	echo -e ""
}



# trap interrupt first
trap 'echo Interrupted; exit' INT

# translate long options to short
for arg
do
	delim=""
	case "$arg" in
		--cdl) DEBUG_CDL=1 ;;
		--help) args="${args}-h ";;
		--port) args="${args}-q ";;
#		--test) TEST=1 ;;
		# pass through anything else
		*) [[ "${arg:0:1}" == "-" ]] || delim="\""
			args="${args}${delim}${arg}${delim} ";;
	esac
done
# reset the translated args
eval set -- $args
# now we can process with getopt
while getopts "a:cd:i:I:p:q:st:u:h" OPTION
do
	case ${OPTION} in
		a)
			ACTION=${OPTARG}
			;;
		c)
			ECHO=yes
			;;
		d)
			DEBUG_PATH=${OPTARG}
			;;
		i)
			IP=${OPTARG}
			;;
		I)
			IP=10.2.10.${OPTARG}
			;;
		p)
			COS_PASSWORD=${OPTARG}
			;;
		q)
			PORT=${OPTARG}
			;;
		s)
			PROTO="telnet"
			;;
		t)
			TYPE=${OPTARG}
			;;
		u)
			USER=${OPTARG}
			;;
		h)
			usage
			exit 0
			;;
		?)
			usage
			exit 0
			;;
	esac
done

if [ $USER = "root" -a $TYPE = "lmc" ]; then
	PASSWORD=$DEFAULT_ROOT_PASSWD
elif [ $USER = "rootd" ]; then
	USER="root"
	PASSWORD=$DEFAULT_ROOT_PASSWD2
elif [ $USER = "console" ]; then
	USER="root"
	PASSWORD=$ROOT_PW2
	IP=$CONSOLE_IP
	PORT=$CONSOLE_PORT
else
	PASSWORD=$USER
fi

if [ $COS_PASSWORD ]; then
	PASSWORD=$COS_PASSWORD
fi

shift $((OPTIND-1))

if [ "x$IP" = "x" -o "x$PASSWORD" = "x" ]; then
	echo "IP [$IP] password [$PASSWORD]"
	usage
	exit 0
fi


ping_ret=1
while [ $ping_ret -eq 1 ]
do
	ping -c 1 $IP > /dev/null
	ping_ret=$?
	if [ $ping_ret -ne 0 ]; then
		echo "$IP can't be connected"
	fi
done

# gen ssh key
$TOP/re-ssh.sh $IP

#echo "$PROTO $USER:$PASSWORD@$IP"
if [ -n "$ACTION" ]; then
	if [ $ACTION = "upgrade" ]; then
		echo "$TCL_SRC/updateImage.tcl $IP $TYPE $PROTO $PORT $ECHO"
		eval $TCL_SRC/updateImage.tcl $IP $TYPE $PROTO $PORT $ECHO
	elif [ $ACTION = "debug" ]; then
		echo "$TCL_SRC/debug.tcl $USER $PASSWORD $IP ${DEBUG_PATH%/} $DEBUG_CDL"
		eval $TCL_SRC/debug.tcl $USER $PASSWORD $IP ${DEBUG_PATH%/} $DEBUG_CDL
	#elif [ $ACTION = "test" ]; then
	#	echo ""
	fi
else
	eval $TCL_SRC/login.tcl $USER $PASSWORD $IP $PROTO $PORT
fi

