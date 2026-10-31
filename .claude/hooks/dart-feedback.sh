#!/usr/bin/env bash
# PostToolUse hook: after any edit to a Dart file, format it and analyze it,
# and hand problems straight back to the agent that made the edit.
input="$(cat)"
. "$(dirname "$0")/../harness/lib.sh"

file="$(json_field file_path "$input")"
case "$file" in *.dart) ;; *) exit 0 ;; esac
[ -f "$file" ] || exit 0
command -v dart >/dev/null 2>&1 || exit 0

dart format "$file" >/dev/null 2>&1
if ! out="$(cd "$ROOT" && dart analyze --fatal-infos "$file" 2>&1)"; then
  printf 'dart analyze found problems in %s. Fix them before moving on:\n%s\n' "${file#"$ROOT"/}" "$out" >&2
  exit 2
fi
exit 0
