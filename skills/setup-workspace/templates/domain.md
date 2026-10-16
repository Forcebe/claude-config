# Domain docs

How to consume this repo's domain documentation. Paths are relative to `cw`.

## Before exploring, read these

- **`GLOSSARY.md`** at the docs root, or
- **`GLOSSARY-MAP.md`** if it exists: this repo has several contexts and the map points at one `GLOSSARY.md` per context. Read the ones relevant to the topic.
- **`adr/`**: read the ADRs touching the area you are about to work in.

If none of these exist, **proceed silently**. Do not flag their absence or offer to create them upfront; `domain-modeling` creates them lazily, when a term or decision actually resolves.

## Use the glossary's vocabulary

When your output names a domain concept — an issue title, a refactor proposal, a hypothesis, a test name — use the term as the glossary defines it, and don't drift to synonyms it explicitly avoids.

A concept missing from the glossary is a signal: either you are inventing language the project doesn't use, which is worth reconsidering, or there is a real gap worth noting for `domain-modeling`.

## Flag ADR conflicts

If your output contradicts an ADR, surface it rather than silently overriding:

> _Contradicts ADR-0007 (event-sourced orders), but worth reopening because…_

Surface it only when the friction is real. Don't list every theoretical change an ADR forbids.

## Layout

Single context, which is almost every repo:

```
<docs root>/
├── GLOSSARY.md
└── adr/
    ├── 0001-event-sourced-orders.md
    └── 0002-postgres-for-write-model.md
```

Several contexts, signalled by `GLOSSARY-MAP.md` at the docs root:

```
<docs root>/
├── GLOSSARY-MAP.md
├── adr/                      ← system-wide decisions
└── <context>/
    ├── GLOSSARY.md
    └── adr/                  ← decisions scoped to that context
```
