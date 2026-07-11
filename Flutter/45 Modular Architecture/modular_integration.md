# Modular Integration (Capstone: A Modular Monorepo Skeleton)

> Assemble the full modular architecture: a **melos monorepo** with an `app` package (composition root) depending on **feature packages** (`feature_auth`, `feature_cart`) and **shared packages** (`core`, `contracts`), each a **Clean slice** with a **minimal public API** (`export`s over `lib/src/`), interacting **only via contracts + DI** on an **acyclic star graph**, managed with **melos scripts** and **incremental CI**, with **per-package ownership/versioning**. This is feature-first with compiler-enforced boundaries and build/team payoffs — the enterprise-scale chassis and the bridge to DDD and scalable apps ([Module 46](../46%20Domain%20Driven%20Design/README.md), [Module 47](../47%20Scalable%20Applications/README.md)).

## Introduction

This module capstone composes fundamentals, melos, boundaries/contracts, and build/versioning into one runnable modular monorepo skeleton — the reference structure teams grow on. It shows the package graph, the composition root wiring, and the operational setup, plus an honest right-sizing note.

## Why this concept exists

The pieces pay off only assembled: packages + melos + contracts + composition root + incremental CI + ownership = a codebase that's hard-bounded, fast to build, ownable, and reusable at scale. This capstone provides that assembled reference and cements the when/how.

## Real-world analogy

It's a **planned industrial park**: standardized plots (packages) with locked gates (public APIs), a shared utilities hub (core) and a standards office (contracts), a central operations building that connects tenants (app/composition root), and a park management system (melos + CI) that services only the plots that changed and tracks who owns which plot. Tenants collaborate through standards, never by trespassing — and a successful plot can be franchised elsewhere (reuse).

## Problem Statement

Build a modular monorepo skeleton: `app` (composition root + router) + `core` + `contracts` + `feature_auth` + `feature_cart`, path-linked (acyclic star), each a Clean slice with a minimal public API, cross-module interaction via `contracts` + DI wired in `app`, melos scripts + incremental CI, CODEOWNERS + versioning policy — with a documented when-to-modularize rationale. You'll compose every file in this module.

## Internal Working

```mermaid
flowchart TD
    App[app (composition root + router)] --> FAuth[feature_auth] & FCart[feature_cart] & Core[core] & Contracts[contracts]
    FAuth --> Core & Contracts
    FCart --> Core & Contracts
    FCart -. implements .-> CartFacade[contracts: CartFacade]
    App -->|DI: bind impls -> contracts| Contracts
    Melos[melos.yaml + CI] --- Repo[monorepo]
    Note[acyclic star: features -> core/contracts; app -> all (wiring)]
```

- **Monorepo layout** ([monorepo_and_melos.md](monorepo_and_melos.md)): `apps/app` + `packages/{core, contracts, feature_auth, feature_cart}`; path deps; `melos.yaml` (globs + analyze/test/gen scripts).
- **Package graph (acyclic star)** ([module_boundaries_and_contracts.md](module_boundaries_and_contracts.md)): features → **core + contracts** (never each other); **app → everything** (to wire). Contracts/core are stable roots; features are leaves; app is the top.
- **Each module = a Clean slice** ([Module 40](../40%20Clean%20Architecture/README.md)) with a **minimal public API** (`export`s; `lib/src/` private) and **self-registration** (`registerX(di)` + routes).
- **Contracts + DI wiring**: shared interfaces/DTOs/events in `contracts`; `feature_cart` **implements** `CartFacade`; `feature_auth`/`checkout` **depend on the contract**; the **`app` composition root** binds impls→contracts and aggregates routes ([Module 14](../14%20Dependency%20Injection/README.md)).
- **Operational setup** ([build_versioning_and_teams.md](build_versioning_and_teams.md)): melos **bootstrap** + **`--since` incremental CI**; **CODEOWNERS** per package; **per-package versioning**; **stable core/contracts**.
- **Right-sizing (honest)**: this full chassis suits **large/multi-team/reuse** scenarios; a small app should stay **feature-first folders** and **grow into** this from a clean base ([Module 44](../44%20Feature%20First%20Architecture/README.md)).
- **Payoff realized**: compiler-enforced boundaries, incremental builds, ownership, reuse — the assembled benefits of the module.

## Memory Representation

Not runtime — a repo of packages + an acyclic package graph annotated with versions/owners; melos manages the workspace; the app composition root builds the DI graph + router at startup by invoking each feature's self-registration.

