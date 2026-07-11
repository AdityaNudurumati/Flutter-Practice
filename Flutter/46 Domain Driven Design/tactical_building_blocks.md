# Tactical Building Blocks (Entities, Value Objects, Services)

> Within a bounded context, DDD models with distinct building blocks: **entities** (things with a persistent **identity** that changes over time — a `Customer`, an `Order`), **value objects** (immutable things defined **only by their attributes**, with no identity — `Money`, `Email`, `DateRange`; two are equal if their values match), **domain services** (stateless operations that don't naturally belong to a single entity/VO — `TransferFunds`), and **factories** (encapsulate complex creation, ensuring a valid object is born). The highest-leverage habit: **push rules into value objects** so illegal states are unrepresentable (a `Money` can't be negative currency-mismatched; an `Email` is always valid).

## Introduction

This file covers the tactical vocabulary that populates a bounded context: entities vs value objects (the key distinction — identity vs value), domain services, and factories. These implement the model the strategic layer defined ([ddd_fundamentals.md](ddd_fundamentals.md)).

## Why this concept exists

Complex domains need precise object semantics. Conflating identity and value (making everything an entity) loses the power of immutable, self-validating value objects; scattering rules across the UI/services instead of into VOs/entities makes them untestable and inconsistent. These building blocks give each concept the right shape so rules live in the model.

## Real-world analogy

An **entity** is a **person**: they have a persistent identity (a passport number) even as their attributes change (address, hair color) — you track *the same person* over time. A **value object** is a **banknote's value**: a $20 is defined entirely by "20 USD" — one $20 is interchangeable with another (no identity), and it's immutable (you don't mutate a $20 into a $50; you get a different value). A **domain service** is a **currency exchange desk** — an operation involving multiple values that belongs to no single note.

## Problem Statement

Model an ordering context's pieces: decide which concepts are entities (identity) vs value objects (value), make value objects self-validating/immutable (`Money`, `Quantity`, `Email`), add a domain service for a multi-entity operation, and use a factory for complex creation. You'll classify + implement the building blocks.

## Internal Working

```mermaid
flowchart TD
    Concept{how is it identified?}
    Concept -->|by identity (tracked over time)| Entity[Entity: id, mutable attributes, lifecycle]
    Concept -->|by its values (interchangeable)| VO[Value Object: immutable, value-equality, self-validating]
    Op{operation belongs to one object?}
    Op -->|no (spans objects)| Service[Domain Service: stateless]
    Create[complex/invariant-heavy creation] --> Factory[Factory: produces valid objects]
```

- **Entity**: has a **stable identity** (an id) that persists across attribute changes; **mutable** over its lifecycle; equality is by **identity**, not attributes (two customers with the same name are different customers). Model things you **track over time**.
- **Value object (VO)**: **immutable**, defined **entirely by its attributes**, **no identity**; equality is by **value** (`Money(20,'USD') == Money(20,'USD')`). **Self-validating** in the constructor (an `Email` that exists is valid; a `Money` enforces currency/non-negativity). VOs make **illegal states unrepresentable** and are **freely shareable/side-effect-free**. **Prefer VOs** — most "fields" (money, dates, ranges, quantities, ids, addresses) are better as VOs than primitives (avoids "primitive obsession").
- **Entity vs VO (the core call)**: ask **"do I care *which* one it is (identity), or only *what* it is (value)?"** Identity → entity; value → VO. Getting this right is the most consequential tactical decision.
- **Domain service**: a **stateless** operation expressing domain logic that **doesn't belong to a single entity/VO** (e.g., `TransferFunds(from, to, amount)`, `PricingService`). Named in the ubiquitous language; contains **domain rules**, not app orchestration (that's an application service — [repositories_and_domain_events.md](repositories_and_domain_events.md)). Don't overuse — prefer putting behavior **on entities/VOs**; use services only for genuinely cross-object logic.
- **Factory**: encapsulates **complex or invariant-heavy creation** so objects are **born valid** (a `create()`/named constructor that enforces rules, or a factory method on an aggregate root). Keeps construction logic out of callers.
- **Behavior belongs in the model**: put **rules/methods on entities and VOs** (rich model), not in procedural services or the UI — the anti-anemic-model principle ([Module 40](../40%20Clean%20Architecture/README.md)).
- **Dart fit**: VOs = immutable classes with value equality (`==`/`hashCode`, or `equatable`/records/`freezed`), validation in the constructor (throw/`Result`); entities = classes with an `id` + identity equality; services/factories = plain classes/functions — all **pure Dart** (no framework).

