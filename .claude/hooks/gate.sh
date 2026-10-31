#!/usr/bin/env bash
# UserPromptSubmit hook: gate 1.
# Only a message typed by the human can approve a spec. When the human replies
# "approve" while a spec is waiting, this records the approval. Agents can't
# trigger this hook, so they can't approve their own spec.
input="$(cat)"
. "$(dirname "$0")/../harness/lib.sh"

[ -f "$STATE" ] || exit 0
[ "$(get phase)" = "spec" ] || exit 0
run="$(get run)"
[ -f "$HDIR/runs/$run/spec.md" ] || exit 0

prompt="$(json_field prompt "$input" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//')"
case "$prompt" in
  approve|approve.|approved|approved.|"approve spec"|"approve the spec")
    touch "$HDIR/runs/$run/approved"
    echo "Gate 1: the human approved the spec for run '$run'. Move on with: .claude/harness/phase.sh tests"
    ;;
esac
exit 0
