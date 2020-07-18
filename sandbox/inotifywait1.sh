#!/bin/bash
sMONITOR_PATH=${1:-"/some/path"}
inotifywait -crm "$sMONITOR_PATH" -e create -e moved_to |
while read -r; do
    sPATH=${REPLY%%,*}
    sFILE=${REPLY##*,}
    sFULLNAME=${sPATH}${sFILE}
    if [[ -f $sFULLNAME && ${sFILE,,} == *.png ]]; then
        echo "$sFULLNAME is a .png file"
    elif [[ -d $sFULLNAME ]]; then
        echo "$sFULLNAME is a directory"
    fi
done
