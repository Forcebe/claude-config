---
name: implement
description: Build one ticket from a run — claim it, work it in its own worktree, review it, close it. Use when the user names a ticket to build, and when implement-spec dispatches a ticket to an implementer subagent.
---

# Implement

One ticket, start to finish. For a whole run at once, use `/implement-spec`.

## 1. Resolve and claim

Resolve the run and the ticket from what the user gave you. `cw frontier <run>` lists what is takeable; if they named nothing, offer the frontier and let them pick rather than choosing for them.

**Claim before anything else:**

```sh
cw claim <run> <ticket>
```

A non-zero exit means another session holds it. Stop and say so — do not work a ticket you do not hold, because the claim is the only thing preventing two worktrees building the same slice.

## 2. Read

Read the ticket in full, and the run's `spec.md`. Follow the context pointers rather than re-deriving what they already say.

Read `GLOSSARY.md` at `$(cw)` for the project's vocabulary, and the ADRs touching the area. Use those words in branch names, commits and tests.

If the ticket carries a `triage:` state of `needs-info`, it is not ready: say what is missing and stop.

## 3. Get a worktree

```sh
wt-add <branch>                       # ordinarily
wt-add <branch> <stack-parent-branch> # when the ticket has a stack-parent
```

Name the branch from the ticket, using the glossary's words. Where the ticket has a `stack-parent`, pass that ticket's `branch` as the base ref — that is what makes the two branches a stack rather than two unrelated changes.

Record the branch in the ticket's `branch:` header so later sessions, `cw status` and any stack built on top can find it.

## 4. Build

Call the Skill tool with "tdd", and work **at the seams the spec already sketched**. If a sketched seam turns out to be wrong, say so and re-agree it; do not quietly test somewhere else.

Typecheck and run the relevant tests as you go, the full suite once at the end.

## 5. Review

Call the Skill tool with "review-loop". It reviews and fixes in the session that wrote the code, which is the only place the informed pushback exists.

## 6. Close

Commit to the ticket's branch. Then:

```sh
cw close <run> <ticket>
```

which marks it done and releases the claim in one step, moving whatever it blocked onto the frontier.

Report the branch, what landed, and the new frontier. Opening a pull request is a separate, deliberate act — offer it, do not assume it.

## If you stop early

A claim outlives the session that took it, on purpose. If you are abandoning the ticket rather than finishing it, `cw release <run> <ticket>` so nobody has to guess. If you are pausing, leave the claim and say so; `cw status` will show it against a worktree with no live session, which is the signal a human needs.
