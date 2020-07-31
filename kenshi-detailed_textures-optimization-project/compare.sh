#!/bin/bash

sDETAILED_TEXTURES_PATH="/home/toazd/.local/share/Steam/steamapps/workshop/content/233860/1676068316"
sCOMPRESSED_TEXTURES_PATH="/home/toazd/.local/share/Steam/steamapps/workshop/content/233860/1649794243"
sKENSHI_DATA_PATH="/home/toazd/.local/share/Steam/steamapps/common/Kenshi/data"

mapfile -t <<< "$(find "$sDETAILED_TEXTURES_PATH" -iname "*.dds" ! -iname "*copy*" ! -iname "*backup*" 2>/dev/null)" iaDETAILED_FILES

# csv header
echo "Version,File,Width,Height,Compression,Transparency,Colorspace,Bytes"

for sFILE in "${iaDETAILED_FILES[@]}"; do

    magick identify -format "Detailed,%[f],%[width],%[height],%[compression],%[A],%[channels],%[B]\n" "$sFILE" 2>/dev/null

    sFILE=$(basename "$sFILE")

    sCOMPRESSED_FILE=$(find "$sCOMPRESSED_TEXTURES_PATH"/ -name "$sFILE" 2>/dev/null)
    if [[ -z $sCOMPRESSED_FILE ]]; then
        : #echo "Compressed,NA"
    else
        magick identify -format "Compressed,%[f],%[width],%[height],%[compression],%[A],%[channels],%[B]\n" "$sCOMPRESSED_FILE" 2>/dev/null
    fi

    sORIGINAL_FILE=$(find "$sKENSHI_DATA_PATH"/ -name "$sFILE" 2>/dev/null)
    if [[ -z $sORIGINAL_FILE ]]; then
        : #echo "Original,NA"
    else
        magick identify -format "Original,%[f],%[width],%[height],%[compression],%[A],%[channels],%[B]\n" "$sORIGINAL_FILE" 2>/dev/null
    fi

    printf "\n"

done
