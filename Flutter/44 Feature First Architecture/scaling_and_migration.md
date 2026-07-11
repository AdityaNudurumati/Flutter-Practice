# Scaling & Migrating to Feature-First

> Feature-first scales from a handful of folders to dozens of features and, eventually, **separate packages** (the bridge to modular architecture — [Module 45](../45%20Modular%20Architecture/README.md)): as the app grows you keep the same slice template, promote shared code to `core` by the rule of three, and extract mature/reusable features into local packages for **enforced boundaries + faster builds**. Migrating a **layer-first** codebase is done **incrementally, feature by feature** (strangler-fig): stand up `features/` + `core/`, move one feature's scattered pieces into its slice, repeat — never a risky big-bang rewrite.

## Introduction

This file covers the two growth dimensions — **scaling** an existing feature-first app (many features → packages) and **migrating** a layer-first app to feature-first incrementally. It's the "how do I actually get here and keep growing" companion to the structure/boundary files.

## Why this concept exists

Teams rarely start clean: they have a layer-first codebase that's tangling, or a feature-first app outgrowing a single package. Both need a **safe, incremental path** — big-bang rewrites fail. Knowing the strangler-fig migration and the scale-up-to-packages progression lets you improve architecture continuously without halting delivery.

## Real-world analogy

Migrating layer-first → feature-first is **renovating a house while living in it**: you don't demolish everything (big-bang); you renovate **one room at a time** (one feature), keeping the house habitable throughout. Scaling to packages is later **converting rooms into self-contained units** (apartments) with their own utilities and locked doors (enforced boundaries) as the building grows.

## Problem Statement

You have a tangled layer-first app and need to migrate to feature-first without stopping shipping; later, as features multiply, decide when/how to extract features into packages. You'll plan an incremental migration and a scaling path.

## Internal Working

```mermaid
flowchart TD
    subgraph Migration (incremental, strangler-fig)
      M1[stand up features/ + core/] --> M2[move ONE feature's pieces into its slice]
      M2 --> M3[wire its DI/routes; delete old scattered files]
      M3 --> M4[repeat per feature; ship continuously]
    end
    subgraph Scaling
      S1[many features in one package] --> S2[promote shared -> core (rule of three)]
      S2 --> S3[extract mature features -> local packages (enforced boundaries + build speed)]
    end
    Note[never big-bang; keep boundaries acyclic]
```

- **Migrating layer-first → feature-first (strangler-fig, incremental)**:
  1. **Create the target structure**: add `features/` and `core/` alongside the existing layout.
  2. **Move cross-cutting first**: relocate shared infra/design-system/utilities into **`core`** (network client, theme, `Result`).
  3. **Migrate one feature at a time**: pick a **cohesive, low-risk** feature; gather its scattered pieces (its model/view/controller/repo) into `features/<name>/{domain,data,presentation}`; wire its **DI + routes**; **delete** the old files. Ship. Repeat.
  4. **Fix boundaries as you go**: when a migrated feature reaches into another's internals, introduce a **core contract** ([feature_boundaries_and_dependencies.md](feature_boundaries_and_dependencies.md)).
  5. **Coexist during transition**: layer-first and feature-first can **coexist**; you're not blocked — the tree just gets progressively feature-first. This is the **strangler-fig** pattern (new structure grows around the old until it's replaced).
  - **Avoid big-bang rewrites** (high risk, long freeze, merge hell).
- **Scaling within a single package (dozens of features)**: keep the **consistent slice template**; promote shared code to `core` by the **rule of three**; consider **sub-grouping** features (`features/shopping/{cart,checkout}`) if natural; keep the **feature graph acyclic** (star around core).
- **Scaling to packages/modules (the bridge to [Module 45](../45%20Modular%20Architecture/README.md))**:
  - Extract **mature, stable, reusable** features (and `core`) into **local packages** (path dependencies in a monorepo / melos workspace).
  - **Why**: **enforced boundaries** (a package literally can't import another's private code), **faster/incremental builds**, **independent versioning/ownership**, potential reuse across apps.
  - **When**: build times hurt, teams need hard isolation, or a feature is reused elsewhere — not prematurely (packages add overhead).
