#!/usr/bin/env bash
#
# Toazd 2020 Unlicense
#
# Find and count files, folders, and symlinks using only bash built-ins
#

shopt -s nullglob extglob globstar dotglob
set -eEBu

sSEARCH_PATH=${1:-"$(builtin pwd -P)"}
iaFILES=()
iaDIRS=()
iaLINKS=()
sNODE=""
iMIMIC_FIND=0 # If you want to count the search_path in the results like find does set iMIMIC_FIND to 1

# If a file is specified as the search path
[[ -f $sSEARCH_PATH ]] && { echo "$sSEARCH_PATH is a file, please specify a path"; exit 1; }

# If search path is not a folder that we can read from, abort
[[ -d $sSEARCH_PATH || -r $sSEARCH_PATH ]] || { echo "$sSEARCH_PATH is not a valid path or cannot be read"; exit 1; }

# Remove a trailing forward-slash "/" if it is present
[[ ${sSEARCH_PATH:${#sSEARCH_PATH}-1:1} = "/" ]] && sSEARCH_PATH=${sSEARCH_PATH:0:${#sSEARCH_PATH}-1}

# NOTE find -type d will return the search_path in the results
# to mimic that behavior, set iMIMIC_FIND=1
(( iMIMIC_FIND )) && iaDIRS+=("$sSEARCH_PATH")

for sNODE in "$sSEARCH_PATH"/**/*; do
    [[ ${sNODE##*/} = @(""|"."|"..") ]] && continue
    [[ -h $sNODE ]] && { iaLINKS+=("${sNODE}"); continue; }
    [[ -f $sNODE ]] && { iaFILES+=("${sNODE}"); continue; }
    [[ -d $sNODE ]] && { iaDIRS+=("${sNODE}"); continue; }
done

printf "\033[0;31m%s%s\033[0m\n" "Files:    " "${#iaFILES[@]}"

printf "\033[0;34m%s%s\033[0m\n" "Folders:  " "${#iaDIRS[@]}"

printf "\033[0;32m%s%s\033[0m\n" "Symlinks: " "${#iaLINKS[@]}"
