---
description: Ship a feature through the full harness - spec, your approval, tests, build, checks, review, then back to you to merge.
argument-hint: <what you want built>
---

Run the full harness for this request: **$ARGUMENTS**

You are the orchestrator. You hand work between the agents and run the scripts. You don't write the spec, the tests or the code yourself. Run every script from the project root.

## 1. Start
Pick a short name for the run (2 to 4 words). Run `.claude/harness/start.sh "<name>" full`.

## 2. Spec, then gate 1
Use the **spec-writer** agent with the request and the run folder.
Then show me a short summary: what will be built, the files on the map, the edge cases, and the open questions, plus the path to `spec.md`.
Ask me to reply **approve** or to tell you what to change. Then stop and wait for me.
- If I ask for changes, send them back to the spec-writer and show me the new version.
- Only my reply can approve. The gate hook records it and tells you. Never create the approval yourself.

## 3. Tests
Run `.claude/harness/phase.sh tests`. If it refuses, tell me why and stop.
Use the **test-writer** agent with the spec. Confirm the new tests fail for the right reason.

## 4. Build
Run `.claude/harness/phase.sh build`.
Use the **builder** agent with the spec and the failing tests.

## 5. Checks
Run `.claude/harness/checks.sh`.
- Passed: go to step 6.
- Failed: send the end of `checks.log` back to the **builder**, then run the checks again.
- If a script prints THIRD STRIKE, stop. Tell me what failed three times and what you think is wrong. Wait for me.

## 6. Review
Run `.claude/harness/phase.sh review`.
Use the **reviewer** agent. It starts fresh and writes `review.md`.
- APPROVE: go to step 7.
- BLOCK: run `.claude/harness/strike.sh review`, then `.claude/harness/phase.sh build`, send the blocking findings to the **builder**, and go back to step 5. Same third-strike rule.

## 7. Gate 2
Run `.claude/harness/record.sh` to record the device flow (it skips itself if no simulator is running).
Write `summary.md` in the run folder from `.claude/harness/templates/summary.md`: what changed and why, how each acceptance criterion was met, files changed, anything the reviewer suggested but didn't block, and anything I should look at closely.
Run `.claude/harness/finish.sh`, then give me its output.
Don't push or merge. That's mine.

## Rules for the whole run
- I'm only interrupted at gate 1, at gate 2, on a third strike, for a spec question only I can answer, or for anything touching credentials, releases or the stores.
- If a guard hook blocks something, don't look for a way around it. Either the wrong role is doing the work, or you need to ask me.
