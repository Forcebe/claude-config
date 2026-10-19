---
name: grill-issue
description: Stress-test the Linear issue on the current branch and turn it into a run — the on-ramp for work that already has a spec, and often slices.
disable-model-invocation: true
---

# Grill Issue

The on-ramp for work that **already exists**. Most TMRW work arrives as a Linear issue, often with a Slite PRD and sometimes with sub-issues the team already wrote. This loads all of it, grills it into shape, and lands it in the run graph so the rest of the pipeline can pick it up.

For an idea with no issue behind it, the route is `/grill-with-docs` then `/to-spec`.

## 0. Make sure the repo is set up

Run `cw --mode`. If it reports `unconfigured`, call the Skill tool with "setup-workspace" and get it configured before going further — don't make the user come back. On a shared repo it will choose sidecar storage, so the repo gains nothing either way.

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

## 4. One slice, unless there is a real reason for more

**A Linear issue is already sized to be one piece of work and one pull request.** The default is therefore exactly one slice covering the whole issue, written to `slices/01-<slug>.md`. Do not break it down, do not propose a breakdown, and do not suggest `/to-slices`.

Splitting is the exception, and it needs a reason you can name:

- The issue genuinely will not fit one session.
- It contains a wide refactor that has to be sequenced expand–contract.
- The team already wrote sub-issues (below).

If one of those holds, say which, propose the split, and let the user decide. Several slices means several branches and several pull requests, so the bar is whether that is actually wanted — not whether the work could in principle be divided.

**If the issue had sub-issues**, mirror them one per slice, in the order the team listed them, then stop and review two things that cannot be imported:

- **Blocking edges.** Linear's MCP exposes no issue relations, so `blocked-by` comes back empty on every slice and the frontier would offer the whole set at once. Propose the edges you believe exist and confirm them.
- **Whether they are really separate.** Sub-issues written for people are often one deliverable viewed from several angles. If they belong in one pull request, collapsing them into one slice is the better answer.

Set `stack-parent` where confirmed edges form a chain.

## 5. Hand off

Report the run slug, the spec path, and `cw frontier <slug>`.

The next step is `/implement` — one slice, one branch, one pull request. Only reach for `/implement-spec` when the run genuinely has several slices with edges between them.

Nothing is written back to Linear. The `linear:` pointer is the only link, and publishing anything is a separate, deliberate act.
