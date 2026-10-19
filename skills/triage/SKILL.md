---
name: triage
description: Take a slice from raw to agent-ready: verify the claim, grill it into shape, and write a brief an agent can act on.
disable-model-invocation: true
---

# Triage

Move a slice from "someone wrote this down" to "an agent can pick this up and build it". The output is a **brief**, and the states are local.

Matt's version of this skill is for maintainers fielding bug reports from strangers. That is not the job here. The slices triaged here are usually ones I wrote myself, or ones a teammate filed in Linear, and the value is in sharpening them — not in running a public inbox.

## States are local, and stay local

A slice's triage state lives in the run graph, in the slice's own header:

```
triage: needs-info | ready-for-agent | ready-for-human | wontfix
```

**Nothing about triage is written to Linear.** No labels, no state comments, no agent metadata. A Linear issue says what the team needs to know about the work; how ready it is for an agent to take is this workflow's business and nobody else's. If a Linear issue needs updating because the *work* changed, that is a separate, deliberate act.

A slice with no `triage:` key has not been triaged. That is the normal state for a slice `/to-slices` just wrote, which is agent-ready by construction and needs no triage at all.

## Process

### 1. Gather

Read the slice in full, and the run's `spec.md` if there is one. If it carries `linear:`, read that issue and its comments too — the reporter's words matter and may contradict the slice.

Explore the codebase using the project's glossary vocabulary, and respect ADRs in the area. Run two checks:

- **Redundancy**: search for an existing implementation by domain concept, not by the request's wording. Say where you looked. Already built is a `wontfix`, and the slice should point at where it lives.
- **Prior rejection**: check whether this has been ruled out before, in a closed slice or an ADR.

### 2. Recommend

Tell the user the state you would apply and why, with a short summary of what the codebase says about it. Wait.

### 3. Verify the claim

Before any grilling, check the claim holds. For a bug, reproduce it. For a change, confirm the thing it describes actually works the way the slice says. Report what happened: confirmed, with the code path; failed; or not enough detail, which is a strong `needs-info`.

A confirmed reproduction makes a far better brief than a described one.

### 4. Grill, if it needs it

If the request is underspecified, call the Skill tool twice, for "grilling" and "domain-modeling". Sharpen the terms and write them down as they land.

### 5. Apply the outcome

Set `triage:` in the slice header and write the brief into the slice body.

- **ready-for-agent** — the brief goes in the slice: what to build, the seams to test at, the acceptance criteria, and the context pointers an agent needs. No file paths that will go stale.
- **ready-for-human** — the same brief, plus why it cannot be delegated: a judgement call, external access, a design decision, manual testing.
- **needs-info** — what is established so far, and the specific questions still outstanding. Capture everything the grilling resolved so the work is not lost.
- **wontfix** — why, and where the existing implementation lives if it is already built. Close the slice with `cw close`.

### 6. Report

Say which slices changed state and what the frontier looks like now (`cw frontier <run>`).
