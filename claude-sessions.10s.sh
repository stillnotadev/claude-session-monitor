#!/bin/bash
#
# SwiftBar plugin: Claude Code session monitor
#
# Shows current memory pressure / free RAM / CPU in the menu bar, with a
# one-line recommendation on whether to run new Claude Code sessions
# locally or in the cloud based on current headroom.
#
# Install:
#   1. Install SwiftBar: https://github.com/swiftbar/SwiftBar
#   2. Copy this file into your SwiftBar plugin folder.
#   3. chmod +x claude-sessions.10s.sh
#
# The "10s" in the filename is the SwiftBar refresh interval — change it if
# you want to poll more or less often.

# ---------- memory ----------

vm_stat_out="$(vm_stat)"
page_size="$(echo "$vm_stat_out" | head -1 | grep -o '[0-9]*')"
[[ -z "$page_size" ]] && page_size=4096

pages_free="$(echo "$vm_stat_out" | awk '/Pages free/ {gsub("[^0-9]","",$3); print $3}')"
pages_inactive="$(echo "$vm_stat_out" | awk '/Pages inactive/ {gsub("[^0-9]","",$3); print $3}')"
pages_free="${pages_free:-0}"
pages_inactive="${pages_inactive:-0}"

free_bytes=$(( (pages_free + pages_inactive) * page_size ))
total_bytes="$(sysctl -n hw.memsize 2>/dev/null || echo 0)"

free_gb="$(awk -v b="$free_bytes" 'BEGIN{printf "%.1f", b/1073741824}')"
total_gb="$(awk -v b="$total_bytes" 'BEGIN{printf "%.0f", b/1073741824}')"

pressure_level="$(sysctl -n kern.memorystatus_vm_pressure_level 2>/dev/null || echo 0)"
case "$pressure_level" in
  1) pressure="Normal"; color="green"; sfimage="checkmark.circle" ;;
  2) pressure="Warning"; color="orange"; sfimage="exclamationmark.triangle" ;;
  4) pressure="Critical"; color="red"; sfimage="xmark.octagon" ;;
  *)
    # Fallback for systems where the sysctl isn't available: estimate from free %.
    free_pct="$(awk -v f="$free_gb" -v t="$total_gb" 'BEGIN{ if (t>0) printf "%.0f", (f/t)*100; else print 100 }')"
    if [[ "$free_pct" -lt 15 ]]; then
      pressure="Critical"; color="red"; sfimage="xmark.octagon"
    elif [[ "$free_pct" -lt 30 ]]; then
      pressure="Warning"; color="orange"; sfimage="exclamationmark.triangle"
    else
      pressure="Normal"; color="green"; sfimage="checkmark.circle"
    fi
    ;;
esac

# ---------- cpu ----------

cpu_line="$(top -l 1 -n 0 2>/dev/null | grep "CPU usage")"
idle="$(echo "$cpu_line" | sed -E 's/.*, *([0-9.]+)% idle.*/\1/')"
if [[ -n "$idle" ]]; then
  cpu_used="$(awk -v i="$idle" 'BEGIN{printf "%.0f", 100-i}')"
else
  cpu_used="?"
fi

# ---------- recommendation ----------

case "$pressure" in
  Critical) recommend="Low memory — run new sessions in cloud"; rec_color="red" ;;
  Warning)  recommend="Low headroom — prefer cloud for new sessions"; rec_color="orange" ;;
  *)        recommend="Plenty of headroom — local is fine"; rec_color="green" ;;
esac

# ---------- menu bar line ----------

echo "${free_gb}GB | sfimage=${sfimage}"
echo "---"
echo "Claude sessions | size=13"
echo "Memory pressure: ${pressure} | color=${color}"
echo "Free: ${free_gb} GB / ${total_gb} GB"
echo "CPU used: ${cpu_used}%"
echo "---"
echo "${recommend} | color=${rec_color}"
echo "---"
echo "Refresh | refresh=true"
