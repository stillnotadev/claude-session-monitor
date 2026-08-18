# Headroom

A menu bar app (SwiftUI, `MenuBarExtra`) that tells you whether your Mac has
enough system headroom to safely run a Claude Code session locally, or
whether you should push new work to the cloud instead. Tracks memory
pressure (with a rising/easing trend), disk space, battery/power, and
thermal throttling, and combines all four into one recommendation.

This started as a session launcher/manager, but that scope moved to the
Claude desktop app's own Code tab (which already handles session listing
and local/cloud filtering natively) — Headroom now focuses purely on the
one thing it does that nothing else does: telling you if your machine can
handle another local session right now.

## Run it

**From Terminal** (fastest, no Xcode UI needed):
```
cd ~/Developer/headroom/native-app
swift run
```
First build takes a minute or two; subsequent runs are fast. Leave the
terminal open — closing it stops the app. Use `swift run -c release` for a
snappier build once you're happy with it.

**From Xcode:**
```
open ~/Developer/headroom/native-app/Package.swift
```
Xcode opens it as a Swift Package. Pick the `Headroom` scheme and hit Run
(⌘R).

## What it shows

- Memory pressure (Normal/Warning/Critical) with free/total GB, a trend
  arrow (rising/easing since the last check), and CPU usage.
- Free disk space on the root volume.
- Battery percentage and whether you're on AC power.
- Thermal throttling state (only shown when it's not nominal).
- One combined recommendation banner, colored by severity, listing which
  factor(s) are driving it (e.g. "memory low, battery low").
- A native notification when things escalate (Normal → Warning →
  Critical), so you find out even if the menu bar isn't visible.
- Quick-action shortcuts: open the git-identity folder or the thresholds
  config file.

Thresholds are configurable at `~/.config/claude-sessions/config.json`
(created automatically on first run) — use the "Edit thresholds config"
menu item to open it directly.

## Background jobs (unchanged, still bash-based)

The memory-leak CSV logger (`claude-mem-log.sh` + its launchd job) and the
per-repo git identity setup (`git-identity/`) are both unrelated to this
app and keep working independently — nothing here touches them.
