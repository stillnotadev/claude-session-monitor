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

urlencode() {
  local string="$1" strlen=${#1} encoded="" pos c o
  for (( pos=0; pos<strlen; pos++ )); do
    c=${string:$pos:1}
    case "$c" in
      [a-zA-Z0-9.~_-]) o="$c" ;;
      *) printf -v o '%%%02X' "'$c" ;;
    esac
    encoded+="$o"
  done
  printf '%s' "$encoded"
}

if [[ "$mode" == "local" ]]; then
  # Open as a real session in the Claude desktop app instead of a bare
  # Terminal window. See: https://support.claude.com/en/articles/14729294
  open "claude://code/new?folder=$(urlencode "$dir")"
  exit 0
fi

# Cloud sessions still go through a Terminal — there's no documented
# desktop deep link for `claude --cloud` yet, and it needs the unpushed
# commit check below before it's worth starting. `claude --cloud` also
# requires a task description up front, so ask for one first.

description="$(osascript -e 'text returned of (display dialog "Describe the task for this cloud session:" default answer "" with title "Claude — cloud session" buttons {"Cancel","Start"} default button "Start")' 2>/dev/null || true)"

if [[ -z "$description" ]]; then
  exit 0
fi

esc_description="$(printf '%q' "$description")"

tmp="$(mktemp /tmp/claude-launch.XXXXXX)"

{
  echo "#!/bin/bash"
  echo "cd \"${dir}\" || exit 1"
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
EOS
  echo "exec claude --cloud ${esc_description}"
} > "$tmp"

chmod +x "$tmp"

osascript -e "tell application \"Terminal\" to activate" \
          -e "tell application \"Terminal\" to do script \"${tmp}\""
