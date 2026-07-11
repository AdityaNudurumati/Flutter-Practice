# Monorepo & Melos

> Modular Flutter apps live in a **monorepo**: one repository holding the `app` package plus many local packages (`core`, `contracts`, `feature_*`), wired together with **path dependencies**. **Melos** is the standard tool to manage this workspace — it **bootstraps** (links local packages), runs **scripts across packages** (`melos run analyze/test`), handles **selective/incremental** execution (only changed packages), and coordinates **versioning/publishing**. The monorepo keeps everything **atomically versioned + refactorable in one PR** while packages give you **enforced boundaries + incremental builds**.

## Introduction

This file covers the practical mechanics: monorepo layout, path dependencies, and using melos to bootstrap, script, scope, and version the workspace. It's the tooling layer under the fundamentals ([modular_fundamentals.md](modular_fundamentals.md)).

## Why this concept exists

Many packages need coordination: linking local deps, running lint/test/build across all of them, doing only what changed, and versioning together. Doing this by hand (per-package `pub get`, manual script loops) is painful and error-prone. Melos + a monorepo standardize it — you get package isolation without multi-repo overhead (no cross-repo version juggling; atomic cross-package changes).

## Real-world analogy

A monorepo is a **single campus with many specialized buildings** (packages) connected by internal walkways (path deps). **Melos** is the **campus operations team**: it hooks up utilities to every building (bootstrap), runs campus-wide drills (scripts across packages), only services the buildings that changed (selective runs), and coordinates campus-wide upgrades (versioning). One campus (repo) beats scattered buildings across the city (multi-repo) for coordinated work.

## Problem Statement

Set up a monorepo for an `app` + `core` + `contracts` + `feature_auth` + `feature_cart`, link them via path deps, and use melos to bootstrap, analyze/test across packages (only changed ones in CI), and version them. You'll structure the workspace + melos config + scripts.

## Internal Working

```mermaid
flowchart TD
    Repo[monorepo] --> App[apps/app (Flutter app)]
    Repo --> Core[packages/core]
    Repo --> Contracts[packages/contracts]
    Repo --> FAuth[packages/feature_auth]
    Repo --> FCart[packages/feature_cart]
    App -->|path dep| FAuth & FCart & Core & Contracts
    FAuth & FCart -->|path dep| Core & Contracts
    Melos[melos.yaml] --> Ops[bootstrap / run scripts / select changed / version]
```

- **Monorepo layout**: one repo, e.g. `apps/app/` (the Flutter application) + `packages/{core, contracts, feature_auth, feature_cart, design_system, ...}`. Each is a normal Dart/Flutter package with its own `pubspec.yaml`/`lib/`/`test/`.
- **Path dependencies**: packages depend on each other via `path:` deps in `pubspec.yaml` (e.g., `feature_cart` → `core`, `contracts`). The **app** depends on the feature packages + core. The graph stays **acyclic** (features → core/contracts, never each other — [module_boundaries_and_contracts.md](module_boundaries_and_contracts.md)).
- **Melos** (`melos.yaml` at the root): declares `packages:` globs and **scripts**.
  - **Bootstrap** (`melos bootstrap`/`melos bs`): resolves + links all local packages (runs `pub get` everywhere, wiring path deps) — the setup step after clone/dep changes.
  - **Scripts** (`melos run <name>`): run a command **across packages** — `analyze`, `test`, `format`, `build_runner`, custom. Define once, run everywhere.
  - **Selective/changed execution**: run only **packages that changed** (or depend on changed ones) via `--since`/filters — the basis for **fast CI** ([build_versioning_and_teams.md](build_versioning_and_teams.md)).
  - **Filtering/scoping**: target subsets (`--scope`, `--ignore`, by directory/flag) — e.g., only feature packages, or only those with tests.
  - **Versioning/publishing** (`melos version`/`publish`): conventional-commit-based version bumps + changelogs across packages (for shared/published packages).
