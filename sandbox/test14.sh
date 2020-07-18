#!/bin/bash
sA="test" sB="test2"
time for i in {1..100000000}; do if [[ $sA == "$sB" ]]; then :; else :; fi done
time for i in {1..100000000}; do if [[ $sA = "$sB" ]]; then :; else :; fi done
