#!/bin/bash

source_dir="/home/e2500/src"
patch_dir="/home/patch"

[ "$#" -ne 1 ] && echo "The number of parameter is not equal 1.  Stop here." \
	&& exit 0

filelist=`grep "^diff" $1 | cut -d ' ' -f 3 | sed -e "s/.*\(router\/.*\)/\1/g"`

echo "** copy the source files..."

for filename in $filelist
do
	#echo $filename
	dir=`echo $filename | sed -e "s/\(.*\/\).*/\1/g"`
	#echo $dir
	if [ ! -d "$patch_dir/$dir" ]; then
		echo "mkdir $patch_dir/$dir"
		mkdir -p $patch_dir/$dir
	fi
	echo "cp $source_dir/$filename $patch_dir/$dir"
	cp $source_dir/$filename $patch_dir/$dir
done

echo "** tar the source files..."

cd /home
tar -czP patch/ -f /home/source.tar.gz
rm -rf $patch_dir

echo "** done"

exit 0


