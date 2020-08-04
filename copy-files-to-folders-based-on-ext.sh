#!/usr/bin/env bash
#
# BUG  The current script name is ignored during searching based on $0 (minus a leading dot forward-slash "./" if it exists).
#      This means that if the script is invoked as ./script.sh, then all copies of "script.sh" in any path within sSEARCH_PATH
#       will be ignored.
#
# BUG  When using asterisk "*" as a search pattern (the default if none is specified) files named like
#       "APACHE-LICENSE-2.0" and "spotify-1.1.10.546-Release" will be put into a folder named based on
#       all of the characters following the right-most dot "." found in their respective names.
#        eg. "APACHE-LICENSE-2.0" will be put into the folder "0" and "spotify-1.1.10.546-Release" will be put into the folder ".546-Release"
#
# BUG  If sMOVE_TO_PATH exists in multiple locations, all of them will be excluded from searches
#       eg. If "sMOVE_TO_PATH=output_path", then both "/home/toazd/output_path" and "/usr/share/output_path" will be ignored
#

shopt -s nullglob dotglob

# TODO parameter handling and usage output
# All parameters are optional
# First parameter = /search/path (default: the current working directory) NOTE this does not have to be the script path
# Second parameter = extension (default: *)
# Third parameter = /path/to/copyto (default: "sandbox/move_ext_test") NOTE this is relative to the current working directory not the script path

sSEARCH_PATH=${1:-"."}
sFILE_EXT=${2:-"*"}
sMOVE_TO_PATH=${3:-"sandbox/move_ext_test"}
sFILE=
iFILE_COUNTER=0
iCOUNTER=0

# TODO remove after testing is "done"
#rm -r "$sMOVE_TO_PATH"
# NOTE the debug-output.csv file will show up in the results if it is in the sSEARCH_PATH
printf "%s\n" "Copy,DupTest,Mkdir,sFILENAME,sBASENAME_NO_EXT,sBASENAME,sEXT,sLOWERCASE_EXT,sMOVE_TO_PATH,sFILE" > debug-output.csv # TODO remove debug stuff

# If sMOVE_TO_PATH is dot ".", dot forward-slash "./", or NULL "", set it to $PWD
# NOTE if sMOVE_TO_PATH is NULL here, then "./" was specified
[[ $sMOVE_TO_PATH =~ ^\.$|^\./+$|^$ ]] && sMOVE_TO_PATH=${PWD:-$(pwd)}

