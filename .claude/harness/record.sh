#!/usr/bin/env bash
# Record the Maestro flows on a booted iOS simulator or Android emulator, so the
# human can watch the feature at gate 2 instead of reading code. Best effort:
# with no device or no Maestro, it says so and exits cleanly.
set -u
. "$(dirname "$0")/lib.sh"
require_run
cd "$ROOT"
out="$RUN_DIR/recording.mp4"

if ! command -v maestro >/dev/null 2>&1 || [ ! -d .maestro ]; then
  echo "Maestro isn't installed or there are no flows in .maestro. Skipping the recording."
  exit 0
fi

if ! { command -v xcrun >/dev/null 2>&1 && xcrun simctl list devices booted 2>/dev/null | grep -q Booted; } \
  && ! { command -v adb >/dev/null 2>&1 && adb get-state >/dev/null 2>&1; }; then
  echo "No booted simulator or emulator. Skipping the recording."
  exit 0
fi

if ! install_app; then
  echo "Couldn't build and install the current app, so there's nothing fresh to record." >&2
  exit 1
fi

if command -v xcrun >/dev/null 2>&1 && xcrun simctl list devices booted 2>/dev/null | grep -q Booted; then
  xcrun simctl io booted recordVideo --force "$out" >/dev/null 2>&1 &
  rec=$!
  sleep 2
  maestro test .maestro; status=$?
  kill -INT "$rec" 2>/dev/null; wait "$rec" 2>/dev/null
elif command -v adb >/dev/null 2>&1 && adb get-state >/dev/null 2>&1; then
  adb shell screenrecord /sdcard/harness.mp4 &
  rec=$!
  sleep 2
  maestro test .maestro; status=$?
  # Stop screenrecord on the device so it can finish the file. Killing the
  # local adb process cuts it off and leaves an MP4 with no index.
  adb shell pkill -INT screenrecord; wait "$rec" 2>/dev/null; sleep 2
  adb pull /sdcard/harness.mp4 "$out" >/dev/null && adb shell rm /sdcard/harness.mp4
else
  echo "No booted simulator or emulator. Skipping the recording."
  exit 0
fi

if command -v ffprobe >/dev/null 2>&1 && ! ffprobe -v error "$out" >/dev/null 2>&1; then
  echo "Recording at $out can't be played (ffprobe can't read it)." >&2
  exit 1
fi

echo "Recording: $out"
exit "$status"
