#!/bin/bash
#
# claude-mem-log.sh
#
# Appends one CSV row per running `claude` CLI process, with its current
# RSS memory in GB. Meant to run on a schedule (see the launchd plist) so
# you can see a specific session's memory climbing over time instead of
# only knowing something's wrong after it crashes.
#
# View the trend for one pid:
#   awk -F, -v pid=12345 '$2==pid' ~/.config/claude-sessions/memory-log.csv
#
# Or open the whole file in Numbers/Excel — it's plain CSV.

LOG="$HOME/.config/claude-sessions/memory-log.csv"
mkdir -p "$(dirname "$LOG")"

if [[ ! -f "$LOG" ]]; then
  echo "timestamp,pid,rss_gb" > "$LOG"
fi

ts="$(date '+%Y-%m-%d %H:%M:%S')"

ps -Ao pid,rss,comm | awk -v ts="$ts" '
  $3 ~ /(^|\/)claude$/ { printf "%s,%s,%.2f\n", ts, $1, $2/1024/1024 }
' >> "$LOG"
