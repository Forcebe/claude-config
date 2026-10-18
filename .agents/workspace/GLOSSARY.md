# Glossary

The vocabulary of the agent workspace. Most of these words were invented for
this project, so they drift easily; `tests/glossary.sh` checks the rejected
synonyms do not come back.

## Agent workspace

The whole per-repository arrangement of agent files: domain docs, run state and
the config that says where they live. Not a single directory — the parts live
in different places on purpose.

## Blocking edge

The relation recorded in a ticket's `blocked-by` header. A ticket is unblocked
when every ticket named there is `done`.

**Not**: "dependency". Blocking is about ordering work, not about code.

## Claim

A directory under a run's `claims/`, created with `mkdir` so that exactly one
of two racing worktrees wins. Its presence *is* the claim; the `holder` file
inside only records who took it.

**Not**: "lock". The mechanism is a lock; the thing a session holds is a claim.

## Docs root

Where a repository's domain docs live — `config.md`, `tracker.md`,
`domain.md`, `GLOSSARY.md`, `adr/`. Printed by `cw`. Under in-repo storage it
is `.agents/workspace/` in the current worktree; otherwise it is the sidecar.

**Not**: "workspace root".

## Frontier

The tickets of a run that are open, unblocked and unclaimed: what can be
started right now. Printed by `cw frontier`.

## PRD

The team's product requirements document, which at TMRW lives in Slite. An
**input** to this workflow, written by people, read by `/grill-issue`.

Distinct from a **spec**, which is what `/to-spec` writes. A PRD describes what
the business wants; a spec describes what will be built. Do not use "PRD" for
the output of `/to-spec`.

## Publish

The deliberate act of putting something on Linear. Never automatic, and never
carries anything about this workflow — no triage state, no claims, no blocking
edges, no labels.

## Run

One effort being built: a spec, the tickets that deliver it, and the claims
against them. Lives at `$(cw --state)/runs/<slug>/` and is referred to by its
slug.

## Run graph

The tickets of a run together with their blocking edges — the execution
surface. Held entirely in the run state, never on Linear.

**Not**: "task graph".

## Run state

Where the run graph and claims live: `$(cw --state)`, inside the repository's
shared git directory. Shared by every worktree, never committed, invisible to
`git status`.

Distinct from the **docs root**. Domain docs follow the storage mode; run state
never does, because two worktrees that cannot see each other's claims cannot
coordinate.

## Seam

A place where behaviour can be observed or altered without editing in that
place — where a module's interface lives. Tests are written at seams because
observation from outside is exactly what a seam affords.

Where to put a seam is its own design decision, separate from what goes behind
it. Seams are named and agreed before any test is written: a spec sketches
them, `/tdd` consumes them, and `/codebase-design` elaborates the design side.

**Not**: "boundary", which is overloaded by bounded context.

## Sidecar

The directory outside a repository that holds its domain docs under sidecar
storage: `~/.claude-workspace/<owner>--<repo>`. A repo in in-repo storage has
none.

## Spec

What `/to-spec` writes: the problem, the solution, the user stories, and the
decisions taken. Lives in the run as `spec.md`.

**Not**: "PRD" (see above).

## Stack-parent

The ticket whose branch another ticket's branch is based on, when a run's
blocking edges form a chain. Those tickets become a stack of pull requests.

## Storage mode

Where a repository's domain docs live: `in-repo`, `sidecar`, or `unconfigured`.
Not recorded as a value anywhere — implied by which `config.md` exists.

## Ticket

One vertical slice of a run, one markdown file, with a header carrying its
status and blocking edges. The unit a session claims and builds.

**Not**: "issue", "task", "work item". An **issue** is a Linear issue, which is
a different thing on a different layer; a ticket never becomes one implicitly.

## Triage state

A ticket's readiness, in its `triage:` header: `needs-info`,
`ready-for-agent`, `ready-for-human`, `wontfix`. Local, and never published.

## User-invoked / model-invoked

Whether a skill can be reached only by a human typing its name
(`disable-model-invocation: true`) or also by another skill calling the Skill
tool. A user-invoked skill can never be called by another skill, which is the
invariant the whole split rests on.

## Vertical slice

A ticket that cuts a narrow but complete path through every layer, so finishing
it leaves something demoable. Also called a **tracer bullet**.

**Not**: a horizontal slice of one layer.
