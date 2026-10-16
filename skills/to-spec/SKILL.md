---
name: to-spec
description: Synthesize a spec from the current conversation and codebase, and publish it.
disable-model-invocation: true
---

# To Spec

Synthesize a spec from the current conversation and codebase understanding. Do NOT interview the user — just produce the document from what has already been discussed.

If the conversation genuinely lacks the context needed to write the spec, say so and point the user at `/grill-with-docs` or `/grill-issue` to work the problem out first, rather than launching an interview here.

## Process

### 1. Explore the codebase

Explore the repo to verify assertions and understand the current state of the code. Use the project's domain glossary vocabulary throughout the spec, and respect any ADRs in the area you're touching.

### 2. Sketch the test seams

Sketch out the seams at which the feature will be tested. Prefer existing seams to new ones, and use the highest seam possible. If new seams are needed, propose them at the highest point you can. The fewer seams across the codebase, the better — the ideal is one.

Confirm with the user that these seams match their expectations.

### 3. Write the spec

Once the problem and solution are clear, write the spec using the template below.

Save it to `$(cw --state)/runs/<slug>/spec.md`, creating the run directory, and write a `run.md` beside it naming the effort. **Not the repo root**: on a shared repo nothing of this workflow may be committed, and the run graph is where `to-tickets` and `implement` will look for it. Pick a short kebab-case slug from the title.

Tell the user the path and the run slug.

### 4. Publishing to Linear is a separate, deliberate act

**Do not publish anything to Linear as part of this skill.** Linear is the team's record, and a spec that has only just been written is not yet something the team needs.

When the user does ask for it, create one issue carrying the problem statement and solution, and **no workflow labels** — no `ready-for-agent`, no agent metadata of any kind. Record the issue id back in the run's `run.md` as `linear: TMRW-123`, which is the only link between the two layers.

<spec-template>

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

A description of the things that are out of scope for this spec.

## Further Notes

Any further notes about the feature.

</spec-template>
