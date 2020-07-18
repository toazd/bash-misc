#!/bin/bash

NORMAL="\e[0m"
CYAN="\e[36m"
LCYAN="\e[96m"
RED="\e[31m"
LRED="\e[31m"
BLUE="\e[34m"
LBLUE="\e[94m"
LYELLOW="\e[93m"
LGRAY="\e[37m"
GRAY="\e[90m"


alias clear='clear && echo -e "$LYELLOW$USER $LGRAY $LCYAN Today is: $GRAY$(date +"%A %d %B") \n"'
echo -e "$LYELLOW$USER $LGRAY $LCYAN Today is: $GRAY$(date +"%A %d %B")\n "


function getStatus(){
	echo "\`
			if [[ \$? = 0 ]]; then
				 echo 🚀\[$LCYAN\];
			else echo 💥\[$LRED\];
			fi
	\`"
}

function getIcon(){
	echo "\`
			if [[ \$(pwd) = "$HOME" ]]; then
				 echo ;
			elif [[ \$(pwd) = "//" ]]; then
				 echo ;
			else echo ;
			fi
	\`"
}

function getGit(){
	echo "\`
			if ! [ -z \$(__git_ps1) ]; then
				 echo   \$(__git_ps1);
			fi
	\`"
}

leftPrompt="$(getStatus) $(getIcon)\[$NORMAL\] \[$BLUE\]\W\[$LYELLOW\]  $(getGit)\n\[$LCYAN\]$ \[$NORMAL\]"



export PS1=$leftPrompt
