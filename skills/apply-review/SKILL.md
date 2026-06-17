---
name: apply-review
description: Writer side of the self-review loop. Reads the review thread on the current branch, verifies each open finding against the current code, then fixes it / disputes it with a reason / marks it stale, runs validation, and updates the thread. Use when asked to "apply the review", "pick up the handoff", "respond to the review findings", "address the review thread", or "fix the review".
---

# Apply Review (writer side)

The writer half of the writer↔reviewer loop. Run this in your **original implementation chat** — you have the context for why the code is the way it is. The reviewer half (`self-review`) runs in a fresh chat. You operate on a shared thread file defined in [the handoff format spec](~/.claude/skills/self-review/references/handoff-format.md) (expand `~` to your home directory) — read it before touching the file.

This is one writer turn: respond to every finding that's currently your move, validate, and hand back.

## Process

1. **Locate the thread.** Default to `.claude/reviews/<branch>.md` for the current branch (replace `/` with `-`). If the user passed a path, use it. If none exists, say so and stop — there's nothing to apply.

2. **Read the spec and the thread.** Identify the findings that are your move: status `OPEN`, `REOPENED`, or `HELD`. Ignore terminal findings.

3. **Verify before acting — every finding, against current code.** Re-read the cited `file:line` and compare it to the finding's **seed snippet**. The code has likely moved since the review (CodeRabbit comments handled, refactors), so findings go stale. Do not trust the line number.

4. **Pick exactly one disposition per finding** (per the spec):
   - **FIXED** — the finding is valid and you changed the code. Keep the change **minimal** — fix the finding, don't refactor around it. → `ADDRESSED`, note what changed.
   - **DISPUTE** — you disagree. Give a concrete, code-grounded reason (not "I think it's fine"). → `DISPUTED`.
   - **STALE** — current code no longer matches the seed snippet and the issue is gone. Say what changed it. → `STALE`.

   On a `HELD` finding, weigh the reviewer's rebuttal specifically — either fix it or escalate, don't just re-assert your first reason.

5. **Validate.** After fixes, run the repo's checks — typecheck, lint, and the tests covering the touched files (use the project's own commands; invoke the `verify` skill if running the app is the only real proof). Report pass/fail with the actual output. Don't claim validation you didn't run.

6. **Update the thread.** Append your disposition to each finding's thread, set the new statuses, bump the turn number, and regenerate the digest exactly per the spec.

7. **Keep the artifact out of git.** This is the chat where you commit the actual fixes, so be deliberate: stage only the changed source files, never anything under `.claude/reviews/`. The seed already wrote `.claude/reviews/.gitignore` (`*`), so `git add .` won't catch it — but don't add it by explicit path either. If the human says to discard the review, `rm` the thread file per the spec's Lifecycle section.

## Report back

Keep it scannable:

```
Writer turn <n> written to .claude/reviews/<branch>.md
<count> fixed · <count> disputed · <count> marked stale
Validation: <pass/fail summary>
```

Then one line per disputed/stale finding (id + the reason), so the human sees your pushback at a glance before it goes back to the reviewer. Remind them the next step is a reviewer turn (`self-review` in the fresh chat) to adjudicate.
