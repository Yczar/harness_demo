# Shared helpers for the harness scripts and hooks. Sourced, not run.
# Works with the bash 3.2 that ships with macOS.

ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
HDIR="$ROOT/.harness"
STATE="$HDIR/state"

# Read a key from the state file. Prints nothing if there is no active run.
get() {
  [ -f "$STATE" ] || return 0
  grep -E "^$1=" "$STATE" | head -1 | cut -d= -f2-
}

# Write a key to the state file.
set_kv() {
  local tmp="$STATE.tmp"
  grep -vE "^$1=" "$STATE" > "$tmp" 2>/dev/null || true
  echo "$1=$2" >> "$tmp"
  mv "$tmp" "$STATE"
}

# Stop unless a run is active; otherwise load RUN, MODE, PHASE and RUN_DIR.
require_run() {
  if [ ! -f "$STATE" ]; then
    echo "No harness run is active. Start one with /ship (feature) or /fix (small change)." >&2
    exit 1
  fi
  RUN="$(get run)"
  MODE="$(get mode)"
  PHASE="$(get phase)"
  RUN_DIR="$HDIR/runs/$RUN"
}

# Pull a string field out of hook JSON on stdin without needing jq.
# Good enough for simple fields like file_path and prompt.
json_field() {
  printf '%s' "$2" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -1
}
