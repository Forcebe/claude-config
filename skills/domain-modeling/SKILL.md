---
name: domain-modeling
description: Build and sharpen a project's domain model. Use when discussing codebase terminology, challenging a fuzzy or overloaded term, writing or editing a GLOSSARY.md, or recording an architectural decision as an ADR.
---

# Domain Modeling

Actively build and sharpen the project's domain model as you design. This is the **active** discipline: challenging terms, inventing edge-case scenarios, and writing the glossary and the decisions down the moment they crystallise.

Merely *reading* `GLOSSARY.md` for vocabulary is not this skill — that is a one-line habit any skill can do. This is for when you are **changing** the model, not just consuming it.

## Where it goes

Resolve the docs root with `cw`, never hardcode it. It is `.agents/workspace/` in the repo under in-repo storage, or a sidecar outside the repo otherwise, and **the difference matters**: under sidecar storage nothing may be written into the working tree, which is the whole reason the mode exists.

```
$(cw)/
├── GLOSSARY.md
└── adr/
    ├── 0001-event-sourced-orders.md
    └── 0002-postgres-for-write-model.md
```

If `$(cw --mode)` reports `unconfigured`, say so and tell the user to run `/setup-workspace`; do not guess a location.

A `GLOSSARY-MAP.md` at the docs root means the repo has several contexts, and the map says where each one's `GLOSSARY.md` lives. Read the ones relevant to the topic.

Create files **lazily** — only when there is something to write. No glossary yet? Create it when the first term resolves. No `adr/`? Create it when the first ADR is needed.

## During the session

**Challenge against the glossary.** When a term conflicts with the language already in `GLOSSARY.md`, call it out at once: "your glossary defines cancellation as X, but you seem to mean Y — which is it?"

**Sharpen fuzzy language.** When a term is vague or overloaded, propose a precise canonical one: "you're saying *account* — do you mean the Customer or the User? Those are different things."

**Stress-test with scenarios.** When domain relationships are being discussed, invent specific scenarios that probe the edges and force precision about where one concept stops and the next starts.

**Cross-reference the code.** When the user states how something works, check whether the code agrees. Surface contradictions: "your code cancels whole Orders, but you just said partial cancellation is possible — which is right?"

**Write terms down inline.** When a term resolves, update `GLOSSARY.md` right then. Don't batch them; they decay. Use [GLOSSARY-FORMAT.md](GLOSSARY-FORMAT.md).

`GLOSSARY.md` is a glossary and nothing else. It carries no implementation detail, is not a spec, and is not a scratchpad.

## Offer ADRs sparingly

Only offer one when all three hold:

1. **Hard to reverse** — changing your mind later costs something real.
2. **Surprising without context** — a future reader will ask "why on earth did they do it this way?"
3. **A genuine trade-off** — there were real alternatives and one was chosen for stated reasons.

Miss any one and skip it. Use [ADR-FORMAT.md](ADR-FORMAT.md).
