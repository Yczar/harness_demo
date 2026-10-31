#!/usr/bin/env bash
# Move the active run to its next phase. Each move checks that the previous
# step really happened, so no phase can be skipped.
#   phase.sh tests    needs: full mode, spec phase, spec.md, and the human's approval
#   phase.sh build    needs: tests written (full mode) or a small run
#   phase.sh review   needs: the checks to have passed
set -eu
. "$(dirname "$0")/lib.sh"
require_run
next="${1:-}"

fail() { echo "Can't move to '$next': $1" >&2; exit 1; }

case "$next" in
  tests)
    [ "$MODE" = "full" ] || fail "small runs have no test-writer phase"
    [ "$PHASE" = "spec" ] || fail "the run is in the '$PHASE' phase, not 'spec'"
    [ -f "$RUN_DIR/spec.md" ] || fail "there is no spec yet ($RUN_DIR/spec.md)"
    [ -f "$RUN_DIR/approved" ] || fail "the human hasn't approved the spec. They approve by replying 'approve'."
    ;;
  build)
    if [ "$MODE" = "full" ]; then
      case "$PHASE" in
        tests) [ -f "$RUN_DIR/approved" ] || fail "the spec isn't approved" ;;
        review) ;;   # the reviewer blocked: back to the builder
        *) fail "the run is in the '$PHASE' phase" ;;
      esac
    else
      case "$PHASE" in build|review) ;; *) fail "the run is in the '$PHASE' phase" ;; esac
    fi
    rm -f "$RUN_DIR/checks_passed"
    ;;
  review)
    [ "$PHASE" = "build" ] || fail "the run is in the '$PHASE' phase, not 'build'"
    [ -f "$RUN_DIR/checks_passed" ] || fail "the checks haven't passed. Run .claude/harness/checks.sh"
    ;;
  *)
    echo "Usage: phase.sh tests|build|review" >&2; exit 1 ;;
esac

set_kv phase "$next"
echo "Phase: $next"
