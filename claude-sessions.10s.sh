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

# ---------- crash-warning notification ----------
# Fires a native notification only when pressure escalates (e.g. Normal ->
# Warning), not on every refresh, so it doesn't spam you while sustained.

rank() {
  case "$1" in
    Critical) echo 2 ;;
    Warning)  echo 1 ;;
    *)        echo 0 ;;
  esac
}

STATE_DIR="$HOME/.config/claude-sessions"
STATE_FILE="$STATE_DIR/last_pressure"
mkdir -p "$STATE_DIR"
last_pressure="$(cat "$STATE_FILE" 2>/dev/null || echo "Normal")"

if [[ "$(rank "$pressure")" -gt "$(rank "$last_pressure")" ]]; then
  osascript -e "display notification \"${free_gb} GB free — ${recommend}\" with title \"Claude sessions\" subtitle \"Memory pressure: ${pressure}\" sound name \"Basso\"" >/dev/null 2>&1
fi
echo "$pressure" > "$STATE_FILE"

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
