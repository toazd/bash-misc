#!/usr/bin/env bash
#
# 2020 Toazd sensors.sh UNLICENSE
#
# Purpose:
#   Parse sensors normal "friendly" output looking for specific sensor names
#   (eg. Vcore) and output to stdout a single line (for i3-blocks, etc.)
#
################################################################################
# Shell options

shopt -s extglob
shopt -s huponexit
shopt -s checkwinsize
set -eEuhC -o pipefail

################################################################################
# CalcCpuUsage
# Parse mpstat output (the last line - avg idle%) and convert it to usage%
# caution: if more than one report is taken, only the avg of all of them
# will be shown.

CalcCpuUsage () {

    local -a iaMPSTAT=()
    local -i iINTERVAL=1
    local -i iREPORTS=1
    local sAVG_LINE=''

    # map the output of mpstat into an indexed array
    IFS=$'\n' mapfile -s 2 -t <<< "$(mpstat $iINTERVAL $iREPORTS --dec=2)" iaMPSTAT

    # we only want the last line which is the same no matter how many reports are chosen (index total - 1)
    sAVG_LINE="${iaMPSTAT[${#iaMPSTAT[@]}-1]}"

    # remove all spaces including any text to the left of them
    sAVG_LINE="${sAVG_LINE##* }"

    # round to 0 decimals (to avoid showing extraneous zeros *.0%), left bound the field (aligns better with icons/glyphs)
    sCPU_USAGE="$(printf '%-.0f' "$(bc -l <<< 100-"${sAVG_LINE}")")%"

    if [[ ${sCPU_USAGE:0:1} -eq 0 ]]; then
        sCPU_USAGE="<1%"
    fi

    return 0
}

declare -a iaSENSORS=()
declare -A aaCPU_DATA=()
declare -A aaGPU_DATA=()
declare -i iLINE=0
declare sONE_LINE=''
declare sLINE=''
declare sSENSOR=''
declare sCPU_USAGE=''

if ! CalcCpuUsage; then
    sCPU_USAGE="err"
fi

IFS=$'\n' mapfile -t <<< "$(sensors -A)" iaSENSORS

for iLINE in "${!iaSENSORS[@]}"; do
    iaSENSORS[$iLINE]="${iaSENSORS[$iLINE]//[[:blank:]]}"
done

for sLINE in "${iaSENSORS[@]}"; do
    if [[ -n $sLINE ]]; then
        if [[ ${sLINE%:*} = @(Vcore|Vsoc|Tdie|Tctl|Tccd1|Icore|Isoc) ]]; then # CPU
            aaCPU_DATA+=(["${sLINE%:*}"]="${sLINE#*:}")
        fi
        if [[ ${sLINE%:*} = @(vddgfx|fan1|edge|junction|mem|power1) ]]; then # GPU
            aaGPU_DATA+=(["${sLINE%:*}"]="${sLINE#*:}")
        fi
    else
        :
    fi
done

for sSENSOR in "${!aaCPU_DATA[@]}"; do
    aaCPU_DATA[$sSENSOR]="${aaCPU_DATA[$sSENSOR]/+}"
    aaCPU_DATA[$sSENSOR]="${aaCPU_DATA[$sSENSOR]/.00}"
    aaCPU_DATA[$sSENSOR]="${aaCPU_DATA[$sSENSOR]/.0°C/°C}"
done

for sSENSOR in "${!aaGPU_DATA[@]}"; do
    aaGPU_DATA[$sSENSOR]="${aaGPU_DATA[$sSENSOR]%(*}"
    aaGPU_DATA[$sSENSOR]="${aaGPU_DATA[$sSENSOR]/+}"
    aaGPU_DATA[$sSENSOR]="${aaGPU_DATA[$sSENSOR]/.00}"
    aaGPU_DATA[$sSENSOR]="${aaGPU_DATA[$sSENSOR]/.0°C/°C}"
done

sONE_LINE="CPU   ${sCPU_USAGE}  ${aaCPU_DATA[Tdie]}  ${aaCPU_DATA[Vcore]} GPU  ${aaGPU_DATA[junction]}  ${aaGPU_DATA[power1]}   ${aaGPU_DATA[fan1]}"

echo "$sONE_LINE"

unset iaSENSORS aaCPU_DATA aaGPU_DATA sONE_LINE iLINE sLINE sSENSOR sCPU_USAGE iINTERVAL iREPORTS

exit 0
