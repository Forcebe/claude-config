---
name: diagnosing-bugs
description: Work a bug that resists a first glance — the intermittent flake, the regression between two known-good states.
disable-model-invocation: true
---

# Diagnosing Bugs

For the bugs that resist. A bug you can see from the stack trace does not need this; reach for it when the first look failed, when it only happens sometimes, or when it crept in between two states that both worked.

The discipline is one rule: **do not theorise until you can make it go red on demand.** Every hour spent reasoning about a bug you cannot reproduce is a guess, and guesses are expensive because they are plausible.

## 1. Build a feedback loop

The goal is **one command that goes red on this bug, now**, and green when it is fixed. Nothing else happens until that exists.

In rough order of preference:

1. A failing test at an existing seam.
2. A failing test at a new seam, if one is cheap. If it is not cheap, that is a finding in itself — call the Skill tool with "codebase-design" and say so.
3. A script that drives the real system and asserts the symptom.
4. A manual sequence you can repeat exactly, written down, as a last resort.

**Tighten it.** A loop that takes two minutes will be run ten times; one that takes two seconds will be run two hundred. Cut setup, shrink fixtures, narrow scope — the loop's speed sets how many hypotheses you can afford.

**If it is intermittent**, do not lose the reproduction to chance. Run it in a loop until it fails and capture everything from the failing run. A flake reproduced once by luck and not captured is worse than no reproduction, because it feels like progress.

**If you genuinely cannot build a loop**, stop and say so rather than proceeding on theory. Ask for what would make one possible: access, logs, a dataset, a failing environment.

## 2. Reproduce, then minimise

With the loop red, cut everything that is not needed to keep it red. Each removal that keeps it red narrows the search; each one that turns it green has just told you something.

Minimising is not tidying. Stop when removing anything else makes it green.

## 3. Hypothesise

Only now. Write down what you think is happening, in one sentence, **as something that could be wrong**. "The cache returns a stale row because the invalidation runs before the write commits" is a hypothesis. "Something is wrong with caching" is not.

Rank by what the loop can distinguish most cheaply, not by what feels most likely.

## 4. Instrument

Add the observation that would separate the top hypotheses. Log the value, assert the invariant, print the ordering.

Instrument to **discriminate**, not to look around. If a log line cannot change which hypothesis you believe, do not add it.

## 5. Fix, with a regression test

Make the loop go green. Then make the loop permanent: the reproduction becomes a test that would have caught this, written at an agreed seam. Call the Skill tool with "tdd" if the fix is large enough to want its own cycle.

A fix without a regression test has not been fixed, it has been removed from view.

## 6. Clean up, then look back

Strip the instrumentation that no longer earns its place. Keep what turned out to be genuinely useful — a well-placed log that found this bug will find the next one.

Then tell the user to run `/retro` while the session is still live — it is user-invoked, so only they can fire it — and say what you would raise: what would have *prevented* this, or caught it sooner. If the answer is that there was no good seam to lock it down at, that is work for `/improve-codebase-architecture`, not a note in a commit message.
