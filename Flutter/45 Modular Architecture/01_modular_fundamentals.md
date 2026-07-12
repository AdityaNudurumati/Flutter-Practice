# Modular Fundamentals (Packages as Hard Boundaries)

> Modular architecture turns each feature (and `core`) into a **separate Dart/Flutter package** so boundaries are **enforced by the compiler/build system**, not by discipline: a package can only use what another package **`export`s**, and if it doesn't declare a dependency in `pubspec.yaml`, it **can't import it at all**. This upgrades feature-first's *lint-enforced* boundaries to *build-enforced* ones, and adds **incremental builds, independent versioning, ownership, and reuse** — at the cost of workspace tooling and wiring overhead. So the core question isn't *how* but **when**: modularize when scale (build time, team count, reuse) justifies the overhead.

## Introduction

This file establishes what a "module" is (a package), why package boundaries are qualitatively stronger than folder boundaries, the concrete benefits, and — crucially — the **when-to-modularize** decision. It's the conceptual base for the monorepo/contracts/build files.

## Why this concept exists

Feature-first folders keep boundaries by convention + lints, which erode silently as teams grow. Packages make boundaries **structural**: the dependency must be declared and only public API is reachable. This structural enforcement, plus per-package builds and versioning, is what large, multi-team codebases need — but it's overhead a small app doesn't.

## Real-world analogy

Feature-first folders are **rooms in an open-plan office** — labeled zones, but anyone can wander in (discipline/lints keep order). Modules are **separate offices with locked doors and a reception desk (public API)**: you can only enter through reception, and to visit at all you need a listed appointment (declared dependency). Building 2 offices is easy; running 40 needs a facilities system (melos) — and you only build offices when the open plan gets too crowded.

## Problem Statement

Decide whether to modularize a growing feature-first app: weigh compiler-enforced boundaries + build speed + team autonomy against tooling/wiring overhead, and identify the signals that justify it. You'll articulate packages-as-boundaries and a when-to-modularize rubric.

## Internal Working

```mermaid
flowchart TD
    subgraph Feature-first (folders)
      F[features/cart/ ...] -->|lint-enforced| Bound1[boundaries by discipline]
    end
    subgraph Modular (packages)
      P[package: feature_cart] -->|pubspec dependency + export| Bound2[boundaries by compiler/build]
    end
    Bound2 --> Benefits[incremental builds, versioning, ownership, reuse]
    Note[can't import undeclared package; can't reach un-exported code]
```

- **A module = a package**: each feature/core becomes a Dart/Flutter package (its own `pubspec.yaml`, `lib/`, tests). In a monorepo they're **path dependencies** ([02_monorepo_and_melos.md](02_monorepo_and_melos.md)).
- **Boundaries become structural (the key upgrade)**:
  - **Declared dependencies**: a package can only import another if it lists it in `pubspec.yaml` — no accidental cross-feature imports.
  - **Public API only**: consumers can only use what a package **`export`s** from its main library; everything else is effectively private ([03_module_boundaries_and_contracts.md](03_module_boundaries_and_contracts.md)).
  - This is **compiler/build-enforced**, not lint-enforced — boundaries can't erode by carelessness.
- **Benefits over feature-first folders**:
  - **Enforced isolation** (structural, not convention).
  - **Incremental/parallel builds**: only changed packages (+ dependents) rebuild/re-test → faster CI at scale ([04_build_versioning_and_teams.md](04_build_versioning_and_teams.md)).
  - **Independent versioning + ownership**: teams own packages with their own version/changelog.
  - **Reuse across apps**: a package (e.g., `core`, `design_system`) can be shared by multiple apps.
- **Costs (be honest)**:
  - **Tooling overhead**: workspace management (melos), `pubspec` maintenance, bootstrapping.
  - **Wiring overhead**: cross-module interaction via contracts + DI (more ceremony than a folder import).
  - **Refactor friction**: moving code across package boundaries is heavier than across folders.
- **When to modularize (the real question)** — signals that justify the overhead:
  - **Build/test times hurting** (large single package → slow CI).
  - **Multiple teams** needing hard isolation + independent ownership.
  - **Reuse** across apps/white-label products.
  - **Very large codebase** where folder discipline no longer holds.
  - **Not** for small/single-team apps → feature-first folders suffice; **grow into** modules from a clean feature-first base ([Module 44](../44%20Feature%20First%20Architecture/README.md)).
