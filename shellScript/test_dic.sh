#!/bin/bash

dir=""
while [ "$dir" != "exit" ]
do
    read -p "Please input a directory: " dir
    if [ -d "$dir" ]; then 
		first_dir_c='echo $dir | cut -c 1'
        if [ "$first_dir_c" == "/" ] || [ "$first_dir_c" == "." ]; then
		    echo "The $dir is exist in your system."
		else
		    echo "$dir is NOT a dirctory"
		fi
	fi
done
exit 0


