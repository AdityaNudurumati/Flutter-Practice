# Decision Frameworks & Trade-offs

> Judgment becomes **repeatable + defensible** when you apply lightweight **frameworks**: weigh a decision's **reversibility** (a "**two-way door**" — cheap to undo → decide fast; a "**one-way door**" → deliberate carefully) and its **cost of change** (how expensive to reverse later?), enumerate **options with explicit trade-offs** (pros/cons/costs, not gut feel), decide with the **least-worst trade-off for the context**, and **record the decision + rationale in an ADR** (Architecture Decision Record) so future teams know *why*. The point isn't bureaucracy — it's **structured, communicable, revisitable reasoning**: spend deliberation proportional to reversibility, make trade-offs explicit, and capture the *why*.

## Introduction

This file gives the frameworks that operationalize judgment ([architectural_judgment.md](architectural_judgment.md)): reversibility/two-way-doors, cost of change, structured trade-off evaluation, and ADRs. These turn "it depends" into a disciplined, documented decision process.

## Why this concept exists

Judgment alone can be inconsistent + opaque; frameworks make decisions **proportional** (don't agonize over reversible choices; do deliberate on irreversible ones), **explicit** (trade-offs named, not implicit), and **durable** (rationale captured so a decision isn't relitigated or lost over years/teams — critical in enterprise — [Module 57](../57%20Enterprise%20Projects/README.md)). They're the practical toolkit that scales judgment across a team + time.

## Real-world analogy

Deciding is like **choosing which doors to walk through**: most are **two-way doors** (you can come back — try it, learn, reverse if wrong → decide quickly), a few are **one-way doors** (hard to undo — a public API, a data-model migration, a framework choice → deliberate carefully, gather more input). You **spend deliberation proportional to how hard it is to return**, weigh the options' costs openly, and **write down why you chose** so the next traveler isn't confused — that's the ADR.

## Internal Working

```mermaid
flowchart TD
    Decision[a decision] --> Rev{reversibility?}
    Rev -->|two-way door (cheap to undo)| Fast[decide fast, learn, revise if wrong]
    Rev -->|one-way door (costly to undo)| Deliberate[deliberate carefully, gather input, prototype]
    Decision --> Options[enumerate options + EXPLICIT trade-offs (pros/cons/costs)]
    Options --> Choose[choose least-worst trade-off FOR THE CONTEXT]
    Choose --> ADR[record decision + rationale in an ADR (the WHY)]
    Note[deliberation proportional to reversibility; trade-offs explicit; capture the why]
```

- **Reversibility / two-way vs one-way doors** (the key framework — from Bezos):
  - **Two-way door** (easily reversible, low cost of change): a widget structure, a local state choice, a UI detail. **Decide fast, act, learn, reverse if wrong** — over-deliberating wastes time.
  - **One-way door** (hard/expensive to reverse): a public API contract, a persistence/data-model choice, a core framework/architecture, a security model, a vendor lock-in. **Deliberate carefully** — gather input, prototype, consider long-term, get review.
  - **Match deliberation to reversibility** — the single most useful decision heuristic. Most decisions are two-way doors treated (wrongly) as one-way (analysis paralysis); a few are one-way doors treated (dangerously) as two-way (rushed irreversible mistakes).
- **Cost of change**: closely related — **how expensive is it to change this later?** Low cost → bias to action + iterate; high cost → invest upfront + design for it (or reduce the cost of change via abstraction/boundaries — the whole point of Clean/modular architecture is **lowering cost of change**). Architecture is largely **managing the cost of change over time**.
- **Structured trade-off evaluation** (not gut feel):
  1. **Enumerate options** (including "do nothing"/simplest).
  2. **List explicit trade-offs** per option (pros/cons/costs — performance, complexity, maintainability, risk, effort, lock-in).
  3. **Weigh against context** (the deciding factors — [architectural_judgment.md](architectural_judgment.md)) and constraints (deadline/budget/team/compliance).
  4. **Choose the least-worst trade-off** — there's rarely a clear winner; you pick the one whose costs you can best live with **for this context**.
  5. **State the trade-off you accepted** ("chose X, accepting Y").
- **ADRs (Architecture Decision Records)** — capture the *why*:
  - A short, versioned doc per significant decision: **context** (situation/forces), **decision** (what + why), **alternatives considered** (+ why rejected), **consequences** (trade-offs/impact), **status** (proposed/accepted/superseded).
  - **Why**: enterprise systems live for years across teams — without recorded rationale, decisions get **relitigated, misunderstood, or accidentally reversed**. ADRs preserve institutional memory + make reasoning **communicable + reviewable** ([Module 57](../57%20Enterprise%20Projects/README.md)/[Module 47](../47%20Scalable%20Applications/README.md)).
  - Reserve for **significant/irreversible-ish** decisions (not every choice) — right-size the process too.
