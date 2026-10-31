---
description: Small fix through the short harness - no spec, no test writer. Build, checks, fresh review, then back to you to merge.
argument-hint: <the small change>
---

Run the short harness for this small change: **$ARGUMENTS**

Specs only pay off on multi-file work, so a small fix skips the spec and the test writer. Everything else still applies: the checks, the fresh review, the three-strike budget, and me at the end.

If this turns out bigger than it looked (more than a couple of files in `lib/`, a new screen, or a decision only I can make), stop and suggest `/ship` instead.

1. Run `.claude/harness/start.sh "<short name>" small`.
2. Use the **builder** agent with the request. In a small run it may add or adjust a test for the fix, but it must not weaken or delete one.
3. Run `.claude/harness/checks.sh`. On failure, send the log back to the builder and run it again. Stop on THIRD STRIKE and tell me.
4. Run `.claude/harness/phase.sh review` and use the **reviewer** agent. On BLOCK: `.claude/harness/strike.sh review`, `.claude/harness/phase.sh build`, findings to the builder, back to step 3.
5. Write `summary.md` in the run folder, run `.claude/harness/finish.sh`, and give me its output. Don't push or merge.
