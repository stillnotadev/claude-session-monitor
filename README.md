# Headroom

A macOS menu bar app that tells you whether your Mac currently has enough
system headroom (memory, disk, battery, thermal) to safely start another
Claude Code session locally — or whether you should push new work to the
cloud instead.

Plus a couple of small, independent shell-based helpers for people running
multiple Claude Code projects across multiple GitHub accounts.

## Install

Requires macOS 13+ and Xcode Command Line Tools (for the Swift compiler —
run `xcode-select --install` if you don't have them).

```
git clone https://github.com/stillnotadev/headroom.git
cd headroom/native-app
./build-app.sh
open ~/Applications/Headroom.app
```

`build-app.sh` builds a release binary and packages it into
`~/Applications/Headroom.app`, ad-hoc signed so it launches without a
Gatekeeper prompt on your own machine. There's no pre-built download —
everyone builds their own copy, since an ad-hoc signature only stays
trusted on the machine that created it. If you send someone else your
built `.app`, they'll need to right-click → Open (or run
`xattr -cr Headroom.app`) the first time.

To auto-start at login, toggle "Launch at login" in the app's menu, or add
it manually in System Settings → General → Login Items & Extensions.

## What's in this repo

- **`native-app/`** — the actual Headroom app (Swift Package, SwiftUI
  `MenuBarExtra`). See [`native-app/README.md`](native-app/README.md) for
  what it shows and how to run it from source (`swift run`) instead of
  building a packaged app.
- **`git-identity/`** — a per-repo GitHub identity fix for anyone juggling
  multiple GitHub accounts across projects. Uses git's `includeIf
  "gitdir:..."` plus a custom credential helper to work around a `gh` CLI
  bug where `gh auth git-credential` ignores which account a repo should
  use. See [`git-identity/README.md`](git-identity/README.md).
- **`claude-mem-log.sh`** + **`com.achint.claude-mem-log.plist`** — a tiny
  background logger (via `launchd`) that appends Claude CLI process memory
  usage to a CSV every 5 minutes, for spotting leaks over time.
- **`claude-launch.sh`**, **`claude-sessions.10s.sh`**, **`SETUP.md`**,
  **`projects.txt.example`** — an earlier SwiftBar-based prototype of this
  same idea, kept for reference. Superseded by `native-app/`.

## Background

This started as a full session launcher/manager for Claude Code (local vs.
cloud), but that scope moved to the Claude desktop app's own Code tab,
which already handles session listing and local/cloud filtering natively.
Headroom now focuses on the one thing nothing else does: telling you if
your machine can handle another local session right now.
