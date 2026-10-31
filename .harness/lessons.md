# Lessons

Every time I reject a change or fix something by hand, the lesson goes here and becomes something the harness enforces: a lint, a test, or a house rule in CLAUDE.md. Every agent reads this file before it starts.

Format: date, what went wrong, the rule that now catches it, and where it lives.

- 2026-10-31 - Example: a fake default (`?? ''`) hid a missing name on the profile screen. Rule: never default over missing data. Lives in: CLAUDE.md house rules, and `.claude/skills/no-error-masking/SKILL.md`.
- 2026-10-31 - In the currency-picker run, the device flows ran against an APK built before the feature, so all three failed for the wrong reason. The Android recording was also unplayable, because `record.sh` stopped `screenrecord` by killing the local adb process, which left the MP4 with no index. Rule: device flows always run against a fresh build, and a recording must be playable. `install_app` builds and installs the current code before every Maestro run, `screenrecord` is stopped on the device, and an unreadable recording fails the step. Lives in: `.claude/harness/lib.sh` (`install_app`), `.claude/harness/checks.sh` (device-flow step), `.claude/harness/record.sh`.