- **Same internals**: each module is still a **Clean slice** (domain/data/presentation — [Module 40](../40%20Clean%20Architecture/README.md)); modularization changes the **boundary mechanism**, not the internal architecture.

## Memory Representation

Not runtime — a **package dependency graph** (must be **acyclic**). Each node is a package with a public API; edges are declared `pubspec` dependencies. The invariant: features → core/contracts, never feature → feature.

## Compiler Behavior

**The whole point**: the compiler/pub resolves only declared dependencies and only exported symbols are visible — cross-package access is **structurally impossible** unless intended. Undeclared import = compile error.

## Runtime Behavior

No runtime change vs feature-first — same code runs; DI composition root still wires modules at startup. Packaging affects **build/tooling**, not runtime behavior.

## Flutter Engine Behavior

Not applicable.

## Dart VM Behavior

Package granularity enables **incremental compilation** — changed packages (and dependents) recompile, others are cached — improving build times at scale.

## Examples

```yaml
# packages/feature_cart/pubspec.yaml — declares ONLY what it may use
name: feature_cart
dependencies:
  core: { path: ../core }         # allowed
  contracts: { path: ../contracts } # allowed
  # feature_auth is NOT listed -> importing it is a COMPILE ERROR (structural boundary)
```

```dart
// packages/feature_cart/lib/feature_cart.dart — the PUBLIC API (only these are visible)
export 'src/presentation/cart_screen.dart';
export 'src/cart_di.dart' show registerCart;   // controlled surface
// src/** internals are NOT exported -> other packages can't reach them
```

```text
When-to-modularize checklist:
  slow builds/CI on a big package .............. modularize (incremental builds)
  multiple teams needing isolation/ownership ... modularize
  reuse across apps / white-label .............. modularize (shared packages)
  small, single-team app ....................... DON'T (feature-first folders)
  ->  grow INTO modules from a clean feature-first base
```

## Diagrams

```mermaid
flowchart LR
    Folders[feature-first folders] -->|lints (erode)| Soft[soft boundaries]
    Packages[modules/packages] -->|pubspec + export (compiler)| Hard[hard boundaries]
    Hard --> Payoff[incremental builds + versioning + ownership + reuse]
    Cost[overhead: tooling + wiring] -.tradeoff.-> Packages
```

## Common Mistakes

| Mistake | Why it's a problem | Fix |
|---------|-------------------|-----|
| Modularizing a small/single-team app | Overhead without payoff | Feature-first folders; grow into modules |
| Feature package depending on another feature | Coupling, cyclic risk | Depend on core/contracts only (acyclic) |
| Exporting everything (`src/**`) | No real boundary | Export only the public API |
| Big-bang split into packages | Risky/disruptive | Extract mature features incrementally |
| Different internal architecture per module | Inconsistent | Keep each a Clean slice |
| Ignoring build/versioning benefits | Miss the payoff | Leverage incremental builds + per-package versions |
| Circular package deps | Won't resolve/build | Keep the graph acyclic (star around core) |

## Best Practices

- Treat a **module as a package** with **compiler-enforced boundaries** (declared deps + controlled `export`s); keep the package graph **acyclic** (features → core/contracts, never each other).
- **Modularize when scale justifies it** (slow builds, multiple teams, reuse) — **not** for small/single-team apps; **grow into** modules from a clean feature-first base.
- Keep each module a **Clean slice** internally; expose a **minimal public API**; wire cross-module via **contracts + DI**.
- Leverage the payoffs deliberately: **incremental/parallel builds, independent versioning, ownership, reuse**; accept the **tooling/wiring overhead** consciously.

## Performance

Runtime-neutral; the performance win is **build/CI time** via incremental compilation (only changed packages rebuild/re-test) and parallelism — significant on large codebases, negligible on small ones (where overhead dominates). This is the quantitative half of the when-to-modularize decision ([04_build_versioning_and_teams.md](04_build_versioning_and_teams.md)).

## Advantages / Disadvantages

