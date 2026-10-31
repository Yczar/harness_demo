#!/usr/bin/env bash
# Start a harness run.
#   start.sh <name> full    a feature: spec -> tests -> build -> checks -> review
#   start.sh <name> small   a small fix: build -> checks -> review (no spec, no test writer)
set -eu
. "$(dirname "$0")/lib.sh"
cd "$ROOT"

name="${1:-}"
mode="${2:-full}"
if [ -z "$name" ]; then echo "Usage: start.sh <name> [full|small]" >&2; exit 1; fi
case "$mode" in full|small) ;; *) echo "Mode must be full or small" >&2; exit 1 ;; esac
if [ -f "$STATE" ]; then
  echo "A run is already active: $(get run) (phase: $(get phase)). Finish or abort it first." >&2
  exit 1
fi

slug="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-*//; s/-*$//' | cut -c1-40)"
run_dir="$HDIR/runs/$slug"
if [ -d "$run_dir" ] && [ -f "$run_dir/state.final" ]; then
  slug="$slug-$(date +%H%M%S)"; run_dir="$HDIR/runs/$slug"
fi
mkdir -p "$run_dir"

first_phase="spec"; [ "$mode" = "small" ] && first_phase="build"
{
  echo "run=$slug"
  echo "mode=$mode"
  echo "phase=$first_phase"
  echo "strikes=0"
  echo "started=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} > "$STATE"

if git rev-parse --git-dir >/dev/null 2>&1; then
  git switch -c "harness/$slug" >/dev/null 2>&1 && echo "Branch: harness/$slug" || echo "Staying on the current branch."
fi

echo "Run: $slug"
echo "Mode: $mode"
echo "Phase: $first_phase"
echo "Folder: .harness/runs/$slug"
