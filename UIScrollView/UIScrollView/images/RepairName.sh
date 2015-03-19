#!/bin/bash
find . -iname '*.jpg' | while read line
do
	name=$(echo ${line} | awk -F/ '{print tolower($NF)}')
	mv -v ${line} ${name}
done