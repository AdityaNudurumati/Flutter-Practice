# DDD Integration (Capstone: Model One Bounded Context)

> Bring it together by fully modeling **one bounded context** end-to-end: a **ubiquitous language** glossary, **value objects** (self-validating, immutable), **entities** (identity + behavior), an **aggregate** (root enforcing invariants), a **domain service** for cross-object rules, a **repository interface** (per aggregate root), **domain events**, and a thin **application service** — all **pure Dart, unit-tested**, and mapped to a **feature/module** ([Module 44](../44%20Feature%20First%20Architecture/README.md)/[Module 45](../45%20Modular%20Architecture/README.md)) as the domain layer of Clean Architecture ([Module 40](../40%20Clean%20Architecture/README.md)). This shows DDD not as isolated patterns but as a coherent model that tames one complex context — applied proportionally.

## Introduction

This module capstone assembles strategic + tactical DDD into a single, coherent bounded-context model and situates it within the app's architecture. It demonstrates how the pieces fit, how they're tested, and how the context maps to a feature/module — the practical payoff.

## Why this concept exists

DDD's value appears only when the pieces cohere into one well-modeled context, expressed in the ubiquitous language and enforcing its invariants. This capstone provides that coherent example and shows DDD as the **rich domain layer** of the app's existing Clean/feature-first/modular structure — not a separate universe.

## Real-world analogy

It's **building one fully-functioning department to a professional standard**: a shared glossary everyone uses (ubiquitous language), precise tools and parts (value objects/entities), a supervised workflow that can't produce defects (aggregate + invariants), specialists for cross-cutting tasks (domain services), a stockroom (repository), an announcement system (events), and a coordinator (application service) — all fitting into the larger company (Clean/feature/module) as one well-run unit.

## Internal Working

```mermaid
flowchart TD
    subgraph "Ordering bounded context (= feature/module domain layer)"
      Lang[ubiquitous language glossary]
      VO[value objects: Money, Quantity, Address]
      Ent[entities: Customer, LineItem]
      Agg[aggregate: Order (root + invariants)]
      Svc[domain service: PricingService]
      Repo[OrderRepository interface (per root)]
      Ev[domain events: OrderPlaced]
      AppSvc[application service: PlaceOrderService]
    end
    AppSvc --> Repo & Agg
    Agg --> VO & Ent & Ev
    Svc --> VO
    Context[bounded context] --> Feature[feature/module (Clean domain layer)]
```

- **Strategic setup** ([01_ddd_fundamentals.md](01_ddd_fundamentals.md)): choose **one bounded context** (Ordering), write its **ubiquitous language** glossary; this context = a **feature/module** whose **domain layer** is this model.
- **Tactical model** ([02_tactical_building_blocks.md](02_tactical_building_blocks.md)): **value objects** (`Money`, `Quantity`, `Address` — immutable, self-validating), **entities** (`Customer`, `LineItem` — identity + behavior), a **domain service** (`PricingService`) for cross-object rules, **factories** for valid creation.
- **Aggregate + invariants** ([03_aggregates_and_invariants.md](03_aggregates_and_invariants.md)): the **`Order` aggregate** — root guards line items + status, enforcing invariants (total = sum of lines, only draft editable, valid transitions, non-empty place); small; references `Customer` by id.
- **Repository + events + app service** ([04_repositories_and_domain_events.md](04_repositories_and_domain_events.md)): **`OrderRepository`** interface (per aggregate root, whole-aggregate), **`OrderPlaced`** domain event, thin **`PlaceOrderService`** (load → `place()` → save → publish).
- **Fit into the architecture**: this whole model is the **domain layer** of a **feature/module** (Clean — [Module 40](../40%20Clean%20Architecture/README.md)); the **data layer** implements `OrderRepository`; the **presentation layer** (MVVM — [Module 43](../43%20MVVM/README.md)) calls the application service. Cross-context interaction goes via **contracts/ACL** ([Module 45](../45%20Modular%20Architecture/README.md)).
- **Purity + testing**: the entire model is **pure Dart** (no framework/IO), **unit-tested** exhaustively (VO validation, aggregate invariants, service, application-service flow with fake repo + captured events) — the DDD payoff realized as fast, confident tests.
- **Proportionality (honest)**: this depth suits a **complex core domain**; a CRUD/generic subdomain should stay simple ([01_ddd_fundamentals.md](01_ddd_fundamentals.md)). DDD is applied **where it earns its cost**.

## Memory Representation

The context is a cohesive object model: VOs (immutable values), entities (identity + state), the `Order` aggregate (encapsulated internals + invariants + pending events), repository interface (domain), and a stateless app service. It lives as one feature/module's domain layer.

## Compiler Behavior

