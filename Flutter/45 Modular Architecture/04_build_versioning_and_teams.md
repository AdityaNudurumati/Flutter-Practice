# Build, Versioning & Teams

> The concrete payoffs of modularization are operational: **build/CI speed** (incremental — only changed packages and their dependents rebuild/re-test), **independent versioning** (per-package versions + changelogs, so shared packages evolve on their own cadence), **team ownership** (a team owns a package, its API, and its release), and **cleaner CI** (scoped runs via melos `--since`). These come from the package graph — but they demand discipline: a **stable, low-churn `core`/`contracts`** (churn there rebuilds everything), **careful contract versioning** (breaking a contract ripples to all consumers), and **clear ownership** to avoid diffuse responsibility.

## Introduction

This file covers the operational/organizational dimension of modules: how packages accelerate builds/CI, how versioning works across packages, how ownership maps to packages, and the discipline required (stable shared packages, contract versioning). It's the "why it pays off (and what to watch)" companion to the structural files.

## Why this concept exists

Modularization is adopted for these outcomes — faster CI, autonomous teams, controlled evolution — not for aesthetics. Understanding *how* they arise (and their failure modes) lets you realize the payoff rather than pay the overhead for nothing. It's also the quantitative side of the when-to-modularize decision ([01_modular_fundamentals.md](01_modular_fundamentals.md)).

## Real-world analogy

Modules are **independent factory lines**: if one line changes, you **retool only that line and the lines that consume its parts** (incremental build), not the whole plant. Each line has its **own model year** (version) and **shift crew** (team). But the **shared parts depot** (core/contracts) must be **rock-stable** — change a shared part spec and **every line retools** (whole-repo rebuild + ripple). Clear line ownership prevents "everyone and no one" responsibility.

## Internal Working

```mermaid
flowchart TD
    Change[change package X] --> Affected[X + packages depending on X]
    Affected --> CI[CI rebuilds/tests only affected]
    Version[per-package version + changelog] --> Cadence[shared packages evolve independently]
    Own[team owns a package (API + release)] --> Autonomy[parallel work, clear responsibility]
    Warn[churny core/contracts] -.rebuilds everything.-> Cost[lost incrementality]
```

- **Incremental build/CI (the headline win)**: with packages, a change recompiles/re-tests only the **changed package + its dependents**, not the whole app. Melos `--since` scopes analyze/test to affected packages ([02_monorepo_and_melos.md](02_monorepo_and_melos.md)) → **CI time scales with change size, not repo size**. Leaf features change often + cheaply; roots (core/contracts) rarely.
- **The stability corollary (critical)**: because **everything depends on `core`/`contracts`**, a change there **rebuilds/re-tests everything** — so keep them **stable, small, low-churn**. Volatile shared packages **destroy** the incremental benefit. Depend on stable things ([Module 04](../04%20SOLID%20Principles/README.md) SDP).
- **Independent versioning**: each package has its own `version` + `CHANGELOG`. Melos (conventional commits) bumps versions per package. Shared/published packages (`design_system`, `core`) can evolve on their **own cadence**; the app pins versions. (Purely-local path-dep packages may skip formal versioning.)
- **Contract versioning (highest blast radius)**: the **`contracts` package** is a **published API** — a breaking change ripples to **all consumers**. Treat it with **semver discipline**, additive/backward-compatible changes where possible, and coordinated migration for breaks. This is the main coupling risk in a modular repo.
- **Team ownership**: a **package = an ownership unit** — a team owns its code, **public API**, tests, and release. `CODEOWNERS` maps packages to teams; PRs to a package need its owners. Enables **autonomy + parallel work** with **clear responsibility** (vs diffuse ownership of shared folders).
- **CI implications** ([Module 50](../50%20CI%20CD/README.md)): `melos bootstrap` → scoped `melos run analyze/test --since` → per-package build/test → optional per-package publish. Parallelizable across packages. Caching keyed by package.
- **Governance discipline**: enforce **acyclic graph** (feature→contracts/core only), **contract review** (breaking changes gated), **stable roots** (change core/contracts deliberately), and **ownership** (CODEOWNERS) — else you get slow CI (churny roots), ripple breakages (loose contracts), or ownership gaps.
- **When the payoff is real**: large repos (build pain), many teams (autonomy), shared/published packages (reuse). For small/single-team apps the versioning/ownership machinery is overhead ([01_modular_fundamentals.md](01_modular_fundamentals.md)).

