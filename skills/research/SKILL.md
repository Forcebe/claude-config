---
name: research
description: Investigate a question against primary sources and capture the findings as a cited Markdown file. Use when the user wants a topic researched, API or documentation facts gathered, or reading legwork delegated so they can keep working.
---

# Research

Spin up a **background agent** to do the reading, so the session keeps moving while it works.

Its job:

1. **Investigate against primary sources** — official documentation, source code, specifications, first-party APIs — never a secondary write-up of them. Follow every claim back to the source that owns it, and say so when a claim has no such source.
2. **Write the findings to a single Markdown file**, citing the source for each claim.
3. **Save it under `$(cw --state)/research/`**, creating the directory if needed.

That path is shared by every worktree of the repo, is never committed, and never appears in `git status` — which is what lets research happen in a shared repo without the repo gaining anything. On a personal repo in in-repo storage, `$(cw)/research/` is the alternative if the notes are worth versioning; ask rather than assume.

Report the path and a short summary when the agent returns. The file is the deliverable; don't paste it into the conversation.

Research **feeds** the thinking, it does not replace it. What comes back is material to take into grilling or a spec, not a decision in itself.
