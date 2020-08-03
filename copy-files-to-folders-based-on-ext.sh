#!/bin/bash
#
# NOTE cp is used instead of mv while testing
# NOTE the path files are copied/moved to and files in it are ignored during searching (in case the sMOVE_TO_PATH is within sSEARCH_PATH)
# NOTE the script that is run is ignored during file searching TODO more testing to ensure the check works in all cases
# NOTE duplicate file checks are based first on case-sensitive file names, followed by checksums IF the names match
#      this means that if you have files with the same contents, but with different names they will be copied
#
# BUG  When using * as a search pattern (the default) files named like "APACHE-LICENSE-2.0" and "spotify-1.1.10.546-Release"
#      will be put into a folder named based on the characters following the right-most dot "." found in the name
#      eg. "0" and ".546-Release"
#

shopt -s globstar nullglob

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

# TODO remove after testing is "done"
#rm -r "$sMOVE_TO_PATH"

# check for write access to the move/copy path
# NOTE if sMOVE_TO_PATH is NULL here, then "./" was specified
if [[ $sMOVE_TO_PATH = "" ]]; then
    sMOVE_TO_PATH=$PWD
    [[ ! -w $sMOVE_TO_PATH ]] && { echo "No write access to ${sMOVE_TO_PATH%%/*}"; exit 1; }
else
    [[ ! -w ${sMOVE_TO_PATH%%/*} ]] && { echo "No write access to ${sMOVE_TO_PATH%%/*}"; exit 1; }
fi

# TODO find out exactly why * does not match dotfiles by itself
for sFILENAME in "$sSEARCH_PATH"/**/{*,.*}; do

    # If no files are found, having nullglob turned on causes the pattern to expand to NULL instead of itself
    [[ -z $sFILENAME ]] && continue

    # Replace all instances of dot forward slash "./" with NULL
    sFILENAME=${sFILENAME//.\/}

    # Filter through the results
    # If sFILENAME is not a folder (eg. "." & "..") and
    # If we have read access to the file and TODO change to -w for move
    # the file path and name (in all lower-case) matches the pattern *.extension (all lower-case) and
    # If the move path is not part of the file name (exclude move path and all files in it) and
    # If the filename is not equal to the script name (with dot forward-slash "./" removed)
    if [[ ! -d $sFILENAME && \
          -r $sFILENAME && \
          ${sFILENAME,,} == *.${sFILE_EXT,,} && \
          ! $sFILENAME == *$sMOVE_TO_PATH* && \
          ! $sFILENAME == *${0//.\/} \
          ]]; then

        # Get the basename of the file not including the extension
        sBASENAME_NO_EXT=${sFILENAME%.*}
        sBASENAME_NO_EXT=${sBASENAME_NO_EXT##*/}

        # Get the basename of the file including the extension
        sBASENAME=${sFILENAME##*/}

        # Get the file extension
        sEXT=${sFILENAME##*.}

        # Get the extension in all lower-case characters
        sLOWERCASE_EXT=${sEXT,,}

        # Create the path to move the file to using the extension,
        # converting the extension to all lower-case to avoid creating
        # extraneous folders
        # NOTE This means that files with extensions that are the same characters
        # but differ in case will be put inside the same folder irregardless of extension case
        # eg. "file.txt", "file.TxT", "file.TXt", "file.TXT", and "file.tXT" will all be put
        # into the same folder named "txt"
        # If you don't want that behavior, change sLOWERCASE_EXT to sEXT where appropriate below
        mkdir -p "$sMOVE_TO_PATH/$sLOWERCASE_EXT"

        # Check for a possible file name conflict
        if [[ ! -f "${sMOVE_TO_PATH}/${sLOWERCASE_EXT}/${sBASENAME}" ]]; then

            # If the path exists and we can write to it, copy the file to its respective path
            # If the copy is successful iterate the file counter
            # TODO change cp to mv when testing is "done"
            [[ -d "${sMOVE_TO_PATH}/${sLOWERCASE_EXT}" && -w "${sMOVE_TO_PATH}/${sLOWERCASE_EXT}" ]] && \
                cp "$sFILENAME" "${sMOVE_TO_PATH}/${sLOWERCASE_EXT}" && iFILE_COUNTER=$((iFILE_COUNTER+1))
        else

            # The name of a file in the same move path we want to copy/move to matches the current file
            echo "Duplicate file name detected: $sFILENAME"

            # If they are hardlinks they are already the same, no need to compare checksums
            [[  $sFILENAME -ef "${sMOVE_TO_PATH}/${sLOWERCASE_EXT}/${sBASENAME}" ]] && {
                echo "Hardlink detected, skipping copy"
                continue
            }

            # Compare checksums and see if there is an exact copy (content but not name wise) already
            # NOTE to narrow down the number of files to compare against, not all files are checked
            # TODO determine an appropriate scope for the comparison
            # TODO different checksum algorithm?
            sDUPLICATE=$(sha512sum "$sFILENAME")
            for sFILE in "${sMOVE_TO_PATH}/${sLOWERCASE_EXT}/${sBASENAME_NO_EXT}"*; do
                sEXISTING=$(sha512sum "$sFILE")
                if [[ ${sDUPLICATE%% *} = "${sEXISTING%% *}" ]]; then
                    echo "Exact copy found at: $sFILE, skipping copy"
                    continue 2
                fi
            done
            echo "Duplicate file is unique, copying but renaming with unique identifier"
            cp "$sFILENAME" "${sMOVE_TO_PATH}/${sLOWERCASE_EXT}/${sBASENAME_NO_EXT}_${RANDOM}${RANDOM}${RANDOM}.${sEXT}" && iFILE_COUNTER=$((iFILE_COUNTER+1))
        fi
    fi
done

# TODO change "copied" to "moved"
echo "$iFILE_COUNTER files copied"
