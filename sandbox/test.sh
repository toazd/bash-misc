#!/bin/bash
zipped="$1"
gunzipped="$(gunzip -c "$zipped")"
mapfile <<< "$gunzipped"
echo "Lines: ${#MAPFILE[@]}"
