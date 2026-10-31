#!/usr/bin/env bash
# PreToolUse hook for Bash. Stops shell commands from doing what the file
# guard and the human gates forbid: rewriting goldens, faking approvals or
# check results, resetting strikes, pushing or merging.
input="$(cat)"
. "$(dirname "$0")/../harness/lib.sh"

block() {
  echo "Harness guard: blocked a shell command. $1" >&2
  exit 2
}

# Check the command itself, not the text a `cat <<EOF` heredoc writes to a file,
# so a review that mentions goldens isn't mistaken for touching them. Heredocs
# fed to anything other than cat are still checked in full. If the input can't
# be parsed, the whole of it is checked.
cmd="$(printf '%s' "$input" | perl -MJSON::PP -0777 -ne '
  my $c = eval { decode_json($_)->{tool_input}{command} };
  $_ = defined $c ? $c : $_;
  s/(\bcat\b[^\n]*<<-?\s*([\x27"]?)(\w+)\2[^\n]*)\n.*?\n[ \t]*\3[ \t]*(?=\n|$)/$1/gs;
  print;
')"
has() { printf '%s' "$cmd" | grep -qE -- "$1"; }


has '--update-goldens|accept-goldens\.sh' \
  && block "Only the human creates or updates golden files."
has 'reset-strikes\.sh' \
  && block "Only the human can reset strikes after a third failure."
has '\.harness' && has 'approved|checks_passed|goldens_pending|strikes|/state' \
  && block "Approvals, check results and strikes are written by the harness and the human, not by an agent."
has 'git push|gh pr merge|git merge ' \
  && block "The harness never pushes or merges. That's the human's call at gate 2."
exit 0
