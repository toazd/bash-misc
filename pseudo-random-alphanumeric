#!/bin/bash
#
# pseudo-random alphanumeric

sLIST=""

sLIST="$(printf "%s" {a..z}{0..9}{A..Z})"
iLEN=10
sRESULT=""
iC=1

# Loop iLEN times
for (( iC; iC<=iLEN; iC++ )) do

    # Randomly choose one offset of length one from sLIST
    sCHAR="${sLIST:$RANDOM%${#sLIST}:1}"

    # Randomly invert the case (ints are ignored)
    (( RANDOM % 2 )) && sCHAR=${sCHAR~}

    # Concatenate sCHAR onto sRESULT
    sRESULT="${sRESULT}${sCHAR}"
done

echo "$sRESULT"
