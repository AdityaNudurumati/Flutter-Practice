# Feature-First Integration (Capstone: An App Skeleton)

> Assemble a complete feature-first skeleton: `features/` (each a Clean/MVVM vertical slice that **self-registers** its DI + routes) + `core/` (infra, design system, `Result`, shared value objects, the **composition root** and **root router**), with **explicit boundaries** (features → core only; cross-feature via core contracts/events/routes; acyclic star-around-core graph). This is the organizing chassis that scales Clean + MVVM across many features, aligns folders with teams and product capabilities, and is ready to grow into packages ([Module 45](../45%20Modular%20Architecture/README.md)).

## Introduction

This module capstone composes fundamentals, feature/core structure, boundaries, and scaling into one working app skeleton. It shows the full tree, the composition root that wires self-registering features, and the boundary discipline that keeps slices decoupled — the template teams grow on.

## Why this concept exists

The parts only pay off when assembled: consistent slices + a curated core + enforced boundaries + a composition root = an app that scales cohesively and stays navigable, ownable, and extractable. This capstone provides that reference skeleton.

## Real-world analogy

It's a **food court built to a standard stall template**: each stall (feature) is a complete mini-restaurant that plugs into the court's shared utilities (core) and registers itself in the directory (routes) and billing (DI). The court operator (composition root) just powers on each stall; stalls cooperate through court services, never by walking into each other's kitchens — and a successful stall can graduate to its own standalone location (package).

## Problem Statement

Build a feature-first skeleton for an e-commerce-ish app (auth, home, cart, profile): each feature a self-registering Clean/MVVM slice, a `core` with the composition root/router/design system/`Result`, boundaries enforced (no cross-feature internal imports; interaction via core), and a documented scaling/migration note. You'll compose every file in this module into a runnable chassis.

## Internal Working

```mermaid
flowchart TD
    Main[main.dart] --> Root[core: composition root]
    Root --> RegCore[registerCore(di) + root router + theme]
    Root --> RegFeatures[each feature: registerX(di) + routes]
    subgraph features
      Auth[auth (slice + auth_di/auth_routes)]
      Cart[cart (slice + cart_di/cart_routes)]
      Home[home] 
      Profile[profile]
    end
    RegFeatures --> features
    features -->|depend on| Core[core]
    Cart -->|CartFacade contract| Core
    Note[features -> core only; cross-feature via core; acyclic star]
```

- **Tree**: `lib/core/` (di, routing, network, error/`Result`, ui/theme + shared widgets, util/value objects, **composition root**) + `lib/features/<name>/` (domain/data/presentation + `*_di.dart`/`*_routes.dart` + barrel) — consistent slice template ([structuring_features_and_core.md](structuring_features_and_core.md)).
- **Each feature = Clean + MVVM** ([Module 40](../40%20Clean%20Architecture/README.md)/[Module 43](../43%20MVVM/README.md)): domain (entities/use cases/interfaces), data (dtos/sources/impls), presentation (view models/screens) — and **self-registers** its DI + routes.
- **Core composition root**: `registerCore(di)` sets up shared infra; then calls each feature's `registerX(di)` and aggregates each feature's routes into the **root router** ([Module 14](../14%20Dependency%20Injection/README.md)/[Module 13](../13%20Routing/README.md)). `main.dart` just runs the root.
- **Boundaries** ([feature_boundaries_and_dependencies.md](feature_boundaries_and_dependencies.md)): features import **own code + core** only; cross-feature via **core contracts** (e.g., `CartFacade`), **events**, or **routes**; **acyclic star-around-core** graph; enforced by import lints (→ package boundaries later).
- **Shared code in core**: `Result`, `Money`, theme, network client, reusable widgets — promoted by the **rule of three**; core never imports a feature.
- **Growth-ready** ([scaling_and_migration.md](scaling_and_migration.md)): the skeleton scales by adding slices; mature features extract into **packages** with minimal change (boundaries already clean).
- **Right-sizing**: this full chassis suits real/growing apps; trivial apps can start lighter and grow into it.

## Memory Representation

