# Lessons

Every time I reject a change or fix something by hand, the lesson goes here and becomes something the harness enforces: a lint, a test, or a house rule in CLAUDE.md. Every agent reads this file before it starts.

Format: date, what went wrong, the rule that now catches it, and where it lives.

- 2026-10-31 - Example: a fake default (`?? ''`) hid a missing name on the profile screen. Rule: never default over missing data. Lives in: CLAUDE.md house rules, and `.claude/skills/no-error-masking/SKILL.md`.