Pure-Dart domain compiles without framework/IO; VOs enforce validity + value equality; aggregate encapsulation prevents invariant bypass; repository/events are domain types. The context is enforceable as a module boundary ([Module 45](../45%20Modular%20Architecture/README.md)).

## Runtime Behavior

App service loads the aggregate, invokes behavior (invariants enforced), saves (one transaction), publishes events after save; handlers react (eventual consistency). Invalid operations are rejected, never producing invalid state.

## Flutter Engine Behavior

None — pure domain; the presentation layer (outside this model) touches the engine and calls the application service.

## Dart VM Behavior

Fastest test tier: VO/entity/aggregate/service/app-service tests run in pure Dart with fakes — no device/binding.

## Examples

```dart
// One coherent bounded-context model (Ordering) — pure Dart, ubiquitous-language names

// Value objects (self-validating, immutable) + entity (identity) — from tactical file
// class Money {...}  class Quantity {...}  class Customer {id, ...}  class LineItem {...}

// Aggregate root (invariants) + events — from aggregates/events files
class Order { /* root: addLine/place/ship; guards invariants; records OrderPlaced */ }

// Repository (domain interface, per aggregate root)
abstract class OrderRepository { Future<Order?> findById(String id); Future<void> save(Order o); }

// Application service (thin orchestration) — the entry point the presentation calls
class PlaceOrderService {
  final OrderRepository orders; final EventDispatcher events; final Clock clock;
  PlaceOrderService(this.orders, this.events, this.clock);
  Future<Result<void>> call(String id) async {
    final o = await orders.findById(id);
    if (o == null) return Failure(NotFoundFailure('order'));
    o.place(clock.now());                 // domain rules/invariants in the aggregate
    await orders.save(o);                 // one aggregate, one transaction
    for (final e in o.pullEvents()) events.publish(e); // after save
    return const Success(null);
  }
}
```

```dart
// Exhaustive, device-free tests — the DDD payoff
test('Money rejects negative + mismatched currency', () { /* VO validation */ });
test('Order enforces invariants (empty place / transitions / edit-when-shipped)', () { /* aggregate */ });
test('PlaceOrderService: places, saves, publishes OrderPlaced', () async {
  final repo = FakeOrderRepo(draftOrderWithLines());
  final events = CapturingDispatcher();
  final r = await PlaceOrderService(repo, events, FixedClock()).call('1');
  expect(r, isA<Success>());
  expect(events.published.single, isA<OrderPlaced>());
});
```

## Diagrams

