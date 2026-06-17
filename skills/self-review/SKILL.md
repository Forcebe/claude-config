---
name: self-review
description: Reviewer side of a writer↔reviewer self-review loop on your own branch. Seeds a stateful review thread from a multi-agent review, and later adjudicates the writer's responses (accepting fixes/pushback or rebutting further). Use ONLY when explicitly asked to "self-review", "start a review thread", "seed a review thread", "adjudicate the responses", or "continue the review thread". Do NOT use for one-shot reviews or reviewing other people's PRs — use code-review for those.
---

# Self-Review (reviewer side)

The reviewer half of a writer↔reviewer negotiation on your own branch. You run this in a **fresh chat** so the review is unbiased by the implementation context. The writer half runs `apply-review` in the original chat. Both operate on a shared thread file; the human triggers every turn and is the final approver.

This skill has two modes — **seed** (round 1) and **adjudicate** (every later reviewer turn). The format of the thread is defined in [references/handoff-format.md](references/handoff-format.md) — read it before writing or updating the file.

## Detect the mode

1. Resolve the thread path: `.claude/reviews/<branch>.md` (replace `/` with `-` in the branch name).
2. If the file does not exist → **seed**.
3. If it exists and has findings in `ADDRESSED`/`DISPUTED`/`STALE` (writer has responded) → **adjudicate**.
4. If it exists but has no pending writer responses → tell the human there's nothing to adjudicate yet (the writer hasn't run `apply-review`), and stop.

## Seed mode

Produce the same analysis as the `code-review` skill, then serialize it into the thread instead of printing a terminal review.

1. **Run the review engine.** Follow `code-review`'s process steps 1–4 (Gather Context → Explore → 6 parallel `cr-review-*` agents → Consolidate), including its severity definitions. Reuse the same `cr-explore` and `cr-review-*` subagents; do not reinvent them.
2. **Serialize, don't prettify.** Two deliberate differences from `code-review`'s terminal output:
   - **Skip the comment-style voice rewrite.** The reader is an agent verifying against code, not a human skimming prose. Keep findings terse and concrete.
   - **No suggestion cap.** Keep every finding — the writer skips stale ones itself, and dropping the weakest loses signal. (Still rank by severity.)
3. **Capture a seed snippet** for every finding: the exact cited code as it stands now. This is what the writer checks staleness against.
4. **Assign stable ids** (`#1`, `#2`, …) and set every finding `OPEN`.
5. **Write the thread file** per the format spec, then generate the digest (turn 1, reviewer seed).
6. **Protect it from git.** Per the spec's Lifecycle section, ensure `.claude/reviews/.gitignore` exists containing `*` so the thread never reaches GitHub. Create it if missing; never stage anything under `.claude/reviews/`.

## Adjudicate mode

One reviewer turn: rule on everything the writer touched.

1. Read the thread file and the format spec.
2. For each `ADDRESSED`/`DISPUTED`/`STALE` finding, **re-read the current code** (never trust the line number or the writer's summary alone) and rule per the spec's [reviewer adjudications](references/handoff-format.md):
   - `ADDRESSED` → `RESOLVED` or `REOPENED` (say what's still wrong).
   - `DISPUTED` → `ACCEPTED` (pushback is reasonable) or `HELD` (with a concrete rebuttal).
   - `STALE` → confirm (terminal) or `REOPENED`.
3. **Apply the deadlock cap**: after 2 DISPUTED↔HELD rounds without convergence, set `DEADLOCKED` and stop arguing — record both final positions.
4. Append each ruling to the finding's thread; bump the turn number; regenerate the digest.
5. **Do not declare the review done** while any finding is non-terminal or escalated — only the human closes it out.

## Close out

When every finding is terminal (or human-ruled) and the human gives final approval, delete the thread per the spec's Lifecycle section: `rm .claude/reviews/<branch>.md`, leaving the `.gitignore` in place. Confirm the thread is fully resolved before deleting — don't delete one with open or deadlocked findings. The same applies if the human says to discard the review.

## Report back

End every turn with a short, scannable summary — never a wall of prose (the human will rubber-stamp it):

```
Reviewer turn <n> written to .claude/reviews/<branch>.md
<count> need your decision · <count> back to the writer · <count> resolved
```

If findings need a human decision, name them by id and the one-line conflict so the human can rule without opening the file. If zero need attention and zero are back with the writer, say the thread is ready for final approval.
