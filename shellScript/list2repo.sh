#!/bin/bash


TOP=`dirname $0`

# set default value for each variable
LIST=""

usage() {
	echo -e "Usage: ${0##*/} -l list"
	echo -e "       ${0##*/} -h"
	echo -e ""
	echo -e "Options:"
	echo -e "  -l: the svn url list"
	echo -e "  -h: display this help message"
	echo -e ""
	echo -e ""
}

# trap interrupt first
trap 'echo Interrupted; exit' INT

# now we can process with getopt
while getopts "s:d:l:rh" OPTION
do
	case ${OPTION} in
		s)
			SOURCE=${OPTARG}
			;;
		d)
			DEST=`readlink -f ${OPTARG}`
			;;
		l)
			LIST=${OPTARG}
			;;
		r)
			cmd="echo"
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


if [ "$LIST" = "" ]; then
	echo "You should specified list"
	echo ""
	usage
	exit 0
fi

cat $LIST > /tmp/external
while read line; do
	git=`echo $line|cut -d ' ' -f 1`
	path=`echo $line|cut -d ' ' -f 2|sed -s "s|/work/ptc-3000/||"`
	
	name=`echo $git|sed "s|http://humvee/svn/||"|sed "s|trunks/||"|sed "s|trunk/||"`
	name=`echo $name|sed "s|sys_sw/||"|sed "s|plat_sw|platform|"`
	name=`echo $name|sed "s|open_src|3rd-party|"`
	name=`echo $name|sed "s|license_mgmt/||"`
	
	printf "\t<project name=\"%s\" path=\"%s\"/>\n" $name $path

done < /tmp/external







