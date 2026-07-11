# Module Boundaries & Contracts

> A module's boundary is its **public API** — precisely the symbols it **`export`s** from its main library (everything under `lib/src/` is private by convention). Cross-module interaction goes through a **`contracts` package**: shared interfaces/DTOs/events that feature packages **implement** or **depend on**, so features never depend on each other — they depend on the neutral contract. This keeps the **package graph acyclic** (features → contracts/core; a thin `app`/composition package wires the concretes) and makes modules independently buildable, replaceable, and reusable.

## Introduction

This file covers designing module public APIs (`export`s + `lib/src/` privacy), the **contracts package** pattern for cross-module interaction, and keeping the dependency graph acyclic. It's the boundary-design layer over fundamentals ([modular_fundamentals.md](modular_fundamentals.md)) and the package-level formalization of feature-first boundaries ([Module 44](../44%20Feature%20First%20Architecture/README.md)).

## Why this concept exists

Packages enforce *that* boundaries exist, but you must *design* them: what's public vs private, and how modules cooperate without depending on each other. A minimal public API + a shared contracts package (dependency inversion at the package level) is what keeps modules loosely coupled and the graph acyclic — the difference between clean modules and a package spaghetti.

## Real-world analogy

Each module is a **company with a published catalog** (public API via `export`s) and **private operations** (`lib/src/`) no outsider sees. Companies don't call each other's internal extensions; they transact through **industry-standard contracts** (the contracts package) — a "supplier agreement" spec that any company can fulfill or rely on. A **general contractor** (the app/composition package) hires specific companies to fulfill specific contracts, so no supplier needs to know another supplier exists.

## Problem Statement

Design `feature_cart`'s public API, let `feature_checkout` use the cart without depending on the cart package, via a `contracts` package (a `CartFacade` interface + shared `Cart` DTO), and keep the whole graph acyclic. You'll define exports, the contracts package, and the wiring.

## Internal Working

```mermaid
flowchart TD
    Contracts[package: contracts (interfaces, DTOs, events)] 
    FCart[feature_cart] -->|implements| Contracts
    FCheckout[feature_checkout] -->|depends on| Contracts
    Core[core] --- FCart & FCheckout
    App[app/composition] -->|wires impls to contracts (DI)| FCart & FCheckout
    Note[features -> contracts/core; NEVER feature -> feature; acyclic]
```

- **Public API via `export` + `lib/src/`**: put implementation under **`lib/src/`** (private by convention) and expose only intended symbols from the package's **main library** (`lib/<pkg>.dart`) via **`export ... show ...`**. Consumers can only use exported symbols — the **API surface is deliberate + minimal**. Prefer a **barrel** that curates exactly the public API.
- **Contracts package (the key pattern)**: a small, **dependency-light** package holding **shared interfaces, DTOs, and events** used across modules (`CartFacade`, `AuthGateway`, `Cart` DTO, `UserLoggedOut` event). It's the **neutral ground**:
  - **Providers** (e.g., `feature_cart`) **implement** a contract.
  - **Consumers** (e.g., `feature_checkout`) **depend on the contract** — not on the provider package.
  - This is **Dependency Inversion at package scale** ([Module 04](../04%20SOLID/README.md)): both sides depend on the abstraction (contracts), so features don't depend on each other.
- **Acyclic graph (star)**: features depend on **contracts + core**, never on **each other**. A thin **`app`/composition package** depends on all features to **wire implementations to contracts** (DI composition root — [Module 14](../14%20Dependency%20Injection/README.md)). Result: a **DAG** — features are leaves, contracts/core are roots, app is the top wiring node.
- **Where shared types live**:
  - **Shared domain interfaces/DTOs/events** → **contracts**.
  - **Shared infra + design system + value objects** → **core** ([Module 44](../44%20Feature%20First%20Architecture/README.md)).
  - A feature's own entities/DTOs stay **private** to that feature.
- **Communication mechanisms** (same as feature-first, now across packages): **contract interfaces** (direct capability, DI-wired), **events** (decoupled reactions via a contracts/core event bus), **routes** (navigate across modules without importing widgets — [Module 13](../13%20Routing/README.md)).
- **Versioning the contract**: the contracts package is a **stable, slowly-changing API**; changing it ripples to all consumers, so treat it as a **published interface** (version carefully — [build_versioning_and_teams.md](build_versioning_and_teams.md)).
- **Enforcement**: package deps + `lib/src/` privacy are **compiler-enforced**; the acyclic rule is maintained by not adding feature→feature deps (reviewable in pubspecs).

