# Code comments

Write fewer, leaner comments. The code should speak for itself.

- Comment the **why**, never the **what**. If a comment just restates what the code plainly does, delete it.
- Only comment where it's genuinely needed: non-obvious intent, a deliberate tradeoff, a workaround, or a surprising constraint. Default to no comment.
- Prefer making the code self-explanatory — clear names, small functions — over explaining it in prose.
- Never reference tickets, PRs, or issue IDs in comments; they go stale. That context belongs in the commit message or PR description.
- Clean as you go: when you touch a file, apply the same bar to the existing comments nearby — remove or fix ones that are redundant, stale, or describe the what.

# PR descriptions

Write for a reader who doesn't know the repo, and keep it concise.

- Describe what the PR literally delivers ("adds the API endpoints for sending…"), not a user capability it doesn't ship yet ("clinicians can now send…").
- **Why** is the product goal in plain words, not a description of a gap in the code.
- Use plain, explicit sentences with a subject and a verb ("Cancelling a requisition does not delete the PDF"), not terse shorthand ("Cancel keeps the PDF") or metaphor ("frozen"; say "can no longer be edited").
- Be concrete: name the table a migration changes, say when something is an environment variable, and give exact accepted values ("anything other than `true`"), not "off".
- Introduce each table with a sentence saying what it shows, and give it headers that stand on their own. "Allowed from" and "Result" were ambiguous: from what? Result stored, returned, or happened?
- Leave out refactor trivia and step-by-step smoke-test logs.