```mermaid
flowchart LR
    Presentation[presentation (MVVM)] --> AppSvc[PlaceOrderService]
    AppSvc --> Repo[OrderRepository (interface)]
    AppSvc --> Agg[Order aggregate (invariants + events)]
    Data[data layer] -. implements .-> Repo
    Context[Ordering bounded context] --> Module[feature/module domain layer]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| DDD depth on a CRUD/generic subdomain | Overkill | Apply to complex core only; keep generic simple |
| Framework/IO in the domain model | Breaks purity/testability | Pure Dart; repo interface only |
| Anemic aggregate (rules elsewhere) | Invariants drift | Rules/invariants in the aggregate |
| Ubiquitous language not in code | Translation drift | Name types/methods in the language |
| Rules in the application service | Anemic domain | Orchestrate only; rules in aggregate/service |
| Ignoring context boundary | Model leaks across contexts | Map context → feature/module; ACL across |
| Skipping tests | Loses the payoff | Unit-test VOs/aggregate/service |

## Best Practices

- Model **one bounded context** coherently: ubiquitous-language names, self-validating **value objects**, rich **entities**, an **aggregate** enforcing invariants, **domain services** for cross-object rules, a **per-root repository interface**, **domain events**, and a thin **application service**.
- Keep it **pure Dart** and **unit-test exhaustively** (VO validation, aggregate invariants, service flow with fakes) — the DDD payoff.
- Situate it as the **domain layer of a feature/module** (Clean); data implements the repo, presentation (MVVM) calls the app service; cross-context via **contracts/ACL**.
- **Apply proportionally** — DDD depth for the **complex core**, simplicity for CRUD/generic.

## Performance

Runtime-neutral vs a simpler model; the payoff is correctness (always-valid aggregates), communication (shared language), and **test speed** (pure-Dart, exhaustive). Aggregate/transaction sizing keeps persistence efficient. Over-applying DDD costs dev time — proportionality is the efficiency lever.

## Advantages / Disadvantages

- **+** Coherent, always-valid, exhaustively-testable model of a complex context; shared language; fits Clean/feature/module cleanly; tames complexity.
- **−** Significant modeling investment; overkill for simple domains; requires discipline (purity, invariants-in-aggregate, language) and proportional application.

## Interview Questions

1. **🟢 What does a fully-modeled bounded context contain?** — Ubiquitous language + value objects, entities, an aggregate (root + invariants), domain services, a per-root repository interface, domain events, and a thin application service.
2. **🟢 Where does this model sit in the app's architecture?** — As the domain layer of a feature/module (Clean); data implements the repository, presentation (MVVM) calls the application service.
3. **🟡 How is the model tested, and why is it fast?** — Pure-Dart unit tests of VOs/aggregate/service (with fakes + captured events) — no framework/IO, so the fastest tier.
4. **🟡 How do you keep the model always-valid?** — Self-validating VOs + aggregate invariants enforced in root methods; the application service orchestrates but holds no rules.
5. **🟡 How does a bounded context map to code structure?** — To a feature/module boundary; cross-context interaction via contracts/ACL (no model leakage).
6. **🔴 When would you not model to this depth?** — For CRUD/generic subdomains — keep them simple; reserve DDD for the complex core (proportionality).
7. **🔴 How do strategic and tactical DDD combine here?** — The ubiquitous language + context boundary (strategic) frame the model; the tactical patterns (VOs/entities/aggregate/services/repo/events) implement it coherently.

## Senior Engineer Tips

- Model one context deeply and correctly (language → VOs → entities → aggregate → repo/events/service) rather than sprinkling patterns across the whole app; depth where it matters beats shallow DDD everywhere.
- Keep the whole model pure Dart and unit-test the invariants exhaustively; the confidence from fast, complete domain tests is the concrete reason to invest in DDD.
- Slot it in as a feature/module's domain layer and reach it via an application service from MVVM; DDD isn't a replacement for Clean/feature-first — it's the rich version of their domain layer, applied to the complex core.

## Architect Perspective

This capstone shows DDD as a coherent domain model for one complex bounded context, sitting as the rich domain layer of the app's Clean/feature-first/modular structure: strategic boundaries + ubiquitous language framing a tactical model of value objects, entities, invariant-guarding aggregates, repositories, and events. It's the deepest expression of the architecture band — the "what the domain truly is" layer — applied proportionally to the core domain where taming complexity pays off, and mapped cleanly onto features/modules with contracts across contexts ([Module 40](../40%20Clean%20Architecture/README.md), [Module 44](../44%20Feature%20First%20Architecture/README.md), [Module 45](../45%20Modular%20Architecture/README.md)).

## Summary

- Model one bounded context coherently: ubiquitous language + VOs + entities + an invariant-guarding aggregate + domain services + per-root repository + domain events + thin application service.
- Keep it pure Dart, unit-test exhaustively; situate as the domain layer of a feature/module (Clean), with data implementing the repo and MVVM calling the app service.
- Apply proportionally — DDD depth for the complex core, simplicity for CRUD/generic; cross-context via contracts/ACL.

## Revision Notes

- Bounded context = feature/module domain layer: ubiquitous language + VOs (self-validating) + entities (identity+behavior) + aggregate (root+invariants) + domain services + per-root repository interface + domain events + thin application service.
- Pure Dart + exhaustive unit tests (VO/aggregate/service, fakes + captured events); data implements repo, MVVM calls app service; cross-context via contracts/ACL.
- Apply proportionally (complex core only); strong consistency inside aggregate, eventual across; DDD = rich domain layer of Clean/feature/modular.

## Practice Questions

1. What are all the pieces of a fully-modeled bounded context, and how do they connect?
2. Where does this model live relative to Clean/feature/modular architecture?
3. How do you decide how much DDD depth to apply?

## Coding Questions

1. Assemble an Ordering context (VOs + entities + `Order` aggregate + `OrderRepository` + `OrderPlaced` + `PlaceOrderService`), pure Dart.
2. Unit-test VOs, aggregate invariants, and the application-service flow (fake repo + captured events).
3. Show how the presentation (MVVM) + data layers connect to this domain model.

## Mini Project

**Bounded-context model (capstone — Flutter/domain):** Fully model the Ordering context: a ubiquitous-language glossary; value objects (`Money`, `Quantity`, `Address`); entities (`Customer`, `LineItem`); the `Order` aggregate (root enforcing invariants); a `PricingService`; an `OrderRepository` interface (per root); an `OrderPlaced` event; and a thin `PlaceOrderService` — all pure Dart, exhaustively unit-tested (VO validation, aggregate invariants, service flow with fake repo + captured events). Document how it maps to a feature/module and note the proportionality decision. Acceptance: coherent context in ubiquitous language; self-validating VOs + rich entities; aggregate always-valid (invariants in root); per-root repo interface; events published after save; thin app service (no rules/presentation); pure Dart + exhaustive tests; mapped to feature/module; proportional-application note.
