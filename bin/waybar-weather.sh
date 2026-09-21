#!/usr/bin/env bash
# Current conditions for a weather station, for the bar's weather module.
#
# The station code is deliberately not in this repository: it says roughly
# where the machine is, and the repository is public. It is read from
# $WEATHER_STATION, or from ~/.config/waybar/station, which is a local file
# that no make target deploys or overwrites. With neither set this prints
# nothing, which makes waybar hide the module rather than show an error.
#
# Set one with:   echo KXYZ > ~/.config/waybar/station

set -uo pipefail

station=${WEATHER_STATION:-}

if [[ -z $station ]]; then
  station_file="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/station"
  [[ -r $station_file ]] && station=$(head -1 "$station_file" | tr -d '[:space:]')
fi

[[ -n $station ]] || exit 0

exec "$HOME/Apps/bin/get_temp.py" "$station"