- **+** Compiler-enforced isolation, incremental/parallel builds, independent versioning/ownership, cross-app reuse, team autonomy.
- **−** Tooling (workspace/melos) + wiring (contracts/DI) + refactor overhead; overkill for small apps; requires acyclic-graph discipline.

## Interview Questions

1. **🟢 What is a module in modular architecture?** — A separate Dart/Flutter package (own pubspec/lib/tests), typically a feature or shared library, with a controlled public API.
2. **🟢 How are package boundaries stronger than folder boundaries?** — They're compiler/build-enforced: you can only import declared dependencies and only their exported symbols — no reliance on discipline/lints.
3. **🟡 What are the main benefits of modularizing?** — Enforced isolation, incremental/parallel builds, independent versioning/ownership, and cross-app reuse.
4. **🟡 What are the costs?** — Workspace tooling, cross-module wiring via contracts/DI, and heavier refactors across boundaries.
5. **🟡 When should you modularize (and not)?** — When build times hurt, multiple teams need isolation, or reuse is needed; not for small/single-team apps — grow into it from feature-first.
6. **🔴 Does modularization change a module's internal architecture?** — No — each module is still a Clean slice; only the boundary mechanism (package vs folder) changes.
7. **🔴 Why must the package graph be acyclic?** — Cyclic package dependencies can't be resolved/built; keep features depending on core/contracts (star), never on each other.

## Senior Engineer Tips

- Modularize reactively on real signals (CI pain, team count, reuse), not aspirationally; premature package splits add tooling/wiring cost with no payoff on a small app.
- Keep the package graph a star around core/contracts and export only the public API; the two ways modular apps rot are cyclic deps and packages that export their internals.
- Build a clean feature-first base first so extraction is mechanical; modules are just feature slices with a locked door — the internal Clean architecture is unchanged.

## Architect Perspective

Modular architecture is feature-first with **structural enforcement**: packages make boundaries a build-time fact, enabling incremental builds, independent versioning/ownership, and reuse. It's the same cohesion/DIP discipline, now enforced by the compiler and rewarded by tooling — but it carries overhead, so it's a **scale decision**, not a default. Adopted at the right time (build/team/reuse pressure) from a clean feature-first base, it's how large Flutter codebases stay buildable, ownable, and evolvable — and it aligns naturally with a module-per-bounded-context DDD split ([Module 44](../44%20Feature%20First%20Architecture/README.md), [Module 46](../46%20Domain%20Driven%20Design/README.md), [Module 47](../47%20Scalable%20Applications/README.md)).

## Summary

- A module is a package; boundaries become compiler/build-enforced (declared deps + exports only) — stronger than folder/lint boundaries.
- Benefits: incremental/parallel builds, independent versioning/ownership, reuse; costs: tooling + wiring + refactor overhead.
- Modularize when scale justifies (build time/teams/reuse), not for small apps; keep modules Clean slices on an acyclic star-around-core graph.

## Revision Notes

- Module = package (pubspec/lib/tests); boundaries compiler-enforced (declared deps + `export` public API only) vs feature-first lint boundaries.
- Benefits: incremental/parallel builds, versioning, ownership, cross-app reuse. Costs: melos tooling, contract/DI wiring, refactor friction.
- When: slow builds / multi-team / reuse → modularize (grow from feature-first); not for small/single-team. Acyclic star (features→core/contracts). Internals still Clean.

## Practice Questions

1. Why are package boundaries qualitatively stronger than folder boundaries?
2. List concrete benefits and costs of modularizing.
3. Give the signals for when to (and not to) modularize.

## Coding Questions

1. Write a feature package `pubspec.yaml` declaring only core/contracts deps.
2. Define a package's public API via `export`s (hiding `src/**`).
3. Draw the acyclic package graph for app + 2 features + core/contracts.

## Mini Project

**Modularization decision + boundary sketch (Flutter):** For a growing feature-first app, write a when-to-modularize rationale (signals present/absent) and sketch the target package graph (app → feature packages → core/contracts, acyclic star), including one feature package's `pubspec.yaml` (declared deps only) and its public-API `export`s (hiding internals). Acceptance: packages-as-hard-boundaries explained; benefits/costs weighed; decision justified by real signals; acyclic star graph; example pubspec (declared deps only) + minimal public API; internals stay Clean.
