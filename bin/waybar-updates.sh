#!/usr/bin/env bash
# Count of pending pacman updates, printed only when there are any, so the
# module stays hidden on an up-to-date system.
#
# checkupdates (pacman-contrib) syncs its own temporary database, so it does
# not need root and does not disturb the real pacman sync state.

set -uo pipefail

command -v checkupdates >/dev/null 2>&1 || exit 0

n=$(checkupdates 2>/dev/null | wc -l)
(( n > 0 )) && printf '%d updates\n' "$n"
exit 0
