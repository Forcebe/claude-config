# ADR format

One decision per file, at `$(cw)/adr/NNNN-kebab-title.md`, numbered in sequence
from `0001`. Numbers are never reused, and a superseded ADR is kept and marked
rather than deleted — the record of what was decided and later changed is the
point.

```markdown
# 0007. Event-sourced orders

**Status**: accepted | superseded by [0012](0012-....md)
**Date**: 2026-10-16

## Context

What was true that forced a decision. The constraint, the pressure, the thing
that made the obvious approach not work.

## Decision

What was decided, in the present tense: "Orders are stored as an append-only
event log."

## Consequences

What this makes easy, what it makes hard, and what it rules out. Be honest
about the costs — an ADR that lists only benefits is marketing.

## Alternatives considered

Each option that was genuinely on the table, and the specific reason it lost.
"We didn't consider anything else" means this is not an ADR.
```

Use the glossary's vocabulary for domain terms.
