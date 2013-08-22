#!/bin/sh

ssh gitolite@gozilla info | grep -v "/\.\*" > ./git.tmp
line=`wc -l ./git.tmp | cut -d " " -f 1`
for (( i=3; i<=$line; i=i+1 ))
do
	text=`sed -n "$i p" ./git.tmp | awk '{print $NF}'`
	if [ "$text" != "test" -a "$text" != "gitolite-admin" ]; then
		echo "gitolite mirror push lilee-git-tw $text"
	fi
done
rm -f ./git.tmp