- **Why monorepo over multi-repo**: **atomic changes** (a cross-package refactor is one PR), **no version juggling** between repos, **shared tooling/CI**, easy local linking — while packages still give **enforced boundaries**. (Multi-repo trades this for stronger org isolation + independent release cadence — rarely needed for one app.)
- **CI integration**: CI runs `melos bootstrap` then scoped `melos run analyze/test` on **changed** packages → incremental, fast pipelines ([Module 50](../50%20CI%20CD/README.md)).
- **`.gitignore`/tooling**: ignore per-package `.dart_tool`/build outputs; commit `melos.yaml` + lockfiles per policy.

## Memory Representation

Not runtime — a **repo tree + a package graph** melos operates on. Melos holds the workspace config (package globs, scripts) and computes changed-package sets for selective runs.

## Compiler Behavior

Path deps + `pub get` (via bootstrap) make local packages resolvable; the compiler still enforces declared-deps + exports (boundaries). Incremental compilation caches unchanged packages.

## Runtime Behavior

No runtime effect — this is dev/build/CI tooling. The built app is identical; only how it's assembled/tested is coordinated.

## Flutter Engine Behavior

Not applicable.

## Dart VM Behavior

Incremental builds: only changed packages (+ dependents) recompile; melos scoping mirrors this for analyze/test to keep CI fast.

## Examples

```yaml
# melos.yaml (repo root)
name: my_app_workspace
packages:
  - apps/**
  - packages/**
scripts:
  analyze: { run: dart analyze, exec: { concurrency: 5 } }
  test:    { run: flutter test, exec: { concurrency: 5 }, packageFilters: { dirExists: test } }
  gen:     { run: dart run build_runner build -d }
```

```yaml
# packages/feature_cart/pubspec.yaml — path deps to local packages (acyclic)
name: feature_cart
dependencies:
  core: { path: ../core }
  contracts: { path: ../contracts }
  # NOT feature_auth (features never depend on each other)
```

```bash
# Workflow
melos bootstrap                     # link + pub get all packages
melos run analyze                   # analyze across all packages
melos run test --since=origin/main  # test ONLY changed packages (fast CI)
melos version                       # bump versions + changelogs (conventional commits)
```

## Diagrams

