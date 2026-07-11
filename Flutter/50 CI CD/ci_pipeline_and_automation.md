# CI Pipeline & Automation

> A Flutter CI pipeline is **config-as-code** (a YAML workflow in GitHub Actions/GitLab CI, or a Codemagic/Bitrise config) that, on each trigger, **sets up the environment** (checkout, pinned Flutter SDK), **installs deps** (`pub get`), and runs the **verification stages** — **`flutter analyze`** → **`flutter test` (+ coverage)** → **`flutter build`** (per flavor) → optionally **integration tests on emulators**. The levers that make it fast + reliable: **dependency + build caching**, **parallel jobs** (Android/iOS/web in matrix), **incremental runs** in a monorepo (`melos run test --since`), and **merge gating** on green. Keep **PR pipelines fast** (analyze + unit/widget); push heavy work (E2E, full builds) to merge/nightly.

## Introduction

This file covers building the CI half concretely: the YAML/config structure, the analyze/test/build stages, caching + parallelism + matrices, monorepo incremental CI, and merge gating — with GitHub Actions as the primary example and Codemagic as the mobile-specialized alternative. It implements the fundamentals ([cicd_fundamentals.md](cicd_fundamentals.md)) and runs the tests from [Module 49](../49%20Testing/README.md).

## Why this concept exists

CI's value depends on being **fast, reliable, and comprehensive** — a slow or flaky pipeline gets bypassed; a shallow one misses regressions. Knowing how to structure the workflow, cache aggressively, parallelize, and run incrementally is what turns "we have CI" into "CI gives trusted feedback in minutes." It's also where testing becomes **enforced** (gate) rather than optional.

## Real-world analogy

The CI pipeline is a **standardized inspection station** on the assembly line: it always uses the **same certified tools** (pinned SDK), keeps **frequently-used parts on hand** (caching — no re-fetching), runs **multiple inspectors in parallel** (matrix jobs for Android/iOS), inspects **only the changed sections** when possible (incremental/monorepo), and **won't let a car pass** without clearing inspection (merge gating). A slow, single-inspector station bottlenecks the whole factory.

## Internal Working

```mermaid
flowchart TD
    Trigger[trigger: PR / push / tag] --> Env[setup: checkout + pinned Flutter SDK]
    Env --> Cache[restore cache: pub + build]
    Cache --> Deps[flutter pub get]
    Deps --> Analyze[flutter analyze / lint]
    Analyze --> Test[flutter test --coverage]
    Test --> Build[flutter build (per flavor) — parallel matrix]
    Build --> Integr[integration tests on emulators (merge/nightly)]
    Integr --> Gate[merge gate: all green]
    Mono[melos run analyze/test --since] -.incremental.-> Analyze
```

