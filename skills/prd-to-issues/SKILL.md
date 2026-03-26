---
name: prd-to-issues
description: This skill should be used when the user asks to "convert PRD to issues", "break down a PRD", "create implementation tickets", "create issues from PRD", "turn this PRD into work items", or wants to split a PRD into independently-grabbable Linear issues using vertical slices.
---

# PRD to Issues

Break a PRD into independently-grabbable Linear issues using vertical slices (tracer bullets).

## Process

### 1. Locate the PRD

Ask the user for the PRD file.

### 2. Ensure a parent Linear issue exists

Check whether a Linear issue already exists for this PRD (one may have been created via the write-a-prd skill). If not, create one using the Linear MCP with the PRD title as the issue title and a summary of the problem statement and solution as the body. This issue serves as the parent for all tracer-bullet sub-issues.

### 3. Explore the codebase (optional)

If the codebase has not already been explored, do so to understand the current state of the code.

### 4. Draft vertical slices

Break the PRD into **tracer bullet** issues. Each issue is a thin vertical slice that cuts through ALL integration layers end-to-end, NOT a horizontal slice of one layer.

Slices may be 'HITL' or 'AFK'. HITL slices require human interaction, such as an architectural decision or a design review. AFK slices can be implemented and merged without human interaction. Prefer AFK over HITL where possible.

<vertical-slice-rules>
- Each slice delivers a narrow but COMPLETE path through every layer (schema, API, UI, tests)
- A completed slice is demoable or verifiable on its own
- Prefer many thin slices over few thick ones
</vertical-slice-rules>

### 5. Quiz the user

Present the proposed breakdown as a numbered list. For each slice, show:

- **Title**: short descriptive name
- **Type**: HITL / AFK
- **Blocked by**: which other slices (if any) must complete first
- **User stories covered**: which user stories from the PRD this addresses

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the dependency relationships correct?
- Should any slices be merged or split further?
- Are the correct slices marked as HITL and AFK?

Iterate until the user approves the breakdown.

### 6. Create the Linear sub-issues

For each approved slice, create a Linear issue as a **sub-issue of the parent PRD issue** using the Linear MCP. Use the issue body template below.

Create issues in dependency order (blockers first) so you can set up relations as you go.

After creating each issue, set the appropriate **Linear issue relations** using the Linear MCP:

- **"blocks"** — if issue A must complete before issue B can start, add a "blocks" relation from A to B
- **"relates to"** — if two issues touch overlapping areas but don't have a strict ordering dependency, link them with "relates to"

Do NOT just mention blockers in the issue body — use actual Linear relations so they appear in the issue sidebar and are enforced by Linear's dependency tracking.

<issue-template>
## Context

Brief outline of the PRD context

## What to build

A concise description of this vertical slice. Describe the end-to-end behavior, not layer-by-layer implementation. Reference specific sections of the parent PRD rather than duplicating content.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## User stories addressed

Reference by number from the parent PRD:

- User story 3
- User story 7

</issue-template>
