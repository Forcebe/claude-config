---
name: tdd
description: This skill should be used when the user asks to "use TDD", "write tests first", "red-green-refactor", "test-driven development", "build with TDD", or wants to build features or fix bugs using a test-first, red-green-refactor workflow.
---

# Test-Driven Development

## Philosophy

**Core principle**: Tests should verify behavior through public interfaces, not implementation details. Code can change entirely; tests shouldn't.

**Good tests** are integration-style: they exercise real code paths through public APIs. They describe _what_ the system does, not _how_ it does it. A good test reads like a specification — "user can checkout with valid cart" tells exactly what capability exists. These tests survive refactors because they don't care about internal structure.

**Bad tests** are coupled to implementation. They mock internal collaborators, test private methods, or verify through external means (like querying a database directly instead of using the interface). The warning sign: a test breaks on refactor, but behavior hasn't changed. If renaming an internal function causes test failures, those tests were testing implementation, not behavior.

See [tests.md](tests.md) for examples and [mocking.md](mocking.md) for mocking guidelines.

## Seams: where tests go

A **seam** is the public boundary you test at — the interface where behaviour can be observed without reaching inside. Tests live at seams, never against internals.

**Name the seams before writing any test.** State which seams you are testing at and what each one catches, then get on with it. You cannot test everything, so naming them up front is what puts the effort on critical paths and complex logic instead of spreading it over every edge case.

**Only stop and ask when there is a real fork** — two seams with a genuine trade-off between them, or a new seam that would change the shape of the code. Confirming an obvious choice every time is friction, not rigour.

Before you start, check your own proposal both ways: would this miss a critical path or a branch of complex logic, and is any of it testing something trivial twice? Say what you concluded.

When the shape of the interface is itself in question — how deep the module is, where the seam belongs, what it should expose — call the Skill tool with "codebase-design". It owns that vocabulary and the references that go with it.

Ask: "what is the public interface here, and which seams should we test?" Give each proposed seam a one-line note on what it catches and what it misses.

Prefer existing seams to new ones, and use the highest seam that can still observe the behaviour. The fewer seams across the codebase, the better — the ideal is one.

A spec written by `/to-spec` already sketches the seams for the feature. Use those rather than inventing new ones mid-build — if a sketched seam turns out to be wrong, say so and re-agree it, don't quietly test somewhere else.

## Anti-Pattern: Horizontal Slices

**DO NOT write all tests first, then all implementation.** This is "horizontal slicing" - treating RED as "write all tests" and GREEN as "write all code."

This produces **crap tests**:

- Tests written in bulk test _imagined_ behavior, not _actual_ behavior
- Bulk tests end up testing the _shape_ of things (data structures, function signatures) rather than user-facing behavior
- Tests become insensitive to real changes — they pass when behavior breaks, fail when behavior is fine
- Writing all tests first means committing to test structure before understanding the implementation

**Correct approach**: Vertical slices via tracer bullets. One test → one implementation → repeat. Each test responds to what was learned from the previous cycle. Having just written the code makes it clear what behavior matters and how to verify it.

```
WRONG (horizontal):
  RED:   test1, test2, test3, test4, test5
  GREEN: impl1, impl2, impl3, impl4, impl5

RIGHT (vertical):
  RED→GREEN: test1→impl1
  RED→GREEN: test2→impl2
  RED→GREEN: test3→impl3
  ...
```

## Workflow

### 1. Planning

Before writing any code:

- [ ] Confirm with the user what interface changes are needed
- [ ] Write down the **seams** under test and confirm them (see [Seams](#seams-where-tests-go))
- [ ] Confirm with the user which behaviors to test (prioritize)
- [ ] Identify opportunities for deep modules: a small interface over a lot of implementation
- [ ] Design the interface for testability
- [ ] List the behaviors to test (not implementation steps)
- [ ] Get user approval on the plan

Ask: "What should the public interface look like? Which behaviors are most important to test?"

**Not everything can be tested.** Confirm with the user exactly which behaviors matter most. Focus testing effort on critical paths and complex logic, not every possible edge case.

### 2. Tracer Bullet

Write ONE test that confirms ONE thing about the system:

```
RED:   Write test for first behavior → test fails
GREEN: Write minimal code to pass → test passes
```

This is your tracer bullet - proves the path works end-to-end.

### 3. Incremental Loop

For each remaining behavior:

```
RED:   Write next test → fails
GREEN: Minimal code to pass → passes
```

Rules:

- One test at a time
- Only enough code to pass current test
- Don't anticipate future tests
- Keep tests focused on observable behavior

### 4. Refactor

After all tests pass, look for refactor candidates:

- [ ] Extract duplication
- [ ] Deepen modules (move complexity behind simple interfaces)
- [ ] Apply SOLID principles where natural
- [ ] Consider what new code reveals about existing code
- [ ] Run tests after each refactor step

**Never refactor while RED.** Get to GREEN first.

## Anti-Pattern: Tautological Tests

A test is **tautological** when its expected value is computed the way the code computes it, so it passes by construction and can never disagree with the implementation. It will survive any bug that is consistent with itself.

```typescript
// BAD: the expectation re-derives the answer the same way
test("calculateTotal sums line items", () => {
  const items = [{ price: 10 }, { price: 5 }];
  const expected = items.reduce((sum, i) => sum + i.price, 0);
  expect(calculateTotal(items)).toBe(expected);
});

// GOOD: the expectation is an independent, known value
test("calculateTotal sums line items", () => {
  expect(calculateTotal([{ price: 10 }, { price: 5 }])).toBe(15);
});
```

Expected values must come from an **independent source of truth**: a literal you worked out yourself, a worked example, the spec, a known-good fixture. The same failure hides in a snapshot generated by the code it is meant to check, and in an assertion that restates the implementation's own formula.

The test: if the implementation were subtly wrong, could this assertion still pass? If yes, it is tautological.

## Checklist Per Cycle

```
[ ] Seam is one the user agreed to
[ ] Test describes behavior, not implementation
[ ] Test uses public interface only
[ ] Expected value comes from outside the implementation
[ ] Test would survive internal refactor
[ ] Code is minimal for this test
[ ] No speculative features added
```