## Memory Representation

Not runtime — a **DAG of packages** with public-API surfaces. Contracts is a root (no deps on features); features implement/consume it; app wires concretes to abstractions at the composition root. Private code lives in `lib/src/` (unreachable across packages).

## Compiler Behavior

Only exported symbols are importable; `lib/src/` is inaccessible from other packages. A consumer depending on `contracts` compiles without knowing which package implements it — the inversion. Undeclared/cyclic deps fail resolution.

## Runtime Behavior

DI (in the app/composition package) binds a provider's implementation to the contract interface; consumers call the interface, resolved to the concrete at runtime — no static consumer→provider import.

## Flutter Engine Behavior

Not applicable (routing aside — navigate across modules by route).

## Dart VM Behavior

Package granularity + minimal public APIs support incremental builds; a stable contracts package changing forces rebuilds of dependents (reason to keep it stable).

## Examples

```dart
// packages/contracts/lib/contracts.dart — neutral shared abstractions (no feature deps)
export 'src/cart_facade.dart';   // abstract class CartFacade { Future<CartDto> current(); }
export 'src/cart_dto.dart';      // shared DTO
export 'src/events.dart';        // e.g., UserLoggedOut

// packages/feature_cart/lib/feature_cart.dart — public API only
export 'src/presentation/cart_screen.dart';
export 'src/cart_di.dart' show registerCart;   // src/** internals stay private

// packages/feature_cart/lib/src/cart_facade_impl.dart — cart IMPLEMENTS the contract
class CartFacadeImpl implements CartFacade {     // depends on contracts, not on checkout
  @override Future<CartDto> current() async => /* ... */;
}

// packages/feature_checkout/lib/src/checkout_vm.dart — depends on the CONTRACT, not on cart
class CheckoutVm {
  final CartFacade cart;                          // from contracts package
  CheckoutVm(this.cart);
}
// app/lib/composition.dart — wires impl -> contract (only the app knows both)
// di.registerSingleton<CartFacade>(() => CartFacadeImpl(...));  // provided by feature_cart
```

```yaml
# feature_checkout/pubspec.yaml — depends on contracts + core, NOT on feature_cart
dependencies:
  contracts: { path: ../contracts }
  core: { path: ../core }
```

## Diagrams

```mermaid
flowchart LR
    Contracts[contracts (root)]
    Core[core (root)]
    FCart[feature_cart] --> Contracts & Core
    FCheckout[feature_checkout] --> Contracts & Core
    App[app] --> FCart & FCheckout & Contracts & Core
    App -->|DI: bind CartFacadeImpl -> CartFacade| Contracts
```

## Common Mistakes

| Mistake | Why it's bad | Fix |
|---------|-------------|-----|
| Feature package depends on another feature | Coupling, cyclic risk | Depend on contracts (both sides) |
| Exporting `src/**` | No real boundary | Export only the public API |
| Fat/unstable contracts package | Ripples to all consumers | Keep contracts small + stable |
| Shared DTO living in a feature | Others must depend on that feature | Put shared DTOs in contracts |
| Cyclic package deps | Won't build | Acyclic star (features→contracts/core) |
| Wiring impls inside feature packages | Features learn of each other | Wire in the app/composition package |
| No composition package | Nowhere to bind impls→contracts | Thin app/composition root wires DI |

## Best Practices

- Expose a **minimal public API** (`export ... show`; keep impl in **`lib/src/`**); curate it via a barrel — the boundary *is* the export list.
- Put **shared interfaces/DTOs/events in a `contracts` package**; providers **implement** it, consumers **depend on it** — features **never** depend on each other (package-level DIP).
- Keep the **graph acyclic (star)**: features → contracts/core; a **thin app/composition package** wires implementations to contracts via **DI**.
- Treat **contracts as a stable published API** (version carefully); shared infra/design system/value objects → **core**; feature-private types stay private.

## Performance

Minimal public APIs + stable contracts maximize incremental-build benefit (fewer forced rebuilds); a churning contracts package rebuilds all dependents (keep it stable). Runtime-neutral; the payoff is build isolation + change locality.

## Advantages / Disadvantages

