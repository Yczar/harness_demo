#!/usr/bin/env bash
# Where is the current run?
. "$(dirname "$0")/lib.sh"
if [ ! -f "$STATE" ]; then echo "No active run."; exit 0; fi
require_run
echo "Run:     $RUN ($MODE)"
echo "Phase:   $PHASE"
echo "Strikes: $(get strikes) of 3"
for f in spec.md approved checks_passed goldens_pending review.md summary.md recording.mp4; do
  [ -e "$RUN_DIR/$f" ] && echo "  has $f"
done
exit 0