echo "Checking $sSEARCH_PATH for files that match the pattern *.$sFILE_EXT"
printf "%s\033[s" "Processing files..."
while IFS= read -r sFILENAME; do

    printf "\033[u%s" "${iCOUNTER}"
    iCOUNTER=$((iCOUNTER+1))

    # Replace all instances of dot forward-slash "./" with NULL
    sFILENAME=${sFILENAME//.\/}

    # Replace all instances of double forward-slash "//" with single forward-slash "/"
    sFILENAME=${sFILENAME//\/\//\/}

    # Filter through the results
    # If we have read access to the file (TODO change to -w for move) and
    if [[ -r $sFILENAME ]]; then

        # Get the basename of the file not including the extension
        sBASENAME_NO_EXT=${sFILENAME%.*}
        sBASENAME_NO_EXT=${sBASENAME_NO_EXT##*/}

        # Get the basename of the file including the extension
        sBASENAME=${sFILENAME##*/}

        # Get the path, and create a suffix from it
        # eg. /path/to/some/file/file.txt becomes path-to-some-file
        #sPATH_SUFFIX=${sFILENAME%/*}
        #sPATH_SUFFIX=${sPATH_SUFFIX//\//-}
        #sPATH_SUFFIX=${sPATH_SUFFIX/#-}
        #sPATH_SUFFIX=${sPATH_SUFFIX/%/_}

        # Get the file extension
        sEXT=${sFILENAME##*.}

        # Get the extension in all lower-case characters
        sLOWERCASE_EXT=${sEXT,,}

        # Create the path to move the file to using the extension,
        # converting the extension to all lower-case to avoid creating
        # extraneous folders
        # NOTE if we have write access the folder already exists and we can write to it
        #      so there's no need to run mkdir
        # NOTE checking for write access will also fail if the path doesn't exist
        [[ -w "$sMOVE_TO_PATH/$sLOWERCASE_EXT" ]] || {
            mkdir -p "$sMOVE_TO_PATH/$sLOWERCASE_EXT" || {
                printf "%s\n" "True,False,False,$sFILENAME,$sBASENAME_NO_EXT,$sBASENAME,$sEXT,$sLOWERCASE_EXT,$sMOVE_TO_PATH,$sFILE" >> debug-output.csv # TODO remove debug stuff
                continue
            }
        }

        # Check for a possible file name conflict
        # No existing file with the same name was found
        if [[ ! -f "${sMOVE_TO_PATH}/${sLOWERCASE_EXT}/${sBASENAME}" ]]; then

            # Copy the file to its respective path
            # If the copy is successful iterate the file counter
            # TODO change cp to mv when testing is "done"
            if cp "$sFILENAME" "${sMOVE_TO_PATH}/${sLOWERCASE_EXT}"; then
                iFILE_COUNTER=$((iFILE_COUNTER+1))
                printf "%s\n" "True,False,True,$sFILENAME,$sBASENAME_NO_EXT,$sBASENAME,$sEXT,$sLOWERCASE_EXT,$sMOVE_TO_PATH,$sFILE" >> debug-output.csv # TODO remove debug stuff
            else
                printf "%s\n" "False,False,True,$sFILENAME,$sBASENAME_NO_EXT,$sBASENAME,$sEXT,$sLOWERCASE_EXT,$sMOVE_TO_PATH,$sFILE" >> debug-output.csv # TODO remove debug stuff
            fi
        else
            # An existing file with the same was found in the sMOVE_TO_PATH/sLOWERCASE_EXT
            #####echo "Duplicate file name detected: $sFILENAME"

            # If they are hardlinks they are already the same, no need to compare
            [[  $sFILENAME -ef "${sMOVE_TO_PATH}/${sLOWERCASE_EXT}/${sBASENAME}" ]] && {
                #####echo "Hardlink detected, skipping copy"
                continue
            }

            # Attempt to narrow down the files to compare against
            # NOTE not all files are checked against. Files with duplicate
            # contents but sufficiently different names will still be copied.
            # NOTE If sBASENAME_NO_EXT=NULL then the file name begins with a dot "."
            # TODO might want to check all files
            if [[ -n $sBASENAME_NO_EXT ]]; then
                for sFILE in "${sMOVE_TO_PATH}/${sLOWERCASE_EXT}/${sBASENAME_NO_EXT}"*; do
                    if cmp -s "$sFILENAME" "$sFILE"; then
                        #####echo "Exact copy found at: $sFILE, skipping copy"
                        continue 2
                    fi
                done
            elif [[ -z $sBASENAME_NO_EXT ]]; then
                for sFILE in "${sMOVE_TO_PATH}/${sLOWERCASE_EXT}/${sBASENAME}"*; do
                    if cmp -s "$sFILENAME" "$sFILE"; then
                        #####echo "Exact copy found at: $sFILE, skipping copy"
                        continue 2
                    fi
                done
            fi

            #####echo "Duplicate file is unique, copying but renaming with unique identifier"
            # Name the file based on whether it is a dotfile or not
            # NOTE if sFILENAME is a dotfile, then sEXT contains it's name
            if [[ -n $sBASENAME_NO_EXT ]]; then
                if cp "$sFILENAME" "${sMOVE_TO_PATH}/${sLOWERCASE_EXT}/${sBASENAME_NO_EXT}_${RANDOM}${RANDOM}.${sEXT}"; then
                    iFILE_COUNTER=$((iFILE_COUNTER+1))
                    printf "%s\n" "True,True,True,$sFILENAME,$sBASENAME_NO_EXT,$sBASENAME,$sEXT,$sLOWERCASE_EXT,$sMOVE_TO_PATH,$sFILE" >> debug-output.csv # TODO remove debug stuff
                else
                    printf "%s\n" "False,True,True,$sFILENAME,$sBASENAME_NO_EXT,$sBASENAME,$sEXT,$sLOWERCASE_EXT,$sMOVE_TO_PATH,$sFILE" >> debug-output.csv # TODO remove debug stuff
                fi
            elif [[ -z $sBASENAME_NO_EXT ]]; then
                if cp "$sFILENAME" "${sMOVE_TO_PATH}/${sLOWERCASE_EXT}/.${sEXT}_${RANDOM}${RANDOM}"; then
                    iFILE_COUNTER=$((iFILE_COUNTER+1))
                    printf "%s\n" "True,True,True,$sFILENAME,$sBASENAME_NO_EXT,$sBASENAME,$sEXT,$sLOWERCASE_EXT,$sMOVE_TO_PATH,$sFILE" >> debug-output.csv # TODO remove debug stuff
                else
                    printf "%s\n" "False,True,True,$sFILENAME,$sBASENAME_NO_EXT,$sBASENAME,$sEXT,$sLOWERCASE_EXT,$sMOVE_TO_PATH,$sFILE" >> debug-output.csv # TODO remove debug stuff
                fi
            fi
        fi
    else
        echo "No read access to: $sFILENAME"
    fi
done < <(find "${sSEARCH_PATH}/" -type f -not -path "*$sMOVE_TO_PATH*" -not -name "${0/#.\/}" -iname "*.${sFILE_EXT}" 2>/dev/null)

# Report what happened
if [[ $iFILE_COUNTER -eq 0 && $iCOUNTER -gt 1 ]]; then
    printf "\r\033[0K%s\n" "$iCOUNTER files checked. No new, unique files found."
elif [[ $iFILE_COUNTER -ge 1 && $iCOUNTER -gt 1 ]]; then
    if [[ $iFILE_COUNTER -eq 1 ]]; then
        printf "\r\033[0K%s\n" "$iCOUNTER files checked. $iFILE_COUNTER is new and unique."
        echo "It was copied to $PWD/$sMOVE_TO_PATH"
    elif [[ $iFILE_COUNTER -gt 1 ]]; then
        printf "\r\033[0K%s\n" "$iCOUNTER files checked. $iFILE_COUNTER are new and unique."
        echo "They were copied to $PWD/$sMOVE_TO_PATH"
    fi
elif [[ $iCOUNTER -eq 0 ]]; then
    printf "\r\033[0K%s\n" "No files found in $sSEARCH_PATH"
else
    printf "\n%s\n" "An unknown error occured: \"$iCOUNTER\" \"$iFILE_COUNTER\""
fi