## Memory Representation

VOs are small immutable values (safe to share/cache; equal-by-value). Entities hold an id + mutable state. Services are stateless (no fields beyond dependencies). Factories are transient constructors. VOs replace scattered primitives, concentrating validation.

## Compiler Behavior

Value equality requires overriding `==`/`hashCode` (or using `equatable`/`freezed`/records); constructors enforce validity (throw or return `Result`). Immutability via `final` fields/`const`. All plain Dart (testable).

## Runtime Behavior

VOs, once constructed, are always valid (validated at birth) and never mutate; entities mutate through methods that preserve their rules; services compute; factories reject invalid inputs at creation.

## Flutter Engine Behavior

None — pure domain (no widgets/IO).

## Dart VM Behavior

Immutable VOs are cheap, shareable, and comparison-friendly; pure-Dart building blocks give fast unit tests.

## Examples

```dart
// VALUE OBJECT — immutable, value-equality, self-validating (illegal states impossible)
class Money {
  final int amountCents; final String currency;
  Money(this.amountCents, this.currency) {
    if (amountCents < 0) throw ArgumentError('Money cannot be negative');
    if (currency.length != 3) throw ArgumentError('Bad currency');
  }
  Money operator +(Money o) {
    if (currency != o.currency) throw ArgumentError('Currency mismatch'); // rule in the VO
    return Money(amountCents + o.amountCents, currency);
  }
  @override bool operator ==(Object o) =>
      o is Money && o.amountCents == amountCents && o.currency == currency; // value equality
  @override int get hashCode => Object.hash(amountCents, currency);
}

class Email {                                  // another self-validating VO (no invalid Email exists)
  final String value;
  Email(this.value) { if (!_re.hasMatch(value)) throw ArgumentError('Invalid email'); }
  static final _re = RegExp(r'^[\w.+-]+@[\w-]+\.\w+$');
}

// ENTITY — identity + mutable lifecycle; behavior (rules) on the entity
class Customer {
  final String id;                             // identity
  Email email; String name;                    // mutable attributes
  Customer(this.id, this.email, this.name);
  @override bool operator ==(Object o) => o is Customer && o.id == id; // identity equality
  @override int get hashCode => id.hashCode;
}

// DOMAIN SERVICE — stateless, spans objects (belongs to no single entity/VO)
class PricingService {
  Money priceFor(List<LineItem> items, Discount d) => /* domain pricing rules */ Money(0, 'USD');
}

// FACTORY — complex/invariant-heavy creation producing a valid object
class OrderFactory {
  Order createEmptyFor(Customer c) => Order.newFor(c.id); // encapsulates valid construction
}
```

## Diagrams

```mermaid
flowchart LR
    Primitive[primitive field (String/int)] -->|primitive obsession| Risk[scattered validation]
    VO[value object (self-validating, immutable)] --> Safe[illegal states impossible]
    Identity[tracked over time] --> EntityN[entity]
    CrossObj[operation spans objects] --> ServiceN[domain service]
```

## Common Mistakes

| Mistake | Why it's wrong | Fix |
|---------|---------------|-----|
| Primitive obsession (String email, int money) | Scattered/duplicated validation | Value objects (self-validating) |
| Everything an entity | Loses VO immutability/value-equality | VO when identity doesn't matter |
| Mutable value objects | Breaks value semantics/sharing | Immutable VOs (new instance on change) |
| Anemic entities (data bags) | Rules leak to services/UI | Put behavior/rules on entities/VOs |
| Overusing domain services | Procedural, anemic model | Prefer methods on entities/VOs; services only for cross-object |
| App orchestration in a domain service | Wrong layer | Domain rules only; orchestration → application service |
| No factory for complex creation | Invalid objects/duplicated logic | Factory ensures born-valid |

## Best Practices

- Distinguish **entities (identity, mutable, lifecycle)** from **value objects (value, immutable, self-validating, no identity)** by asking "do I care *which* or only *what*?"
- **Prefer value objects** over primitives (kill primitive obsession); validate in the constructor so **illegal states are unrepresentable**; use **value equality**.
- Put **behavior/rules on entities and VOs** (rich model); use **domain services** only for genuinely cross-object stateless logic (domain rules, not app orchestration).
- Use **factories** for complex/invariant-heavy creation (born-valid objects); keep all building blocks **pure Dart** (testable).

## Performance

