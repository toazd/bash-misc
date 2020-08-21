#!/usr/bin/env bash
#
# Compare two "equal" directory trees and compare the files using md5, sha1sum , sha256sum, or sha512sum
# reporting if any are not exactly the same. If a log is desired pipe the output through tee or directly to a file
#

# Shell options
shopt -s extglob
set -eEu

# Initialize global variables
sSEARCH_PATH_A=${1-""}
sSEARCH_PATH_B=${2-""}
sALGO=${3:-"md5"}
sFILE_EXT=${4:-"**"}
sFILE_CHECKSUM_A=""
sFILE_CHECKSUM_B=""
iaFILES_A=()
iaFILES_B=()
iCOUNTER=0

# Basic usage
ShowUsage() {
    printf "\nUsage:\n\t%s\n\t%s\n\n" "$0 [path_A] [path_B] [algorithm] [file_extension]" "Use \"**\" for the extension parameter to find all files"
    exit
}

# Basic parameter checks
[[ $sSEARCH_PATH_A = @(""|"-h"|"-H"|"-help"|"--help") ]] && ShowUsage
[[ $sALGO = @("md5"|"sha1"|"sha256"|"sha512") ]] || ShowUsage

# If the number of parameters is below the number of required parameters
# or the number of parameters is above the maximum parameters accepted
# NOTE 2 parameters are required, the 3rd is optional
[[ $# -lt 2 || $# -gt 3 ]] && ShowUsage

# Get the full, real path of the paths supplied as parameters
sSEARCH_PATH_A=$(realpath -q "$sSEARCH_PATH_A")
sSEARCH_PATH_B=$(realpath -q "$sSEARCH_PATH_B")

# Check that both search paths are actually paths (eg. not files)
[[ -d $sSEARCH_PATH_A && -d $sSEARCH_PATH_B ]] || ShowUsage

# Check for read permission to both search paths
[[ -r $sSEARCH_PATH_A && -r $sSEARCH_PATH_B ]] || { echo "This script requires read access to both paths"; exit; }

# Generate a new header for a new run
echo -e "$(date +%c)\nComparing (${sFILE_EXT}/${sALGO^^}):\n${sSEARCH_PATH_A} <==> ${sSEARCH_PATH_B}\n"

if [[ $sFILE_EXT = "**" ]]; then
    mapfile -t <<< "$(find "$sSEARCH_PATH_A" -type f -iwholename "*" | LC_ALL=C sort -uf)" iaFILES_A
    mapfile -t <<< "$(find "$sSEARCH_PATH_B" -type f -iwholename "*" | LC_ALL=C sort -uf)" iaFILES_B
else
    mapfile -t <<< "$(find "$sSEARCH_PATH_A" -type f -iwholename "*.${sFILE_EXT}" | LC_ALL=C sort -uf)" iaFILES_A
    mapfile -t <<< "$(find "$sSEARCH_PATH_B" -type f -iwholename "*.${sFILE_EXT}" | LC_ALL=C sort -uf)" iaFILES_B
fi

#
[[ ${#iaFILES_A[@]} = "${#iaFILES_B[@]}" ]] || { echo "Paths do not have an equal number of files (${#iaFILES_A[@]} vs ${#iaFILES_B[@]})"; exit 1; }

#
[[ "${#iaFILES_A[@]}" -eq 1 ]] && { echo "No files found"; exit 0; }

#
for (( iCOUNTER=0; iCOUNTER<${#iaFILES_A[@]}; iCOUNTER++ )); do
    #
    case ${sALGO,,} in
        ("md5")
            sFILE_CHECKSUM_A=$(md5sum "${iaFILES_A[$iCOUNTER]}")
            sFILE_CHECKSUM_A=${sFILE_CHECKSUM_A%%[[:blank:]]*}

            sFILE_CHECKSUM_B=$(md5sum "${iaFILES_B[$iCOUNTER]}")
            sFILE_CHECKSUM_B=${sFILE_CHECKSUM_B%%[[:blank:]]*}
            #echo "$sFILE_CHECKSUM_A <==> $sFILE_CHECKSUM_B"
            [[ $sFILE_CHECKSUM_A = "$sFILE_CHECKSUM_B" ]] || echo "${iaFILES_A[$iCOUNTER]} != ${iaFILES_B[$iCOUNTER]}"
        ;;
        ("sha1")
            sFILE_CHECKSUM_A=$(sha1sum "${iaFILES_A[$iCOUNTER]}")
            sFILE_CHECKSUM_A=${sFILE_CHECKSUM_A%%[[:blank:]]*}

            sFILE_CHECKSUM_B=$(sha1sum "${iaFILES_B[$iCOUNTER]}")
            sFILE_CHECKSUM_B=${sFILE_CHECKSUM_B%%[[:blank:]]*}
            #echo "$sFILE_CHECKSUM_A <==> $sFILE_CHECKSUM_B"
            [[ $sFILE_CHECKSUM_A = "$sFILE_CHECKSUM_B" ]] || echo "${iaFILES_A[$iCOUNTER]} != ${iaFILES_B[$iCOUNTER]}"
        ;;
        ("sha256")
            sFILE_CHECKSUM_A=$(sha256sum "${iaFILES_A[$iCOUNTER]}")
            sFILE_CHECKSUM_A=${sFILE_CHECKSUM_A%%[[:blank:]]*}

            sFILE_CHECKSUM_B=$(sha256sum "${iaFILES_B[$iCOUNTER]}")
            sFILE_CHECKSUM_B=${sFILE_CHECKSUM_B%%[[:blank:]]*}
            #echo "$sFILE_CHECKSUM_A <==> $sFILE_CHECKSUM_B"
            [[ $sFILE_CHECKSUM_A = "$sFILE_CHECKSUM_B" ]] || echo "${iaFILES_A[$iCOUNTER]} != ${iaFILES_B[$iCOUNTER]}"
        ;;
        ("sha512")
            sFILE_CHECKSUM_A=$(sha512sum "${iaFILES_A[$iCOUNTER]}")
            sFILE_CHECKSUM_A=${sFILE_CHECKSUM_A%%[[:blank:]]*}

            sFILE_CHECKSUM_B=$(sha512sum "${iaFILES_B[$iCOUNTER]}")
            sFILE_CHECKSUM_B=${sFILE_CHECKSUM_B%%[[:blank:]]*}
            #echo "$sFILE_CHECKSUM_A <==> $sFILE_CHECKSUM_B"
            [[ $sFILE_CHECKSUM_A = "$sFILE_CHECKSUM_B" ]] || echo "${iaFILES_A[$iCOUNTER]} != ${iaFILES_B[$iCOUNTER]}"
        ;;
    esac
done
