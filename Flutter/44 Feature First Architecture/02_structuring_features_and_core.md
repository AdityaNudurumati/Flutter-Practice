# Structuring Features & the Core Module

> Each feature folder is a **mini Clean app** — `features/<name>/{domain, data, presentation}` — and everything **shared across features** lives in a **`core/`** (or `shared/`) module: cross-cutting infrastructure (DI, routing, networking client, `Result`/error types, theme, localization) and **truly reusable** widgets/utilities. The discipline is deciding **what's a feature vs what's core**: feature-specific code stays in the feature; only genuinely cross-cutting, stable, reusable code goes to core. A bloated core (dumping ground) or a leaky feature (reaching into another) are the two failure modes.

## Introduction

This file details the internal structure of a feature slice and the shared `core` module: what each contains, the feature↔core relationship, and the judgment of feature-vs-core placement. It's the "what goes where" companion to the fundamentals ([01_feature_first_fundamentals.md](01_feature_first_fundamentals.md)).

## Why this concept exists

Feature-first only works if features are consistent (predictable internal structure) and shared code has a clear home. Without a `core`, cross-cutting concerns get duplicated or dumped into a random feature; without placement discipline, `core` becomes a junk drawer or features leak into each other. A defined feature structure + a curated core keep the app cohesive and navigable.

## Real-world analogy

Each **feature** is a fully-equipped **food truck** (its own kitchen, menu, register — domain/data/presentation) that can operate independently. The **`core`** is the **commissary/shared kitchen**: shared ovens, the payment system, the brand signage, common ingredients every truck uses. You don't put the taco truck's salsa recipe in the commissary (feature-specific → stays in the truck), and you don't give each truck its own payment terminal (cross-cutting → belongs in core). A commissary crammed with every truck's private gear is chaos; a truck secretly using another truck's fryer is a boundary violation.

## Problem Statement

Structure a `features/cart/` slice internally and decide, for a list of items (a `Money` value object, the `dio` client, a `PrimaryButton`, the cart repository, the app theme, a date formatter), whether each belongs in the cart feature or in `core`. You'll define the feature layout + core contents + placement rules.

## Internal Working

```mermaid
flowchart TD
    subgraph features/cart
      D[domain/ (entities, use cases, repo interfaces)]
      DA[data/ (dtos, sources, repo impl)]
      P[presentation/ (view models, widgets, screens)]
      FDI[cart_di.dart / cart_routes.dart (feature wiring)]
    end
    subgraph core
      Infra[di, routing, network client, Result/errors]
      UI[theme, shared widgets, localization]
      Util[shared value objects, formatters, extensions]
    end
    features/cart --> core
    Note[features depend on core; core NEVER depends on a feature]
```

- **Feature slice internals** (consistent across features): `features/<name>/`
  - **`domain/`** — entities, use cases, repository **interfaces** (pure — [Module 40](../40%20Clean%20Architecture/README.md)).
  - **`data/`** — DTOs, data sources, repository **impls** (map/convert).
  - **`presentation/`** — view models + widgets/screens (MVVM — [Module 43](../43%20MVVM/README.md)).
  - **feature wiring** — the feature's **DI registration** and **routes** (`cart_di.dart`, `cart_routes.dart`) so the feature self-registers ([Module 14](../14%20Dependency%20Injection/README.md)/[Module 13](../13%20Routing/README.md)).
  - Optional `<feature>.dart` **barrel** exposing the feature's **public API** (what other parts may use) while keeping internals private.
- **The `core`/`shared` module** — cross-cutting, feature-agnostic:
  - **Infrastructure**: DI container setup, router root, the **network client** (`dio` + interceptors), **`Result`/error types**, logging facade, storage helpers.
  - **UI**: **theme/design system**, **truly reusable widgets** (`PrimaryButton`, `AppScaffold`), localization.
  - **Utilities**: shared **value objects** (`Money`, `Email`), formatters (`intl`), extensions, constants.
  - Sometimes split into `core/` (infra) + `shared/`/`ui/` (design system) — pick a convention.
