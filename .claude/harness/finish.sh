#!/usr/bin/env bash
# Close the run after the reviewer approved. The change is ready for gate 2:
# the human watches the recording, reads summary.md and merges it themselves.
set -eu
. "$(dirname "$0")/lib.sh"
require_run
cd "$ROOT"

[ "$PHASE" = "review" ] || { echo "Can't finish: the run is in the '$PHASE' phase, not 'review'." >&2; exit 1; }
[ -f "$RUN_DIR/checks_passed" ] || { echo "Can't finish: the checks haven't passed." >&2; exit 1; }
grep -qiE '^verdict:[[:space:]]*approve' "$RUN_DIR/review.md" 2>/dev/null \
  || { echo "Can't finish: review.md doesn't say 'Verdict: APPROVE'." >&2; exit 1; }
[ -f "$RUN_DIR/summary.md" ] || { echo "Can't finish: write $RUN_DIR/summary.md first (template in .claude/harness/templates)." >&2; exit 1; }

mv "$STATE" "$RUN_DIR/state.final"
echo "Run $RUN is ready for you."
echo "  Summary:   $RUN_DIR/summary.md"
echo "  Review:    $RUN_DIR/review.md"
[ -f "$RUN_DIR/recording.mp4" ] && echo "  Recording: $RUN_DIR/recording.mp4"
[ -f "$RUN_DIR/goldens_pending" ] && echo "  New golden files are waiting: look at the UI, then run .claude/harness/accept-goldens.sh yourself."
if git rev-parse --git-dir >/dev/null 2>&1; then
  echo "  Changes:"
  git --no-pager diff --stat HEAD 2>/dev/null | sed 's/^/    /'
fi
echo "Merging is yours. The harness never pushes or merges."
