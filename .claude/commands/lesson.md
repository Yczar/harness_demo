---
description: Turn a correction into a rule the harness enforces, so the same mistake gets caught before it reaches you again.
argument-hint: <what went wrong, or what you corrected>
---

I just corrected something: **$ARGUMENTS**

Turn it into a rule so the harness catches it next time, before it reaches me.

1. Check that no run is active with `.claude/harness/status.sh`. The rules can't change mid-run. If one is active, tell me and stop.
2. Pick the strongest form that fits, in this order:
   - **A lint** in `analysis_options.yaml`, if an existing Dart lint catches it. Lints run in the checks, so it can never pass again.
   - **A test**, if it's about behaviour. Add it under `test/`.
   - **A rule in `CLAUDE.md`**, under "House rules", if it needs judgement. Write it as one plain sentence with a short example.
3. Add an entry to `.harness/lessons.md`: today's date, what went wrong, and the rule you added and where. Every agent reads this file before it starts.
4. Show me the change. Keep it to the one lesson. Don't tidy up anything else.