- **Enforcement throughout**: import lints during single-package phase; **package boundaries** once extracted — the same acyclic, star-around-core graph, now hard-enforced.
- **Right-sizing the journey**: small app → single package feature-first; large/multi-team → package-per-feature. Migrate/scale **only as pain justifies**.

## Memory Representation

Not runtime — an **evolving source tree + dependency graph**. Migration transforms a layer-first tree into feature slices incrementally; scaling optionally lifts slices into packages. The invariant across all phases: acyclic, star-around-core dependencies.

## Compiler Behavior

Single-package phase: import lints enforce boundaries. Package phase: the **build system enforces** boundaries (can't import a package's non-exported code) and enables **incremental compilation** per package.

## Runtime Behavior

Organization/packaging don't change runtime behavior; packaging can improve **build**/tooling performance. DI composition root still wires everything at startup.

## Flutter Engine Behavior

Not applicable.

## Dart VM Behavior

Package extraction enables **incremental/parallel builds** (only changed packages rebuild) — a tooling/build-time benefit ([Module 45](../45%20Modular%20Architecture/README.md)).

## Examples

```text
Migration order (strangler-fig), shipping after each step:
  1) add features/ + core/                       (structure)
  2) move network client, theme, Result -> core/ (cross-cutting first)
  3) migrate features/profile/ (low-risk, cohesive); wire DI+routes; delete old files
  4) migrate features/auth/; introduce core contracts where features interacted
  5) ... repeat per feature; layer-first shrinks as feature-first grows
```

```yaml
# Scaling to packages (monorepo, e.g. melos): features & core become path packages
# packages/core, packages/feature_cart, packages/feature_auth ...
# app/pubspec.yaml
dependencies:
  core: { path: ../packages/core }
  feature_cart: { path: ../packages/feature_cart }   # boundaries now build-enforced
  feature_auth: { path: ../packages/feature_auth }
# feature_cart depends on core; NOT on feature_auth (acyclic, star around core)
```

## Diagrams

```mermaid
flowchart LR
    Layer[layer-first (tangled)] -->|one feature at a time| Feat[feature-first (single package)]
    Feat -->|grows / build pain / teams| Pkgs[packages per feature + core]
    Pkgs --> Enforced[hard boundaries + faster builds]
```

## Common Mistakes

| Mistake | Why it fails | Fix |
|---------|-------------|-----|
| Big-bang rewrite | High risk, long freeze, merge hell | Incremental strangler-fig, feature by feature |
| Migrating a high-risk feature first | Risky learning curve | Start with a low-risk cohesive feature |
| Not moving cross-cutting to core first | Features re-scatter shared code | Relocate infra/design system to core early |
| Premature package extraction | Overhead without payoff | Extract only mature/reused features when pain justifies |
| Leaving old files after migrating | Duplication/confusion | Delete migrated originals |
| Ignoring boundaries during migration | Re-tangling | Introduce core contracts as needed |
| Cyclic feature deps at scale | Un-extractable | Keep acyclic (star around core) |

## Best Practices

- Migrate **incrementally (strangler-fig)**: stand up `features/`+`core/`, move **cross-cutting to core first**, then migrate **one low-risk cohesive feature at a time**, wiring DI/routes and **deleting old files**; ship after each — **never big-bang**.
- **Fix boundaries as you migrate** (introduce core contracts when features interact); keep the graph **acyclic** throughout.
- **Scale** by keeping the slice template + promoting to core (rule of three); **extract features into packages** only when **build pain/team isolation/reuse** justifies it (enforced boundaries + faster builds).
- **Right-size**: single-package feature-first for most apps; package-per-feature for large/multi-team; enforce boundaries with lints → package boundaries.

## Performance

Reorganization is runtime-neutral. **Package extraction** improves **build times** (incremental/parallel) and tooling at scale — a real payoff for large monorepos. The dominant benefit throughout is **developer velocity** (localized changes, parallel work, enforced boundaries).

## Advantages / Disadvantages

- **+** Safe continuous improvement (no freeze), progressive cohesion, enforced boundaries + faster builds at scale, incremental risk.
- **−** Migration takes time (coexistence period), judgment on order/when-to-package, discipline to delete old code + fix boundaries, package overhead if premature.

## Interview Questions

