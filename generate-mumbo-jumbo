#!/usr/bin/env bash
#
#

set -eEmBu

iLINE_LENGTH=${1:-100}
iLINES_TOTAL=${2:-1000}
iCOUNTER=0
iPROGRESS_PERCENT=0
iPREV_PROGRESS=1
sTMP_FILE=""
sLIST="$(printf "%s" {a..z}{0..9}{A..Z})"
#iCHILD_MAX=$(( $(nproc) / 2 ))
iCHILD_MAX=$(( $(nproc) * 200 ))

# Trap control+c and ensure all child processes stop
TrapCtrlC() {
    printf "\n%s\n" "Killing process group..."
    if ! kill -n 15 %1; then kill -n 9 %1; fi
    exit
}

# Primitive replacement for mktemp using only Bash built-ins
# shellcheck disable=SC2155
MkTemp() {

    local sPATH="/tmp"
    local sFILE=""

    [[ -d $sPATH ]] || { echo "Invalid path requested: \"$sPATH\""; return; }

    sFILE="$sPATH/tmp.$(GenerateRandomAlphaNumericString 15)"

    # Check for write access in the path that contains the temp file
    [[ -w "${sFILE%/*}" ]] || { echo "No write access to temp file path \"${sFILE%/*}\""; return; }

    # If somehow a temp file with the same name already exists inform the user and back it up
    [[ -f "sFILE" ]] && { echo "Backing up temp file with same name (old backups will be overwritten)"; mv -fv "$sFILE" "${sFILE}.bak"; }

    # Create the empty temp file
    printf "" > "$sFILE"

    # "Return" the path and filename
    printf "%s" "$sFILE"

    return 0

}

# Generate a "random" alphanumeric string using Bash built-ins
# shellcheck disable=SC2155
GenerateRandomAlphaNumericString() {

    local sRESULT=""
    local iC=0

    [[ -n ${1-} ]] && local iOLD_LINE_LENGTH=$iLINE_LENGTH && iLINE_LENGTH=$1

    # Loop iLINE_LENGTH-1 times
    for (( iC; iC<iLINE_LENGTH; iC++ )) do

        # Randomly choose one offset of length one from sLIST
        sCHAR="${sLIST:$RANDOM%${#sLIST}:1}"

        # Randomly invert the case (ints are ignored)
        #(( RANDOM % 2 )) && sCHAR=${sCHAR~}

        # Concatenate sRESULT and sCHAR
        sRESULT="${sRESULT}${sCHAR}"

    done

    # "Return" the resulting string
    printf "%s" "$sRESULT"

    [[ -n ${1-} ]] && local iLINE_LENGTH=$iOLD_LINE_LENGTH

    return 0

}

trap 'TrapCtrlC' INT

# If the length requested is outside sane upper and lower bounds, reset it
[[ $iLINE_LENGTH -lt 1 ]] && iLINE_LENGTH=1
[[ $iLINE_LENGTH -gt 32767 ]] && iLINE_LENGTH=32767

# Create the tmp file for output
sTMP_FILE="$(MkTemp)"

echo "Outputting to $sTMP_FILE with a maximum of $iCHILD_MAX child processes"

# NOTE Counting starts at 0
while [[ $iCOUNTER -lt $iLINES_TOTAL ]]; do

    # Create a child process that generates and pipes one line to the tmp file
    printf "%s\n" "$(GenerateRandomAlphaNumericString)" >> "$sTMP_FILE" &

    # Increment the counter
    iCOUNTER=$(( iCOUNTER + 1 ))

    # If you want to control the maximum number of child processes created
    # uncomment the next line and set iCHILD_MAX in variable declartion at the top
    #[[ $(jobs -pr | wc -l) -ge $iCHILD_MAX ]] && wait

    # Update the progress
    iPROGRESS_PERCENT=$(( (iCOUNTER*100) / iLINES_TOTAL ))

    # Report progress
    [[ $iPROGRESS_PERCENT -ne $iPREV_PROGRESS ]] && printf "Generating...%s\r" "${iPROGRESS_PERCENT}%"

    # Update prev-progress value (used to prevent the same-value progress from being printed multiple times)
    iPREV_PROGRESS=$iPROGRESS_PERCENT
done

[[ "$(jobs -p | wc -l)" -gt 0 ]] && printf "%s" "Waiting for $(jobs -p | wc -l) jobs to finish..."

wait

printf "\033[2K\r"

sync "$sTMP_FILE"

#xdg-open "$sTMP_FILE" &
