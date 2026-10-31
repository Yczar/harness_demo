# harness_demo

This is the sample project from my talk, *Do we still need to write code as Mobile Engineers?*

The app is deliberately boring: a bill splitter with one screen. The interesting part is `.claude/`. It's the harness I use so that I don't write code and I'm not the bottleneck: four agents, one set of machine checks, and me at both ends.

```
You (approve spec) → spec writer → test writer → builder → checks → reviewer → You (merge)
                                                    ↑__________|________|
                                       failed a check or the review? back to the builder.
                                       third failure? it comes to me.
```

## Set it up

You need Flutter 3.35 or newer (for the Dart and Flutter MCP server), and Claude Code.

```bash
cd ~/Documents/01_Projects/Development/harness_demo

# 1. Put the harness in place (it ships in claude-setup/, see claude-setup/INSTALL.md)
mv claude-setup/claude .claude
mv claude-setup/mcp.json .mcp.json
chmod +x .claude/hooks/*.sh .claude/harness/*.sh
rm -r claude-setup

# 2. Finish the Flutter project
flutter create . --org com.example --project-name harness_demo   # adds android/, ios/ and the rest
flutter pub get
git init && git add -A && git commit -m "Start"
flutter test --exclude-tags golden
.claude/harness/accept-goldens.sh   # look at test/golden/goldens/ after this
```

Optional, for device flows and recordings: install [Maestro](https://maestro.mobile.dev), boot a simulator, and set `HARNESS_DEVICE_FLOWS=1`.

Then open Claude Code in this folder and try:

```
/ship Add a "round up to the nearest whole amount" switch below the tip field
```

## What's in `.claude/`

| Path | What it is |
|---|---|
| `agents/spec-writer.md` | Turns my request into a spec plus a map of every file it touches. Runs on opus. |
| `agents/test-writer.md` | Writes failing tests from the spec before any code exists. Runs on sonnet. |
| `agents/builder.md` | Makes the tests pass. Gets the Dart and Flutter MCP server so it can see the app. Runs on sonnet. |
| `agents/reviewer.md` | Fresh context, different model (opus), reads the diff against the spec. Can block, can't edit. |
| `commands/ship.md` | `/ship`: the full run. |
| `commands/fix.md` | `/fix`: small changes skip the spec and the test writer. |
| `commands/lesson.md` | `/lesson`: turns a correction into a lint, a test or a house rule. |
| `skills/` | How tests are written here, and the error-masking patterns to avoid. |
| `hooks/gate.sh` | Gate 1. Only my typed "approve" can approve a spec. |
| `hooks/guard-files.sh` | Each phase can only touch its own files. Tests lock once they're written. Goldens are mine. |
| `hooks/guard-bash.sh` | No rewriting goldens, faking approvals, resetting strikes, pushing or merging. |
| `hooks/dart-feedback.sh` | Formats and analyzes every Dart file the moment it's edited. |
| `harness/*.sh` | The scripts that move a run along, run the checks, count strikes and record the device flow. |
| `settings.json` | Permissions (no secrets, no push, no publishing) and the hook wiring. |

`.mcp.json` connects the Dart and Flutter MCP server. `.harness/lessons.md` is the list of rules I've added after real mistakes. `.harness/runs/` keeps each run's spec, review and summary.

## Things only I do

- Reply **approve** to a spec (gate 1).
- Run `.claude/harness/accept-goldens.sh` after looking at new UI.
- Run `.claude/harness/reset-strikes.sh` after a third strike, once I've fixed whatever was wrong (usually the spec).
- Push and merge (gate 2).

## Honest limits

The hooks stop mistakes and keep each role in its lane. They aren't a security boundary. An agent that really wanted to could work around a shell-text check. The real protection is the same as for people: keep production and store credentials off the machine the agents run on, and keep merging in human hands.
