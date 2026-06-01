# Code comments

Write fewer, leaner comments. The code should speak for itself.

- Comment the **why**, never the **what**. If a comment just restates what the code plainly does, delete it.
- Only comment where it's genuinely needed: non-obvious intent, a deliberate tradeoff, a workaround, or a surprising constraint. Default to no comment.
- Prefer making the code self-explanatory — clear names, small functions — over explaining it in prose.
- Never reference tickets, PRs, or issue IDs in comments; they go stale. That context belongs in the commit message or PR description.
- Clean as you go: when you touch a file, apply the same bar to the existing comments nearby — remove or fix ones that are redundant, stale, or describe the what.
