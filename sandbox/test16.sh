#!/bin/bash
exit
alias pkgmaint='[[ $- == *i* ]] && { sudo apt update; sudo apt full-upgrade; sudo apt autoremove; sudo apt clean; }'

alias pkgmaint='[[ $- == *i* ]] && sudo apt {update && ,full-upgrade && ,autoremove && ,clean}'
