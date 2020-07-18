#!/bin/bash

set -e

sFILE=${1:-""}

GetFile() {
    read -rp "Enter a path/file to use: " sFILE
    return 0
}

# True if string is empty (sFILE=NULL="")
[[ -z "$sFILE" ]] && { echo "File parameter required"; GetFile; }

# True if file is a directory
[[ -d $sFILE ]] && { echo "\"$sFILE\" is a directory, not a file"; exit 1; }

# True if file exists and is a regular file
[[ ! -f $sFILE ]] && { echo "Not a valid file descriptor: \"$sFILE\""; exit 1; }

# True if file is readable by you
[[ ! -r $sFILE ]] && { echo "Cannot read file: \"$sFILE\""; exit 1; }

while read -r; do
    #if ! youtube-dl -f best -ci "$REPLY"; then
        echo "$REPLY" #>> failed-videos.txt
    #fi
done < "$sFILE"