- **+** Deliberate/minimal surfaces, decoupled features (no feature→feature deps), acyclic graph, replaceable/reusable modules, DIP at scale.
- **−** Contracts-package design + versioning care, composition-package wiring, export/`src` discipline, more packages to maintain.

## Interview Questions

1. **🟢 What is a module's public API?** — Exactly the symbols it `export`s from its main library; everything in `lib/src/` is private and unreachable from other packages.
2. **🟢 What is the contracts package for?** — Holding shared interfaces/DTOs/events so features interact through neutral abstractions instead of depending on each other.
3. **🟡 How do two features cooperate without depending on each other?** — Both depend on the contracts package: the provider implements the contract, the consumer depends on it; the app wires the impl to the interface via DI (package-level DIP).
4. **🟡 Why must the package graph be acyclic, and what shape is ideal?** — Cyclic deps can't build; ideal is a star/DAG — features → contracts/core, app → everything for wiring.
5. **🟡 Where do shared DTOs/entities live?** — Shared cross-module DTOs/interfaces/events in `contracts`; shared infra/value objects in `core`; feature-private types stay in the feature.
6. **🔴 Why keep the contracts package small and stable?** — Every consumer depends on it, so changes ripple widely and force rebuilds — treat it as a versioned published API.
7. **🔴 Why wire implementations in the app/composition package, not in features?** — So features never learn of each other's concretes; only the app knows both sides and binds impl→contract.

## Senior Engineer Tips

- Design the export list deliberately (small, `show`-listed) and keep everything else in `lib/src/`; a package that exports its internals has a boundary in name only.
- Route all cross-feature needs through the contracts package and wire concretes in the app; the moment `feature_a` lists `feature_b` in its pubspec, you've broken the acyclic star.
- Guard the contracts package like a public API — small, stable, versioned; it's the highest-leverage (and highest-blast-radius) package in the repo.

## Architect Perspective

Module boundaries + contracts are Dependency Inversion realized at the package level: minimal public APIs define surfaces, and a neutral contracts package lets features depend on abstractions rather than each other, keeping the graph an acyclic star with a thin composition root wiring concretes. This is what makes modules independently buildable, replaceable, and reusable — the structural backbone for multi-team, multi-app, and DDD (module-per-bounded-context) architectures ([modular_fundamentals.md](modular_fundamentals.md), [Module 46](../46%20Domain%20Driven%20Design/README.md), [Module 04](../04%20SOLID/README.md)).

## Summary

- A module's boundary = its `export`ed public API (`lib/src/` private); curate it minimally via a barrel.
- Cross-module interaction via a `contracts` package (shared interfaces/DTOs/events): providers implement, consumers depend on it — features never depend on each other (package DIP).
- Keep the graph acyclic (star: features→contracts/core; app wires impls→contracts via DI); treat contracts as a stable versioned API.

## Revision Notes

- Public API = `export ... show` from `lib/<pkg>.dart`; impl in `lib/src/` (private cross-package). Curate via barrel.
- `contracts` package = shared interfaces/DTOs/events; provider implements, consumer depends on it (package-level DIP); app/composition wires impl→contract via DI.
- Acyclic star: features→contracts/core, never feature→feature; app→all (wiring). Shared infra/value objects→core; contracts small+stable+versioned.

## Practice Questions

1. How do you define and minimize a package's public API?
2. How does a contracts package let features cooperate without coupling?
3. Why must implementations be wired in the app, not in feature packages?

## Coding Questions

1. Define a `contracts` package with a `CartFacade` + shared DTO, exported.
2. Implement it in `feature_cart`, depend on it from `feature_checkout` (no feature→feature dep).
3. Wire the impl→contract binding in the app composition root; show the acyclic pubspecs.

## Mini Project

**Contracts-based module boundaries (Flutter):** Create a `contracts` package (`CartFacade` interface + `CartDto` + an event), have `feature_cart` implement it (public API via `export`s, internals in `lib/src/`), and `feature_checkout` depend only on `contracts` + `core` (no dep on `feature_cart`); wire the impl→contract in the `app` composition root via DI. Verify the package graph is an acyclic star. Acceptance: minimal public APIs (`export`/`src` privacy); cross-feature interaction via contracts (package DIP); no feature→feature deps; app wires concretes; acyclic star graph; contracts kept small/stable.
