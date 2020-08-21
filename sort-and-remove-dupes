#!/bin/bash

[[ -n "$1" && -f "$1" && -w "$1" ]] || return
LC_ALL=C sort -u "$1" -o "$1"
