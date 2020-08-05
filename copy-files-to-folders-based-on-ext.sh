#!/usr/bin/env bash
#
# BUG  When using asterisk "*" as a search pattern (the default if none is specified) files named like
#       "APACHE-LICENSE-2.0" and "spotify-1.1.10.546-Release" will be put into a folder named based on
#       all of the characters following the right-most dot "." found in their respective names.
#        eg. "APACHE-LICENSE-2.0" will be put into the folder "0" and "spotify-1.1.10.546-Release" will be put into the folder ".546-Release"
#
# BUG  If sTARGET_PATH exists in multiple locations, all of them will be excluded from searches
#       eg. If "sTARGET_PATH=output_path", then both "/home/toazd/output_path" and "/usr/share/output_path" will be ignored
#

#
# NOTE /proc/* and /dev/* are explicitly ignored
#

shopt -s nullglob dotglob

ShowUsage() {
    printf 'Usage:\n%s\n%s\n' \
           "${0##*/} [/search/path] [/target/path] *.[pattern]" \
           "[/search/path] and [/target/path] are required, [pattern] defaults to \"*\""
    exit 0
}

sSOURCE_PATH=
sTARGET_PATH=
sSEARCH_PATTERN=${3-'*'}
sSCRIPT_SOURCE_NAME=
sEXISTING_FILE=
iFILE_COUNTER=0
iCOUNTER=0

