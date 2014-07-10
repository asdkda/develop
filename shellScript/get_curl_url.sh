#!/bin/bash

TOP=`dirname $0`
ip=$($TOP/get_ip.sh)

usage() {
	echo -e "Usage: ${0##*/} [-t] [-f]"
	echo -e "       ${0##*/} -h"
	echo -e ""
	echo -e "Options:"
	echo -e "  -t: tftp command"
	echo -e "  -f: fcaps lib"
	echo -e "  -h: display this help message"
	echo -e ""
	echo -e ""
}

cmdType=0
# now we can process with getopt
while getopts "tfzh" OPTION
do
	case ${OPTION} in
		t)
			cmdType=t
			;;
		f)
			cmdType=f
			;;
		z)
			cmdType=z
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

shift $((OPTIND-1))

file=`basename $1`

if [ $cmdType = 't' ]; then
	echo "curl -O -f tftp://$ip/$file"
elif [ $cmdType = 'f' ]; then
	echo "curl -f http://$ip/tftpboot/$file -o /opt/lilee/lib/fcaps/$file"
elif [ $cmdType = 'z' ]; then
	echo "tftp -g -r \"$file\" $ip"
else
	echo "curl -O -f http://$ip/tftpboot/$file; chmod 777 $file"
fi

