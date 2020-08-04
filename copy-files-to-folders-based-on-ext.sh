#!/usr/bin/env bash
#
# BUG  The current script name is ignored during searching based on $0 (minus a leading dot forward-slash "./" if it exists).
#      This means that if the script is invoked as ./script.sh, then all copies of "script.sh" in any path within sSOURCE_PATH
#       will be ignored.
#
# BUG  When using asterisk "*" as a search pattern (the default if none is specified) files named like
#       "APACHE-LICENSE-2.0" and "spotify-1.1.10.546-Release" will be put into a folder named based on
#       all of the characters following the right-most dot "." found in their respective names.
#        eg. "APACHE-LICENSE-2.0" will be put into the folder "0" and "spotify-1.1.10.546-Release" will be put into the folder ".546-Release"
#
# BUG  If sTARGET_PATH exists in multiple locations, all of them will be excluded from searches
#       eg. If "sTARGET_PATH=output_path", then both "/home/toazd/output_path" and "/usr/share/output_path" will be ignored
#

shopt -s nullglob dotglob

# TODO parameter handling and usage output
# All parameters are optional
# First parameter = /search/path (default: the current working directory) NOTE this does not have to be the script path
# Second parameter = extension (default: *)
# Third parameter = /path/to/copyto (default: "sandbox/move_ext_test") NOTE this is relative to the current working directory not the script path

ShowUsage() {
    printf 'Usage:\n%s\n%s\n' \
           "${0##*/} [/search/path] [/target/path] *.[pattern]" \
           "[/search/path] and [/target/path] are required, [pattern] defaults to \"*\""
    exit 0
}

sSOURCE_PATH=
sTARGET_PATH=
sSEARCH_PATTERN=${3-'*'}
sFILE=
iFILE_COUNTER=0
iCOUNTER=0

