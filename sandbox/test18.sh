#!/bin/bash
while :; do
    $(true $RANDOM $(false $RANDOM)) <<<$(false $RANDOM $(true $RANDOM)) | $(false $RANDOM $(true $RANDOM)) <<<$(true $RANDOM $(false $RANDOM)) &
    jobs -pr | wc -l
done
