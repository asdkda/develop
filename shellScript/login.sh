#!/bin/bash

source ~/config/config.sh
TOP=`dirname $0`
TCL_SRC=`readlink -f $TOP/../tcl`

useage() {
	echo -e "Useage: ${0##*/} [-s] [-h]"
	echo -e "\t [-u name] [-p passwd] [--port port] [--upgrade] [--test] [-d soName --cdl] [--lmc] [--wms] -i ip"
	echo -e ""
	echo -e "  -s: ssh login"
	echo -e "  -d: debug so"
	echo -e "  --cdl: debug with cdl"
	echo -e "  -h: display this help message"
	echo -e ""
	echo -e "  Use admin:admin telnet login remote device(10.2.10.85) by default."
	echo -e ""
}

# set default value for each variable
USER="admin"
PASSWORD=$ADMIN_PW
COS_PASSWORD=""
IP="10.2.10.100"
PROTO="telnet"
TYPE="marconi"
PORT=""
DEFAULT_ROOT_PASSWD=$LILEE_PW
DEFAULT_ROOT_PASSWD2=$ROOT_PW

UPGRADE=0
DEBUG=0
DEBUG_SO=""
DEBUG_CDL=0
TEST=0

# trap interrupt first
trap 'echo Interrupted; exit' INT

# translate long options to short
for arg
do
	delim=""
	case "$arg" in
		--cdl) args="${args}-c ";;
		--help) args="${args}-h ";;
		--port) args="${args}-t ";;
		--upgrade) args="${args}-a ";;
		--lmc) args="${args}-l ";;
		--wms) args="${args}-w ";;
		--test) TEST=1;;
		# pass through anything else
		*) [[ "${arg:0:1}" == "-" ]] || delim="\""
			args="${args}${delim}${arg}${delim} ";;
	esac
done
# reset the translated args
eval set -- $args
# now we can process with getopt
while getopts "ashlwu:p:t:i:I:d:c" OPTION
do
	case ${OPTION} in
		c)
			DEBUG_CDL=1
			;;
		d)
			DEBUG=1
			DEBUG_SO=${OPTARG}
			;;
		s)
			PROTO="ssh"
			;;
		u)
			USER=${OPTARG}
			;;
		p)
			COS_PASSWORD=${OPTARG}
			;;
		t)
			PORT=${OPTARG}
			;;
		i)
			IP=${OPTARG}
			;;
		I)
			IP=10.2.10.${OPTARG}
			;;
		a)
			UPGRADE=1
			;;
		l)
			TYPE="lmc"
			;;
		w)
			TYPE="wms"
			;;
		h)
			useage
			exit 0
			;;
		?)
			useage
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
	useage
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

if [ $DEBUG = 1 ]; then
	echo "$TCL_SRC/debug.tcl $USER $PASSWORD $IP $DEBUG_SO $DEBUG_CDL"
	eval $TCL_SRC/debug.tcl $USER $PASSWORD $IP $DEBUG_SO $DEBUG_CDL
elif [ $UPGRADE = 1 ]; then
	echo "$TCL_SRC/updateImage.tcl $IP $TYPE $PROTO $PORT"
	eval $TCL_SRC/updateImage.tcl $IP $TYPE $PROTO $PORT
elif [ $TEST = 1 ]; then
	echo "$DEV_PATH/shellScript/caseTest.sh -i $IP -t $TYPE"
	eval $DEV_PATH/shellScript/caseTest.sh -i $IP -t $TYPE
else
	echo "$TCL_SRC/login.tcl $USER $PASSWORD $IP $PROTO $PORT"
	eval $TCL_SRC/login.tcl $USER $PASSWORD $IP $PROTO $PORT
fi

