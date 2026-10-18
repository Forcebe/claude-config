---
name: improve-codebase-architecture
description: Explore a codebase for architectural friction and module-deepening refactors.
disable-model-invocation: true
---

# Improve Codebase Architecture

Explore a codebase like an AI would, surface architectural friction, discover opportunities for improving testability, and propose module-deepening refactors.

A **deep module** (John Ousterhout, "A Philosophy of Software Design") has a small interface hiding a large implementation. Deep modules are more testable, more AI-navigable, and let you test at the boundary instead of inside.

## Process

### 1. Scope before you scan

Deepening a module pays off by making future change to it easier, so weight the search toward where change actually lands. Decide *where* to look before looking:

- If the user named a direction — a module, a subsystem, a pain point — take it and skip the inference.
- Otherwise walk back a good stretch of `git log --oneline` for the hot spots: the files and areas that keep coming up. Let those pull your attention first.
- If the history is scattered with no clear hot spot, widen the net and say so.

Read `GLOSSARY.md` at `$(cw)` and the ADRs for the area first, so the proposals use the project's own words and do not re-litigate settled decisions.

Call the Skill tool with "codebase-design" for the architecture vocabulary — module, interface, depth, seam, adapter, leverage, locality — and use those terms exactly rather than drifting into "component" or "service".

### 2. Explore the codebase

Use the Agent tool with subagent_type=Explore to navigate the codebase naturally. Do NOT follow rigid heuristics — explore organically and note where you experience friction:

- Where does understanding one concept require bouncing between many small files?
- Where are modules so shallow that the interface is nearly as complex as the implementation?
- Where have pure functions been extracted just for testability, but the real bugs hide in how they're called?
- Where do tightly-coupled modules create integration risk in the seams between them?
- Which parts of the codebase are untested, or hard to test?

The friction you encounter IS the signal.

Apply the **deletion test** to anything you suspect is shallow: would deleting it *concentrate* complexity, or merely move it? "Concentrates" is the signal worth acting on; "moves it" is churn wearing a refactor's clothes.

### 3. Present candidates

Present a numbered list of deepening opportunities. For each candidate, show:

- **Cluster**: Which modules/concepts are involved
- **Why they're coupled**: Shared types, call patterns, co-ownership of a concept
- **Dependency category**: See [REFERENCE.md](REFERENCE.md) for the four categories
- **Test impact**: What existing tests would be replaced by boundary tests

Do NOT propose interfaces yet. Ask the user: "Which of these would you like to explore?"

### 4. User picks a candidate

### 5. Frame the problem space

Before spawning sub-agents, write a user-facing explanation of the problem space for the chosen candidate:

- The constraints any new interface would need to satisfy
- The dependencies it would need to rely on
- A rough illustrative code sketch to make the constraints concrete — this is not a proposal, just a way to ground the constraints

Present this to the user, then immediately proceed to Step 5. The user reads and thinks about the problem while the sub-agents work in parallel.

### 6. Design multiple interfaces

Spawn 3+ sub-agents in parallel using the Agent tool. Each must produce a **radically different** interface for the deepened module.

Prompt each sub-agent with a separate technical brief (file paths, coupling details, dependency category, what's being hidden). This brief is independent of the user-facing explanation in Step 4. Give each agent a different design constraint:

- Agent 1: "Minimize the interface — aim for 1-3 entry points max"
- Agent 2: "Maximize flexibility — support many use cases and extension"
- Agent 3: "Optimize for the most common caller — make the default case trivial"
- Agent 4 (if applicable): "Design around the ports & adapters pattern for cross-boundary dependencies"

Each sub-agent outputs:

1. Interface signature (types, methods, params)
2. Usage example showing how callers use it
3. What complexity it hides internally
4. Dependency strategy (how deps are handled — see [REFERENCE.md](REFERENCE.md))
5. Trade-offs

Present designs sequentially, then compare them in prose.

After comparing, give your own recommendation: which design you think is strongest and why. If elements from different designs would combine well, propose a hybrid. Be opinionated — the user wants a strong read, not just a menu.

### 7. User picks an interface (or accepts recommendation)

### 8. Present the refactor proposal

Present the complete refactor proposal using the template in [REFERENCE.md](REFERENCE.md). Ask the user whether they want to:

- **Implement now** — proceed with the refactor immediately
- **Save for later** — the user will triage this into issues themselves
