#!/bin/sh

DIR="/work/private/test_case"
source ~/config/config.sh

USE_ZENITY=1
tmp_file="/tmp/.dialog"

source $DEV_PATH/shellScript/login.sh -a test $@

useage() {
	echo -e "Useage: ${0##*/} [-i IP] [-t device type] [-h]"
	echo -e "  -h: display this help message"
	echo -e ""
}

read_input()
{
	cat $tmp_file
	read ans
	if [ $ans -le 0 -o $ans -gt $i ]; then
		echo puts "Please input correct option!"
		exit
	fi
}

generate_zenity_menu()
{
	echo "zenity --list --width=500 --height=400 \\
          --title=\"Choose the Item You Wish to Test\" \\
          --column=\"No\" --column=\"Item                              \" --column=\"Detail\" \\" > $tmp_file
          

	C=0
	while [ "${ARRAY[$C]}" != "" ]
	do
		if [ "${ARRAY[$C]}" != "" ] ; then
			echo "\"$(($C+1))\" \"${ARRAY[$C]}\" \"${DESC[$C]}\" \\" >> $tmp_file
		fi
		C=$(($C+1))
	done
	echo "\"$(($C+1))\" \"all\" \"\" \\" >> $tmp_file
	C=$(($C+1))

	echo " > /tmp/.select" >> $tmp_file

	sh $tmp_file
	ans=`cat /tmp/.select`
	if [ -z $ans ]; then
		echo "Please input correct option!"
		exit
	fi
}

generate_zenity_file_menu()
{
	echo "zenity --list --width=500 --height=400 \\
          --title=\"Choose the Item You Wish to Test\" \\
          --column=\"No\" --column=\"Item                              \" --column=\"Detail\" \\" > $tmp_file
          

	C=0
	while [ "${FILE[$C]}" != "" ]
	do
		if [ "${FILE[$C]}" != "" ] ; then
			echo "\"$(($C+1))\" \"`basename ${FILE[$C]}`\" \"${FILEDESC[$C]}\" \\" >> $tmp_file
		fi
		C=$(($C+1))
	done
	echo "\"$(($C+1))\" \"all\" \"\" \\" >> $tmp_file
	C=$(($C+1))

	echo " > /tmp/.select" >> $tmp_file

	sh $tmp_file
	ans=`cat /tmp/.select`
	if [ -z $ans ]; then
		echo "Please input correct option!"
		exit
	fi
}


echo "What do you want to test ?" > $tmp_file
i=1
ARRAY=()
for dir in `ls -d $DIR/*/`
do
	dir_name=`basename $dir`
	echo $i. $dir_name >> $tmp_file
	i=$(($i+1))
	ARRAY+=("$dir_name")
done
echo $i. all >> $tmp_file
#echo "${ARRAY[@]}"

if [ $USE_ZENITY -eq 0 ]; then
	read_input
else
	generate_zenity_menu
fi

# check if it is all
if [ $i -eq $ans ]; then
	cd $DIR && ./start.tcl $IP $TYPE $DIR/all.tcl
	exit
fi

echo "What case do you want to test ?" > $tmp_file
i=1
FILE=()
for file in `ls $DIR/${ARRAY[$(($ans-1))]}/`
do
	echo $i. $file >> $tmp_file
	i=$(($i+1))
	FILE+=("${ARRAY[$(($ans-1))]}/$file")
done
echo $i. all >> $tmp_file
#echo "${FILE[@]}"

if [ $USE_ZENITY -eq 0 ]; then
	read_input
else
	generate_zenity_file_menu
fi


# do tcl
if [ $i -eq $ans ]; then
	cd $DIR && ./start.tcl $IP $TYPE ${FILE[@]}
else
	cd $DIR && ./start.tcl $IP $TYPE ${FILE[$(($ans-1))]}
fi




