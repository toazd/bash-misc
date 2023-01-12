#!/bin/bash

output_folder="output"

mkdir -p "$output_folder"

for file in "${PWD}/"*.mp4
do
    nice -n 19 ffmpeg -n -i "$file" -preset veryfast -tune film -profile:v main -c:v libx264 -c:a aac -b:a 192k -movflags +faststart -filter:a "volume=30dB" "${output_folder}/$(basename "$file")"
done
