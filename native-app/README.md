# Claude session monitor — native app

A menu bar app (SwiftUI, `MenuBarExtra`) replacing the SwiftBar plugin, with
the full feature set: memory pressure + trend, disk space, battery/power,
thermal throttling, a combined local/cloud recommendation, a kill-switch for
locally running `claude` CLI processes, one-click local/cloud session launch,
and quick-action shortcuts.

## Run it

**From Terminal** (fastest, no Xcode UI needed):
```
cd ~/Developer/claude-session-monitor/native-app
swift run
```
First build takes a minute or two; subsequent runs are fast. Leave the
terminal open — closing it stops the app. Use `swift run -c release` for a
snappier build once you're happy with it.

**From Xcode:**
```
open ~/Developer/claude-session-monitor/native-app/Package.swift
```
Xcode opens it as a Swift Package. Pick the `ClaudeSessionMonitor` scheme
and hit Run (⌘R).

## What's different from the SwiftBar version

- Custom UI (colored banners, buttons, cards) instead of plain macOS menu
  text — SwiftBar can't render that, this can.
- Battery, disk, and thermal state now feed into the local/cloud
  recommendation alongside memory pressure.
- Trend arrow (rising/easing) is tracked in memory between refreshes — no
  state file needed, unlike the SwiftBar script which had to persist it to
  disk since it re-runs as a fresh process every cycle.
- Thresholds are configurable via `~/.config/claude-sessions/config.json`
  (created automatically on first run with defaults) instead of being
  hardcoded — use the "Edit thresholds config" menu item to open it.
- "Run locally" / "Run in cloud" now prompt you to pick a project folder via
  a native file picker each time, rather than reading a fixed
  `projects.txt` list.

## Known limitations (same root causes as before)

- The "Running locally" list only detects processes literally named
  `claude` (the CLI). It cannot see sessions opened through the Claude
  desktop app's Code tab — there's no public API for per-session resource
  usage, from either the CLI or the desktop app.
- Killing a process is immediate (`kill -9`), no confirmation dialog.
- No cloud deep link exists yet, so "Run in cloud" still opens a Terminal
  window rather than opening directly in the desktop app the way "Run
  locally" does.

## Background jobs (unchanged, still bash-based)

The memory-leak CSV logger (`claude-mem-log.sh` + its launchd job) is
unaffected by this app and keeps running independently — no need to touch
it. The per-repo git identity setup (`git-identity/`) is also unrelated to
this app; nothing here changes it.
