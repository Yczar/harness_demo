#!/usr/bin/env bash
# PreToolUse hook for Edit, Write and MultiEdit.
# Each phase of a run can only touch the files that belong to it, so a role
# can't do another role's job: the test writer can't write code, the builder
# can't touch the tests, and the reviewer can't edit anything.
# Exit 2 blocks the edit and tells Claude why.
input="$(cat)"
. "$(dirname "$0")/../harness/lib.sh"

file="$(json_field file_path "$input")"
[ -n "$file" ] || exit 0
rel="${file#"$ROOT"/}"

block() {
  echo "Harness guard: blocked an edit to $rel. $1" >&2
  exit 2
}

# Always protected, run or no run: the harness's own records and the golden files.
case "$rel" in
  .harness/state*|.harness/runs/*/approved|.harness/runs/*/checks_passed|.harness/runs/*/goldens_pending|.harness/runs/*/strikes.log|.harness/runs/*/state.*)
    block "These records are written by the harness scripts and the human, never by an agent." ;;
  */goldens/*.png|*/goldens/*)
    block "Golden files belong to the human. They review the UI and run .claude/harness/accept-goldens.sh themselves." ;;
esac

# No active run: stay out of the way.
[ -f "$STATE" ] || exit 0
run="$(get run)"; mode="$(get mode)"; phase="$(get phase)"

# The run's own notes (spec, review, summary) can always be written.
case "$rel" in
  .harness/runs/"$run"/*.md) exit 0 ;;
esac

# The rules can't change mid-run. Lessons are added between runs with /lesson.
case "$rel" in
  .claude/*|analysis_options.yaml|dart_test.yaml|CLAUDE.md|.mcp.json)
    block "The harness rules can't change during a run. Finish the run, then use /lesson." ;;
esac

is_code=0; is_test=0
case "$rel" in lib/*|pubspec.yaml|assets/*) is_code=1 ;; esac
case "$rel" in test/*|integration_test/*|.maestro/*) is_test=1 ;; esac

case "$phase" in
  spec)
    [ $is_code = 1 ] || [ $is_test = 1 ] && block "Nothing gets built until the human approves the spec."
    ;;
  tests)
    [ $is_code = 1 ] && block "This is the test writer's phase. Tests come before any code."
    ;;
  build)
    if [ $is_test = 1 ] && [ "$mode" = "full" ]; then
      block "The tests are locked. They're the contract the builder has to meet, so the builder can't edit them."
    fi
    ;;
  review)
    [ $is_code = 1 ] || [ $is_test = 1 ] && block "The reviewer can block a change, but it can't edit one."
    ;;
  blocked)
    block "This run hit three strikes. It's waiting for the human."
    ;;
esac
exit 0
