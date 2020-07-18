#!/bin/bash

iLINES=${1:-""}

[[ -z $iLINES ]] && exit 1

sFILE=$(mktemp -q)
echo "Using \"$sFILE\" for output..."

for ((i=0; i<iLINES; i++)); do
    printf "\n" >> "$sFILE"
done
