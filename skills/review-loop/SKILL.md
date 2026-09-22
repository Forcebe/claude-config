---
name: review-loop
description: Runs the writer↔reviewer review negotiation automatically, in the chat that wrote the code — seeds a verified review, responds to every finding, has fresh agents adjudicate the responses, and reports what changed. Use when asked to "run the review loop", "review and fix", "auto-review", "review this branch and address it", or to review and act on findings without driving each turn by hand. Do NOT use in a fresh chat with no implementation context — use self-review. Do NOT use for a review with no fixes — use code-review.
---

# Review Loop

The writer↔reviewer negotiation, driven end to end without the human taking a turn.

**This chat is the writer.** Run it where the code was written, because the writer's real job is informed pushback — "that input can't reach this function, the caller validates it" — and that argument only exists where the context does. The reviewing is done by fresh subagents that have never seen this conversation, so the review stays unbiased while the writer stays informed.

You operate on the thread file defined in [the handoff format spec](../self-review/references/handoff-format.md). Read it before touching the file. The thread is the audit trail the final report is built from.

## Before you start

**Check you're in the right chat.** If you have no context on how this branch came to be — you just opened this session, or the conversation is about something else — stop and say so. Running the loop from a cold start produces a writer that agrees with everything, which is worse than no review. Point the human at `self-review` + `apply-review` instead.

If a thread file already exists for this branch, don't re-seed. Pick up from wherever it is: if findings are awaiting the writer, take a writer turn; if they're awaiting the reviewer, adjudicate.

## Ground rules for the whole loop

1. **Git is read-only.** `git diff`, `log`, `status`, `show` are fine. Never `add`, `commit`, `push`, `checkout`, `switch`, `stash`, `reset`, `restore`, `rebase`, `merge`, `clean`. The human commits when the loop is done and they've read the report — the unstaged diff is their review surface, and anything that rewrites it destroys the thing they're meant to check.
2. **Fixes stay minimal.** Fix the finding; don't refactor around it. Every line you change is a line the human has to review on top of the code they already wrote.
3. **Never reach outside the diff.** A fix that needs a change to a file nobody touched is an escalation, not a fix.
4. **Escalate rather than guess.** See [Escalating](#escalating).
5. **Never mark the review complete.** Only the human closes it out.

## Round 1 — Seed

Run `code-review`'s process steps 1–6, including verification. Reuse its subagents; do not reinvent them.

Serialize the result into the thread file per the format spec, with one difference from `code-review`'s terminal output: apply no cap. The top-10 cut exists because a human is reading a terminal; here the reader is an agent working findings one at a time, and a cut finding never gets answered. Keep everything that cleared the bar. Capture a seed snippet and, where the verifier produced one, the verification verdict and its evidence.

If the review produced zero findings, write nothing, report that the branch is clean, and stop.

## Writer turn

Findings whose move is yours: `OPEN`, `REOPENED`, `HELD`.

**Re-read the cited code and compare it to the seed snippet before acting on any of them.** Then pick exactly one disposition per the spec:

- **FIXED** → `ADDRESSED`. Note what changed.
- **DISPUTE** → `DISPUTED`. Give a concrete, code-grounded reason. "I think it's fine" is not one; "the only caller is the route handler, which rejects an empty body first" is.
- **STALE** → `STALE`. Say what changed it.

On a `HELD` finding, answer the reviewer's specific rebuttal. Re-asserting your first reason burns a round and gets you to the deadlock cap without learning anything.

**A confirmed finding is not disputable on the facts.** The verifier ran something and watched it happen. You can still argue it doesn't matter, or that the behaviour is intended — but not that it doesn't occur.

**Then validate.** Run the repo's typecheck, lint, and the tests covering the files you touched. If validation goes red, make **one** repair attempt. Still red → halt the loop, leave the tree exactly as it is, and report what broke with the actual output. Do not keep fixing forward; you are now changing code nobody asked you to change, in a session the human isn't watching.

## Re-verification

Queue every finding you marked `ADDRESSED` that carried a falsifiable check at seed. Spawn `cr-verify` with the original `repro` and `expected` for each, plus the instruction to re-run the same check.

```
Use the Agent tool with:
  subagent_type: cr-verify
  prompt: <for each ADDRESSED finding: id, file:line, the original problem,
           the verification block, and the command it ran at seed>
```

This is what makes `RESOLVED` mean something. A fix is accepted because the check that failed now passes — not because the diff reads convincingly.

## Adjudication

Spawn `cr-adjudicate`, fresh, with everything it needs to rule without trusting you:

```
Use the Agent tool with:
  subagent_type: cr-adjudicate
  prompt: <for each ADDRESSED/DISPUTED/STALE finding: id, severity, domains,
           file:line, the problem, the fix, the seed snippet, your
           disposition and note, and the re-verification verdict if there is one>
```

Apply its rulings to the thread, append each to the finding's thread, bump the turn number, and regenerate the digest. Add any `new_findings` it returned as fresh `OPEN` findings with new ids.

## Loop control

Continue while any finding is non-terminal. **Stop at three reviewer turns** — the seed plus two adjudications. Findings still open at the cap are reported as unresolved, not quietly dropped.

Halt immediately, mid-round, on any of these:

| Trigger | What you do |
|---|---|
| Validation red after one repair attempt | Stop. Leave the tree. Report the failure output. |
| Either side raises `NEEDS-HUMAN` | Stop. Report with the question. |
| A fix would need changes outside the diff | Stop. Report what it would take. |
| `cr-verify` reports `unexpected_changes` | Stop. Report it first — the working tree moved and the human must check `git status` before committing. |
| Three reviewer turns elapsed | Stop. Report what's still open. |

## Escalating

`NEEDS-HUMAN` is a first-class move either side can play at any point, not just a deadlock outcome. Play it when:

- The right answer depends on intended product behaviour neither side can infer from the code.
- The fix requires a decision with consequences beyond this branch — a schema change, an API contract, a dependency.
- A finding exposes a problem larger than the finding, where fixing only what was flagged would paper over it.
- The fix would be irreversible or would touch data.

Escalating early on a genuine unknown beats two confident rounds and a deadlock. It stops the loop immediately — don't finish the round first.

## Report

Terminal output, once, at the end. Lead with what needs the human, because that's the part they'll act on and the only part guaranteed to be read.

```
## Review loop: <branch> — <n> turns, <halted | complete>

### ⚠ Needs you (<count>)
- #<id> <DEADLOCKED|NEEDS-HUMAN> — <one-line topic>
    writer:   "<one sentence>"
    reviewer: "<one sentence>"
(omit when zero; when zero, say "Nothing needs you" on one line instead)

### Changed (<n> findings → <n> files)
- #<id> <what changed, one line>  `<file>:<line>`
  (grouped by finding, not by file — you're auditing decisions, not edits)

### Stood as written (<count>)
- #<id> <the claim> — reviewer accepted: <why, one line>

### Unresolved (<count>)
- #<id> <STATUS> — <why it didn't finish>
(omit when zero)

Verified: <n> confirmed · <n> refuted · <n> re-checked after fix
Validation: <typecheck/lint/test result>
Diff: <n> files, +<n> −<n> — nothing staged, nothing committed
```

Keep every line short enough to scan. If the human has to read prose to find out what happened, they'll wave it through instead, and an unread automated review is worse than none — it launders changes they never actually checked.

Then tell them the thread file is at `.claude/reviews/<branch>.md` if they want to drill into any finding's full history, and that the code is unstaged and waiting for them to commit.
