#!/usr/bin/env bash
# HUMAN ONLY. After a third strike, once you've decided what to change
# (usually the spec), give the run three fresh attempts.
set -eu
. "$(dirname "$0")/lib.sh"
require_run
set_kv strikes 0
set_kv phase "${1:-build}"
echo "Strikes reset. Phase: $(get phase)."
