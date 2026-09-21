#!/usr/bin/env bash
# Battery level of the first bluetooth mouse upower knows about.
#
# The device is looked up at runtime rather than pinned in waybar's config:
# its native-path is /org/bluez/hci0/dev_<MAC>, and this repo is public.
# Prints nothing when no mouse is paired, which makes waybar hide the module.

set -uo pipefail

dev=$(upower -e 2>/dev/null | grep -m1 mouse) || exit 0
[[ -n ${dev:-} ]] || exit 0

upower -i "$dev" 2>/dev/null |
  awk '/percentage:/ { gsub("%", "", $2); printf "MOUSE %d%%\n", $2; exit }'
