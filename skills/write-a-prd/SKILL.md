---
name: write-a-prd
description: This skill should be used when the user asks to "write a PRD", "create a product requirements document", "plan a new feature", "write up requirements", or wants to produce a PRD through interview, codebase exploration, and module design.
---

# Write a PRD

Create a PRD through user interview, codebase exploration, and module design. Steps may be skipped when clearly not applicable.

## Process

### 1. Gather the problem description

Ask the user for a detailed description of the problem to solve and any potential ideas for solutions.

### 2. Explore the codebase

Explore the repo to verify assertions and understand the current state of the code.

### 3. Interview the user

Interview the user relentlessly about every aspect of the plan until reaching a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one.

### 4. Sketch modules

Sketch out the major modules to build or modify. Actively look for opportunities to extract deep modules that can be tested in isolation.

A deep module (as opposed to a shallow module) encapsulates a lot of functionality in a simple, testable interface which rarely changes.

Confirm with the user that these modules match expectations. Confirm which modules need tests.

### 5. Write the PRD

Once a complete understanding of the problem and solution is reached, use the template below to write the PRD. Save it as a markdown file in the project root.

### 6. Offer to create a Linear issue

After saving the PRD, ask the user if they would like to create a Linear issue. If yes, create a Linear issue using the Linear MCP with the PRD title as the issue title and a summary of the problem statement and solution as the body. Share the issue URL — this issue can later serve as the parent for tracer-bullet sub-issues via the prd-to-issues skill.

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

## Testing Decisions

A list of testing decisions that were made. Include:

- A description of what makes a good test (only test external behavior, not implementation details)
- Which modules will be tested
- Prior art for the tests (i.e. similar types of tests in the codebase)

## Out of Scope

A description of the things that are out of scope for this PRD.

## Further Notes

Any further notes about the feature.

</prd-template>
