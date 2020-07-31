#!/bin/bash

sTEST=$(echo "This is my exam"|if grep -q test;then echo "Test works";elif grep -q my;then echo "Test still works";fi)
echo $sTEST
