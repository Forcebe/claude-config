# Comment Style Guide

How to write the prose in every finding — the `summary`, `problem` and `fix` the review agents produce, and the prose they become in draft PR comments. This is about *voice*, not substance: it doesn't change which issues you raise or their severity, only how you word them.

## Reader model

Write for **a competent engineer who is new to this repository**.

Assume they are fluent in the language and general engineering concepts. Do *not* assume they know anything specific to this codebase — its conventions, module boundaries, helper functions, or domain terms. The job of a good comment is to close that repo-specific gap, not to teach programming.

This calibration matters in both directions:
- Aiming too high (terse, jargon-dense, assumes deep repo familiarity) leaves the reader guessing.
- Aiming too low (explaining language fundamentals, chatty, slangy) reads as condescending and buries the point.

## The three fields

Each carries a hard shape. Most of the brevity problem is solved by respecting these rather than by editing afterwards.

| Field | Shape |
|-------|-------|
| `summary` | One line, at most 10 words. Name the consequence, not the code construct — "Empty result crashes the caller", not "Array access in parseIds". |
| `problem` | At most two sentences. Symptom first, then cause. Name real functions and variables. |
| `fix` | One imperative sentence naming the function, variable or value to change. Never "consider refactoring", never "you might want to". If the fix is a genuine design choice, frame it as two options and say which is simpler. |

Three sentences of `problem` is a sign you're describing two findings. Split it or drop the weaker half.

## Rules

1. **Plain words over jargon.** Prefer the ordinary word unless a precise term genuinely carries more meaning. Don't say "materialize the full row," "incurs deserialization overhead," or "hot path" when "loads data we don't use" or "this runs on every request" says it. Keep a real term (`JSONB`, `N+1`, race condition) when it's the accurate name for the thing — just don't pile them up.
2. **Explain the repo-specific part, not the obvious part.** Point to the existing pattern, helper, or convention the reader can't be expected to know (e.g. "`getArtifactMetadataByClientIds` already does it this way"). Skip explanations of how `Promise.all` or a `for` loop works.
3. **One thing per comment.** Each finding makes a single point. If you're tempted to write "also," it's probably a second finding.
4. **Short — hard cap.** Two sentences of `problem`, one of `fix`. There is no third sentence: if you've written a "Separately…" or tacked on a parenthetical second point, cut it or split it into its own finding. Always prefer the shortest version that's still clear.
5. **State it, don't soften or perform it.** No "heads up," no "just," no exclamation marks, no emoji. Confident and matter-of-fact, not bossy and not chummy. You're a peer leaving a note, not a linter and not a cheerleader.
6. **Name concrete things.** Reference the actual variables, functions, and files (`status`, `provider`) rather than abstractions ("the relevant fields"). Concreteness is what makes a short comment clear.

## Examples

Same finding, calibrated three ways.

**Too high — jargon-dense, assumes repo familiarity:**
> **summary:** Unprojected select materializes JSONB
> **problem:** `select()` materializes the full row incl. the `metadata` JSONB; only `status`/`provider`/`updatedAt` are consumed.
> **fix:** Project the columns — cf. `getArtifactMetadataByClientIds`.

**Too low — explains fundamentals, slangy:**
> **summary:** This query is grabbing way too much stuff
> **problem:** Heads up — this grabs everything from the table, even the big `metadata` blob you don't really need! That means the database has to read and send data that just gets thrown away.
> **fix:** Just pull the columns you actually use and it'll be a lot faster. 🚀

**On target:**
> **summary:** Query loads a large JSONB nobody reads
> **problem:** This selects every column, including the large `metadata` JSONB, but the code only reads `status`, `provider` and `updatedAt`.
> **fix:** Select just those three — `getArtifactMetadataByClientIds` already does it this way.

---

A correctness finding:

**Too high:**
> **problem:** Unguarded array access — `items[0]` will throw on an empty result set upstream of the null check.

**On target:**
> **summary:** Empty search result crashes the handler
> **problem:** When `findMatches` returns an empty array — any search with no results — `items[0]` is `undefined`, and the `.id` access on the next line throws.
> **fix:** Return early when `items` is empty, before reading the first element.
