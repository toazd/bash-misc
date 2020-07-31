#!/bin/bash
while :; do
    if (( RANDOM % 2 )); then
        [[ $(true $(false $(true $(false $(true $(false $(true $(false $(true))))))))) && $(true) && $(true) || $(true) || $(true) ]] && $(true) &
    else
        [[ $(true $(false $(true $(false $(true $(false $(true $(false $(true))))))))) && $(true) && $(true) || $(true) || $(true) ]] && $(true) &
    fi

    #jobs -pr | wc -l
done
