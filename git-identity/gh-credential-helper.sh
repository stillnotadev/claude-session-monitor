#!/bin/bash
#
# gh-credential-helper.sh <gh-username> <get|store|erase>
#
# Works around a gh CLI limitation (cli/cli#9111): `gh auth git-credential`
# ignores git's username hint and always serves whichever account is
# currently "active" via `gh auth switch`, so multi-account per-repo setups
# silently fall back to an interactive password prompt.
#
# `gh auth token --user <name>` DOES correctly fetch a specific non-active
# account's token, so this wraps that in git's credential-helper protocol
# instead. Configure it per-repo (via includeIf) like:
#
#   [credential "https://github.com"]
#       helper =
#       helper = !/absolute/path/to/gh-credential-helper.sh <gh-username>
#
# The username is baked into the config, not read from git's request, so
# there's no ambiguity about which account this repo should use.

GH_BIN="/opt/homebrew/bin/gh"
[[ -x "$GH_BIN" ]] || GH_BIN="$(command -v gh)"

user="$1"
action="$2"

# Always drain stdin — git sends protocol=...\nhost=...\n and expects the
# helper to consume it even if unused.
cat >/dev/null

if [[ "$action" != "get" || -z "$user" ]]; then
  exit 0
fi

token="$("$GH_BIN" auth token --user "$user" 2>/dev/null)"

if [[ -n "$token" ]]; then
  echo "username=${user}"
  echo "password=${token}"
fi
