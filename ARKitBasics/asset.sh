#!/usr/bin/env bash

name=$(echo ${1} | awk -F'/' '{print $NF}' | sed 's/\(\.[^\.]*\)$/_icon\1/')
let size=2048
let scale=1
while [ ${scale} -le 3 ]
do
	icon_name=$(echo ${name} | sed "s/\(\.[^\.]*\)$/@${scale}x\1/")
	if [ ${scale} -eq 1 ]
	then
		icon_name=${name}
	fi
	let icon_size=size*scale
	convert ${1} -verbose -resize ${icon_size}x ${icon_name}
	let scale=scale+1
done