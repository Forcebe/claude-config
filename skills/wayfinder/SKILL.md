---
name: wayfinder
description: Chart a piece of work too big and too foggy for one session as a map of open decisions, then resolve them one at a time until the way is clear.
disable-model-invocation: true
---

# Wayfinder

A loose idea has arrived, too big for one session and wrapped in fog: the way from here to the **destination** is not visible yet. Wayfinding is about finding that way, not charging at the destination.

This is the most demanding flow here, and it is slower and denser than the rest. Use it for the idea you cannot hold in one session. For a well-scoped feature, `/grill-with-docs` then `/to-spec` is the right route and this one is overkill.

## What a map produces

A map produces **a decision, or a set of decisions, written down** — never code and never a built thing. It is finished when someone could pick up the decisions and go and build, with nothing left to work out.

Name the **destination** first, in one line, as the artefact that ends the effort. Concretely:

- "A spec for the referrals rebuild that `/to-spec` can turn into slices."
- "A decision on whether notifications go through the existing event bus or a new one, with the reasoning recorded as an ADR."
- "The requisition tables migrated to the new shape, with the cutover sequence agreed."

If you cannot write the destination as a thing that will exist when this is over, the effort is not ready for a map — grill it until you can.

## Plan, don't do

Wayfinder **produces decisions, not deliverables**. Each slice resolves a question; the map is finished when nothing is left to decide and someone could go and build the thing. The pull to just do the work is usually the signal you have reached the edge of the map and it is time to hand off — merge onto the main flow at `/to-spec`, which collapses the decisions into something buildable.

A map can override this in its **Notes** and carry execution, but absent that, decide rather than deliver.

## A map is a run

There is no separate machinery. A map is a run under `$(cw --state)/runs/<slug>/`, so the frontier, claims and blocking edges all work exactly as they do for a build. What differs is what the slices produce.

`run.md` carries the map:

```markdown
# <map title>

kind: wayfinder
linear:

## Destination

What reaching the end of this map looks like: the spec, the decision, or the
change this effort is finding its way to. One or two lines. Every session
orients to it before choosing a slice.

## Notes

The domain. Skills every session should consult. Standing preferences.

## Decisions so far

<!-- one line per closed slice: enough to judge relevance, then open the
     slice for the detail. A decision lives in exactly one place. -->

- **<slice title>**: <one-line gist of the answer>

## Not yet specified

<!-- fog: in-scope questions you cannot phrase sharply enough to slice yet -->

## Out of scope

<!-- ruled beyond the destination. Closed, and never graduates. -->
```

The map is an **index, not a store**. A decision lives in its slice; the map gists it and points. Open slices are not listed — they are found with `cw frontier <slug>`.

Refer to slices by **title** in anything a human reads. A wall of ids is illegible.

## Slice types

Each slice carries `type:` in its header, one of:

- **research** (AFK) — a fact a decision waits on, outside this working directory. Resolved by calling the Skill tool with "research". The only type that may be resolved several at a time, in parallel.
- **prototype** (with a human) — raise the fidelity of the argument by making something cheap and concrete to react to. Call the Skill tool with "prototype". The branch stays local and the pointer goes on the slice.
- **grilling** (with a human) — conversation. The default. Call the Skill tool twice, for "grilling" and "domain-modeling".
- **task** (either) — manual work that must happen before a decision can be made: provisioning access, signing up for a service so its API can be judged, moving data so its shape can be seen. The one type that *does* rather than decides, and it earns its place by unblocking a decision.

A slice worked **with a human** only resolves through that exchange. An agent that answers its own grilling questions has broken the type.

## Fog of war

The map is deliberately incomplete. Beyond the live slices is fog: questions you can tell are coming but cannot yet pin down, because they hang on answers you do not have. **Not yet specified** is where that is written down.

The test is whether you can state the question **precisely now**, not whether you can answer it.

- **Slice it** when the question is already sharp, even if it is blocked.
- **Leave it in the fog** when you cannot phrase it that sharply. Do not carve fog up in advance; one patch may graduate into several slices, or none.

Resolving a slice clears the fog ahead of it. Graduate whatever has become specifiable into real slices and delete that patch from **Not yet specified**, so it lives in exactly one place.

## Out of scope

Fog only gathers *toward* the destination. Work beyond it is out of scope — a scoping act, not a step on the route. When an existing slice turns out to sit past the destination, **close it** and leave one line under **Out of scope** with the gist and why. It stays out of **Decisions so far**, which records the route actually walked.

## Chart a map

The user arrives with a loose idea.

1. **Name the destination.** Call the Skill tool twice, for "grilling" and "domain-modeling". The destination fixes the scope, so settle it first.
2. **Map the frontier.** Grill again, **breadth-first** this time: fan out across the whole space rather than deep on one thread. **If this surfaces no fog** — the way is already clear and the whole journey fits one session — you do not need a map. Say so and stop.
3. **Create the run** with `run.md` as above, Decisions-so-far empty and the fog sketched into Not yet specified.
4. **Write the slices you can specify now**, with their `type:` and their blocking edges. Check the result with `cw frontier <slug>`.
5. **Fire the research slices.** For each, call the Skill tool with "research" so they resolve in parallel while you stop.
6. **Stop.** Charting is one session's work and resolves nothing by hand.

## Work through a map

The user arrives with a map, and optionally a slice. Without one, you pick — the frontier decides, not the user.

1. Read `run.md`. The low-resolution view, not every slice body.
2. Take a slice from `cw frontier <slug>` and **claim it** before any work.
3. Resolve it as its `type:` says. Read the type, not just the body. Zoom into closed slices on demand for detail the map only gists.
4. Record the answer in the slice, `cw close <slug> <slice>`, and append one line to **Decisions so far**.
5. Graduate any fog the answer made specifiable, clearing those patches from **Not yet specified**. If the answer puts a slice beyond the destination, rule it out of scope rather than resolving it.

**Never resolve more than one slice per session**, research excepted. The context a decision needs is the context the next decision will contradict.

## Publishing

A map is local. It is half-formed by construction, and a team board is the wrong place for thinking out loud.

When an effort stops being exploratory and the team needs to see it, publish deliberately: one Linear issue for the map carrying its Destination and Decisions so far, and a sub-issue per slice that is genuinely work the team should track. **No labels**, no slice types, no blocking edges, no claims — the same rule as everywhere else, and a `wayfinder:*` label would be exactly the workflow marker Linear must not carry.

Record the issue id in `run.md` as `linear:`. After publishing, Linear is canonical for anything the team reads; the local map keeps the fog and the decision detail, which are yours.
