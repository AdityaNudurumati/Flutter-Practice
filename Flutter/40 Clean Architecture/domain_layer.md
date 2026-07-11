# The Domain Layer (Entities, Use Cases, Interfaces)

> The domain is the **pure heart** of the app — **entities** (business objects + invariants), **use cases/interactors** (one class = one application action, orchestrating entities), and **repository interfaces** (what the app needs from the outside, declared abstractly) — written in **plain Dart with zero framework/IO imports**. It depends on **nothing**; everything depends on it. This is what makes business logic testable in milliseconds, reusable across UIs, and immune to changes in Flutter, the network, or the database.

## Introduction

This file details the innermost layer: what entities/use cases/interfaces are, how to design them, and why keeping them pure is the whole game. It's the concrete realization of "policy independent of details" from the overview ([clean_architecture_overview.md](clean_architecture_overview.md)).

## Why this concept exists

Business rules are the app's most valuable and most stable asset — and the thing most damaged by being tangled with UI/IO. Isolating them in a framework-free layer means they can be tested exhaustively without a device, reused across platforms/UIs, and left untouched when details churn. Use cases give each action a single, named, testable home instead of scattering logic across widgets and repositories.

## Real-world analogy

The domain is a **recipe book**: **entities** are the ingredients with their properties (an egg, its freshness rules), **use cases** are the recipes (one recipe = "make an omelette," a specific sequence), and **repository interfaces** are the **shopping list** ("I need eggs and butter") — the recipe says *what* it needs, not *which shop* provides it. The recipe book works in any kitchen (UI) with any supplier (data source).

## Problem Statement

Model a feature's core: define entities with invariants, a use case per action that orchestrates them via repository interfaces, and abstract interfaces declaring exactly what the app needs from outside — all in pure Dart, unit-testable with fakes. You'll design the pure domain for, say, placing an order.

## Internal Working

```mermaid
flowchart TD
    UC[Use case: PlaceOrder] --> Ent[Entities: Order, LineItem (invariants)]
    UC --> Repo[Repository interfaces: OrderRepository, PaymentGateway]
    UC --> Rules[application rules: validate, compute totals, orchestrate]
    Repo -.implemented by data layer.-> Data[(details)]
    Note[pure Dart: no Flutter/dio/sqflite]
```

- **Entities** (enterprise business rules): the core objects + **invariants** (an `Order` total must equal the sum of line items; an email must be valid). Prefer **immutable** value objects; put **business validation/behavior** on them (not just data bags). They're the most stable, framework-free code.
- **Use cases / interactors** (application rules): **one class per application action** (`GetProfile`, `PlaceOrder`, `SearchProducts`), typically with a single `call(...)` (callable class). They **orchestrate** entities + repository interfaces to fulfill the action, applying app-specific rules (validation, sequencing, combining sources) and returning a **`Result`/`Either`** ([Module 38](../38%20Error%20Handling/README.md)). They depend only on **abstractions**.
- **Repository interfaces**: abstract contracts declaring **what the domain needs** (`Future<Result<Order>> placeOrder(Order)`), **defined in the domain**, implemented in the data layer ([data_layer.md](data_layer.md)). This is the **inversion** that keeps dependencies inward ([Module 04](../04%20SOLID/README.md)).
- **Purity (non-negotiable)**: **no** `package:flutter`, `dio`, `sqflite`, `path_provider`, etc. If the domain needs a value (current time, id) it takes it as a parameter or via an injected abstraction (a `Clock`/`IdGenerator` interface) — never a framework call.
- **Failures as values**: use cases return typed failures (`Result`/sealed `Failure`) rather than throwing for expected outcomes ([Module 38](../38%20Error%20Handling/README.md)); bugs still throw.
- **No UI/persistence concerns**: no widgets, no JSON, no SQL — those live outward. The domain speaks only entities + interfaces.
- **Testability**: use cases are unit-tested by injecting **fake repositories** and asserting orchestration/rules — fast, deterministic, no device ([Module 49](../49%20Testing/README.md)).

