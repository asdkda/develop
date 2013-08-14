#!/bin/bash


TOP=`dirname $0`

# set default value for each variable
LIST=""
DEST=""
cmd=""

url_list=()


usage() {
	echo -e "Usage: ${0##*/} -l list -d dest"
	echo -e "       ${0##*/} -h"
	echo -e ""
	echo -e "Options:"
	echo -e "  -l: the svn url list"
	echo -e "  -d: git destination dir"
	echo -e "  -r: dryrun"
	echo -e "  -h: display this help message"
	echo -e ""
	echo -e ""
}

convertBranch() {
	# $1: url
	# $2: branch version
	
	# open_src return error
	test=`echo $1 | grep "/open_src/"`
	if [ -n "$test" ]; then
		return 1
	fi
	
	branch=`echo $1 | sed "s/trunks/branches/"`
	branch=`echo $branch | sed "s/trunk/branches/"`
	branch="$branch/$2"
	
	return 0
}

fettchBranch() {
	# $1: url
	# $2: branch version
	convertBranch $1 $2
	if [ $? = 0 ]; then
		svn info $branch > /dev/null
		if [ $? != 0 ]; then
			return
		fi
		eval "$cmd git config --add svn-remote.$2.url $branch"
		eval "$cmd git config --add svn-remote.$2.fetch :refs/remotes/$2"
		eval "$cmd git svn fetch $2"
		eval "$cmd git checkout -b $2 remotes/$2"
		eval "$cmd git push origin $2"
	fi
}

convertGit() {
	# $1: url
	# $2: git name
	#printf "%-75s -> %s\n" $1 $2

	eval "$cmd git svn init $1"
	eval "$cmd git svn fetch"
	
	eval "$cmd git remote add origin gitolite@gozilla:$2"
	eval "$cmd git push origin master"
	fettchBranch $1 2.5
	fettchBranch $1 2.3
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


if [ "$LIST" = "" -o "$DEST" = "" ]; then
	echo "You should specified list and destination"
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

for list in `cat $LIST`; do
	name=`echo $list|sed "s|http://humvee/svn/||"|sed "s|trunks/||"|sed "s|trunk/||"`
	name=`echo $name|sed "s|sys_sw/||"|sed "s|plat_sw|platform|"`
	name=`echo $name|sed "s|open_src|3rd-party|"`
	name=`echo $name|sed "s|license_mgmt/||"`
	
	path="$DEST/$name"
	mkdir -p $path
	cd $path
	convertGit $list $name
done





