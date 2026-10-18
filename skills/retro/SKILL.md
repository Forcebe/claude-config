---
name: retro
description: Look back over a session and improve the agent's environment, not the code.
disable-model-invocation: true
---

# Retro

A retrospective on a coding session. The output is changes to the **environment** an agent works in — navigation, checks, standards, tooling — never changes to the feature that was built.

Run it in the session being looked back on, before clearing. Afterwards, point it at that session's log instead.

## Process

1. Read the primary sources for the session. Default to the current one unless the user names another.

2. Look for candidates in these categories, and say which applies:

   - **Navigation** — how long did it take to find the right file? Would a pointer in `CLAUDE.md` or the workspace config have saved it? *When* the session spent a long time looking.
   - **Automated checks** — could a check have caught the mistake? Read the repo's existing `lint` / `typecheck` / `test` scripts and its CI first: a check that exists but sits unwired or silently broken is the finding, not a reinvention. A repo with no guardrail at all is itself a finding.
   - **Coding standards** — classify the violation before writing a rule. A **mechanical** one (a banned API, an import shape, a file-location rule) gets a deterministic check, full stop. Reserve written standards for **judgement calls** no check could substitute for. *When* review missed something.
   - **Steering files** — instructions that no longer change behaviour, or that belong in a check instead. *When* `CLAUDE.md` has grown unwieldy.
   - **Tool economy** — expensive or chatty tool calls that could have been one command. *When* the session burned context on retrieval.
   - **Information access** — something the agent could not see and should have: logs, read-only access, a `cw` path it was not permitted to resolve. *When* a crucial fact was unavailable.

3. Present the candidates in order of severity, each with the evidence from the session that prompted it. **A retro proposes; it does not start making the changes.**

## Where findings go

A finding about **this workflow** belongs in the workspace: `$(cw)/config.md` for a standing fact about the repo, an ADR for a decision with a real trade-off, `GLOSSARY.md` for a term that keeps drifting.

A finding about **the repo's own conventions** belongs in the repo — which on a shared repo means raising it with the team, not writing it yourself.

## Implementation and review carry different pressure

The implementing agent carries the most context pressure: it explores, writes and debugs. The reviewing agent carries the least, because it receives a diff.

So standards belong on the reviewer, not the implementer. A rule added to `CLAUDE.md` costs every session; the same rule enforced at review costs one.
