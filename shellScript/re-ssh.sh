#!/bin/bash

useage() {
	echo -e "Useage: ${0##*/} [-h] [hostname]"
	echo -e ""
	echo -e "  -h: display this help message"
	echo -e ""
}

if [ $# -eq 0 -o $# -gt 1 ]; then
	useage
	exit 0
fi

while getopts "h" OPTION
do
	case ${OPTION} in
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

ssh-keygen -R $1 > /dev/null 2>&1
ssh-keyscan $1 >> ~/.ssh/known_hosts 2> /dev/null


