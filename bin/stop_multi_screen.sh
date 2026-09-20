#!/usr/bin/env bash

if [ $# -eq 0 ]
then
        echo "Usage: $0 [Display]"
        exit 1
fi

xrandr --output $1 --off 