```mermaid
flowchart LR
    Clone[clone repo] --> Boot[melos bootstrap (link + pub get)]
    Boot --> Dev[dev: edit any package]
    Dev --> CI[CI: melos run test --since=main (changed only)]
    CI --> Fast[fast incremental pipeline]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| Manual per-package `pub get`/scripts | Error-prone, slow | Use `melos bootstrap`/`run` |
| Cyclic path deps | Won't resolve | Keep graph acyclic (features→core/contracts) |
| Running everything every CI build | Slow pipelines | Scope with `--since`/filters (changed only) |
| Feature package path-depending on another feature | Coupling | Depend only on core/contracts |
| Multi-repo for one app | Version juggling, no atomic refactors | Monorepo (melos) |
| Not bootstrapping after dep changes | Broken links | Re-run `melos bootstrap` |
| Publishing versioning on purely-local packages | Unneeded | Version/publish only shared/published packages |

## Best Practices

- Use a **monorepo** (`apps/` + `packages/`) with **path dependencies**, kept **acyclic** (features → core/contracts); manage it with **melos**.
- **Bootstrap** after clone/dep changes; define **workspace scripts** (analyze/test/format/gen) once and run across packages; **scope to changed packages** (`--since`) for fast CI.
- Prefer **monorepo over multi-repo** for one app (atomic cross-package refactors, no version juggling, shared tooling); version/publish only **shared/published** packages.
- Keep tooling consistent (root analysis options, ignored build outputs); integrate melos into **CI** for incremental pipelines ([Module 50](../50%20CI%20CD/README.md)).

## Performance

Melos + incremental/selective execution is the **build-time** payoff: CI runs analyze/test only on changed packages (+ dependents), and Dart caches unchanged packages — pipelines scale sub-linearly with codebase size. Runtime is unaffected.

## Advantages / Disadvantages

- **+** Coordinated multi-package workflow, atomic cross-package changes, incremental/selective CI, shared tooling, easy local linking + versioning.
- **−** Learning/tooling overhead (melos config, bootstrap step), monorepo size/CI setup, discipline to keep the graph acyclic + scripts maintained.

## Interview Questions

1. **🟢 What is a monorepo in this context?** — One repository holding the app + many local packages (core/contracts/features) wired via path dependencies.
2. **🟢 What does melos do?** — Manages the workspace: bootstraps (links local packages), runs scripts across packages, scopes to changed packages, and coordinates versioning/publishing.
3. **🟡 What is `melos bootstrap` for?** — Resolving and linking all local path dependencies (`pub get` everywhere) so packages reference each other correctly.
4. **🟡 How does melos speed up CI?** — Selective execution: run analyze/test only on packages that changed (or depend on changed ones) via `--since`/filters.
5. **🟡 Why monorepo over multi-repo for one app?** — Atomic cross-package refactors in one PR, no cross-repo version juggling, and shared tooling/CI — while packages still enforce boundaries.
6. **🔴 How do packages depend on each other locally?** — Via `path:` dependencies in `pubspec.yaml`, kept acyclic (features → core/contracts, never each other).
7. **🔴 What must remain true of the package graph, and why?** — Acyclic — cyclic path deps can't be resolved/built; keep a star around core/contracts.

## Senior Engineer Tips

- Wire CI to `melos bootstrap` + scoped `melos run test --since=main` from the start; running the whole workspace every build erases modular architecture's build-speed payoff.
- Enforce the acyclic star (features → core/contracts) in path deps and review; a single feature→feature path dep starts the slide back to a tangled monolith.
- Keep one repo for one app (monorepo) unless org/release-cadence pressures truly demand multi-repo — the coordination cost of multi-repo rarely pays off for a single product.

## Architect Perspective

The monorepo + melos is the operational substrate of modular architecture: it makes many packages practical to develop, test, and version together while preserving hard boundaries and unlocking incremental CI. It gives the best of both worlds — package isolation (enforced boundaries, ownership, reuse) with monorepo cohesion (atomic changes, shared tooling) — and is the platform on which enterprise-scale and CI/CD strategies are built ([modular_fundamentals.md](modular_fundamentals.md), [build_versioning_and_teams.md](build_versioning_and_teams.md), [Module 50](../50%20CI%20CD/README.md)).

## Summary

- Monorepo: `apps/app` + `packages/{core,contracts,feature_*}` linked by path deps (acyclic star), managed with melos.
- Melos: bootstrap (link/`pub get`), run scripts across packages, scope to changed packages (`--since`) for fast CI, coordinate versioning.
- Monorepo beats multi-repo for one app (atomic refactors, no version juggling, shared tooling); runtime-neutral, build-time win.

## Revision Notes

- Layout: `apps/app` + `packages/{core, contracts, feature_*}`; path deps in pubspec (acyclic, features→core/contracts).
- Melos: `melos.yaml` (packages globs + scripts); `bootstrap` (link/pub get), `run <script>` across packages, `--since`/filters (changed only), `version`/`publish`.
- Monorepo > multi-repo for one app (atomic changes, shared tooling); CI = bootstrap + scoped run; keep graph acyclic; runtime-neutral.

## Practice Questions

1. What does `melos bootstrap` do and when do you run it?
2. How do you make CI only test changed packages?
3. Why prefer a monorepo over multi-repo for a single app?

## Coding Questions

1. Write a `melos.yaml` with analyze/test scripts and package globs.
2. Add path deps to a feature package (core/contracts only, acyclic).
3. Show the CI commands for bootstrap + changed-only tests.

## Mini Project

**Melos monorepo setup (Flutter):** Lay out a monorepo (`apps/app` + `packages/core`, `contracts`, `feature_auth`, `feature_cart`) with path deps (acyclic star), a `melos.yaml` (packages globs + analyze/test/gen scripts), and CI commands (`bootstrap` + `run test --since=main`). Ensure no feature→feature path dep. Acceptance: monorepo layout + path deps (acyclic); melos scripts defined; bootstrap + selective/changed CI commands; features depend only on core/contracts; workspace-manageable with melos.