- **Deciding with incomplete information**: you rarely have full data; make the **best decision with what you have**, note assumptions, prefer **reversible experiments** (two-way doors) to reduce risk, and **revise as you learn**. Perfectionism/analysis-paralysis is itself a failure — **a good decision now often beats a perfect one late** (esp. for two-way doors).
- **Bias to action, proportionally**: for reversible/low-cost decisions, **decide + move** (iterate later); for irreversible/high-cost, **slow down + deliberate + document**. Don't invert this (the common mistakes).
- **Frameworks serve judgment, not replace it**: reversibility/cost-of-change/trade-off-analysis/ADRs are **structuring tools** for the contextual judgment of [architectural_judgment.md](architectural_judgment.md) — they make it consistent, proportional, explicit, and durable.

## Memory Representation

Not code — a **decision process + artifacts**: a reversibility/cost-of-change assessment, an options × trade-offs comparison, and an **ADR** capturing context/decision/alternatives/consequences. The corpus of ADRs is the team's decision memory.

## Compiler / Runtime / Engine / VM Behavior

Not applicable — decision-making is a cognitive/process skill; its outputs are the architectures/choices detailed across the handbook. Reducing "cost of change" is realized technically via abstractions/boundaries (Clean/modular — [Module 40](../40%20Clean%20Architecture/README.md)/[Module 45](../45%20Modular%20Architecture/README.md)).

## Examples

```text
Reversibility → deliberation:
  TWO-WAY (decide fast, iterate):  widget structure | local state approach | UI copy/layout | a screen's internal logic
  ONE-WAY (deliberate + document): public API/contract | data-model/persistence schema | core framework/architecture
                                   | security/auth model | vendor lock-in | cross-team contract
  -> spend deliberation PROPORTIONAL to how hard it is to reverse

Structured trade-off (choose least-worst for context):
  Option A: setState            -> + simple/fast  - not scalable/testable
  Option B: ChangeNotifier/MVVM -> + testable/scalable  - some boilerplate
  Option C: Bloc                -> + structured/testable - most boilerplate/learning
  context: typical app, mixed team -> choose B (accepting boilerplate for testability/scalability)
```

```markdown
# ADR-014: Adopt a Backend-for-Frontend (BFF) for the mobile client
Status: Accepted
Context: Data spans 6 microservices; the client is chatty + coupled to service topology.
Decision: Introduce a BFF aggregating services into client-shaped responses.
Alternatives: (a) direct multi-service calls — rejected (chatty/coupled); (b) client-side aggregation — rejected (complexity/perf).
Consequences: + fewer round-trips, decoupled client; − a new backend layer to own/deploy.
```

## Diagrams

```mermaid
flowchart LR
    Assess[assess reversibility + cost of change] --> Proportional[deliberation proportional to reversibility]
    Proportional --> Options2[enumerate options + explicit trade-offs]
    Options2 --> LeastWorst[choose least-worst for context]
    LeastWorst --> Record[record in ADR (the why)]
    Record --> Revise[revise as you learn (esp. two-way doors)]
```

## Common Mistakes

| Mistake | Why it's wrong | Fix |
|---------|---------------|-----|
| Over-deliberating reversible decisions | Analysis paralysis; wastes time | Two-way door → decide fast, iterate |
| Rushing irreversible decisions | Costly, hard-to-undo mistakes | One-way door → deliberate + document |
| Implicit/gut-feel trade-offs | Unexamined risks + blind spots | Enumerate options + explicit trade-offs |
| Seeking a clear "winner" | Rarely exists | Choose least-worst for context; state the cost |
| No decision record | Relitigation/lost rationale over years | ADRs for significant decisions |
| ADR for every trivial choice | Bureaucracy | Right-size — significant/irreversible only |
| Waiting for perfect information | Never comes; paralysis | Best decision now + reversible experiments + revise |
| Ignoring cost of change | Painful future reversals | Weigh + reduce cost of change (abstractions/boundaries) |

## Best Practices

- Assess **reversibility (two-way vs one-way door)** and **cost of change**, and **match deliberation to it** — decide fast on reversible/low-cost choices (iterate); deliberate + gather input + document on irreversible/high-cost ones.
- Evaluate decisions with **explicit trade-offs** (enumerate options → list pros/cons/costs → weigh against context → choose the **least-worst** → state the accepted cost) — not gut feel.
- **Record significant decisions in ADRs** (context/decision/alternatives/consequences) to preserve rationale + make reasoning communicable/reviewable — **right-size** the process (not every choice).
- **Decide with available information** (prefer reversible experiments, note assumptions, revise as you learn); **reduce cost of change** via abstractions/boundaries (Clean/modular) so more decisions become reversible.

## Performance

Not runtime — the payoff is **decision quality + velocity + institutional memory**: proportional deliberation avoids both paralysis (over-thinking reversible choices) and costly irreversible mistakes; explicit trade-offs surface risks; ADRs prevent relitigation. Reducing cost of change (via architecture) is itself a long-term "performance" multiplier for the team.

## Advantages / Disadvantages

- **+** Consistent, proportional, explicit, documented decisions; faster on reversible choices, safer on irreversible ones; preserved rationale; communicable/reviewable.
- **−** Requires discipline (right-sizing the process, writing ADRs); frameworks aid but don't replace judgment; over-applied ADRs/deliberation become bureaucracy.