Immutable VOs are cheap and shareable; value-equality comparisons are fast for small VOs. Rich models add no runtime cost vs anemic ones. Pure-Dart building blocks give the fastest tests. Excessive tiny allocations are rarely an issue relative to correctness gains.

## Advantages / Disadvantages

- **+** Precise semantics, self-validating VOs (fewer bugs), rich testable model, illegal states unrepresentable, clear cross-object logic via services.
- **−** More types (VOs for many fields), value-equality boilerplate (mitigated by `freezed`/`equatable`/records), judgment on entity-vs-VO and service usage.

## Interview Questions

1. **🟢 Entity vs value object?** — Entity has a persistent identity and mutable lifecycle (equality by id); a value object is immutable, has no identity, and is equal by its attributes.
2. **🟢 Why prefer value objects over primitives?** — They centralize validation (self-validating), make illegal states unrepresentable, and carry domain meaning — avoiding "primitive obsession."
3. **🟡 How do you decide entity vs VO?** — Ask whether you care *which* instance (identity → entity) or only *what* it is (value → VO).
4. **🟡 When do you use a domain service?** — For stateless domain logic that spans multiple objects and belongs to no single entity/VO — not for app orchestration.
5. **🟡 What's a factory for?** — Encapsulating complex/invariant-heavy creation so objects are born valid, keeping construction logic out of callers.
6. **🔴 Why put behavior on entities/VOs instead of services?** — To avoid an anemic model — rules live with the data they govern, staying consistent and testable; services are for genuinely cross-object logic only.
7. **🔴 How do you implement value equality + immutability in Dart?** — Immutable (`final`/`const`) fields + `==`/`hashCode` overrides (or `equatable`/`freezed`/records), validating in the constructor.

## Senior Engineer Tips

- Wrap almost every "field" (money, email, dates, quantities, ids) in a self-validating value object; it eliminates a whole class of validation bugs and makes the model speak the domain.
- Keep entities rich (behavior + invariants on them) and reach for domain services sparingly; a domain full of services and anemic data bags is a procedural program wearing DDD clothes.
- Use `freezed`/`equatable`/records to remove value-equality boilerplate so the cost of "more VOs" is low and you actually create them.

## Architect Perspective

The tactical building blocks give a bounded context a precise, rule-bearing model: value objects make invalid states impossible and carry domain meaning, entities track identity + lifecycle with behavior on them, domain services capture cross-object rules, and factories guarantee valid creation. This rich model is the substance of Clean Architecture's domain layer and the material aggregates organize into consistency boundaries. Preferring VOs and rich entities (over primitives and anemic bags) is the highest-leverage tactical habit ([aggregates_and_invariants.md](aggregates_and_invariants.md), [Module 40](../40%20Clean%20Architecture/README.md)).

## Summary

- Entities = identity + mutable lifecycle (equality by id); value objects = immutable, value-equality, self-validating, no identity — prefer VOs over primitives.
- Domain services = stateless cross-object domain logic (not orchestration); factories = born-valid creation.
- Put behavior/rules on entities/VOs (rich model, illegal states unrepresentable); all pure Dart, testable.

## Revision Notes

- Entity: identity (id), mutable, lifecycle, equality by id. VO: immutable, value-equality, self-validating (constructor), no identity — prefer over primitives (no primitive obsession).
- Entity-vs-VO: care *which* (identity→entity) or *what* (value→VO). Behavior/rules on entities/VOs (anti-anemic).
- Domain service: stateless, cross-object domain rules (not app orchestration). Factory: complex/invariant creation → born valid. All pure Dart; value equality via `==`/`hashCode`/`freezed`/`equatable`/records.

## Practice Questions

1. Classify five concepts as entities or value objects and justify.
2. Why does a self-validating value object eliminate bug classes?
3. When is a domain service appropriate vs putting logic on an entity?

## Coding Questions

1. Implement a self-validating, value-equal `Money` VO with `+`.
2. Model an entity with identity equality + behavior (a rule method).
3. Add a domain service for a cross-object operation and a factory for creation.

## Mini Project

**Tactical building blocks (Flutter/domain):** For an ordering context, implement value objects (`Money`, `Quantity`, `Email` — immutable, self-validating, value-equality), entities with identity + behavior (`Customer`, `LineItem`), a domain service (`PricingService`) for a cross-object rule, and a factory for valid creation — all pure Dart, unit-tested. Acceptance: correct entity-vs-VO classification; VOs immutable + self-validating + value-equal (illegal states impossible); behavior on entities/VOs (no anemic bags); domain service only for cross-object logic; factory yields valid objects; unit-tested without a device.
