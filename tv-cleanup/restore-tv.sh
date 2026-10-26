#!/usr/bin/env bash
# Undo clean-tv.sh. Pass the log file it wrote, or 'all' to re-enable everything that is disabled.
# Usage: ./restore-tv.sh <tv-ip-address> <disabled-*.txt | all>
set -u
TV="${1:-}"; SRC="${2:-}"
[ -z "$TV" ] || [ -z "$SRC" ] && { echo "Usage: $0 <tv-ip-address> <disabled-*.txt | all>"; exit 1; }

adb connect "$TV:5555" >/dev/null
A=(adb -s "$TV:5555" shell)

if [ "$SRC" = all ]; then
  LIST=$("${A[@]}" pm list packages -d | sed 's/package://' | tr -d '\r')
else
  LIST=$(cat "$SRC")
fi

for p in $LIST; do
  if [ "$p" = private_dns ]; then
    "${A[@]}" settings put global private_dns_mode off && echo "DNS back to normal"
  else
    "${A[@]}" pm enable "$p" >/dev/null && echo "re-enabled $p"
  fi
done
[ "$SRC" = all ] && "${A[@]}" settings put global private_dns_mode off
echo "Done. Restart the TV (hold power on the remote) to be safe."
