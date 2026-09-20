#!/usr/bin/env bash

if [ $# -eq 0 ]
then
        echo "Usage $0 [Display]"
        exit 1
fi

running_monitor=$(xrandr --listactivemonitors | tail -n 1 | cut -d ' ' -f 3 | tr -d *,+)

xrandr --output $1 --auto --right-of $running_monitor
