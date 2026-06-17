---
name: grill-issue
description: Stress-test the plan for the Linear issue on the current branch. Detects the issue ID from the branch name, loads the issue and its linked Slite PRD as context, grills relentlessly, then hands off a decision log into plan mode. Use when asked to "grill-issue", "grill me on the issue/ticket", "grill me on linear", or to stress-test the work for the current branch's issue. For grilling a plan with no associated issue, use grill-me.
---

Stress-test the plan for the Linear issue on the current branch, then hand off a decision log into planning. This is the issue-anchored variant of `grill-me`; the interview technique is the same, the context loading and handoff are added.

## 1. Load context

1. **Resolve the issue from the branch.** Parse the current branch name for a Linear identifier (patterns like `TMRW-123`, `feat/TMRW-123-description`, `fix/TMRW-123`). If the user gave an explicit ID in the prompt, prefer that. If no ID can be found, say so and suggest plain `grill-me` instead — don't invent one.
2. **Fetch the issue** via Linear MCP (`get_issue`) — title, description, acceptance criteria, and comments.
3. **Find the PRD.** Parse the issue description and comments for linked Slite/PRD URLs and fetch them (Slite MCP `get-note`). If the user named a doc ("See Slite '<name>'") instead, resolve it with `search-notes` then `get-note`.
4. Skip any source gracefully if the MCP isn't available — grill with whatever context you did gather.

## 2. Grill

Use the `grill-me` technique: interview relentlessly, one question at a time, walking each branch of the design tree and resolving dependencies one-by-one; recommend an answer for every question; and explore the codebase instead of asking when the answer is discoverable there.

**Anchor the questions to the loaded docs** — derive them from gaps in the issue and PRD: unstated assumptions, ambiguous acceptance criteria, unhandled edge cases, and dependencies between decisions — rather than generic questioning.

## 3. Close: decision log + plan handoff

When you've walked the tree and reached shared understanding, output a compact **decision log** in the conversation:

- **Decisions** — each resolved question → the chosen answer, plus a one-line why
- **Assumptions** — what you're treating as given
- **Open / deferred** — anything unresolved or intentionally punted
- **Risks** — concerns surfaced during the grilling

Then **offer** to enter plan mode seeded with this log (via `EnterPlanMode`) so the plan builds directly from the decisions. Wait for confirmation — don't switch on your own.