# If there is at least two parameters but
# no more than three parameters
[[ $# -ge 2 && $# -le 3 ]] || ShowUsage

# Read parameters into their respective variables
# Attempt to support all characters that find supports
# NOTE $# is 0 and $@ is empty after this
if [[ $1 ]]; then
    [[ -z $sSOURCE_PATH ]] && sSOURCE_PATH=$1
    shift
    [[ -z $sTARGET_PATH ]] && sTARGET_PATH=$1
    shift
    [[ -n $1 ]] && sSEARCH_PATTERN=$1
    shift
fi

# If sTARGET_PATH is dot ".", dot forward-slash "./", or NULL "", set it to $PWD
[[ $sTARGET_PATH =~ ^\.$|^\./+$|^$ ]] && sTARGET_PATH=${PWD:-$(pwd)}

echo "Checking the path \"$sSOURCE_PATH\" for files that match the pattern \"*.$sSEARCH_PATTERN\""
printf "%s\033[s" "Processing files..."
while IFS= read -r sFILENAME; do

    [[ $iCOUNTER -eq 0 ]] && \
        printf "%s\n" "Copy,DupTest,Mkdir,sFILENAME,sBASENAME_NO_EXT,sBASENAME,sEXT,sLOWERCASE_EXT,sTARGET_PATH,sFILE" > debug-output.csv # TODO remove debug stuff

    # Count each file returned from find
    iCOUNTER=$((iCOUNTER+1))

    # Output progress (which file returned from find is about to be processed)
    printf "\033[u%s" "${iCOUNTER}"

    # Replace all instances of dot forward-slash "./" with NULL
    sFILENAME=${sFILENAME//.\/}

    # Replace all instances of double forward-slash "//" with single forward-slash "/"
    #sFILENAME=${sFILENAME//\/\//\/}

    # Filter through the results
    #
    # If we have read access to the file (TODO change to -w for move) and
    if [[ -r $sFILENAME ]]; then

        # Get the basename of the file not including the extension
        sBASENAME_NO_EXT=${sFILENAME%.*}
        sBASENAME_NO_EXT=${sBASENAME_NO_EXT##*/}

        # Get the basename of the file including the extension
        sBASENAME=${sFILENAME##*/}

        # Get the file extension
        sEXT=${sFILENAME##*.}

        # Get the extension in all lower-case characters
        sLOWERCASE_EXT=${sEXT,,}

        # Create the path to move the file to using the extension
        # after converting the extension to all lower-case
        #
        # NOTE if we have write access the folder already exists and we can write to it
        #      so there's no need to run mkdir
        # NOTE checking for write access will also fail if the path does not exist
        [[ -w "$sTARGET_PATH/$sLOWERCASE_EXT" ]] || {
            mkdir -p "$sTARGET_PATH/$sLOWERCASE_EXT" || {
                printf "%s\n" "True,False,False,$sFILENAME,$sBASENAME_NO_EXT,$sBASENAME,$sEXT,$sLOWERCASE_EXT,$sTARGET_PATH,$sFILE" >> debug-output.csv # TODO remove debug stuff
                continue
            }
        }

        # Check for a possible file name conflicts and handle conflicts in a way
        # that prevents files from being overwritten
        #
        # No existing file with the same name was found
        if [[ ! -f "${sTARGET_PATH}/${sLOWERCASE_EXT}/${sBASENAME}" ]]; then

            # Copy the file to its respective path
            # If the copy is successful iterate the file counter
            # TODO change cp to mv when testing is "done"
            if cp -n "$sFILENAME" "${sTARGET_PATH}/${sLOWERCASE_EXT}"; then
                iFILE_COUNTER=$((iFILE_COUNTER+1))
                printf "%s\n" "True,False,True,$sFILENAME,$sBASENAME_NO_EXT,$sBASENAME,$sEXT,$sLOWERCASE_EXT,$sTARGET_PATH,$sFILE" >> debug-output.csv # TODO remove debug stuff
            else
                printf "%s\n" "False,False,True,$sFILENAME,$sBASENAME_NO_EXT,$sBASENAME,$sEXT,$sLOWERCASE_EXT,$sTARGET_PATH,$sFILE" >> debug-output.csv # TODO remove debug stuff
            fi
        # An existing file with the same was found in the path sTARGET_PATH/sLOWERCASE_EXT
        else
            #####echo "Duplicate file name detected: $sFILENAME"

            # If they are hardlinks they are already the same, no need to compare
            [[  $sFILENAME -ef "${sTARGET_PATH}/${sLOWERCASE_EXT}/${sBASENAME}" ]] && {
                #####echo "Hardlink detected, skipping copy"
                continue
            }

            # Attempt to narrow down the files to compare against
            #
            # NOTE not all files are checked against. Files with duplicate
            # contents but sufficiently different names will still be copied.
            # NOTE If sBASENAME_NO_EXT=NULL then the file name begins with a dot "."
            # TODO whether or not to check all files might make a good option parameter
            if [[ -n $sBASENAME_NO_EXT ]]; then
                for sFILE in "${sTARGET_PATH}/${sLOWERCASE_EXT}/${sBASENAME_NO_EXT}"*; do
                    if cmp -s "$sFILENAME" "$sFILE"; then
                        #####echo "Exact copy found at: $sFILE, skipping copy"
                        continue 2
                    fi
                done
            elif [[ -z $sBASENAME_NO_EXT ]]; then
                for sFILE in "${sTARGET_PATH}/${sLOWERCASE_EXT}/${sBASENAME}"*; do
                    if cmp -s "$sFILENAME" "$sFILE"; then
                        #####echo "Exact copy found at: $sFILE, skipping copy"
                        continue 2
                    fi
                done
            fi

            #####echo "Duplicate file is unique, copying but renaming with unique identifier"

            # Name the file based on whether it is a dotfile or not
            #
            # NOTE if sFILENAME is a dotfile, then sEXT contains all the characters after the leading dot
            # TODO better unique identifiers
            if [[ -n $sBASENAME_NO_EXT ]]; then
                if cp -n "$sFILENAME" "${sTARGET_PATH}/${sLOWERCASE_EXT}/${sBASENAME_NO_EXT}_${RANDOM}${RANDOM}.${sEXT}"; then
                    iFILE_COUNTER=$((iFILE_COUNTER+1))
                    printf "%s\n" "True,True,True,$sFILENAME,$sBASENAME_NO_EXT,$sBASENAME,$sEXT,$sLOWERCASE_EXT,$sTARGET_PATH,$sFILE" >> debug-output.csv # TODO remove debug stuff
                else
                    printf "%s\n" "False,True,True,$sFILENAME,$sBASENAME_NO_EXT,$sBASENAME,$sEXT,$sLOWERCASE_EXT,$sTARGET_PATH,$sFILE" >> debug-output.csv # TODO remove debug stuff
                fi
            elif [[ -z $sBASENAME_NO_EXT ]]; then
                if cp -n "$sFILENAME" "${sTARGET_PATH}/${sLOWERCASE_EXT}/.${sEXT}_${RANDOM}${RANDOM}"; then
                    iFILE_COUNTER=$((iFILE_COUNTER+1))
                    printf "%s\n" "True,True,True,$sFILENAME,$sBASENAME_NO_EXT,$sBASENAME,$sEXT,$sLOWERCASE_EXT,$sTARGET_PATH,$sFILE" >> debug-output.csv # TODO remove debug stuff
                else
                    printf "%s\n" "False,True,True,$sFILENAME,$sBASENAME_NO_EXT,$sBASENAME,$sEXT,$sLOWERCASE_EXT,$sTARGET_PATH,$sFILE" >> debug-output.csv # TODO remove debug stuff
                fi
            fi
        fi
    else
        echo "No read access to: \"$sFILENAME\""
    fi
done < <(find "${sSOURCE_PATH}" -type f -not -path "*$sTARGET_PATH*" -not -name "${0/#.\/}" -iname "*.${sSEARCH_PATTERN}" 2>/dev/null)

# Report what happened
if [[ $iFILE_COUNTER -eq 0 && $iCOUNTER -gt 1 ]]; then
    printf "\r\033[0K%s\n" "$iCOUNTER files checked. No new, unique files found."
elif [[ $iFILE_COUNTER -ge 1 && $iCOUNTER -gt 1 ]]; then
    if [[ $iFILE_COUNTER -eq 1 ]]; then
        printf "\r\033[0K%s\n" "$iCOUNTER files checked. $iFILE_COUNTER is new and unique."
        echo "It was copied to \"$PWD/$sTARGET_PATH\""
    elif [[ $iFILE_COUNTER -gt 1 ]]; then
        printf "\r\033[0K%s\n" "$iCOUNTER files checked. $iFILE_COUNTER are new and unique."
        echo "They were copied to \"$PWD/$sTARGET_PATH\""
    fi
elif [[ $iCOUNTER -eq 0 ]]; then
    printf "\r\033[0K%s\n" "No files found in path \"$sSOURCE_PATH\". No changes were made."
else
    printf "\n%s\n" "An unknown error occured: \"$iCOUNTER\" \"$iFILE_COUNTER\""
fi