Not runtime state — a source tree + an acyclic dependency graph (features → core). At startup the composition root builds the DI graph + router by invoking each feature's self-registration.

## Compiler Behavior

Domain pure; features UI-aware only in presentation; import lints enforce feature→core-only + no cross-feature internals; barrels expose public APIs. Package-ready boundaries.

## Runtime Behavior

`main` → composition root → registerCore + per-feature register → app runs with shared infra + feature routes/DI wired. Cross-feature calls resolve to core-contract implementations at runtime.

## Flutter Engine Behavior

Standard; only presentation touches the engine. Routing via the root router (navigate by route across features).

## Dart VM Behavior

Single package now; package extraction later enables incremental/parallel builds ([Module 45](../45%20Modular%20Architecture/README.md)).

## Examples

```text
lib/
  core/
    di/ (register_core.dart, composition_root.dart)
    routing/ (root_router.dart)
    network/ (dio client)
    error/ (result.dart, failure.dart)
    ui/ (theme.dart, primary_button.dart)
    util/ (money.dart, formatters.dart)
    contracts/ (cart_facade.dart)          # cross-feature contracts live in core
  features/
    auth/    (domain/ data/ presentation/ auth_di.dart auth_routes.dart auth.dart)
    home/    ...
    cart/    (... cart_di.dart cart_routes.dart cart.dart)   # implements CartFacade
    profile/ ...
  main.dart
```

```dart
// core/di/composition_root.dart — wires self-registering features
Future<void> bootstrap(GetIt di) async {
  registerCore(di);                 // shared infra (client, Result, theme)
  registerAuth(di);                 // each feature self-registers DI + routes
  registerCart(di);                 // cart also registers its CartFacade impl
  registerHome(di);
  registerProfile(di);
}

// core/routing/root_router.dart aggregates each feature's routes:
final router = GoRouter(routes: [...authRoutes, ...cartRoutes, ...homeRoutes, ...profileRoutes]);

// main.dart — just runs the root
void main() async {
  final di = GetIt.instance;
  await bootstrap(di);
  runApp(App(router: router));      // no feature knows about another
}
```

## Diagrams

