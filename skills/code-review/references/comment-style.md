# Comment Style Guide

How to write the prose in every finding — the `explanation` and `recommendation` you surface in the terminal review and in draft PR comments. This is about *voice*, not substance: it doesn't change which issues you raise or their severity, only how you word them.

## Reader model

Write for **a competent engineer who is new to this repository**.

Assume they are fluent in the language and general engineering concepts. Do *not* assume they know anything specific to this codebase — its conventions, module boundaries, helper functions, or domain terms. The job of a good comment is to close that repo-specific gap, not to teach programming.

This calibration matters in both directions:
- Aiming too high (terse, jargon-dense, assumes deep repo familiarity) leaves the reader guessing.
- Aiming too low (explaining language fundamentals, chatty, slangy) reads as condescending and buries the point.

## Rules

1. **Plain words over jargon.** Prefer the ordinary word unless a precise term genuinely carries more meaning. Don't say "materialize the full row," "incurs deserialization overhead," or "hot path" when "loads data we don't use" or "this runs on every request" says it. Keep a real term (`JSONB`, `N+1`, race condition) when it's the accurate name for the thing — just don't pile them up.
2. **Explain the repo-specific part, not the obvious part.** Point to the existing pattern, helper, or convention the reader can't be expected to know (e.g. "`getArtifactMetadataByClientIds` already does it this way"). Skip explanations of how `Promise.all` or a `for` loop works.
3. **One thing per comment.** Each finding makes a single point. If you're tempted to write "also," it's probably a second finding.
4. **Short.** Two or three sentences is plenty. Lead with what's wrong, then why it matters, then (in the recommendation) what to do. The reader shouldn't have to scroll.
5. **State it, don't soften or perform it.** No "heads up," no "just," no exclamation marks, no emoji. Confident and matter-of-fact, not bossy and not chummy. You're a peer leaving a note, not a linter and not a cheerleader.
6. **Name concrete things.** Reference the actual variables, functions, and files (`status`, `provider`) rather than abstractions ("the relevant fields"). Concreteness is what makes a short comment clear.

## Examples

Same finding, calibrated three ways:

**Too high — jargon-dense, assumes repo familiarity:**
> `select()` materializes the full row incl. the `metadata` JSONB; only `status`/`provider`/`updatedAt` are consumed. Project the columns — cf. `getArtifactMetadataByClientIds`.

**Too low — explains fundamentals, slangy:**
> Heads up — this grabs everything from the table, even the big `metadata` blob you don't really need! Just pull the columns you actually use and it'll be a lot faster. 🚀

**On target — plain, explains the repo-specific part:**
> This selects every column, including the `metadata` JSONB which can be large. The code only reads `status`, `provider`, and `updatedAt` — selecting just those avoids loading data we never use. `getArtifactMetadataByClientIds` already does it this way.

---

Another, for a correctness finding:

**Too high:**
> Unguarded array access — `items[0]` will throw on an empty result set upstream of the null check.

**On target:**
> If `findMatches` returns an empty array, `items[0]` is `undefined` and the `.id` access on the next line throws. This can happen whenever a search has no results. Guard for the empty case before reading the first element.