## Memory Representation

Not runtime — a package graph annotated with **versions + owners**, and a CI notion of the **changed set** (affected packages). Incrementality = rebuild/test only the changed set; stability of roots keeps that set small.

## Compiler Behavior

Package-granular incremental compilation: unchanged packages are cached; changed packages + dependents recompile. Contract/core changes invalidate broad swaths (hence keep them stable).

## Runtime Behavior

None — build/versioning/ownership are dev/CI/org concerns. The shipped app is identical regardless.

## Flutter Engine Behavior

Not applicable.

## Dart VM Behavior

Incremental compilation per package is the mechanism behind faster builds; broad invalidation (core/contracts change) is the cost to manage.

## Examples

```bash
# CI: incremental — only affected packages analyzed/tested
melos bootstrap
melos run analyze --since=origin/main
melos run test    --since=origin/main   # scales with change size, not repo size
melos version                            # per-package version bump + changelog (conventional commits)
```

```text
# CODEOWNERS — package = ownership unit
/packages/feature_cart/     @team-commerce
/packages/feature_auth/     @team-identity
/packages/contracts/        @team-architecture   # gate breaking contract changes
/packages/core/             @team-platform       # keep stable/low-churn

Stability rule of thumb:
  leaf feature packages  -> change often, cheap (rebuild themselves + few dependents)
  core / contracts       -> change rarely, expensive (rebuild EVERYTHING) -> keep stable
```

## Diagrams

```mermaid
flowchart LR
    Edit[edit feature_cart] --> Scope[CI: rebuild/test feature_cart + dependents]
    EditCore[edit core/contracts] --> All[rebuild/test EVERYTHING (avoid churn)]
    Own[CODEOWNERS] --> Teams[team autonomy + clear responsibility]
```

## Common Mistakes

| Mistake | Why it's a problem | Fix |
|---------|-------------------|-----|
| Churny `core`/`contracts` | Rebuilds everything (kills incrementality) | Keep roots small, stable, low-churn |
| Breaking the contracts API casually | Ripples to all consumers | Semver + additive changes + gated review |
| Running full CI every build | No incremental payoff | Scope with `--since`/affected packages |
| No package ownership | Diffuse responsibility | CODEOWNERS per package |
| Versioning purely-local packages needlessly | Overhead | Version/publish only shared/published |
| Deep dependency chains | Wide rebuild ripple | Shallow, star-shaped graph |
| Modular machinery on a small app | Overhead > payoff | Right-size (feature-first folders) |

## Best Practices

- Realize the **incremental build/CI** payoff (melos `--since`, per-package cache); design so **leaves change often (cheap)** and **roots (core/contracts) change rarely (stable)**.
- Keep **`core`/`contracts` small, stable, low-churn**; treat **contracts as a versioned published API** (semver, additive, gated breaking changes).
- Use **per-package versioning + changelogs** (melos) for shared/published packages; map **ownership to packages** (CODEOWNERS) for autonomy + clear responsibility.
- Enforce an **acyclic, shallow star graph**; integrate melos into **CI** for scoped runs; **right-size** — adopt this machinery only at justifying scale.

## Performance

Build-time is the win: CI cost scales with the **changed set**, not repo size — provided **roots are stable** (churny core/contracts erase it) and the graph is **shallow** (deep chains widen ripple). Parallel per-package CI compounds the gain. Runtime unaffected.

## Advantages / Disadvantages

- **+** Fast incremental CI, independent versioning/cadence, team autonomy + clear ownership, parallelizable pipelines, controlled evolution.
- **−** Requires stable roots + contract-version discipline, CODEOWNERS/governance, versioning overhead, only pays off at scale.

## Interview Questions