```mermaid
flowchart LR
    Main --> Boot[bootstrap (composition root)]
    Boot --> Core[registerCore]
    Boot --> Feats[registerAuth/Cart/Home/Profile]
    Feats -->|routes| Router[root router]
    Feats -->|deps| CoreDeps[core (contracts/infra)]
    Cart -. implements .-> CartFacade[core CartFacade]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| Centralizing all DI/routes away from features | Low cohesion | Features self-register; root aggregates |
| Cross-feature internal imports | Coupling | Interact via core contracts/events/routes |
| Bloated core / core→feature import | Re-scatter / inverted dep | Curated core; features→core only |
| Inconsistent slice structure | Hard to navigate | Standard template per feature |
| Cyclic feature deps | Un-extractable | Acyclic star around core |
| No boundary enforcement | Erodes to monolith | Import lints → package boundaries |
| Over-building for a tiny app | Overkill | Right-size; grow into it |

## Best Practices

- Standardize the **slice template** (Clean/MVVM + `*_di`/`*_routes` + barrel); have each feature **self-register** DI + routes into a **core composition root/root router**.
- Keep **`core` curated** (infra + design system + shared value objects + cross-feature **contracts**); enforce **features → core only** and **acyclic star** boundaries.
- Interact **cross-feature via core contracts/events/routes** (never internal imports); promote shared code by the **rule of three**.
- Keep the skeleton **package-ready** (clean boundaries) and **right-size** — start lighter and grow; enforce boundaries with lints → package boundaries.

## Performance

Runtime-neutral; benefits are developer velocity (cohesion, parallel work, onboarding) and, at scale, build speed once features become packages. The composition root adds negligible startup wiring.

## Advantages / Disadvantages

- **+** Cohesive, consistent, self-wiring features; curated core; enforced boundaries; team ownership; scales Clean/MVVM; package-ready.
- **−** Upfront chassis setup + conventions, boundary discipline/tooling, judgment on core placement, overkill for trivial apps.

## Interview Questions

1. **🟢 What's in the skeleton's `core` vs `features`?** — Core: infra, design system, `Result`, shared value objects, cross-feature contracts, composition root/router. Features: self-contained Clean/MVVM slices + their DI/routes.
2. **🟢 How do features get wired?** — Each self-registers DI + routes; the core composition root calls them and aggregates routes into the root router; `main` runs the root.
3. **🟡 How do features interact without coupling?** — Via core contracts (e.g., `CartFacade`), events, or routes — never by importing each other's internals; the graph stays acyclic (star around core).
4. **🟡 Where do shared entities/value objects live?** — In core (promoted by the rule of three); core never imports a feature.
5. **🟡 How is this skeleton package-ready?** — Clean feature→core boundaries mean a mature feature can be lifted into a package with minimal change.
6. **🔴 How do you enforce boundaries?** — Import lints now (forbid cross-feature internals), package boundaries later; barrels expose public APIs.
7. **🔴 How does this scale Clean + MVVM?** — Each feature is a Clean/MVVM slice; feature-first makes feature the outer axis so many such slices coexist cohesively with a shared core.

## Senior Engineer Tips

- Build one exemplary self-registering slice + the composition root first; it becomes the template every feature follows, making the codebase uniform and onboarding trivial.
- Keep `main` dumb (just bootstrap + run) and let features own their DI/routes; centralizing wiring re-creates the low-cohesion problem feature-first solves.
- Enforce feature→core-only imports from day one and keep the graph acyclic; that discipline is what makes the eventual package extraction a cheap, mechanical step.

## Architect Perspective

The feature-first skeleton is the app's organizational chassis: consistent Clean/MVVM slices that self-wire into a curated core, with enforced, acyclic boundaries. It scales the presentation/layering patterns across many features, aligns structure with teams and product capabilities, keeps changes local, and graduates cleanly into a modular (package) architecture. It's the practical synthesis of everything in the architecture band so far — and the launchpad for modularization and DDD ([Module 43](../43%20MVVM/README.md), [Module 40](../40%20Clean%20Architecture/README.md), [Module 45](../45%20Modular%20Architecture/README.md), [Module 46](../46%20Domain%20Driven%20Design/README.md)).

## Summary

- Skeleton = `features/` (self-registering Clean/MVVM slices) + `core/` (infra, design system, `Result`, contracts, composition root/router); `main` just bootstraps + runs.
- Boundaries: features → core only; cross-feature via core contracts/events/routes; acyclic star-around-core; enforced by lints → packages.
- Curated core (rule of three); consistent slice template; package-ready; right-size and grow.

## Revision Notes

- Tree: `core/` (di/routing/network/error/ui/util/contracts + composition root) + `features/<name>/` (domain/data/presentation + `*_di`/`*_routes` + barrel).
- Wiring: features self-register DI+routes; core composition root calls them + aggregates routes; `main` runs root; cross-feature via core contracts/events/routes.
- Boundaries: features→core only (acyclic star), curated core (rule of three), lints→package boundaries; package-ready; right-size.

## Practice Questions

1. How does a feature self-register, and what does the composition root do?
2. How do features cooperate without importing each other?
3. What makes this skeleton ready to modularize?

## Coding Questions

1. Lay out the full `core/` + `features/` tree with per-feature wiring.
2. Write the composition root that wires self-registering features + aggregates routes.
3. Add a cross-feature `CartFacade` contract (core) implemented by cart, used by checkout.

## Mini Project

**Feature-first app skeleton (capstone — Flutter):** Build a runnable skeleton with `core/` (composition root, root router, network client, `Result`, theme, a `CartFacade` contract) and `features/` (auth, home, cart, profile — each a Clean/MVVM slice that self-registers DI + routes; cart implements `CartFacade`). Enforce features→core-only imports and cross-feature interaction via core; keep the graph acyclic; document the scaling/migration path. Acceptance: consistent self-registering slices + curated core; composition root wires features + aggregates routes; no cross-feature internal imports (interaction via core contract/route); acyclic star graph; boundary lint; scaling/migration note; package-ready; runs end-to-end.
