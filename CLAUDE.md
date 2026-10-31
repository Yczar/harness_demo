# harness_demo

A tiny Flutter bill splitter. It exists to show the harness: I don't write the code here, I run a system that does, and I show up at the start and the end.

## The harness

| Who | Does | Can't |
|---|---|---|
| **Me, gate 1** | Approve the spec by replying "approve" | |
| **spec-writer** (opus) | Turns my request into a spec and a map of every file it touches | Write code or tests |
| **test-writer** (sonnet) | Writes failing unit, widget and golden tests and a Maestro flow, from the spec only | Write app code, or create golden files |
| **builder** (sonnet) | Makes the tests pass, using the Dart and Flutter MCP server to see the app | Touch tests, goldens, the rules or secrets |
| **checks** (a script, not an agent) | Format, strict lints, tests, goldens, device flows | Be argued with |
| **reviewer** (opus, fresh context) | Reads the diff against the spec, looks for what tests miss | Edit or merge. It can only block. |
| **Me, gate 2** | Watch the recording, read the summary, accept goldens, merge | |

- Start a feature with `/ship <request>`. A small fix uses `/fix <change>`: no spec, no test writer, everything else the same.
- A failed check or a blocking review sends the work back to the builder. The third strike stops the run and comes to me.
- After I correct something, `/lesson` turns it into a lint, a test or a house rule, and logs it in `.harness/lessons.md`.
- Hooks enforce all of this: `.claude/hooks/`. Scripts that move a run along: `.claude/harness/`. Each run's spec, review and summary: `.harness/runs/<run>/`.

## Commands
- `flutter pub get`
- `flutter test --exclude-tags golden` for unit and widget tests
- `flutter test --tags golden` for goldens (only the human updates them)
- `flutter analyze --fatal-infos`
- `.claude/harness/checks.sh` runs everything the way the harness does
- `.claude/harness/status.sh` shows where the current run is

## Code layout
- `lib/main.dart` is the app shell.
- `lib/src/<feature>/` holds one folder per feature: a pure Dart file for logic and a screen file for UI.
- Logic stays out of widgets, so it can be unit tested.
- State is a plain `StatefulWidget`. The app is too small for a state library.

## House rules
- Every interactive widget has a clear visible label (a field's `labelText`, a button's text). Device tests find widgets by these labels through the Semantics tree. Don't stack extra `Semantics(label:)` on top of them.
- Never hide a failure: no `?? ''` over missing data, no `!` without a guarantee, no empty or catch-all `catch`. See `.claude/skills/no-error-masking/SKILL.md`.
- Anything that can fail returns a result type, and the UI shows a message for every failure case.
- No secrets in code, logs or tests. Never read `.env`, keystores or signing files.
- No new packages without asking me.
- Read `.harness/lessons.md` before starting any task. Those are rules I added after real mistakes.
