# GLOSSARY.md format

One entry per term, alphabetical. The glossary says what a word *means* in this
domain — never how it is implemented.

```markdown
# Glossary

## Order

A customer's committed request for goods at an agreed price. Becomes an Order
only once payment is authorised; before that it is a Basket.

**Not**: "cart", "purchase". Use Order.

## Requisition

...
```

Each entry gives the definition, and where a term has been confused with
another, the distinction that separates them. A **Not:** line records synonyms
the project has deliberately rejected, so the next reader does not reintroduce
them.

Keep entries short. If an entry needs more than a paragraph, the concept is
probably two concepts.

No file paths, no type names, no schema, no code. Those go stale and belong in
an ADR or the code itself.
