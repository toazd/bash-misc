#!/bin/bash

trap 'trap_ctrlc' INT

trap_ctrlc() {
    printf "\n%s\n"  "So long, and thanks for all the fish"
    kill 0
}

while :; do
    :
done
