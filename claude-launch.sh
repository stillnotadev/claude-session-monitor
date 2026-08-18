#!/bin/bash
#
# claude-launch.sh <local|cloud> <project-path>
#
# Called by claude-sessions.10s.sh. Opens a new Terminal window in the given
# project directory and starts Claude Code there — either a local session,
# or `claude --cloud` (which requires the current branch to be pushed to
# GitHub; this script warns you first if it isn't).

set -euo pipefail

mode="${1:-}"
dir="${2:-}"

if [[ -z "$mode" || -z "$dir" ]]; then
  osascript -e 'display alert "Claude launcher" message "Missing mode or project path."'
  exit 1
fi

if [[ ! -d "$dir" ]]; then
  osascript -e "display alert \"Claude launcher\" message \"Path not found: ${dir}\""
  exit 1
fi

tmp="$(mktemp /tmp/claude-launch.XXXXXX.sh)"

{
  echo "#!/bin/bash"
  echo "cd \"${dir}\" || exit 1"
  if [[ "$mode" == "cloud" ]]; then
    cat <<'EOS'
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git fetch --quiet 2>/dev/null || true
  unpushed="$(git log @{u}.. --oneline 2>/dev/null || true)"
  if [[ -n "$unpushed" ]]; then
    echo "Warning: you have commits not pushed to GitHub."
    echo "Cloud sessions only see what's on the remote — push first if you want this work included."
    echo
  fi
else
  echo "Warning: this folder isn't a git repo. Cloud sessions require a pushed GitHub remote."
  echo
fi
exec claude --cloud
EOS
  else
    echo "exec claude"
  fi
} > "$tmp"

chmod +x "$tmp"

osascript -e "tell application \"Terminal\" to activate" \
          -e "tell application \"Terminal\" to do script \"${tmp}\""
