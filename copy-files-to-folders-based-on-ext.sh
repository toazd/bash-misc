#!/bin/bash
#
# NOTE cp is used instead of mv while testing
# NOTE the path files are copied/moved to and files in it are ignored during searching (in case the sMOVE_TO_PATH is within sSEARCH_PATH)
# NOTE the script that is run is ignored during file searching TODO more testing to ensure the check works in all cases
# NOTE duplicate file checks are based first on case-sensitive file names, followed by checksums IF the names match
#      this means that if you have files with the same contents, but with different names
#      they will be copied
# BUG  When using * as a search pattern (the default) files named like "APACHE-LICENSE-2.0" and "spotify-1.1.10.546-Release"
#      will be put into a folder named based on the characters following the right-most dot "." found in the name
#      eg. "0" and ".546-Release"
#
# TODO parameter handling and usage output
#

shopt -s globstar nullglob

# All parameters are optional
# First parameter = /search/path (default: the current working directory) NOTE this does not have to be the script path
# Second parameter = extension (default: *) NOTE the pattern searched becomes *.extension
# Third parameter = /path/to/copyto (default: "sandbox/move_ext_test") NOTE this is relative to the current working directory not the script path

sSEARCH_PATH=${1:-"."}
sFILE_EXT=${2:-"*"}
sMOVE_TO_PATH=${3:-"sandbox/move_ext_test"}
iFILE_COUNTER=0

# TODO remove after testing is "done"
#rm -r "$sMOVE_TO_PATH"

# NOTE You could use *.$sFILE_EXT (NOT *."$sFILE_EXT") which would likely
# be faster, but then you run the risk that if any IFS characters appear
# in the given extension the script does not behave as expected
# alternatively, the faster method could be used if a sanity check is done on
# sFILE_EXT before using it for processing
for sFILENAME in "$sSEARCH_PATH"/**/*.*; do

    # Replace all instances of dot forward slash "./" with NULL
    # in both the filename found and the specified sMOVE_TO_PATH
    sFILENAME=${sFILENAME//.\/}
    sMOVE_TO_PATH=${sMOVE_TO_PATH//.\/}

    # If sFILENAME is not a folder and
    # If we have write access to the file (for move, only read is needed for copy) and
    # the file name (in all lower-case) matches the pattern *.extension (all lower-case) and
    # NOTE if *.* is changed to *.$sFILE_EXT, remove the extension pattern check here
    # If the move path is not part of the file name and
    # If the filename is not equal to the script name
    if [[ ! -d $sFILENAME && -w $sFILENAME && ${sFILENAME,,} == *.${sFILE_EXT,,} && ! $sFILENAME == *$sMOVE_TO_PATH* && ! $sFILENAME == *${0//.\/} ]]; then

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
        mkdir -p "$sMOVE_TO_PATH/$sLOWERCASE_EXT"

        # Check for a possible file name conflict
        if [[ ! -f "${sMOVE_TO_PATH}/${sLOWERCASE_EXT}/${sBASENAME}" ]]; then

            # If the path exists and we can write to it, copy the file to its respective path
            # If the copy is successful iterate the file counter
            # TODO change cp to mv when testing is "done"
            [[ -d "${sMOVE_TO_PATH}/${sLOWERCASE_EXT}" && -w "${sMOVE_TO_PATH}/${sLOWERCASE_EXT}" ]] && \
                cp "$sFILENAME" "${sMOVE_TO_PATH}/${sLOWERCASE_EXT}" && iFILE_COUNTER=$((iFILE_COUNTER+1))
        else
            echo "Duplicate file name detected: $sFILENAME"
            [[  $sFILENAME -ef "${sMOVE_TO_PATH}/${sLOWERCASE_EXT}/${sBASENAME}" ]] && {
                echo "Hardlink detected, skipping copy"
                continue
            }

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
