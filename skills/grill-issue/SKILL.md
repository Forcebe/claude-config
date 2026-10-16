---
name: grill-issue
description: Stress-test the plan for the Linear issue on the current branch, anchored to the issue and its PRD.
disable-model-invocation: true
---

Stress-test the plan for the Linear issue on the current branch, then hand off a decision log into planning. The interview technique is the same as `/grill-me`; the context loading and the handoff are what this adds.

## 1. Load context

1. **Resolve the issue from the branch.** Parse the current branch name for a Linear identifier (patterns like `TMRW-123`, `feat/TMRW-123-description`, `fix/TMRW-123`). If the user gave an explicit ID in the prompt, prefer that. If no ID can be found, say so and suggest plain `grill-me` instead — don't invent one.
2. **Fetch the issue** via the `tmrw-standards` Linear MCP (`get_issue`) — title, description, acceptance criteria, and comments.
3. **Find the PRD.** Parse the issue description and comments for linked Slite/PRD URLs and fetch them (Slite MCP `get-note`). If the user named a doc ("See Slite '<name>'") instead, resolve it with `search-notes` then `get-note`.
4. Skip any source gracefully if the MCP isn't available — grill with whatever context you did gather.

## 2. Grill

Call the Skill tool twice, for "grilling" and "domain-modeling": the issue is attached to a repository, so vocabulary and decisions settled here are worth writing down.

**Anchor the questions to the loaded docs** — derive them from gaps in the issue and PRD: unstated assumptions, ambiguous acceptance criteria, unhandled edge cases, and dependencies between decisions — rather than generic questioning.

## 3. Close: decision log + plan handoff

When you've walked the tree and reached shared understanding, output a compact **decision log** in the conversation:

- **Decisions** — each resolved question → the chosen answer, plus a one-line why
- **Assumptions** — what you're treating as given
- **Open / deferred** — anything unresolved or intentionally punted
- **Risks** — concerns surfaced during the grilling

Then **offer** to enter plan mode seeded with this log (via `EnterPlanMode`) so the plan builds directly from the decisions. Wait for confirmation — don't switch on your own.
