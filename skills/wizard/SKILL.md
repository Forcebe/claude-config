---
name: wizard
description: Generate an interactive script that walks a human through steps only they can take.
disable-model-invocation: true
---

# Wizard

A **wizard** is a script that walks a human through a manual procedure which is tedious to do by hand and more tedious to re-explain to an agent every time: provisioning infrastructure, setting up credentials or CI secrets, clicking through an unfamiliar dashboard, running a one-off migration.

**Only for steps a human must take.** If the agent could do it, the agent should do it. This exists for the wall only a person can pass.

A wizard is ephemeral by default: built for one run, written to the scratch directory, deleted when the job is done. Commit it only when it is a repeatable setup path the next person should run instead of asking an agent.

## Process

### 1. Scope it

Work out every manual step, and every value captured along the way. Read before asking: `.env`, `.env.example`, the README, compose files, framework config, and `.github/workflows/*` — every `secrets.*` and `vars.*` reference is a value the wizard must produce.

Show the user the ordered stages and the values each produces. They may add, drop or reorder.

**Done when** every stage is named in order and, for each value, you know where the human gets it, where it is written, and whether it is secret.

### 2. Map each journey

For each stage write the precise path: which URL, what to do there, where the value appears, which variable it fills. "Dashboard → Developers → API keys → Reveal → copy."

Where you do not actually know the current UI or the exact command, **say so and ask**. Never invent steps that may not exist: a wizard that sends someone to a page that is not there is worse than no wizard, because they will trust it.

**Done when** every stage traces to instructions a stranger could follow.

### 3. Write it

One stage per step, in dependency order. Hold this bar:

- Open the URL **before** asking for the value it yields.
- Hide secret entry, and never echo a secret back.
- Write every persisted value where step 1 said it goes.
- Confirm before anything irreversible.
- Keep each stage to one focused task, so nothing the human still needs scrolls away.
- Show progress: which stage this is, and how many remain.

### 4. Verify and hand off

Run `bash -n` over it, and `shellcheck` if available. Make it executable.

**Do not run it end to end yourself.** It opens browsers and blocks on input. Trace it statically instead: every value from step 1 is captured and lands where step 1 said, and every secret name matches a reference in CI exactly.

Then tell the user how to run it.
