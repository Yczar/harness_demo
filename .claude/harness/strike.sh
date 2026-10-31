#!/usr/bin/env bash
# Count a failed attempt (failed checks or a blocking review).
# The third strike stops the run and hands it to the human.
set -eu
. "$(dirname "$0")/lib.sh"
require_run
reason="${1:-unknown}"

n=$(( $(get strikes) + 1 ))
set_kv strikes "$n"
echo "$(date -u +%H:%M:%S) strike $n: $reason" >> "$RUN_DIR/strikes.log"

if [ "$n" -ge 3 ]; then
  set_kv phase blocked
  echo "THIRD STRIKE ($reason). The run is blocked. Stop and hand it to the human:"
  echo "show them $RUN_DIR/strikes.log, the last checks.log or review.md, and what you think is wrong."
  exit 3
fi
echo "Strike $n of 3 ($reason). Send the failure back to the builder."
