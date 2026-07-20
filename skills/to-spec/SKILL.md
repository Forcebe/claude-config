---
name: to-spec
description: This skill should be used when the user asks to "write a PRD", "write a spec", "create a product requirements document", "plan a new feature", "write up requirements", or wants to produce a spec by synthesizing the current conversation, exploring the codebase, and designing test seams.
---

# To Spec

Synthesize a PRD from the current conversation and codebase understanding. Do NOT interview the user — just produce the document from what has already been discussed.

If the conversation genuinely lacks the context needed to write the PRD, say so and point the user at grill-me / grill-issue to work the problem out first, rather than launching an interview here.

## Process

### 1. Explore the codebase

Explore the repo to verify assertions and understand the current state of the code. Use the project's domain glossary vocabulary throughout the PRD, and respect any ADRs in the area you're touching.

### 2. Sketch the test seams

Sketch out the seams at which the feature will be tested. Prefer existing seams to new ones, and use the highest seam possible. If new seams are needed, propose them at the highest point you can. The fewer seams across the codebase, the better — the ideal is one.

Confirm with the user that these seams match their expectations.

### 3. Write the PRD

Once the problem and solution are clear, use the template below to write the PRD. Save it as a markdown file in the project root.

### 4. Publish to Linear

Create a Linear issue using the Linear MCP with the PRD title as the issue title and a summary of the problem statement and solution as the body. Apply the team's `ready-for-agent` triage label. Share the issue URL — this issue can later serve as the parent for tracer-bullet sub-issues via the to-tickets skill.

<prd-template>

## Problem Statement

The problem that the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

A LONG, numbered list of user stories. Each user story should be in the format of:

1. As an <actor>, I want a <feature>, so that <benefit>

<user-story-example>
1. As a mobile bank customer, I want to see balance on my accounts, so that I can make better informed decisions about my spending
</user-story-example>

This list of user stories should be extremely extensive and cover all aspects of the feature.

## Implementation Decisions

A list of implementation decisions that were made. This can include:

- The modules that will be built/modified
- The interfaces of those modules that will be modified
- Technical clarifications from the developer
- Architectural decisions
- Schema changes
- API contracts
- Specific interactions

Do NOT include specific file paths or code snippets. They may end up being outdated very quickly.

Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it within the relevant decision and note briefly that it came from a prototype. Trim to the decision-rich parts — not a working demo, just the important bits.

## Testing Decisions

A list of testing decisions that were made. Include:

- A description of what makes a good test (only test external behavior, not implementation details)
- Which seams will be tested
- Prior art for the tests (i.e. similar types of tests in the codebase)

## Out of Scope

A description of the things that are out of scope for this PRD.

## Further Notes

Any further notes about the feature.

</prd-template>