# If there is at least two parameters but
# no more than three parameters
[[ $# -ge 2 && $# -le 3 ]] || ShowUsage

# Read parameters into their respective variables
# Attempt to support all characters that find supports
# NOTE $# wil be 0 and $@ will be null after this
if [[ $1 ]]; then
    [[ -z $sSOURCE_PATH ]] && sSOURCE_PATH=$1
    shift
    [[ -z $sTARGET_PATH ]] && sTARGET_PATH=$1
    shift
    [[ -n $1 ]] && sSEARCH_PATTERN=$1
    shift
fi

# Check if the search path specified is a valid path
# NOTE read permission is intentionally not checked here because the script supports providing paths
# such as the root "/" and subsequently processing only files that can be read with the current UID
[[ -d $sSOURCE_PATH ]] || { echo "Search path does not exist: \"$sSOURCE_PATH\""; ShowUsage; }

# If sTARGET_PATH is dot ".", dot (one or more) forward-slash(es) "./", or NULL "", set it to $PWD
# TODO checking for NULL is probably not needed anymore
[[ $sTARGET_PATH =~ ^\.$|^\./+$|^$ ]] && sTARGET_PATH=${PWD:-$(pwd)}

# Canonicalize the name of the running script, supporting both symlinks and relative symlinks
# NOTE The "! -samefile" find parameter below handles ignoring hardlinks (when using find -P) but to have
# find also ignore symlinks "find -L" is required which could potentially return results that we aren't
# interested in and don't want to waste resources checking for. It could also potentially cost more resources
# for find to resolve those results that we aren't interested in.
sSCRIPT_SOURCE_NAME=${BASH_SOURCE[0]}
while [[ -h $sSCRIPT_SOURCE_NAME ]]; do
    sPATH_NAME=$(cd -P "$(dirname "$sSCRIPT_SOURCE_NAME")" >/dev/null 2>&1 && pwd)
    sSCRIPT_SOURCE_NAME=$(readlink "$sSCRIPT_SOURCE_NAME")
    [[ $sSCRIPT_SOURCE_NAME =~ ^[^/] ]] && sSCRIPT_SOURCE_NAME=$sPATH_NAME/$sSCRIPT_SOURCE_NAME
done

# Sanity checks
[[ -f $sSCRIPT_SOURCE_NAME ]] || { echo "sSCRIPT_SOURCE_NAME failed file test at line $LINENO. It's value was: \"$sSCRIPT_SOURCE_NAME\""; exit 1; }

printf "%s\n" "Copy,DupTest,Mkdir,sFILE_NAME,sBASENAME_NO_EXT,sBASENAME,sEXT,sLOWERCASE_EXT,sTARGET_PATH,sEXISTING_FILE" > debug-output.csv # TODO remove debug stuff

echo "Checking the path \"$sSOURCE_PATH\" for files that match the pattern \"*.$sSEARCH_PATTERN\""
printf "%s\033[s" "Processing files..."
while IFS= read -r sFILE_NAME; do

    # Count each file returned from find
    iCOUNTER=$((iCOUNTER+1))

    # Output progress (which file returned from find is about to be processed)
    printf "\033[u%s" "${iCOUNTER}"

    # Anchored from the left, remove the first instance of dot forward-slash "./" if present
    sFILE_NAME=${sFILE_NAME/#.\/}

    # Get the basename of the file not including the extension
    sBASENAME_NO_EXT=${sFILE_NAME%.*}
    sBASENAME_NO_EXT=${sBASENAME_NO_EXT##*/}

    # Get the basename of the file including the extension
    sBASENAME=${sFILE_NAME##*/}

    # Get the file extension
    sEXT=${sFILE_NAME##*.}

    # Get the extension in all lower-case characters
    sLOWERCASE_EXT=${sEXT,,}

    # If sFILE_NAME is equal to the canonicalized name of the script that is running, exclude it
    [[ $sFILE_NAME = "$sSCRIPT_SOURCE_NAME" ]] && continue

    # Create the path to move the file to using the extension
    # after converting the extension to all lower-case
    #
    # NOTE if we have write access the folder already exists and we can write to it
    # NOTE checking for write access will fail if the path does not exist
    [[ -w "$sTARGET_PATH/$sLOWERCASE_EXT" ]] || {
        mkdir -p "$sTARGET_PATH/$sLOWERCASE_EXT" || {
            printf "%s\n" "True,False,False,$sFILE_NAME,$sBASENAME_NO_EXT,$sBASENAME,$sEXT,$sLOWERCASE_EXT,$sTARGET_PATH,$sEXISTING_FILE" >> debug-output.csv # TODO remove debug stuff
            printf "\n%s\n%s\n" "Failed to create path \"$sTARGET_PATH/$sLOWERCASE_EXT\"" "Ensure proper write permissions in \"$sTARGET_PATH\""
            exit 1
        }
    }

    # Check for a file that already exists with the same name, if not copy the new file
    # If an existing file of the same name is found check if the new file is unique
    # to determine whether to copy it using a different name or ignore it
    #
    # No existing file with the same name was found
    if [[ ! -f "$sTARGET_PATH/$sLOWERCASE_EXT/$sBASENAME" ]]; then

        # Copy the file to its respective path
        # If the copy is successful iterate the file counter
        if cp -n "$sFILE_NAME" "$sTARGET_PATH/$sLOWERCASE_EXT"; then
            iFILE_COUNTER=$((iFILE_COUNTER+1))
            printf "%s\n" "True,False,True,$sFILE_NAME,$sBASENAME_NO_EXT,$sBASENAME,$sEXT,$sLOWERCASE_EXT,$sTARGET_PATH,$sEXISTING_FILE" >> debug-output.csv # TODO remove debug stuff
        else
            printf "%s\n" "False,False,True,$sFILE_NAME,$sBASENAME_NO_EXT,$sBASENAME,$sEXT,$sLOWERCASE_EXT,$sTARGET_PATH,$sEXISTING_FILE" >> debug-output.csv # TODO remove debug stuff
        fi
    # An existing file with the same was found in the path sTARGET_PATH/sLOWERCASE_EXT
    else
        # If they are hardlinks they are already the same, no need to compare
        [[  $sFILE_NAME -ef "$sTARGET_PATH/$sLOWERCASE_EXT/$sBASENAME" ]] && continue

        # Attempt to narrow down the files to compare against
        #
        # NOTE not all files are checked against. Files with duplicate
        # contents but sufficiently different names will still be copied.
        # NOTE If sBASENAME_NO_EXT=NULL then the file name begins with a dot "."
        # TODO whether or not to check all files might make a good option parameter
        if [[ -n $sBASENAME_NO_EXT ]]; then
            for sEXISTING_FILE in "$sTARGET_PATH/$sLOWERCASE_EXT/$sBASENAME_NO_EXT"*; do
                cmp -s "$sFILE_NAME" "$sEXISTING_FILE" && continue 2
            done
        elif [[ -z $sBASENAME_NO_EXT ]]; then
            for sEXISTING_FILE in "$sTARGET_PATH/$sLOWERCASE_EXT/$sBASENAME"*; do
                cmp -s "$sFILE_NAME" "$sEXISTING_FILE" && continue 2
            done
        fi

        # The duplicate file is potentially unique
        # Rename the file based on whether it is a dotfile or not and copy it
        #
        # NOTE if sFILE_NAME is a dotfile, then sEXT contains all the characters after the leading dot
        # TODO better unique identifiers
        if [[ -n $sBASENAME_NO_EXT ]]; then
            if cp -n "$sFILE_NAME" "${sTARGET_PATH}/${sLOWERCASE_EXT}/${sBASENAME_NO_EXT}_${RANDOM}${RANDOM}.${sEXT}"; then
                iFILE_COUNTER=$((iFILE_COUNTER+1))
                printf "%s\n" "True,True,True,$sFILE_NAME,$sBASENAME_NO_EXT,$sBASENAME,$sEXT,$sLOWERCASE_EXT,$sTARGET_PATH,$sEXISTING_FILE" >> debug-output.csv # TODO remove debug stuff
            else
                printf "%s\n" "False,True,True,$sFILE_NAME,$sBASENAME_NO_EXT,$sBASENAME,$sEXT,$sLOWERCASE_EXT,$sTARGET_PATH,$sEXISTING_FILE" >> debug-output.csv # TODO remove debug stuff
            fi
        elif [[ -z $sBASENAME_NO_EXT ]]; then
            if cp -n "$sFILE_NAME" "${sTARGET_PATH}/${sLOWERCASE_EXT}/.${sEXT}_${RANDOM}${RANDOM}"; then
                iFILE_COUNTER=$((iFILE_COUNTER+1))
                printf "%s\n" "True,True,True,$sFILE_NAME,$sBASENAME_NO_EXT,$sBASENAME,$sEXT,$sLOWERCASE_EXT,$sTARGET_PATH,$sEXISTING_FILE" >> debug-output.csv # TODO remove debug stuff
            else
                printf "%s\n" "False,True,True,$sFILE_NAME,$sBASENAME_NO_EXT,$sBASENAME,$sEXT,$sLOWERCASE_EXT,$sTARGET_PATH,$sEXISTING_FILE" >> debug-output.csv # TODO remove debug stuff
            fi
        fi
    fi
done < <(find -P "$sSOURCE_PATH" -type f -readable ! -path "/proc/*" ! -path "/dev/*" ! -path "*$sTARGET_PATH*" ! -samefile "$sSCRIPT_SOURCE_NAME" -iname "*.$sSEARCH_PATTERN" 2>/dev/null)

# Report what happened
if [[ $iFILE_COUNTER -eq 0 && $iCOUNTER -gt 1 ]]; then
    printf "\r\033[0K%s\n" "$iCOUNTER files checked. No new, unique files found."
elif [[ $iFILE_COUNTER -ge 1 && $iCOUNTER -gt 1 ]]; then
    if [[ $iFILE_COUNTER -eq 1 ]]; then
        printf "\r\033[0K%s\n" "$iCOUNTER files checked. $iFILE_COUNTER was found to be unique."
        echo "It was copied to \"$PWD/$sTARGET_PATH\""
    elif [[ $iFILE_COUNTER -gt 1 ]]; then
        printf "\r\033[0K%s\n" "$iCOUNTER files checked. $iFILE_COUNTER were found to be unique."
        echo "They were copied to \"$PWD/$sTARGET_PATH\""
    fi
elif [[ $iCOUNTER -eq 0 ]]; then
    printf "\r\033[0K%s\n" "No files found in path \"$sSOURCE_PATH\". No changes were made."
else
    printf "\n%s\n" "An unknown error occured: \"$iCOUNTER\" \"$iFILE_COUNTER\""
fi
