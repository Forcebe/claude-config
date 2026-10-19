---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
disable-model-invocation: true
argument-hint: "What will the next session be used for?"
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work.

Save it to `$(cw --state)/handoffs/<short-slug>.md`, creating the directory if needed. That path is shared by every worktree of the repo and is never committed, so a handoff written in one worktree can be picked up in another, and it survives `wt-rm`. Outside a git repository, fall back to a path from `mktemp -t handoff-XXXXXX.md`.

Include a **suggested skills** section naming the skills the next agent should call the Skill tool for, if any.

Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead. If the work is part of a run, point at the run and the slice rather than restating them.

Redact anything sensitive: API keys, tokens, passwords, personal data.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.

Tell the user the path when you are done.