## Memory Representation

Entities are plain (ideally immutable) Dart objects. Use cases hold references to injected interfaces. No framework handles, no IO state — just business data + behavior.

## Compiler Behavior

The domain compiles with **no framework imports** — a hard, checkable boundary. If it references Flutter/dio, purity is broken. Sealed classes/`Result` give exhaustive failure handling.

## Runtime Behavior

Use cases execute orchestration synchronously/asynchronously against injected interfaces; at runtime DI supplies real implementations, but the domain code is oblivious to which.

## Flutter Engine Behavior

None — the domain runs on the plain Dart VM (unit tests need no `WidgetsFlutterBinding`).

## Dart VM Behavior

Pure-Dart, so domain tests are the fastest tier (no Flutter binding, no IO). Immutable entities are cheap and safe to share.

## Examples

```dart
// ENTITIES — business objects with invariants (pure Dart, immutable)
class LineItem {
  final String productId; final int qty; final int unitPriceCents;
  const LineItem(this.productId, this.qty, this.unitPriceCents);
  int get subtotalCents => qty * unitPriceCents;
}

class Order {
  final String id; final List<LineItem> items;
  Order(this.id, this.items) {
    if (items.isEmpty) throw ArgumentError('order needs items'); // invariant (bug if violated)
  }
  int get totalCents => items.fold(0, (s, i) => s + i.subtotalCents);
}

// REPOSITORY INTERFACES — what the domain needs (defined here, implemented in data)
abstract class OrderRepository { Future<Result<Order>> place(Order order); }
abstract class Clock { DateTime now(); }   // abstract even for "framework" values

// USE CASE — one application action; orchestrates + applies rules; returns Result
class PlaceOrder {
  final OrderRepository orders;
  PlaceOrder(this.orders);
  Future<Result<Order>> call(Order order) async {
    if (order.totalCents <= 0) return Failure(ValidationFailure('empty order')); // app rule
    return orders.place(order);          // orchestrate via the abstraction
  }
}
```

```dart
// Testable with a FAKE repo — no device/network
test('PlaceOrder rejects empty totals', () async {
  final uc = PlaceOrder(FakeOrderRepo());
  final r = await uc(Order('1', [LineItem('p', 0, 0)]));
  expect(r, isA<Failure>());
});
```

## Diagrams