- **Feature-vs-core placement rules**:
  - **Feature-specific** (used by one feature) → **stays in the feature** (even if it *looks* generic — don't pre-promote).
  - **Cross-cutting / used by many, stable, reusable** → **core**.
  - **Rule of three (heuristic)**: promote to core when **≥2–3 features genuinely need it**; before that, keep it local (avoid premature/wrong abstractions).
- **Dependency direction (critical)**: **features depend on `core`; `core` NEVER depends on a feature.** Core is the stable base; features are the volatile leaves. A `core` importing a feature is a red flag (inverted dependency).
- **Failure modes**: **bloated core** (everything dumped in → a second layer-first app) and **leaky features** (feature A imports feature B's internals → coupling — [03_feature_boundaries_and_dependencies.md](03_feature_boundaries_and_dependencies.md)).

## Memory Representation

Not runtime — a **tree + dependency direction**. Each feature is a subtree (domain/data/presentation + wiring); core is a shared subtree features import. The invariant: edges go feature→core, never core→feature.

## Compiler Behavior

Barrel files + private (`_`) members let a feature expose a **public API** and hide internals; import lints can enforce feature→core-only and no core→feature imports (checkable boundaries).

## Runtime Behavior

At startup, each feature registers its DI + routes (into core's container/router); core infra (client, theme) is shared. Organization doesn't change runtime behavior, only wiring locality.

## Flutter Engine Behavior

Not applicable.

## Dart VM Behavior

Not applicable (until features become packages — [Module 45](../45%20Modular%20Architecture/README.md)).

## Examples

```text
lib/
  core/
    di/            (getIt setup, registerCore)
    routing/       (root router)
    network/       (dio client + interceptors)
    error/         (Result, Failure hierarchy)
    ui/            (theme, PrimaryButton, AppScaffold)
    util/          (Money, formatters, extensions)
  features/
    cart/
      domain/      (Cart, AddToCart, CartRepository interface)
      data/        (CartDto, CartRemote/Local, CartRepositoryImpl)
      presentation/(CartViewModel, CartScreen, widgets)
      cart_di.dart      (registerCart -> registers repo/use cases/VM)
      cart_routes.dart  (cart routes)
      cart.dart         (barrel: public API only)
    auth/  home/  profile/  ...
```

```dart
// Feature self-registers its DI (called from core's composition root)
void registerCart(GetIt di) {
  di.registerLazySingleton<CartRepository>(() => CartRepositoryImpl(di())); // uses core network client
  di.registerFactory(() => AddToCart(di<CartRepository>()));
  di.registerFactory(() => CartViewModel(di<AddToCart>()));
}
// core/di/register_core.dart calls registerCore() then each feature's registerX(di).
// A `Money` value object used by cart + checkout + wallet -> promote to core/util (rule of three).
```

## Diagrams

```mermaid
flowchart LR
    Feature[feature (volatile)] -->|imports| Core[core (stable)]
    Core -.NEVER imports.-> Feature
    Feature --> Internal[domain/data/presentation + wiring]
    Core --> Shared[infra + ui + util]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| `core` imports a feature | Inverted dependency | Core stays feature-agnostic (features→core only) |
| Bloated core (junk drawer) | Second layer-first blob | Only cross-cutting/stable/reusable in core |
| Pre-promoting feature-specific code to core | Wrong abstraction | Keep local until ≥2–3 features need it |
| Inconsistent feature internals | Hard to navigate | Standard `domain/data/presentation` + wiring |
| No public API/barrel | Internals leak | Barrel + private members |
| Feature imports another feature's internals | Coupling | Interact via core/interfaces ([boundaries](03_feature_boundaries_and_dependencies.md)) |
| DI/routes centralized away from features | Low cohesion | Feature self-registers DI + routes |

## Best Practices

- Give every feature a **consistent internal structure** (`domain/data/presentation` + `*_di.dart`/`*_routes.dart` + a barrel exposing a **public API**); keep internals private.
- Put **only cross-cutting, stable, reusable** code in **`core`** (infra + design system + shared value objects/utils); apply the **rule of three** before promoting.
- Enforce the **dependency direction**: **features → core**, never **core → feature**; keep core a clean, feature-agnostic base.
- Let **features self-register** DI + routes into core's composition root/router; avoid a bloated core and leaky features.

## Performance

No runtime cost. The benefit is developer velocity: consistent slices are fast to navigate/onboard; a lean core avoids the layer-first scatter returning through the back door. (Package extraction later can improve build times — [Module 45](../45%20Modular%20Architecture/README.md).)

## Advantages / Disadvantages

- **+** Predictable, cohesive slices; clear home for shared code; enforceable dependency direction; self-registering features; modularization-ready.
- **−** Placement judgment (feature vs core), risk of bloated core / leaky features, barrel/public-API discipline, some wiring boilerplate.

## Interview Questions

1. **🟢 What's inside a feature folder?** — Its own `domain/`, `data/`, `presentation/` plus feature wiring (DI registration, routes) and a barrel exposing its public API.
2. **🟢 What belongs in `core`?** — Cross-cutting, feature-agnostic, stable, reusable code: DI/routing/network client/`Result`, theme/shared widgets, shared value objects/formatters.
3. **🟡 What's the cardinal dependency rule?** — Features depend on core; **core never depends on a feature** (stable base vs volatile leaves).
4. **🟡 When do you promote code from a feature to core?** — When ≥2–3 features genuinely need it (rule of three) — not preemptively, to avoid wrong abstractions.
5. **🟡 How do features self-register?** — Each exposes `registerX(di)`/routes that core's composition root/router calls at startup — keeping wiring cohesive.
6. **🔴 What are the two failure modes?** — A bloated core (junk drawer → second layer-first blob) and leaky features (importing each other's internals → coupling).
7. **🔴 How do you hide a feature's internals?** — A barrel exposing only the public API + private (`_`) members; lint import boundaries.

## Senior Engineer Tips

- Treat `core` as a curated library with the same "would I publish this?" bar; the moment it becomes a dumping ground, you've recreated layer-first inside it.
- Resist promoting code to core until multiple features truly need it — premature promotion creates wrong shared abstractions that are painful to unwind.
- Standardize the feature template (domain/data/presentation + `_di`/`_routes` + barrel) and have features self-register; consistency + cohesion are what make feature-first pay off.

## Architect Perspective

The feature-slice + `core` split operationalizes stable-dependencies: `core` is the stable, feature-agnostic base; features are volatile leaves that depend on it, never the reverse. Consistent internal structure (Clean layers), self-registration, and public-API barrels make features cohesive and swappable, while a disciplined core avoids the layer-first blob returning. This structure is what a package/module boundary later formalizes ([03_feature_boundaries_and_dependencies.md](03_feature_boundaries_and_dependencies.md), [Module 45](../45%20Modular%20Architecture/README.md), [Module 40](../40%20Clean%20Architecture/README.md)).

## Summary

- Feature = `domain/data/presentation` + wiring (`*_di`/`*_routes`) + barrel (public API); consistent across features.
- `core` = cross-cutting, stable, reusable code (infra + design system + shared value objects); features → core, **never** core → feature.
- Promote to core by the rule of three; avoid bloated core / leaky features; features self-register DI + routes.

## Revision Notes

- Feature internals: `domain/` (entities/use cases/interfaces), `data/` (dtos/sources/impl), `presentation/` (VM/widgets), `*_di.dart`/`*_routes.dart`, barrel (public API + private members).
- `core`/`shared`: DI/routing/network/`Result`/errors, theme/shared widgets/l10n, shared value objects/formatters/extensions.
- Direction: features→core only (core feature-agnostic); rule of three to promote; features self-register DI+routes; avoid bloated core & leaky features.

## Practice Questions

1. What's the standard internal structure of a feature?
2. What is (and isn't) allowed in `core`, and why the dependency direction?
3. When do you promote code from a feature to core?

## Coding Questions

1. Lay out a `features/cart/` slice + a `core/` tree.
2. Write `registerCart(di)` self-registration using core's network client.
3. Classify five items as feature-local vs core with justification.

## Mini Project

**Feature slice + core (Flutter):** Structure a `features/cart/` slice (domain/data/presentation + `cart_di.dart`/`cart_routes.dart` + barrel exposing a public API) and a `core/` module (DI, network client, `Result`, theme, a shared `Money` value object). Classify a given list of items as feature-local vs core (rule of three), and ensure features depend on core (never the reverse). Acceptance: consistent feature internals + wiring + barrel; core holds only cross-cutting/stable/reusable code; features→core dependency only; placement decisions justified; feature self-registers DI/routes.