## Interview Questions

1. **🟢 What is the reversibility / two-way-door framework?** — Classify decisions by how hard they are to undo: two-way doors (reversible) → decide fast + iterate; one-way doors (irreversible) → deliberate carefully + document — matching deliberation to reversibility.
2. **🟢 What is an ADR and why use it?** — An Architecture Decision Record capturing a significant decision's context/decision/alternatives/consequences — preserving the *why* so decisions aren't relitigated, misunderstood, or accidentally reversed over years/teams.
3. **🟡 How do you evaluate a trade-off rigorously?** — Enumerate options, list explicit pros/cons/costs, weigh against the context/constraints, choose the least-worst, and state the trade-off you accepted — not gut feel.
4. **🟡 What is "cost of change" and how does it shape decisions?** — How expensive a decision is to reverse later; low cost → bias to action/iterate, high cost → invest upfront/design for it — and architecture largely exists to lower the cost of change.
5. **🟡 How do you decide with incomplete information?** — Make the best decision with what you have, note assumptions, prefer reversible experiments (two-way doors), and revise as you learn — a good decision now often beats a perfect one late.
6. **🔴 Why match deliberation to reversibility?** — Over-deliberating reversible decisions causes paralysis; rushing irreversible ones causes costly mistakes — proportional deliberation optimizes both speed and safety.
7. **🔴 When should you write an ADR (and not)?** — For significant/irreversible-ish decisions (framework, data model, API contract, cross-team choices); not for trivial reversible ones — right-size the process.

## Senior Engineer Tips

- Classify every meaningful decision as a two-way or one-way door first; it instantly tells you whether to move fast (most decisions) or slow down + document — and stops both analysis paralysis and rushed irreversible mistakes.
- Make trade-offs explicit and write ADRs for the few significant/irreversible decisions; the "why" is what future teams (and future you) desperately need, and it turns your judgment into something reviewable and durable.
- Use architecture to lower the cost of change (abstractions, boundaries, contracts) so more decisions become reversible experiments — the more two-way doors you create, the faster and safer the team can move.

## Architect Perspective

Decision frameworks operationalize judgment into a repeatable, proportional, documented practice: reversibility + cost of change tell you **how much to deliberate**, structured trade-off analysis tells you **how to choose**, and ADRs **capture the why** for a long-lived, multi-team system. They scale one person's judgment across a team + time, and they reveal that much of architecture is about **managing the cost of change** — designing so decisions stay reversible. Combined with judgment, they're how a senior makes decisions others can trust, review, and build on ([architectural_judgment.md](architectural_judgment.md), [Module 57](../57%20Enterprise%20Projects/README.md), [Module 47](../47%20Scalable%20Applications/README.md)).

## Summary

- Match **deliberation to reversibility** (two-way door → fast + iterate; one-way door → deliberate + document) and weigh **cost of change**.
- Evaluate **explicit trade-offs** (options → pros/cons/costs → least-worst for context → state the accepted cost), not gut feel.
- **Record significant decisions in ADRs** (context/decision/alternatives/consequences); decide with available info + revise; reduce cost of change via architecture; right-size the process.

## Revision Notes

- Reversibility: two-way door (reversible → decide fast, iterate) vs one-way door (irreversible → deliberate/gather input/prototype/document); deliberation proportional to reversibility. Cost of change: low → bias to action; high → invest upfront/design for it; architecture lowers cost of change (abstractions/boundaries).
- Trade-off eval: enumerate options (incl. simplest) → explicit pros/cons/costs → weigh vs context/constraints → choose least-worst → state accepted trade-off (no clear winner usually).
- ADR (significant/irreversible decisions): context/decision/alternatives/consequences/status → preserves the *why* (no relitigation over years/teams); right-size (not every choice). Decide with incomplete info (best-now + reversible experiments + revise; avoid paralysis). Frameworks serve judgment, not replace it.

## Practice Questions

1. Classify several decisions as two-way vs one-way doors and set deliberation accordingly.
2. Do a structured trade-off evaluation for a real choice.
3. Write an ADR for a significant decision.

## Coding Questions

1. Write an ADR template + one filled example (e.g., state-management or backend choice).
2. Build an options × trade-offs table and pick the least-worst for a given context.
3. Identify which of a set of decisions warrant ADRs (right-size the process).

## Mini Project

**Decision framework kit (capstone-prep):** Assemble your decision toolkit: an ADR template; a reversibility/cost-of-change checklist (two-way vs one-way doors → deliberation level); a structured trade-off-evaluation format (options × pros/cons/costs → least-worst); and 2 worked examples (one two-way door decided fast, one one-way door deliberated + ADR-documented). Acceptance: reversibility framework applied (deliberation proportional); explicit trade-off evaluation (least-worst for context, accepted cost stated); ADR template + a filled example; right-sized process (ADRs for significant decisions only); note on deciding with incomplete info + revising.
