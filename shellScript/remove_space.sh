#!/bin/sh
#  Author: Gavin.Ke
#  Update Time: 2009/11/10
#
#  It trim spaces and tabs at the start end of line.

FIND="/usr/bin/find"
SED="/bin/sed"
GREP="/bin/grep"
 
list=$(${FIND} . -name "*.c" -o -name "*.cpp" -o -name "*.h" -o -name "*.as")
if [ "$list" == "" ]
then
	echo "There are no *.c *.cpp *.h *.as file in $(pwd) directory"
	exit 1
fi
 
for i in $list
do
	target=$(${GREP} -P "[ \t]*[ \t]$" $i)
	
	if [ ! "$target" == "" ]
	then
		${SED} -e "s/[ \t]*[ \t]$//g" -i $i
		echo $i
	fi
done
