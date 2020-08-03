#!/bin/bash
#
# NOTE cp is used instead of mv while testing
# NOTE the path files are copied/moved to and files in it are ignored during searching (in case the sMOVE_TO_PATH is within sSEARCH_PATH)
# NOTE the script that is run is ignored during file searching BUG all copies anywhere are skipped
# NOTE duplicate file checks are based first on case-sensitive file names, followed by checksums IF the names match
#      this means that if you have files with the same contents, but with different names they will be copied
#
# BUG  When using * as a search pattern (the default) files named like "APACHE-LICENSE-2.0" and "spotify-1.1.10.546-Release"
#      will be put into a folder named based on the characters following the right-most dot "." found in the name
#      eg. "0" and ".546-Release"
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
sMOVE_TO_PATH=${sMOVE_TO_PATH//.\/}
iFILE_COUNTER=0
iCOUNTER=0

# TODO remove after testing is "done"
#rm -r "$sMOVE_TO_PATH"
# NOTE the debug.output.csv file will show up in the results if it is in the sSEARCH_PATH
printf "%s\n" "DupTestResult,sFILENAME,sBASENAME_NO_EXT,sBASENAME,sEXT,sLOWERCASE_EXT,sMOVE_TO_PATH,sFILE" > debug.output.csv # TODO remove debug stuff

# check for write access to the move/copy path
# NOTE if sMOVE_TO_PATH is NULL here, then "./" was specified
if [[ $sMOVE_TO_PATH = "" ]]; then
    sMOVE_TO_PATH=$PWD
    [[ ! -w $sMOVE_TO_PATH ]] && { echo "No write access to ${sMOVE_TO_PATH%%/*}"; exit 1; }
else
    [[ ! -w ${sMOVE_TO_PATH%%/*} ]] && { echo "No write access to ${sMOVE_TO_PATH%%/*}"; exit 1; }
fi

echo "Checking $sSEARCH_PATH for files that match the pattern *.$sFILE_EXT"
printf "%s\033[s" "Processing files..."
while IFS= read -r sFILENAME; do

    printf "\033[u%s" "${iCOUNTER}"
    iCOUNTER=$((iCOUNTER+1))

    # Replace all instances of dot forward slash "./" with NULL
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
        mkdir -p "$sMOVE_TO_PATH/$sLOWERCASE_EXT"

        # Check for a possible file name conflict
        # No existing file with the same name was found
        if [[ ! -f "${sMOVE_TO_PATH}/${sLOWERCASE_EXT}/${sBASENAME}" ]]; then

            # Copy the file to its respective path
            # If the copy is successful iterate the file counter
            # TODO change cp to mv when testing is "done"
            cp "$sFILENAME" "${sMOVE_TO_PATH}/${sLOWERCASE_EXT}" && iFILE_COUNTER=$((iFILE_COUNTER+1))
            printf "%s\n" "False,$sFILENAME,$sBASENAME_NO_EXT,$sBASENAME,$sEXT,$sLOWERCASE_EXT,$sMOVE_TO_PATH" >> debug.output.csv # TODO remove debug stuff
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
                cp "$sFILENAME" "${sMOVE_TO_PATH}/${sLOWERCASE_EXT}/${sBASENAME_NO_EXT}_${RANDOM}${RANDOM}.${sEXT}" && iFILE_COUNTER=$((iFILE_COUNTER+1))
            elif [[ -z $sBASENAME_NO_EXT ]]; then
                cp "$sFILENAME" "${sMOVE_TO_PATH}/${sLOWERCASE_EXT}/.${sEXT}_${RANDOM}${RANDOM}" && iFILE_COUNTER=$((iFILE_COUNTER+1))
            fi
            printf "%s\n" "True,$sFILENAME,$sBASENAME_NO_EXT,$sBASENAME,$sEXT,$sLOWERCASE_EXT,$sMOVE_TO_PATH,$sFILE" >> debug.output.csv # TODO remove debug stuff
        fi
    else
        echo "No read access to: $sFILENAME"
    fi
done < <(find "${sSEARCH_PATH}/" -type f -not -path "*$sMOVE_TO_PATH*" -not -name "*${0//.\/}*" -iname "*.${sFILE_EXT}" 2>/dev/null)

# Report what happened
if [[ $iFILE_COUNTER -eq 0 && $iCOUNTER -gt 1 ]]; then
    printf "\r\033[0K%s\n" "$iCOUNTER files checked. No new or unique files found."
elif [[ $iFILE_COUNTER -gt 0 && $iCOUNTER -gt 1 ]]; then
    printf "\r\033[0K%s\n" "${iFILE_COUNTER}/$iCOUNTER files checked were new and unique."
    if [[ $iFILE_COUNTER -eq 1 ]]; then
        echo "It was copied to $PWD/$sMOVE_TO_PATH"
    elif [[ $iFILE_COUNTER -gt 1 ]]; then
        echo "They were copied to $PWD/$sMOVE_TO_PATH"
    fi
elif [[ $iCOUNTER -eq 0 ]]; then
    printf "\r\033[0K%s\n" "No files found in $sSEARCH_PATH"
else
    printf "\r\033[0K%s\n" "An unknown error occured"
fi