1. **🟢 How does modularization speed up builds/CI?** — Only changed packages (+ dependents) rebuild/re-test (incremental), scoped via melos `--since` — CI scales with change size, not repo size.
2. **🟢 Why must `core`/`contracts` be stable?** — Everything depends on them, so any change rebuilds/re-tests the whole repo — churn there destroys incrementality.
3. **🟡 How does versioning work across packages?** — Each package has its own version + changelog (melos/conventional commits); shared/published packages evolve on their own cadence, pinned by the app.
4. **🟡 Why is contract versioning the highest-risk?** — The contracts API is depended on by all consumers; a breaking change ripples everywhere — use semver, additive changes, and gated review.
5. **🟡 How does ownership map to modules?** — A package is an ownership unit (code + API + tests + release); CODEOWNERS assigns teams, enabling autonomy + clear responsibility.
6. **🔴 What graph properties keep CI fast?** — Acyclic + shallow + stable roots (star around core/contracts); deep chains or churny roots widen rebuild ripple.
7. **🔴 When is this machinery not worth it?** — Small/single-team apps — the versioning/ownership/tooling overhead exceeds the build/autonomy payoff.

## Senior Engineer Tips

- Guard `core`/`contracts` like production APIs — small, stable, review-gated; their churn is the single biggest way teams lose the incremental-build payoff they modularized for.
- Wire CI to affected-package runs (`--since`) and CODEOWNERS to packages from day one; incrementality and clear ownership are the concrete reasons to modularize.
- Prefer additive, backward-compatible contract changes and coordinate the rare breaks; a careless breaking change to `contracts` is a repo-wide fire drill.

## Architect Perspective

The build/versioning/ownership layer is *why* modularization is worth its cost at scale: incremental CI, independent cadence, and autonomous teams — all flowing from the package graph, all contingent on **stable roots** and **disciplined contract evolution**. This is the Stable-Dependencies/Stable-Abstractions principle made operational: depend on stable things, keep shared abstractions stable, and let volatile features be cheap leaves. Realized well, it's the foundation of scalable, multi-team, multi-app Flutter delivery ([01_modular_fundamentals.md](01_modular_fundamentals.md), [Module 47](../47%20Scalable%20Applications/README.md), [Module 50](../50%20CI%20CD/README.md)).

## Summary

- Modules give incremental build/CI (only changed packages + dependents), independent versioning/cadence, and team ownership — via the package graph.
- Payoff depends on **stable, low-churn core/contracts** (churn rebuilds everything), **disciplined contract versioning** (semver/additive/gated), and **CODEOWNERS** ownership.
- Keep the graph acyclic + shallow (star), scope CI with `--since`, and adopt this machinery only at justifying scale.

## Revision Notes

- Incremental CI: rebuild/test changed package + dependents (`melos run --since`); scales with change size — **only if roots stable**.
- Stability: core/contracts churn → rebuild everything (avoid); keep small/stable/low-churn (SDP). Contracts = versioned published API (semver, additive, gated breaks).
- Versioning per-package (melos/conventional commits, own cadence for shared); ownership = package (CODEOWNERS); acyclic + shallow star; right-size to scale.

## Practice Questions

1. Why does core/contracts stability determine your CI speed?
2. How is versioning and ownership organized across packages?
3. Why is a breaking contracts change the riskiest kind?

## Coding Questions

1. Write CI commands for incremental analyze/test with melos `--since`.
2. Author a CODEOWNERS mapping packages to teams (incl. gated contracts).
3. Show an additive vs breaking contract change and how you'd manage each.

## Mini Project

**Build/versioning/ownership plan (Flutter):** For a modular monorepo (app + core + contracts + feature packages), write the CI plan (melos bootstrap + `--since` scoped analyze/test), a CODEOWNERS mapping (features to teams, contracts/core to platform/architecture with gated changes), and a versioning/contract-evolution policy (per-package versions; additive-preferred, semver, gated breaking contract changes). Note the stability rule (keep core/contracts low-churn) and when this machinery is justified. Acceptance: incremental CI plan (`--since`); CODEOWNERS per package (gated contracts/core); per-package versioning + contract-evolution policy; stable-roots rule stated; right-sizing justified.
