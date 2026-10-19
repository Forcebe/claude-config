---
name: grilling
description: Interview the user relentlessly about a plan, decision or design until you reach shared understanding. Use when the user wants their thinking stress-tested, says "grill me", "poke holes in this", "challenge my design", or when another skill needs the interview technique itself.
---

# Grilling

Interview the user relentlessly until you reach a shared understanding. Map the problem as a **design tree**: every decision branches into the decisions that hang off it.

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled — the questions you can ask *now* without guessing at answers you have not heard yet. Ask the whole frontier in one round, then wait.

```
❓ **Q1** — **<question title>**: <the question, which may be several paragraphs and may offer choices>

➡️ <your recommended answer>

---

❓ **Q2** — **<question title>**: <…>

➡️ <your recommended answer>
```

Word each question so that "yes" accepts your recommendation. Give a recommendation on every question; "what do you think?" is not a round.

A question whose answer depends on another question still open in this round belongs to a **later** round. Each round's answers reshape the tree: settled decisions push the frontier outward and unblock what depended on them. Recompute and ask again.

**Ask at most four questions in a round, and fewer if they are long.** A round has to be readable in one screen without scrolling, because the user is typing their answers while reading it. More than that and the earlier questions scroll away. If the frontier is wider than four, ask the four that unblock the most and keep the rest for the next round.

**Finish all your tool calls before you present the round.** Find the facts first, then write the questions in a single uninterrupted message. A round with exploration interleaved between the questions is unreadable, and re-numbering or amending questions after they are on screen is worse — the user may already be answering.

**Facts are your job; decisions are the user's.** When a question needs a fact from the environment — the filesystem, the codebase, a tool, the tracker — go and find it rather than asking. If a fact turns out to be slow to get, drop the questions that depend on it to a later round rather than making the user wait mid-round.

The session is done when the frontier is empty: every branch visited, nothing silently assumed. **Do not act on the outcome until the user confirms** you have reached shared understanding.
