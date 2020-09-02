#!/usr/bin/env bash

IsRunning() {

    local cmd param1 arg1 param2 arg2 remaining
    local search_cmd="metromulti"
    local search_param1="-i"
    local search_param2="-m"
    local flag_found=0

    while IFS=' ' read -r -- cmd param1 arg1 param2 arg2 remaining; do

        # Ignore the ps cmd itself and this script as a cmd or a parameter
        [[ $cmd = 'ps' || $cmd = "${0##*/}" || $param1 = "${0##*/}" ]] && continue

        # Match search_cmd and /path/to/search_cmd
        [[ $cmd = *"$search_cmd" ]] && {
            ((flag_found++))

            # Check parameters for matches
            [[ -n $param1 && $param1 = @($search_param1|$search_param2) ]] && ((flag_found++))
            [[ -n $param2 && $param2 = @($search_param1|$search_param2) ]] && ((flag_found++))

            # If the cmd and both parameters are found, break out of the while loop
            [[ $flag_found -eq 3 ]] && break
        }
    done < <(ps -eo cmd)

    # If all 3 are found return 0 (true), else return 1 (false)
    return $(( flag_found == 3 ? 0 : 1 ))
}

