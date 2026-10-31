#!/usr/bin/env bash
# The checks. Not an agent: if a machine can check it, a machine checks it.
# Pass: writes checks_passed so the run can move to review.
# Fail: counts a strike and prints where the log is. The builder gets the log.
set -u
. "$(dirname "$0")/lib.sh"
require_run
cd "$ROOT"

log="$RUN_DIR/checks.log"
: > "$log"
rm -f "$RUN_DIR/checks_passed" "$RUN_DIR/goldens_pending"
ok=1

step() {
  local title="$1"; shift
  echo "== $title" | tee -a "$log"
  if "$@" >> "$log" 2>&1; then
    echo "   ok" | tee -a "$log"
  else
    echo "   FAILED" | tee -a "$log"
    ok=0
  fi
}

step "format" dart format --output=none --set-exit-if-changed lib test
step "analyze (lints are gates)" flutter analyze --fatal-infos --fatal-warnings
step "unit and widget tests" flutter test --exclude-tags golden

# Goldens: a missing golden is new UI waiting for the human to look at it.
# A golden that exists and no longer matches is a real failure.
echo "== goldens" | tee -a "$log"
gout="$(flutter test --tags golden 2>&1)"; gstatus=$?
printf '%s\n' "$gout" >> "$log"
if [ $gstatus -eq 0 ] || printf '%s' "$gout" | grep -q "No tests ran"; then
  echo "   ok" | tee -a "$log"
elif printf '%s' "$gout" | grep -q "non-existent file" && ! printf '%s' "$gout" | grep -qE "Pixel test failed|diff detected"; then
  echo "   new golden files are waiting for the human (not a failure)" | tee -a "$log"
  touch "$RUN_DIR/goldens_pending"
else
  echo "   FAILED" | tee -a "$log"
  ok=0
fi

# Device flows need a booted simulator or emulator, so they're opt-in.
if [ "${HARNESS_DEVICE_FLOWS:-0}" = "1" ] && command -v maestro >/dev/null 2>&1 && [ -d .maestro ]; then
  step "device flows (Maestro)" maestro test .maestro
else
  echo "== device flows: skipped (start a simulator and set HARNESS_DEVICE_FLOWS=1)" | tee -a "$log"
fi

if [ $ok -eq 1 ]; then
  touch "$RUN_DIR/checks_passed"
  echo "CHECKS PASSED"
  exit 0
fi

echo "CHECKS FAILED. Full log: $log"
"$(dirname "$0")/strike.sh" checks
exit 1