- **Config-as-code**: the pipeline lives in the repo — **GitHub Actions** (`.github/workflows/*.yml`), **GitLab CI** (`.gitlab-ci.yml`), or a mobile-specialized service (**Codemagic**/**Bitrise**) config. Versioned, reviewable, reproducible.
- **Environment setup**: **checkout** the repo, **install a pinned Flutter/Dart SDK** (e.g., `subosito/flutter-action` with a fixed version) — pinning ensures reproducibility.
- **Verification stages** (from [Module 49](../49%20Testing/README.md)):
  - **`flutter pub get`** (install deps).
  - **`flutter analyze`** (+ `dart format --set-exit-if-changed`) — static analysis/lint gate.
  - **`flutter test --coverage`** — unit + widget tests (upload LCOV to Codecov etc.).
  - **`flutter build apk/appbundle/ipa/web`** per **flavor** — verifies it builds (release build on tags).
  - **`flutter test integration_test`** on **emulators/device farm** (Firebase Test Lab) — heavier, run on **merge/nightly**, not every PR.
- **Caching (biggest speed lever)**: cache the **pub cache** (`~/.pub-cache`), **Gradle** (`~/.gradle`), **CocoaPods** (`Pods/`), and build outputs — keyed by lockfiles (`pubspec.lock`, etc.). Cache hits skip re-downloading deps → pipelines go from many minutes to a fraction.
- **Parallelism + matrices**: run **Android/iOS/web builds and test shards in parallel jobs** (a matrix), so total wall-clock ≈ the slowest job, not the sum. Split large test suites into shards.
- **Monorepo incremental CI** ([Module 45](../45%20Modular%20Architecture/README.md)): with melos, **`melos bootstrap`** then **`melos run analyze/test --since=origin/main`** runs only **changed packages (+ dependents)** — CI scales with change size, not repo size (requires stable core/contracts).
- **Fast-PR discipline**: PR pipeline = **analyze + unit/widget (cached, parallel)** for minutes-scale feedback; **defer** E2E + full multi-platform release builds to merge/tag/nightly. Slow PR pipelines get bypassed.
- **Merge gating**: **protected branches require the pipeline green** to merge (+ required reviewers/CODEOWNERS — [Module 47](../47%20Scalable%20Applications/README.md)); optionally a **coverage threshold/no-regression** check.
- **Secrets** (for signed builds/integration with services): stored in the CI provider's **encrypted secrets** (never in the repo), injected as env vars ([build_signing_and_flavors.md](build_signing_and_flavors.md)/[Module 37](../37%20Security/README.md)).
- **GH Actions vs Codemagic**: **GH Actions** = general, flexible, free tier, but you assemble signing/store steps yourself; **Codemagic/Bitrise** = Flutter/mobile-first with **built-in signing + store publishing** (less setup, paid). Choose by team needs.

## Memory Representation

Not runtime — a **workflow definition** (jobs/steps/triggers/caches/matrix) + per-run logs/artifacts. Caches persist between runs keyed by lockfiles; artifacts (builds, coverage) are stored per run.

## Compiler Behavior

The pipeline invokes the Flutter compiler/analyzer; pinned SDK versions make compilation reproducible; caches speed dependency resolution + incremental compilation.

## Runtime Behavior

Jobs run on ephemeral CI runners (clean each time — reproducible); stages gate on exit codes; parallel jobs run concurrently; caches restore/save around runs. Integration tests spin up emulators.

## Flutter Engine Behavior

Integration-test jobs run the engine on emulators (Android)/simulators; other stages don't run the engine ([Module 49](../49%20Testing/README.md)).

## Dart VM Behavior

Analyze/test run in the VM; incremental monorepo runs recompile only changed packages ([Module 45](../45%20Modular%20Architecture/README.md)).

## Examples

```yaml
# .github/workflows/ci.yml — fast PR pipeline (analyze + test), cached
name: CI
on: [pull_request]
jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.24.0', cache: true }   # pinned + cache SDK
      - run: flutter pub get
      - run: dart format --set-exit-if-changed .            # format gate
      - run: flutter analyze                                # analyze gate
      - run: flutter test --coverage                        # unit + widget (+LCOV)
      # (build/integration deferred to merge/nightly workflows)
```

```yaml
# Parallel build matrix (Android/iOS/web) + monorepo incremental tests
strategy:
  matrix: { platform: [apk, ipa, web] }
steps:
  - run: flutter build ${{ matrix.platform }} --release --flavor prod
# Monorepo (melos): only changed packages
  - run: melos bootstrap
  - run: melos run test --since=origin/main
```

```text
Caching keys (skip re-downloading deps):
  ~/.pub-cache   keyed by pubspec.lock
  ~/.gradle      keyed by *.gradle / gradle-wrapper
  ios/Pods       keyed by Podfile.lock
  -> cache HIT turns a multi-minute install into seconds
```

## Diagrams

```mermaid
flowchart LR
    PR[PR] --> Fast[fast: analyze + unit/widget (cached, parallel)]
    Fast -->|green| Gate[merge gate]
    Merge[merge/tag] --> Heavy[build (flavors, matrix) + integration on emulators]
    Nightly[nightly] --> E2E[full E2E suite]
```

## Common Mistakes

| Mistake | Why it's a problem | Fix |
|---------|-------------------|-----|
| No caching | Slow pipelines (re-download deps) | Cache pub/gradle/pods keyed by lockfiles |
| Running E2E/full builds on every PR | Slow feedback | PR = fast (analyze+unit/widget); heavy on merge/nightly |
| Unpinned Flutter SDK | Non-reproducible builds | Pin SDK version |
| Serial single job | Long wall-clock | Parallel jobs/matrix + shards |
| Full monorepo test every run | Doesn't scale | `melos run --since` (changed packages) |
| No merge gating | Regressions land | Protected branch requires green |
| Secrets in the repo/config | Security breach | CI encrypted secrets (env vars) |
| No format/analyze gate | Style/quality drift | `analyze` + `format --set-exit-if-changed` |

## Best Practices

- Define CI as **config-as-code** with a **pinned Flutter SDK**; run **analyze + format + `flutter test --coverage`** on PRs, deferring **E2E + full/multi-platform builds** to merge/nightly (fast feedback).
- **Cache aggressively** (pub/gradle/pods keyed by lockfiles) and **parallelize** (Android/iOS/web matrix + test shards); in monorepos use **`melos run --since`** for incremental runs.
- **Gate merges** on green (protected branches + CODEOWNERS, optional coverage threshold); store **secrets in the CI provider's encrypted store** (never in the repo).
- Choose the platform to fit (**GH Actions/GitLab** general vs **Codemagic/Bitrise** mobile-specialized with built-in signing/publishing); keep runners **clean/ephemeral** for reproducibility.

## Performance

Caching + parallelism + incremental (`melos --since`) are the speed levers that keep CI in the minutes range as the codebase grows — the difference between trusted, fast feedback and a bypassed bottleneck. Fast-PR discipline (heavy stages later) keeps the inner loop tight ([Module 47](../47%20Scalable%20Applications/README.md)).

## Advantages / Disadvantages

- **+** Fast trusted feedback, enforced testing (gate), reproducible builds, parallel/incremental scaling, config-as-code (reviewable/versioned).
- **−** Setup + maintenance (YAML/caches/matrices), CI-minutes cost, secrets/signing config, emulator flakiness for E2E, provider lock-in nuances.

## Interview Questions

1. **🟢 What stages does a Flutter CI pipeline run?** — checkout + pinned SDK → `pub get` → `analyze`/format → `flutter test --coverage` → `flutter build` (per flavor) → integration tests (on merge/nightly).
2. **🟢 How do you keep CI fast?** — Cache deps (pub/gradle/pods), parallelize (matrix + shards), run incrementally in monorepos (`melos --since`), and keep heavy stages (E2E/full builds) off the PR path.
3. **🟡 Why pin the Flutter SDK version?** — Reproducibility — the same commit builds identically across runs/machines, avoiding "works on my machine."
4. **🟡 What runs on a PR vs on merge/nightly?** — PR: analyze + unit/widget (fast); merge/tag: builds + integration; nightly: full E2E — for fast feedback.
5. **🟡 How does monorepo CI scale?** — `melos run analyze/test --since=origin/main` runs only changed packages (+ dependents), so CI cost scales with change size (given stable roots).
6. **🔴 How are secrets handled in CI?** — Stored in the provider's encrypted secrets, injected as env vars at runtime — never committed to the repo/config.
7. **🔴 GitHub Actions vs Codemagic — trade-offs?** — GH Actions: general, flexible, cheap, but you build signing/store steps yourself; Codemagic/Bitrise: Flutter/mobile-first with built-in signing/publishing (less setup, paid).

## Senior Engineer Tips

- Cache the pub/gradle/pods directories keyed by lockfiles and parallelize platform builds first; those two changes usually cut pipeline time the most and are what make CI trusted rather than bypassed.
- Keep the PR pipeline ruthlessly fast (analyze + unit/widget) and shove E2E + full/multi-platform builds to merge/nightly; developers judge CI by PR latency.
- In monorepos, wire `melos --since` early so CI stays fast as the repo grows — but keep core/contracts stable, or every change rebuilds everything.

## Architect Perspective

The CI pipeline is where testing becomes enforced and feedback becomes fast: config-as-code stages with pinned SDKs, aggressive caching, parallel matrices, and incremental monorepo runs, gated at merge. Designed well, it gives minutes-scale trusted verification that scales with the codebase — the foundation the CD/signing/release layers build on and a core lever of scalable, multi-team delivery ([cicd_fundamentals.md](cicd_fundamentals.md), [build_signing_and_flavors.md](build_signing_and_flavors.md), [Module 45](../45%20Modular%20Architecture/README.md), [Module 47](../47%20Scalable%20Applications/README.md)).

## Summary

- CI = config-as-code (GH Actions/Codemagic): pinned SDK → `pub get` → analyze/format → `flutter test --coverage` → build (flavors) → integration (merge/nightly), gated at merge.
- Fast + reliable via caching (pub/gradle/pods), parallel matrices/shards, and monorepo incremental runs (`melos --since`); keep PR pipelines fast, defer heavy stages.
- Secrets in encrypted CI store; choose GH Actions (general) vs Codemagic/Bitrise (mobile-specialized) by needs.

## Revision Notes

- Config-as-code (GH Actions `.github/workflows`, GitLab CI, Codemagic/Bitrise); setup = checkout + pinned Flutter SDK (`subosito/flutter-action`).
- Stages: `pub get` → `dart format --set-exit-if-changed` + `flutter analyze` → `flutter test --coverage` → `flutter build` (flavor, matrix) → `integration_test` on emulators (merge/nightly).
- Speed: cache pub/gradle/pods (keyed by lockfiles), parallel matrix + shards, monorepo `melos run --since`. PR fast (analyze+unit/widget), heavy later. Merge gate (protected + CODEOWNERS + coverage). Secrets in encrypted CI store. GH Actions (general) vs Codemagic/Bitrise (mobile signing/publish built-in).

## Practice Questions

1. What runs on a PR pipeline vs merge/nightly, and why?
2. What are the biggest levers for CI speed?
3. How do secrets get into a CI build safely?

## Coding Questions

1. Write a GitHub Actions workflow for a fast PR pipeline (analyze + test, cached).
2. Add a parallel build matrix (Android/iOS/web) + monorepo incremental tests.
3. Configure caching keyed by lockfiles for pub/gradle/pods.

## Mini Project

**CI pipeline (Flutter):** Author a GitHub Actions (or Codemagic) CI config: a fast PR job (pinned SDK, cached pub/gradle/pods, `format` + `analyze` + `flutter test --coverage`), a merge/nightly job (parallel build matrix per platform/flavor + `integration_test` on an emulator), and (if monorepo) `melos run --since` incremental tests — with merge gating and secrets from the encrypted store. Acceptance: config-as-code with pinned SDK; PR pipeline fast (analyze+unit/widget, cached/parallel); heavy stages (E2E/full builds) on merge/nightly; caching keyed by lockfiles; monorepo incremental (if applicable); merge-gated; secrets encrypted (not in repo).
