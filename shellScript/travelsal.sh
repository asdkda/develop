#!/bin/bash


TOP=`dirname $0`

# set default value for each variable
SOURCE=""
DEST=""
LIST=""

url_list=()

usage() {
	echo -e "Usage: ${0##*/} -s source -d dest [-l list]"
	echo -e "       ${0##*/} -h"
	echo -e ""
	echo -e "Options:"
	echo -e "  -s: svn source code dir"
	echo -e "  -d: destination dir"
	echo -e "  -l: the list we already generated"
	echo -e "  -h: display this help message"
	echo -e ""
	echo -e ""
}

add_int_list() {
	#check if already in $LIST
	if [ "$LIST" != "" ]; then
		for list in `cat $LIST`; do
			if [ $list = $1 ]; then
				return 1
			fi
		done
	fi
	
	url_list+=("$1")
	return 0
}

trace_external() {
	svn pg svn:externals $1 2> /dev/null > /tmp/external
	while read line; do
		link=`echo $line|grep "http://"|sed "s/.*\(http:[a-zA-Z0-9/_-.]*\).*/\1/"`
		path=`echo $line|grep "http://"|sed "s/http:[a-zA-Z0-9/_-.]*//"| sed "s/ //"`
		if [ -z "$link" ]; then
			continue
		fi

		#echo $link
		add_int_list $link
		if [ $? -eq 0 ]; then
			printf "%-60s %s\n" $link $1/$path >> $DPATH
		fi
	done < /tmp/external
	
	for dir in `ls $1/* -d`; do
		#echo "got $dir"
		if [ -d $dir -a ! -L $dir ]; then
			trace_external $dir
		fi
	done
}


# trap interrupt first
trap 'echo Interrupted; exit' INT

# now we can process with getopt
while getopts "s:d:l:h" OPTION
do
	case ${OPTION} in
		s)
			SOURCE=${OPTARG}
			;;
		d)
			DEST=${OPTARG}
			;;
		l)
			LIST=${OPTARG}
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


if [ "$SOURCE" = "" -o "$DEST" = "" ]; then
	echo "You should specified source and destination"
	echo ""
	usage
	exit 0
fi

if [ ! -d "$SOURCE" -o ! -w "$SOURCE" ]; then
	echo "source: \"$SOURCE\" is bad"
	echo ""
	usage
	exit 0
fi

if [ ! -d "$DEST" -o ! -w "$DEST" ]; then
	echo "destination: \"$DEST\" is bad"
	echo ""
	usage
	exit 0
fi

DLIST=$DEST/list
DPATH=$DEST/path

rm -f $DLIST $DPATH
touch $DLIST $DPATH

url=`svn info $SOURCE| grep URL| cut -d ' ' -f 2`
add_int_list $url

trace_external $SOURCE

# output list
while [ "${url_list[$i]}" != "" ]
do
	echo ${url_list[$i]} >> $DLIST
	i=$(($i+1))
done



