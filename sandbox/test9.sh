#!/bin/bash

STATUS="    pool: tank

   state: ONLINE

   scrub: none requested

  config:



    NAME        STATE     READ WRITE CKSUM

    tank        ONLINE       0     0     0

      mirror    ONLINE       0     0     0

        c1t0d0  ONLINE       0     0     0

        c1t1d0  ONLINE       0     0     0



errors: No known data errors

"

STATUS="${STATUS#*"state:"}" # removes everything up to state:

STATUS="${STATUS%"scrub:"*}"

STATUS="${STATUS//[[:space:]]}" # drops whitespace

printf '%s' "$STATUS"
