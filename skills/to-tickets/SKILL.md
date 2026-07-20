---
name: to-tickets
description: This skill should be used when the user asks to "convert PRD to issues", "break down a PRD", "create implementation tickets", "create tickets", "create issues from PRD", "turn this PRD into work items", or wants to split a PRD, spec, or conversation into independently-grabbable Linear issues using vertical slices, each declaring its blocking edges.
---

# To Tickets

Break a PRD, plan, or the current conversation into independently-grabbable Linear issues — tracer-bullet vertical slices, each declaring the issues that **block** it.

## Process

### 1. Gather context

Work from whatever is already in the conversation. If the user passes a reference (a PRD file path, a Linear issue URL or ID), fetch it and read its full body and comments.

### 2. Ensure a parent Linear issue exists

Check whether a Linear issue already exists for this PRD (one may have been created via the to-spec skill). If not, create one using the Linear MCP with the PRD title as the issue title and a summary of the problem statement and solution as the body. This issue serves as the parent for all tracer-bullet sub-issues.

### 3. Explore the codebase (optional)

If the codebase has not already been explored, do so to understand the current state of the code. Issue titles and descriptions should use the project's domain glossary vocabulary, and respect ADRs in the area you're touching.

Look for opportunities to prefactor the code to make the implementation easier. "Make the change easy, then make the easy change." Prefactoring slices come first in the dependency order.

### 4. Draft vertical slices

Break the work into **tracer bullet** issues.

<vertical-slice-rules>
- Each slice cuts a narrow but COMPLETE path through every layer (schema, API, UI, tests) — vertical, NOT a horizontal slice of one layer
- A completed slice is demoable or verifiable on its own
- Each slice is sized to fit in a single fresh context window
- Any prefactoring should be done first
</vertical-slice-rules>

Give each issue its **blocking edges** — the other issues that must complete before it can start. An issue with no blockers can start immediately.

**Wide refactors are the exception to vertical slicing.** A wide refactor is one mechanical change — rename a column, retype a shared symbol — whose blast radius fans across the whole codebase, so a single edit breaks thousands of call sites at once and no vertical slice can land green. Don't force it into a tracer bullet; sequence it as **expand–contract**. First expand: add the new form beside the old so nothing breaks. Then migrate the call sites over in batches sized by blast radius (per package, per directory), each batch its own issue blocked by the expand, keeping CI green batch to batch because the old form still exists. Finally contract: delete the old form once no caller remains, in an issue blocked by every migrate batch. When even the batches can't stay green alone, keep the sequence but let them share an integration branch that all block a final integrate-and-verify issue — green is promised only there.

### 5. Quiz the user

Present the proposed breakdown as a numbered list. For each issue, show:

- **Title**: short descriptive name
- **Blocked by**: which other issues (if any) must complete first
- **What it delivers**: the end-to-end behavior this issue makes work
- **User stories covered**: which user stories from the PRD this addresses

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the blocking edges correct — does each issue only depend on issues that genuinely gate it?
- Should any issues be merged or split further?

Iterate until the user approves the breakdown.

### 6. Create the Linear sub-issues

For each approved slice, create a Linear issue as a **sub-issue of the parent PRD issue** using the Linear MCP. Use the issue body template below. Apply the team's `ready-for-agent` triage label — the issues are agent-grabbable by construction.

Create issues in dependency order (blockers first) so you can set up relations as you go. For each blocking edge, add a **"blocks"** relation from the blocker to the blocked issue using the Linear MCP — do NOT just mention blockers in the body, so they appear in the sidebar and are enforced by Linear's dependency tracking.

Work the **frontier**: any issue whose blockers are all done. For a purely linear chain that means top to bottom. Implement one issue at a time, clearing context between issues.

<issue-template>
## Context

Brief outline of the PRD context. Reference specific sections of the parent PRD rather than duplicating content.

## What to build

A concise description of this vertical slice. Describe the end-to-end behavior, not layer-by-layer implementation.

Avoid specific file paths or code snippets — they go stale fast. Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it and note briefly that it came from a prototype. Trim to the decision-rich parts.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Blocked by

The blocking issues (set as Linear "blocks" relations), or "None — can start immediately".

## User stories addressed

Reference by number from the parent PRD:

- User story 3
- User story 7

</issue-template>
