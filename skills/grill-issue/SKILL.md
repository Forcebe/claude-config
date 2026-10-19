---
name: grill-issue
description: Stress-test the Linear issue on the current branch and turn it into a run — the on-ramp for work that already has a spec, and often tickets.
disable-model-invocation: true
---

# Grill Issue

The on-ramp for work that **already exists**. Most TMRW work arrives as a Linear issue, often with a Slite PRD and sometimes with sub-issues the team already wrote. This loads all of it, grills it into shape, and lands it in the run graph so the rest of the pipeline can pick it up.

For an idea with no issue behind it, the route is `/grill-with-docs` then `/to-spec`.

## 1. Load context

1. **Resolve the issue.** Parse the current branch for a Linear identifier (`TMRW-123`, `feat/TMRW-123-description`, `nick/tmrw-123-thing`). Prefer an explicit id in the prompt. If none can be found, say so and suggest `/grill-with-docs` — don't invent one.
2. **Fetch the issue** via the `tmrw-standards` Linear MCP (`get_issue`): title, description, acceptance criteria, comments.
3. **Fetch its sub-issues**, if any. The team may already have broken the work down.
4. **Find the PRD.** Parse the issue and its comments for Slite links and fetch them (`get-note`). If the user named a doc instead, resolve it with `search-notes` then `get-note`.
5. Skip any source gracefully if its MCP is unavailable — grill with what you did gather, and say what was missing.

## 2. Grill

Call the Skill tool twice, for "grilling" and "domain-modeling". The issue is attached to a repository, so the vocabulary and the decisions settled here are worth writing down.

**Anchor the questions to what you loaded** — unstated assumptions, ambiguous acceptance criteria, unhandled edge cases, dependencies between decisions — rather than asking generically. The PRD says what the business wants; the gaps between it and what would actually be built are the interesting questions.

## 3. Write the run

This is what makes the work reachable. Create `$(cw --state)/runs/<slug>/`, creating the directories — `cw` resolves paths but creates nothing. Take the slug from the issue, e.g. `tmrw-123-referral-export`.

**`run.md`** carries the pointers and the decisions:

```markdown
# <issue title>

linear: TMRW-123
prd: <Slite URL, if there is one>

## Decisions

- <resolved question>: <the answer, and a one-line why>

## Assumptions

## Open

## Risks
```

**`spec.md`** carries the PRD's substance, not a link to it. Snapshot what the work actually requires, in the project's own vocabulary, and fold in the decisions the grilling just settled. The pointer in `run.md` is how a reader gets back to the original.

Snapshot rather than link because an implementer subagent runs AFK and may have no Slite access at all — a run that cannot be built without a browser is not a run. Note in `spec.md` that it is a snapshot and when it was taken, so a reader knows to re-check Slite if the two disagree.

## 4. Mirror the sub-issues, then review the slicing

If the issue had sub-issues, write one ticket per sub-issue under `tickets/`, numbered in the order the team listed them, using the ticket format.

**Then stop and review it with the user**, because two things cannot be imported:

- **Blocking edges.** Linear's MCP exposes no issue relations, so `blocked-by` comes back empty on every ticket and the frontier would offer the whole set at once. Propose the edges you believe exist and confirm them.
- **Slicing.** A breakdown written for people is not always a set of vertical slices. Say where you think it holds and where it does not, and let the user decide whether to re-slice.

Set `stack-parent` where the confirmed edges form a chain.

If there were **no** sub-issues, leave `tickets/` empty and point the user at `/to-tickets`, which slices the spec you just wrote.

## 5. Hand off

Report the run slug, the spec path, and `cw frontier <slug>`.

Then say what comes next: `/to-tickets` if there are no tickets yet, `/implement` for a single ticket, `/implement-spec` for the whole run.

Nothing is written back to Linear. The `linear:` pointer is the only link, and publishing anything is a separate, deliberate act.