1. **🟢 How do you migrate a layer-first app to feature-first?** — Incrementally (strangler-fig): add `features/`+`core/`, move cross-cutting to core, migrate one low-risk feature at a time (wire DI/routes, delete old files), ship after each — no big-bang.
2. **🟢 Why avoid a big-bang rewrite?** — High risk, long code freeze, and merge hell; incremental migration keeps the app shippable throughout.
3. **🟡 Which feature do you migrate first, and why?** — A low-risk, cohesive one — to learn the process safely before tackling tangled/critical features.
4. **🟡 When do you extract features into packages?** — When build times hurt, teams need hard isolation, or a feature is reused — not prematurely (packages add overhead).
5. **🟡 What do packages buy you over folders?** — Build-enforced boundaries (can't import private code), faster incremental/parallel builds, independent versioning/ownership.
6. **🔴 How do you keep boundaries clean during migration?** — Introduce core contracts when migrated features need to interact, and keep the feature graph acyclic (star around core).
7. **🔴 How do layer-first and feature-first coexist during migration?** — They live side by side; the feature-first tree grows as you migrate, and the layer-first tree shrinks — the strangler-fig pattern.

## Senior Engineer Tips

- Migrate one cohesive, low-risk feature end-to-end first as a template; it de-risks the process and gives the team a concrete pattern to follow.
- Move shared infrastructure to `core` before migrating features, or you'll re-scatter it; and delete migrated originals immediately to avoid a confusing dual tree.
- Extract packages reactively (build pain, team isolation, reuse), not aspirationally; premature modularization adds friction without payoff — but keep boundaries clean so extraction is cheap when the time comes.

## Architect Perspective

Scaling and migration make feature-first a **continuous, low-risk evolution** rather than a rewrite: the strangler-fig pattern converts a tangled layer-first app feature by feature while shipping, and the same cohesive slices later graduate into packages for hard boundaries and build speed. Throughout, the invariant is an acyclic, star-around-core dependency graph — which is exactly what a modular (package) architecture formalizes. The judgment is timing: migrate/scale as pain justifies, keeping boundaries clean so the next step is always cheap ([feature_boundaries_and_dependencies.md](feature_boundaries_and_dependencies.md), [Module 45](../45%20Modular%20Architecture/README.md)).

## Summary

- Migrate layer-first → feature-first **incrementally** (strangler-fig): structure + core-first + one low-risk feature at a time (wire DI/routes, delete old, ship) — never big-bang; fix boundaries as you go.
- Scale by keeping the slice template + promoting to core; **extract features into packages** when build pain/team isolation/reuse justify (enforced boundaries + faster builds).
- Keep the graph acyclic (star around core) throughout; right-size; boundaries are the bridge to modular architecture.

## Revision Notes

- Migration (strangler-fig): add features/+core/; move cross-cutting→core first; migrate one low-risk cohesive feature at a time (DI/routes, delete originals); ship after each; introduce core contracts as needed; layer/feature coexist; no big-bang.
- Scaling: consistent slice template + rule-of-three promotion; extract mature/reused features → local packages (monorepo/melos) for enforced boundaries + incremental builds; when build pain/team isolation/reuse justify.
- Invariant: acyclic star-around-core graph; enforce via lints → package boundaries; right-size; bridge to Module 45.

## Practice Questions

1. Outline an incremental migration from layer-first and why big-bang is avoided.
2. Which feature would you migrate first and why?
3. When and why extract a feature into a package?

## Coding Questions

1. Plan a step-by-step migration order for a given layer-first app.
2. Convert two features + core into path packages (monorepo) keeping the graph acyclic.
3. Add boundary enforcement (lint now, package later) for a migrated feature.

## Mini Project

**Migration + scaling plan (Flutter):** For a tangled layer-first app (auth/feed/cart/profile + shared services), write an incremental strangler-fig migration plan (structure → core-first → per-feature order with DI/routes + deletion + ship points + boundary fixes), and a scaling plan to packages (which features to extract, when, and why — enforced boundaries/build speed), keeping the feature graph acyclic. Acceptance: incremental (no big-bang) migration with a sensible order (low-risk first) and coexistence; cross-cutting→core first; boundaries fixed via core contracts; package-extraction criteria + acyclic graph; right-sized to the app.
