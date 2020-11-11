#!/usr/bin/env bash

# min ~38.62
delay=40

sleep $delay

PID=$(pgrep -n RDR2.exe 2>/dev/null)

[[ -z $PID ]] && { echo "pgrep error: \"$PID\""; exit 1; }

if kill -s SIGSTOP "$PID"; then
    if ! kill -s SIGCONT "$PID"; then
        echo "Failed to send SIGCONT to $PID"
    fi
else
    echo "Failed to send SIGSTOP to $PID"
fi
