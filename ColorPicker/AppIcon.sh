#!/usr/bin/env bash

PNG_IMAGE_PATH=${1}

convert ${PNG_IMAGE_PATH} -trim AppIcon.png
num=512
while [ ${num} -ge 16 ]
do
	scale=1
	while [ ${scale} -le 2 ]
	do
		let size=num*scale
		name="icon_${num}x${num}@x${scale}.png"
		if [ ${scale} -eq 1 ]
		then
			name="icon_${num}x${num}.png"
		fi
		convert AppIcon.png -resize x${size} -background none -gravity center -extent ${size}x${size} "${name}"
		echo "    {
      \"size\" : \"${num}x${num}\",
      \"idiom\" : \"mac\",
      \"filename\" : \"${name}\",
      \"scale\" : \"${scale}x\"
    },"
		let scale=scale+1
	done
	let num=num/2
done
