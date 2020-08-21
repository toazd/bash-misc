#!/usr/bin/env bash
#
#

# Shell options
set -eEBu
shopt -s extglob

# Initialize global variables
sIN_FILE="${1:-""}"
sSTART_LINE=${2:-"###START###"}
sEND_LINE=${3:-"###END###"}
sOUT_FILE=""
iREMOVE=0

# Script usage hints
ShowUsage() {

    printf "\nUsage:\n\t%s\n" "$0 [file] [start] [end]"
    printf "\nExample file:\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n" "some stuff" "more stuff" "$sSTART_LINE" "delete this" "delete that" "$sEND_LINE" "dont delete this." "leave this too"

    exit 0

}

# Create a temp file with a unique name to use for processing
# shellcheck disable=SC2155
MkTemp() {

    local sBASE_PATH="/tmp"

    sOUT_FILE="$sBASE_PATH/tmp.$(GenRandAlphNum)"

    # Check for write access in the path that contains the temp file
    [[ -w "${sOUT_FILE%/*}" ]] || { echo "No write access to temp file path \"${sOUT_FILE%/*}\""; exit; }

    # If somehow a temp file with the same name already exists inform the user and back it up
    [[ -f "sOUT_FILE" ]] && { echo "Backing up temp file with same name (old backups will be overwritten)"; mv -fv "$sOUT_FILE" "${sOUT_FILE}.bak"; }

    # Create the empty temp file
    printf "" > "$sOUT_FILE"

    # "Return" the path and filename
    printf "%s" "$sOUT_FILE"

    return 0

}

# Generate a pseudo-random alphanumeric string
# shellcheck disable=SC2155
GenRandAlphNum() {

    local sLIST="$(printf "%s" {a..z}{0..9}{A..Z})"
    local iLEN=10
    local sRESULT=""
    local iC=1

    # Loop iLEN times
    for (( iC; iC<=iLEN; iC++ )) do

        # Randomly choose one offset of length one from sLIST
        sCHAR="${sLIST:$RANDOM%${#sLIST}:1}"

        # Randomly invert the case (ints are ignored)
        (( RANDOM % 2 )) && sCHAR=${sCHAR~}

        # Concatenate sCHAR onto sRESULT
        sRESULT="${sRESULT}${sCHAR}"

    done

    # "Return" the resulting string
    printf "%s" "$sRESULT"

    return 0

}

# Generic cleanup function
CleanUp() {

    # If a temp file was created ask to remove it
    [[ -f "$sOUT_FILE" && -w "$sOUT_FILE" ]] && rm -iv "$sOUT_FILE"

    exit 0

}

# CleanUp function gets called on EXIT signal
trap 'CleanUp' EXIT

# Very basic parameter validation
if [[ -z $sIN_FILE ]] || [[ $sIN_FILE = @("-h"|"-H"|"-help"|"--help") ]]; then
    ShowUsage
fi

# Check the first parameter
if [[ ! -f $sIN_FILE ]]; then
    echo "\"$sIN_FILE\" is not a valid file descriptor"
    ShowUsage
elif [[ ! -r $sIN_FILE ]]; then
    echo "\"$sIN_FILE\" cannot be read"
    ShowUsage
else
    # Inform the user which file will be used for input
    echo "Using \"$sIN_FILE\" for input"
fi

# Get a temporary path and filename for output
# Change MkTemp to mktemp to use the external command instead
sOUT_FILE="$(MkTemp -q)"

# Make sure that the temp file was created (only needed if external mktemp is used)
[[ -f $sOUT_FILE || -w $sOUT_FILE ]] || { echo "Temp file failure: \"$sOUT_FILE\""; exit; }

# Inform the user where the temp file was created
[[ -f $sOUT_FILE && -w $sOUT_FILE ]] && echo "Using \"$sOUT_FILE\" for processing"

# Process the input file one line at a time outputting to the temp file,
# skipping delimiter lines in addition to lines in-between the delimiters
# TODO Partial line match
while IFS=$'\n' read -r; do
    [[ $REPLY = "$sSTART_LINE" ]] && { iREMOVE=1; continue; }
    [[ $REPLY = "$sEND_LINE" ]] && { iREMOVE=0; continue; }
    (( iREMOVE )) || printf "%s\n" "$REPLY" >> "$sOUT_FILE"
done < "$sIN_FILE"

# Ask before overwriting the original file and report on failure
if ! cp -iv "$sOUT_FILE" "${sIN_FILE}"; then
        echo "Copy from \"$sOUT_FILE\" to \"$sIN_FILE\" failed"
        exit
fi
