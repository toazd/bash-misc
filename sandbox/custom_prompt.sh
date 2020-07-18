#!/bin/bash
#https://github.com/niksingh710/Bash_Prompt/blob/master/custom_prompt.sh
#shellcheck disable=SC2034
cNORMAL="\e[0m"
cCYAN="\e[36m"
cLCYAN="\e[96m"
cRED="\e[31m"
cLRED="\e[31m"
cBLUE="\e[34m"
cLBLUE="\e[94m"
cLYELLOW="\e[93m"
cLGRAY="\e[37m"
cGRAY="\e[90m"

sGREETING="$cLYELLOW$USER $cLGRAY $cLCYAN Today is: $cGRAY$(date +"%A %d %B")$cNORMAL\n"
alias clear='clear && echo -e $sGREETING'
echo -e "$sGREETING"

getStatus() {
    if [[ $? -eq 0 ]]; then
        echo -e "🚀\e[36m"
    else
        echo -e "💥\e[31m"
    fi
}

getIcon() {
    if [[ $1 = "$HOME" ]]; then
        echo ""
    elif [[ $1 = "/" ]]; then
        echo ""
    else
        echo ""
    fi
}

getGit() {
    if [[ -d $1/.git ]]; then
        if [[ -n $(git branch --show-current) ]]; then
            echo "  $(git branch --show-current)";
        fi
    fi
}

export PS1="\$(getStatus) \$(getIcon "\$PWD")\[$cNORMAL\] \[$cBLUE\]\W\[$cLYELLOW\]  \$(getGit "\$PWD")\[$cNORMAL\]\n\[$cLCYAN\]\$\[$cNORMAL\] "
