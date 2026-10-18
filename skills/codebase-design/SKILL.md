---
name: codebase-design
description: Shared vocabulary for designing deep modules. Use when designing or improving a module's interface, deciding where a seam goes, making code more testable, or when another skill needs the deep-module language.
---

# Codebase Design

Design **deep modules**: a lot of behaviour behind a small interface, placed at a clean seam, testable through that interface. This is a reference to consult, not a session to run — `/tdd` and `/improve-codebase-architecture` both reach for it.

## Use these words exactly

Consistent language is the whole point. Don't substitute "component", "service", "API" or "boundary".

**Module** — anything with an interface and an implementation. Deliberately scale-agnostic: a function, a class, a package, a slice spanning tiers. *Not*: unit, component, service.

**Interface** — everything a caller must know to use the module correctly. The type signature, but also invariants, ordering constraints, error modes, required configuration and performance characteristics. *Not*: API, signature, which name only the type-level surface.

**Implementation** — what is inside the module. Distinct from an **adapter**: a thing can be a small adapter over a large implementation (a Postgres repository) or a large adapter over a small one (an in-memory fake).

**Depth** — leverage at the interface: how much behaviour a caller or a test can exercise per unit of interface they must learn. **Deep** is a lot of behaviour behind a small interface; **shallow** is an interface nearly as complex as what it hides.

**Seam** — a place where behaviour can be altered without editing in that place; where a module's interface lives. Where to put the seam is its own decision, separate from what goes behind it. *Not*: boundary, which is overloaded by bounded context. This is the same word `/tdd` and `/to-spec` use for where a test is written.

**Adapter** — a concrete thing satisfying an interface at a seam. Names a role, not a substance.

**Leverage** — what callers get from depth: more capability per unit of interface learned. One implementation pays back across every call site and every test.

**Locality** — what maintainers get from depth: change, bugs and verification concentrate in one place. Fix once, fixed everywhere.

## Principles

**The deletion test.** Suspect a module is shallow? Ask whether deleting it would *concentrate* complexity or merely move it. Concentrating is the signal worth acting on; moving it is churn.

**The interface is the test surface.** If a module is painful to test, that is a fact about its interface, not about testing. Deepen the module rather than reaching for mocks.

**One adapter is a hypothetical seam; two is a real one.** A seam with a single implementation is a guess about the future. Do not build for the second adapter until it exists.

**Design it twice.** Before committing to an interface, sketch a radically different one. The second sketch is not a candidate so much as a way of finding out what the first one assumed.

## References

- [deep-modules.md](deep-modules.md) — what depth looks like, with examples
- [interface-design.md](interface-design.md) — designing interfaces for testability
- [refactoring.md](refactoring.md) — what to look for after green
