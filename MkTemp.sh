# Bash only primitive replacement for mktemp
# Accepts one parameter: the path where the temp file will be created (default: /tmp)
# shellcheck disable=SC2155
MkTemp() {

    local sTMP_PATH="${1:-"/tmp"}"
    local sTMP_FILE=""

    [[ -d $sTMP_PATH ]] || { echo "Invalid path requested: \"$sTMP_PATH\""; return; }

    sTMP_FILE="$sTMP_PATH/tmp.$(GenerateRandomAlphaNumericString)"

    # Check for write access in the path that contains the temp file
    [[ -w "${sTMP_FILE%/*}" ]] || { echo "No write access to temp file path \"${sTMP_FILE%/*}\""; return; }

    # If somehow a temp file with the same name already exists inform the user and back it up
    [[ -f "sTMP_FILE" ]] && { echo "Backing up temp file with same name (old backups will be overwritten)"; mv -fv "$sTMP_FILE" "${sTMP_FILE}.bak"; }

    # Create the empty temp file
    printf "" > "$sTMP_FILE"

    # "Return" the path and filename
    printf "%s" "$sTMP_FILE"

    return 0

}

# Generate a pseudo-random alphanumeric string using only Bash
# Accepts one parameter: the length of the string to generate (range 1-32767) (default: 10)
# shellcheck disable=SC2155
GenerateRandomAlphaNumericString() {

    local sLIST="$(printf "%s" {a..z}{0..9}{A..Z})"
    local iLEN=${1:-10}
    local sRESULT=""
    local iC=1

    # If the length requested is outside sane upper and lower bounds, reset it
    [[ $iLEN -lt 1 ]] && iLEN=1
    [[ $iLEN -gt 32767 ]] && iLEN=32767

    # Loop iLEN times
    for (( iC; iC<=iLEN; iC++ )) do

        # Randomly choose one offset of length one from sLIST
        sCHAR="${sLIST:$RANDOM%${#sLIST}:1}"

        # Randomly invert the case (ints are ignored)
        (( RANDOM % 2 )) && sCHAR=${sCHAR~}

        # Concatenate sRESULT and sCHAR
        sRESULT="${sRESULT}${sCHAR}"

    done

    # "Return" the resulting string
    printf "%s" "$sRESULT"

    return 0

}
