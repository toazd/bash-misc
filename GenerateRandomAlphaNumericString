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

        # Concatenate sCHAR onto sRESULT
        sRESULT="${sRESULT}${sCHAR}"

    done

    # "Return" the resulting string
    printf "%s" "$sRESULT"

    return 0

}
