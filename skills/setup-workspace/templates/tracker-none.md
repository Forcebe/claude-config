# Issue tracker: none

This repo has no team-facing issue tracker, which is the normal case for a solo repo.

## When a skill says "publish to the issue tracker"

There is nowhere to publish. Keep the work in the run graph, which lives in the run state that `cw --state` prints, and tell the user that is where it landed, rather than inventing a tracker or writing anything into the repo.

## When a skill says "fetch the relevant ticket"

Read it from the run graph. If the user passed a path or a slug, resolve it there.