```mermaid
flowchart LR
    Action[app action] --> UseCase[Use case.call()]
    UseCase --> Validate[apply rules on Entities]
    UseCase --> Repo[Repository interface]
    Repo -->|Result| UseCase
    UseCase -->|Result| Caller[presentation]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| Framework imports in domain | Breaks purity/testability | Plain Dart + abstractions (Clock/Id) |
| Anemic entities (data bags only) | Rules leak elsewhere | Put invariants/behavior on entities |
| Business logic in repositories/widgets | Untestable, scattered | Put it in use cases/entities |
| Use cases returning DTOs/JSON | Leaks data concerns inward | Return entities/`Result` |
| One giant "service" instead of use cases | Poor cohesion/naming | One use case per action |
| Throwing for expected failures | Callers may miss them | Return `Result`/typed failures |
| Depending on concrete repos | Violates dependency rule | Depend on interfaces |

## Best Practices

- Keep the domain **pure** (no framework/IO); model **entities with invariants/behavior** (not anemic bags); prefer **immutability**.
- **One use case per application action** (callable `call`), **orchestrating** entities + repository **interfaces**, returning **`Result`/typed failures**.
- **Define repository interfaces in the domain**; abstract even "framework" needs (time/ids) behind interfaces so the core stays pure.
- Put **business rules in the domain** (entities/use cases), never in widgets/repos; **unit-test** use cases with fakes (fast, no device).

## Performance

Pure-Dart domain tests are the fastest tier (no binding/IO). Immutable entities are cheap; use cases add negligible orchestration cost. The design cost is more classes/files — offset by test speed and change-resilience.

## Advantages / Disadvantages

- **+** Fast/exhaustive unit tests (no device), reusable across UIs/platforms, business rules centralized + stable, framework-independent.
- **−** More classes (use cases/interfaces), mapping to/from data types, risk of anemic/ceremonial use cases if overdone.

## Interview Questions

1. **🟢 What lives in the domain layer?** — Entities (business objects + invariants), use cases (application actions), and repository interfaces — all pure Dart.
2. **🟢 What is a use case?** — A single-responsibility class for one application action (`call(...)`) that orchestrates entities/repositories and returns a `Result`.
3. **🟡 Why must the domain be framework-free?** — So business rules are testable without a device/network and independent of UI/DB/network changes.
4. **🟡 Where are repository interfaces defined and why?** — In the domain (implemented in data), so dependencies point inward (Dependency Inversion).
5. **🟡 How do you handle a "framework" need like current time in a pure domain?** — Abstract it (a `Clock` interface) and inject an implementation, keeping the domain pure and testable.
6. **🔴 Entities vs anemic models — why does it matter?** — Entities carry invariants/behavior so rules live in one testable place; anemic bags push logic into repos/widgets where it tangles and can't be tested.
7. **🔴 Why return `Result` from use cases instead of throwing?** — Expected failures become explicit, compiler-checkable outcomes callers must handle; bugs still throw.

## Senior Engineer Tips

- Keep a hard "no Flutter/dio/sqflite import" rule on the domain folder and test it in pure Dart; that single constraint delivers most of Clean Architecture's value.
- Make use cases thin-but-meaningful — real orchestration/validation, not empty pass-throughs; if a use case only forwards to a repo, ask whether it earns its place.
- Put invariants on entities (constructors/methods) so illegal states are unrepresentable, and abstract even time/ids behind interfaces so tests are deterministic.

## Architect Perspective

The domain layer is where the app's essential complexity lives, protected from accidental complexity (frameworks/IO). Entities encode enterprise rules, use cases encode application rules, and interfaces declare needs — all pure, testable, and stable. This is the asset the whole architecture exists to protect and the seam DDD later deepens (aggregates/value objects) ([Module 46](../46%20Domain%20Driven%20Design/README.md)); the data layer merely satisfies its interfaces ([data_layer.md](data_layer.md)).

## Summary

- Domain = pure Dart: entities (invariants/behavior), use cases (one action each, orchestrate + return `Result`), repository interfaces (defined here).
- No framework/IO imports; abstract even time/ids; business rules live here; return typed failures.
- Unit-testable with fakes (fastest tier); depends on nothing, everything depends on it.

## Revision Notes

- Entities: business objects + invariants (immutable, behavior on them); use cases: one action, `call()`, orchestrate entities + interfaces, return `Result`.
- Repository interfaces defined in domain (impl in data — DIP); no Flutter/dio/sqflite; abstract Clock/IdGenerator for purity.
- Business rules in domain; expected failures as `Result`/typed; unit-test with fakes (pure Dart, no device).

## Practice Questions

1. What distinguishes an entity from an anemic model?
2. Why is a use case better than putting logic in the repository?
3. How do you keep the domain pure when it needs the current time?

## Coding Questions

1. Model an entity with an invariant and a use case that enforces an app rule.
2. Define a repository interface in the domain and a `Clock` abstraction.
3. Unit-test the use case with a fake repository (no device).

## Mini Project

**Pure domain slice (Flutter):** Model a feature's domain — entities with invariants/behavior, repository interfaces (+ a `Clock`/`IdGenerator` abstraction), and use cases (one per action) that orchestrate and return `Result`/typed failures — in pure Dart. Unit-test the use cases with fakes. Acceptance: zero framework/IO imports in domain; entities carry invariants; use cases orchestrate + return typed results; interfaces defined in domain; use cases unit-tested with fakes (no device); business rules live in the domain only.
