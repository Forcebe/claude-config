---
name: to-tickets
description: Break a spec, plan or conversation into tracer-bullet tickets, each declaring its blocking edges.
disable-model-invocation: true
---

# To Tickets

Break a spec, plan, or the current conversation into independently-grabbable **tickets** in the run graph — tracer-bullet vertical slices, each declaring the tickets that **block** it.

The tickets go in the run graph under `$(cw --state)/runs/`, never on Linear. The template at the end of this file is the format. Linear is the team's record and receives only what would have been created there by hand; publishing is a separate, deliberate act.

## Process

### 1. Gather context

Work from whatever is already in the conversation. If the user passes a reference — a run slug, a spec path, a Linear issue id — resolve it and read it in full.

### 2. Locate or create the run

A spec written by `/to-spec` already has a run at `$(cw --state)/runs/<slug>/`. Use it. If there is no run yet, create one: a directory under `$(cw --state)/runs/`, with a `run.md` naming the effort and recording `linear: <id>` if a Linear issue already covers it.

Confirm the slug with the user before writing anything, since every later skill refers to the run by it.

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

### 6. Write the tickets

Write one file per ticket to `$(cw --state)/runs/<slug>/tickets/NN-slug.md`, numbered from `01` in dependency order so that reading the directory reads the intended sequence. Use the template below.

**Write nothing to Linear.** Not the tickets, not a parent issue, not a label. The run graph holds the whole task graph; Linear holds only what the team would have seen anyway.

Set `blocked-by` to the ids of the blocking tickets, space separated, or leave it empty. Where the graph is a chain, set `stack-parent` too: those tickets become a stack of PRs, and `wt-add <branch> <parent-branch>` takes the parent's branch as its base.

Then verify with `cw frontier <slug>`: it should list exactly the tickets that can start immediately. If it lists more or fewer than expected, the edges are wrong — fix them before telling the user you are done.

Report the run slug and the frontier.

<ticket-template>
---
status: open
blocked-by: 01-prefactor-the-thing
branch:
stack-parent: 01-prefactor-the-thing
---

# Add the referral export endpoint

## What to build

A concise description of this vertical slice: the end-to-end behaviour it makes work, from the user's point of view, not a layer-by-layer implementation list.

Avoid specific file paths or code snippets — they go stale fast. Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (a state machine, a reducer, a schema, a type shape), inline it and note that it came from a prototype. Trim it to the decision-rich part.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2

## Context

Point at the spec rather than restating it: `spec.md`, and the sections that matter. Name the user stories by number.

</ticket-template>

`branch` is left empty until the work starts; `implement` fills it in. The header is the contract — only the block between the fences is read, so prose in the body that happens to start with a key is just prose.
