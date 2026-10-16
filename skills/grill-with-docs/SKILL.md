---
name: grill-with-docs
description: Stress-test a plan or design by interview, building the project's glossary and ADRs as decisions land.
disable-model-invocation: true
---

# Grill With Docs

The interview, with a paper trail. Use this whenever you are working in a repository: it runs the same technique as `grill-me` but leaves the vocabulary and the hard-to-reverse decisions written down, so the next session starts where this one finished.

Call the Skill tool twice, for "grilling" and "domain-modeling".

Before the first round, check `cw --mode`. If it reports `unconfigured`, tell the user to run `/setup-workspace` first — otherwise there is nowhere for the glossary and ADRs to go, and the paper trail is the reason to use this skill over `grill-me`.
