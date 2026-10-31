#!/usr/bin/env bash
# PreToolUse hook for Bash. Stops shell commands from doing what the file
# guard and the human gates forbid: rewriting goldens, faking approvals or
# check results, resetting strikes, pushing or merging.
input="$(cat)"
. "$(dirname "$0")/../harness/lib.sh"

block() {
  echo "Harness guard: blocked a shell command. $1" >&2
  exit 2
}

has() { printf '%s' "$input" | grep -qE -- "$1"; }

has '--update-goldens|accept-goldens\.sh' \
  && block "Only the human creates or updates golden files."
has 'reset-strikes\.sh' \
  && block "Only the human can reset strikes after a third failure."
has '\.harness' && has 'approved|checks_passed|goldens_pending|strikes|/state' \
  && block "Approvals, check results and strikes are written by the harness and the human, not by an agent."
has 'git push|gh pr merge|git merge ' \
  && block "The harness never pushes or merges. That's the human's call at gate 2."
exit 0
