# Self-Review Handoff Format

The shared contract for the writer↔reviewer negotiation loop. `self-review` seeds and adjudicates this file; `apply-review` responds to it. Both skills read this spec so the format never drifts.

## Location

One file per branch: `.claude/reviews/<branch>.md`. Replace `/` in the branch name with `-` (e.g. `feat/PROJ-123` → `.claude/reviews/feat-PROJ-123.md`). Create the `.claude/reviews/` directory if it doesn't exist.

## Lifecycle & cleanup

These threads are local working artifacts. They must never be committed or pushed.

- **On create (seed):** also write `.claude/reviews/.gitignore` containing a single line `*`. That ignores everything in the directory — including the thread files and the `.gitignore` itself — so the whole mechanism leaves zero git footprint and never appears as untracked. Only write it if it isn't already there.
- **Never stage it.** No move may `git add`, commit, or push anything under `.claude/reviews/`. If you notice a thread file is already tracked in this repo (it shouldn't be), stop and tell the human rather than committing over it.
- **On close:** when the human gives final approval, `rm` the thread file for the branch. Leave the `.gitignore` in place so the next review is pre-protected.
- **On discard:** if the human abandons the review ("discard the review", "delete the review thread"), `rm` the thread file the same way. Confirm the file before deleting if there's any ambiguity about which branch.

## Design goal: resist the lazy approval

The human triggers every turn and is the final approver, so the file's top section is the only part they're guaranteed to read. Build it to stop a reflexive "LGTM" on something not actually understood:

- **Lead with what needs a decision.** Unresolved conflicts and escalations go at the very top, never buried under resolved noise.
- **Render every conflict as two short claims, side by side** — writer says X, reviewer says Y. The human adjudicates a stated disagreement, never rubber-stamps prose.
- **Show a live count** of findings needing a decision, so a `(0)` turn is provably safe to wave through and a `(2)` turn is loud.
- **Collapse resolved items to one line.** Detail lives below for drill-in, not in the digest.
- **Block "done" while anything is unresolved.** See [Approval](#approval).

## File structure

Two layers: the **digest** (regenerated on every turn) and the **findings** (the durable per-item threads).

### Digest

Regenerate this block from scratch each turn. Exact layout:

```markdown
## Review thread: <branch>  ·  turn <n> (<who> <move>)

### ⚠ Needs your decision (<count>)
- #<id> <STATUS> — <one-line topic>
    writer:   "<one sentence>"
    reviewer: "<one sentence>"
- ...
(omit this whole section when count is 0)

### Resolved this turn (<count>)
#<id> fixed ✓  #<id> accepted ✓  #<id> stale ✓
(one line; omit if none)

### Still open, no conflict (<count>)
- #<id> <STATUS> — awaiting <writer fix | reviewer adjudication>
(omit if none)

### All clear
(show this line only when every finding is terminal — see Approval)
```

The `Needs your decision` section appears for findings in `DEADLOCKED`/`NEEDS-HUMAN`, and for any `HELD` or `REOPENED` item the human asked to be looped in on. Sort by severity within it.

### Findings

Below the digest, under a `## Findings` heading, one block per finding. Order by id. The header line carries the mutable state; the thread records history.

```markdown
#### #<id> · <STATUS> · <Critical|Warning|Suggestion> · [<Domain>, <Domain>]
`<file>:<line-start>-<line-end>`
**Claim:** <what's wrong, one or two sentences>
**Recommendation:** <what to do>
**Snippet (at seed):**
​```<lang>
<the cited code as it stood when the finding was raised>
​```
**Thread:**
- turn 1 · reviewer · seed — raised
- turn 2 · writer · <FIXED|DISPUTE|STALE> — <note>
- turn 3 · reviewer · <RESOLVED|REOPENED|ACCEPTED|HELD|confirm-stale> — <note>
```

The seed snippet is load-bearing: `apply-review` checks the current code against it to detect staleness, and the reviewer uses it to judge whether a "stale" claim is honest.

## Status state machine

```
OPEN ──writer fixes──▶ ADDRESSED ──reviewer──▶ RESOLVED ✓
  │                                    └──────▶ REOPENED ──(back to writer)
  ├──writer disputes──▶ DISPUTED ──reviewer──▶ ACCEPTED ✓   (reviewer drops it)
  │                                    └──────▶ HELD + rebuttal ──(back to writer)
  └──writer: stale────▶ STALE ──────reviewer──▶ confirmed ✓ / REOPENED
```

| Status | Set by | Meaning |
|--------|--------|---------|
| `OPEN` | reviewer (seed) | Raised, awaiting writer |
| `ADDRESSED` | writer | Fixed in code, awaiting reviewer |
| `DISPUTED` | writer | Writer pushes back with a reason, awaiting reviewer |
| `STALE` | writer | Writer says the finding no longer applies |
| `RESOLVED` ✓ | reviewer | Fix accepted — terminal |
| `ACCEPTED` ✓ | reviewer | Reviewer drops the finding (writer's pushback stands) — terminal |
| `REOPENED` | reviewer | Fix or stale-claim rejected, back to writer |
| `HELD` | reviewer | Reviewer holds the finding with a rebuttal, back to writer |
| `DEADLOCKED` / `NEEDS-HUMAN` | either | Escalated to the human — terminal until the human rules |

Terminal: `RESOLVED`, `ACCEPTED`, confirmed-`STALE`. A finding is "done" only in a terminal state or after a human ruling.

## Deadlock cap

Count the DISPUTED↔HELD round-trips on a finding. After **2 full rounds** without convergence, the reviewer must set it `DEADLOCKED` and stop arguing — surface it in the digest's `Needs your decision` section with both final positions. Agents entrench; they rarely converge by attrition. Don't burn turns past the cap.

## Writer dispositions (apply-review)

For each `OPEN`/`REOPENED`/`HELD` finding, the writer picks exactly one, re-reading the current code first:

- **FIXED** — made the change → `ADDRESSED`. Note what changed.
- **DISPUTE** — disagrees, with a concrete reason → `DISPUTED`.
- **STALE** — code no longer matches the seed snippet and the issue is gone → `STALE`. Note what changed it.

## Reviewer adjudications (self-review, adjudicate mode)

For each `ADDRESSED`/`DISPUTED`/`STALE` finding, re-read the current code and rule:

- On `ADDRESSED`: `RESOLVED` if the fix holds, else `REOPENED` with what's still wrong.
- On `DISPUTED`: `ACCEPTED` if the pushback is reasonable, else `HELD` with a rebuttal.
- On `STALE`: confirm (terminal) if the code genuinely moved, else `REOPENED`.
- Apply the [deadlock cap](#deadlock-cap).

## Approval

No move marks the review complete — only the human does. Adjudicate/apply moves must **refuse to declare the thread done** while any finding is non-terminal or `DEADLOCKED`/`NEEDS-HUMAN`. To close out an escalated finding the human types a verdict per item (e.g. "accept #4's pushback", "hold #1, writer must fix"); the next reviewer turn records it as `ACCEPTED`/`REOPENED` accordingly.