## Compiler Behavior

Declared path deps + `export`/`lib/src/` privacy enforce boundaries structurally; incremental compilation caches unchanged packages; undeclared/cyclic deps fail. Consumers compile against contracts without knowing implementing features.

## Runtime Behavior

`main` → app composition root → registerCore + per-feature register (incl. cart's `CartFacade` impl) + route aggregation → app runs; cross-module calls resolve to contract implementations via DI. Identical runtime to feature-first; packaging affects build/CI only.

## Flutter Engine Behavior

Standard; routing via the app's root router (navigate across modules by route).

## Dart VM Behavior

Package-granular incremental builds; melos scopes analyze/test to changed packages for fast CI.

## Examples

```text
monorepo/
  melos.yaml
  apps/app/        (composition root, root router, main.dart) -> depends on all packages
  packages/
    core/          (di, network, Result, theme, value objects)   [stable root]
    contracts/     (CartFacade, DTOs, events)                     [stable root]
    feature_auth/  (Clean slice; depends on core+contracts)       [leaf]
    feature_cart/  (Clean slice; implements CartFacade)           [leaf]
```

```dart
// apps/app/lib/composition.dart — the ONLY place that knows all modules; wires impls->contracts
Future<void> bootstrap(GetIt di) async {
  registerCore(di);                                   // core (stable)
  registerAuth(di);                                   // feature self-registration
  registerCart(di);                                   // registers CartFacadeImpl -> CartFacade
}
final router = GoRouter(routes: [...authRoutes, ...cartRoutes]); // aggregate feature routes

// packages/feature_checkout/... depends on contracts only:
class CheckoutVm { final CartFacade cart; CheckoutVm(this.cart); } // no dep on feature_cart
```

```bash
# Operational
melos bootstrap
melos run analyze --since=origin/main
melos run test    --since=origin/main    # incremental CI
```

## Diagrams

```mermaid
flowchart LR
    Main[main.dart] --> Boot[app: bootstrap (composition root)]
    Boot --> Core[registerCore]
    Boot --> Feats[registerAuth/Cart (self-register + CartFacade impl)]
    Feats -->|routes| Router[root router]
    Feats -->|deps| Roots[core + contracts (stable)]
    CI[melos --since] --> Fast[incremental pipeline]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| Feature package depends on another feature | Coupling/cyclic | Depend on contracts/core; wire in app |
| Exporting internals (`src/**`) | No real boundary | Minimal public API |
| Churny core/contracts | Rebuilds everything | Keep roots stable/low-churn |
| Full CI every build | No incremental payoff | `--since` scoped runs |
| Wiring impls inside features | Features learn of each other | Wire in app composition root |
| No ownership/versioning | Diffuse responsibility | CODEOWNERS + per-package versions |
| Modular chassis on a small app | Overhead > payoff | Feature-first folders; grow into it |

## Best Practices

- Structure a **melos monorepo** (`apps/app` + `packages/{core, contracts, feature_*}`) with **path deps** on an **acyclic star** (features → core/contracts; app → all).
- Make each module a **Clean slice** with a **minimal public API** (`export`/`src`) that **self-registers**; interact **cross-module via contracts + DI** wired in the **app composition root**.
- Keep **core/contracts stable/low-churn** + **versioned** (contracts as published API); use **incremental CI** (`--since`) and **CODEOWNERS** per package.
- **Right-size**: adopt this at justifying scale; otherwise stay feature-first and **grow into** modules from a clean base.

## Performance

Build/CI scales with the changed set (incremental, `--since`) given **stable roots** and a **shallow acyclic graph**; parallel per-package CI compounds it. Runtime is identical to feature-first. The chassis's value is build speed + team autonomy + reuse at scale.

## Advantages / Disadvantages

- **+** Compiler-enforced boundaries, incremental/parallel CI, ownership + independent versioning, cross-app reuse, consistent Clean slices — enterprise-ready.
- **−** Workspace tooling + contract/DI wiring + versioning/governance overhead; overkill for small apps; requires stable-roots + acyclic discipline.

## Interview Questions

1. **🟢 What's in a modular monorepo skeleton?** — `apps/app` (composition root/router) + `packages/{core, contracts, feature_*}`, path-linked on an acyclic star, managed by melos.
2. **🟢 How do modules interact?** — Via a `contracts` package (interfaces/DTOs/events): providers implement, consumers depend on it; the app composition root wires impls→contracts via DI — no feature→feature deps.
3. **🟡 Where is cross-module wiring done, and why there?** — In the `app` composition root — the only place that knows all modules — so features stay unaware of each other's concretes.
4. **🟡 How is CI kept fast?** — melos `--since` runs analyze/test only on changed packages + dependents; stable core/contracts keep the changed set small.
5. **🟡 How do ownership and versioning work?** — Package = ownership unit (CODEOWNERS) with its own version/changelog; contracts/core are stable, gated, versioned as published APIs.
6. **🔴 Why must the graph be an acyclic star and roots stable?** — Cyclic deps can't build; churny roots rebuild everything — a star with stable core/contracts preserves incrementality.
7. **🔴 When is this chassis justified vs overkill?** — Justified at scale (build pain, multiple teams, reuse); overkill for small/single-team apps — stay feature-first and grow into it.

## Senior Engineer Tips

- Build one exemplary feature package + the app composition root + melos/CI wiring first; it's the template every module follows and proves the incremental-build payoff.
- Keep the app the sole wiring point (impls→contracts) and keep core/contracts stable and gated; those two disciplines protect both the acyclic graph and your CI speed.
- Modularize from a clean feature-first base only when signals justify it; extraction should be mechanical (locked-door feature slices), and premature modularization is pure overhead.

## Architect Perspective

The modular monorepo is the structural endgame of the feature-first arc: cohesive Clean slices with **compiler-enforced** boundaries, interacting through a neutral contracts package on an acyclic star, wired at a single app composition root, and operated with incremental CI + per-package ownership/versioning. It delivers isolation, build speed, autonomy, and reuse — the platform for enterprise-scale delivery and a natural fit for module-per-bounded-context DDD. Its power is real and so is its overhead, so it's a **scale-justified** choice built on a clean feature-first foundation ([Module 44](../44%20Feature%20First%20Architecture/README.md), [Module 46](../46%20Domain%20Driven%20Design/README.md), [Module 47](../47%20Scalable%20Applications/README.md), [Module 50](../50%20CI%20CD/README.md)).

## Summary

- Skeleton: melos monorepo — `apps/app` (composition root/router) + `packages/{core, contracts, feature_*}`, path deps, acyclic star (features→core/contracts; app→all).
- Each module = Clean slice + minimal public API + self-registration; cross-module via contracts + DI wired in app; incremental CI (`--since`) + CODEOWNERS + per-package versioning; stable core/contracts.
- Delivers enforced boundaries + build speed + ownership + reuse; right-size — grow into it from feature-first.

## Revision Notes

- Layout: `apps/app` (composition root + router) + `packages/{core, contracts, feature_auth, feature_cart}`; path deps; melos scripts.
- Graph: acyclic star (features→core/contracts, app→all); each module Clean slice + minimal public API (`export`/`src`) + self-register; cross-module via contracts+DI wired in app.
- Ops: bootstrap + `--since` incremental CI; CODEOWNERS per package; per-package versioning; stable/low-churn core/contracts; right-size (grow from feature-first).

## Practice Questions

1. Sketch the package graph and explain why it's an acyclic star.
2. Where and how is cross-module interaction wired?
3. What operational payoffs does this skeleton deliver, and what discipline sustains them?

## Coding Questions

1. Lay out the monorepo (app + core + contracts + 2 features) with path deps + melos.yaml.
2. Wire the app composition root (self-registering features + contract impl bindings + route aggregation).
3. Add incremental CI commands + a CODEOWNERS mapping.

## Mini Project

**Modular monorepo skeleton (capstone — Flutter):** Build a melos monorepo — `apps/app` (composition root + root router), `packages/core`, `packages/contracts` (`CartFacade` + DTO), `feature_auth`, `feature_cart` (implements `CartFacade`) — each a Clean slice with a minimal public API + self-registration, path-linked on an acyclic star (features→core/contracts; app→all), with cross-module interaction via contracts + DI wired in `app`, melos scripts + `--since` CI, CODEOWNERS, and a versioning/stability policy. Document the when-to-modularize rationale. Acceptance: acyclic star package graph (no feature→feature deps); minimal public APIs (`export`/`src`); contracts + DI wiring in app (self-registering features); incremental CI + CODEOWNERS + versioning; stable core/contracts; right-sizing justified; runs end-to-end.
