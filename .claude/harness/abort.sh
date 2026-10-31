#!/usr/bin/env bash
# Stop the active run without finishing it. Keeps its folder for reference.
set -eu
. "$(dirname "$0")/lib.sh"
require_run
mv "$STATE" "$RUN_DIR/state.aborted"
echo "Run $RUN aborted. Its notes are still in $RUN_DIR."
