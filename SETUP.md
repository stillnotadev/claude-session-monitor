# Setup: Claude session menu bar monitor

## 1. Install SwiftBar
Download from https://github.com/swiftbar/SwiftBar (or `brew install swiftbar`). Open it once and pick a plugin folder when prompted — remember that path for step 2.

## 2. Add the plugin scripts
Copy `claude-sessions.10s.sh` and `claude-launch.sh` into the SwiftBar plugin folder you chose, then make them executable:

```
chmod +x claude-sessions.10s.sh claude-launch.sh
```

SwiftBar picks up new plugins automatically (or use "Refresh All" from its menu bar icon).

## 3. Add your projects
```
mkdir -p ~/.config/claude-sessions
cp projects.txt.example ~/.config/claude-sessions/projects.txt
```
Edit that file to list your real project folders (`Name | /absolute/path`). You can also open it anytime from the app's "Edit projects list" menu item.

## 4. What you'll see
Clicking the menu bar icon (shows free RAM, colored by memory pressure) opens a dropdown with:
- Memory pressure, free RAM, CPU
- A one-line recommendation (local vs. cloud) based on current headroom
- Locally running `claude` processes, each with a Kill button
- A launch menu per project — "Run locally" or "Run in cloud"
- "Run in cloud" checks for unpushed git commits first and warns you in the terminal before starting, since Claude Code's cloud sessions only see what's pushed to GitHub

## Notes / limitations
- Memory pressure and CPU come from macOS (`vm_stat`, `sysctl`, `top`) — not from Claude Code itself, since there's no official API for per-session resource usage.
- The process list matches any process literally named `claude` — it can't distinguish which project a given PID belongs to unless you're only running one at a time. Killing is `kill -9`, immediate, no confirmation dialog (SwiftBar menu clicks don't have a built-in confirm step) — double-check the PID before clicking.
- The refresh interval is set by the filename (`claude-sessions.10s.sh` = every 10s). Rename to change it, e.g. `claude-sessions.30s.sh`.
- Requires `claude --cloud` to already be authorized with GitHub once (normal `claude` login flow) — this script doesn't handle first-time auth.
