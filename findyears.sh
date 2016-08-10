#!/bin/sh
for file in `ls`
do
	#dos2unix -o $file
	file $file
done

