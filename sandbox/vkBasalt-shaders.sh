#!/bin/bash
sSHADERS_PATH="/usr/share/reshade/shaders"
for sFILE in "$sSHADERS_PATH"/*; do
    [[ ${sFILE,,} == *.fx ]] && {
        printf "%s = %s\n" "$(basename "${sFILE,,}" .fx)" "\"$sFILE\""
    }
done
