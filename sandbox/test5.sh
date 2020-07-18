#!/bin/bash
set -x

# unquoted assignment
sIN_A=$1

# quoted assignment
sIN_B="$1"

# unquoted assignment result
printf "%s\n" "$sIN_A"

# quoted assignment result
printf "%s\n" "$sIN_B"
