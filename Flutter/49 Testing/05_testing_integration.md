# Testing Integration (Capstone: Test Every Layer + Coverage + CI)

> Bring the pyramid to a real feature: **unit-test each architectural layer** (domain use cases with fake repos; data repositories with fake sources; presentation view-models via state sequences), **widget-test** the screen's states + interactions (+ a golden for stable UI), and write **one integration test** for the critical journey — then **measure coverage meaningfully** (behavior + unhappy paths, not a 100% vanity metric) and **gate it all in CI** (`flutter test` + `integration_test`, or `melos run test` for a monorepo). The result: a **pyramid-shaped, layer-complete, CI-gated** suite that makes the feature safe to change — the payoff of the whole handbook's testable architecture.

## Introduction

This module capstone composes unit/widget/golden/integration testing into one layered suite for a feature, adds coverage measurement and CI gating, and shows how testable architecture makes it straightforward. It's the practical "how it all fits" deliverable.

## Why this concept exists

Individual test types are only valuable **assembled into a coherent, pyramid-shaped suite** that covers every layer, runs in CI, and is measured meaningfully. This capstone demonstrates that assembly — the difference between "we have some tests" and "the feature is safe to change."

## Real-world analogy

It's the **full QA program for one car model**: bench tests for every component (unit per layer), rig tests for subsystems (widget/golden), a road test of the key journey (E2E), a **coverage report** of what's verified, and an **assembly-line gate** that won't ship a car that fails any of them (CI). Together they let the factory iterate the model confidently.

## Internal Working

```mermaid
flowchart TD
    subgraph Feature slice
      D[domain: use cases] --> DU[unit tests (fake repo)]
      DA[data: repositories] --> DAU[unit tests (fake sources)]
      P[presentation: view models] --> PU[unit tests (state sequences)]
      W[widgets/screens] --> WT[widget tests (states + interactions) + golden]
      J[critical journey] --> E2E[1 integration test]
    end
    DU & DAU & PU & WT & E2E --> Coverage[meaningful coverage (behavior + unhappy paths)]
    Coverage --> CI[CI gate: flutter test + integration_test / melos run test]
    Note[pyramid-shaped: many unit, some widget, few E2E]
```

- **Test every layer (unit — the base)**:
  - **Domain**: use cases with **fake repositories** (assert `Result`/behavior + invariants) — pure Dart, fastest ([Module 40](../40%20Clean%20Architecture/README.md)/[Module 46](../46%20Domain%20Driven%20Design/README.md)).
  - **Data**: repository impls with **fake data sources** (mapping DTO↔entity, cache/offline logic, exception→`Failure` conversion — [Module 40](../40%20Clean%20Architecture/README.md)).
  - **Presentation**: view models via **state sequences** (loading → data/empty/error) with fake use cases (`blocTest`/listeners — [Module 43](../43%20MVVM/README.md)).
  - Each **isolated** with fakes at boundaries — the architecture's payoff ([02_unit_and_mocking.md](02_unit_and_mocking.md)).
- **Widget + golden (middle)**: widget-test the screen's **states + interactions** (faked VM); a **golden** for a stable design-system component/key screen ([03_widget_and_golden_tests.md](03_widget_and_golden_tests.md)).
- **Integration (tip)**: **one** integration test for the feature's **critical journey** (deterministic data, stable finders — [04_integration_and_e2e.md](04_integration_and_e2e.md)).
- **Coverage — meaningful, not vanity**:
  - Measure with `flutter test --coverage` (LCOV) → view in CI / tools (Codecov). Use it to **find untested behavior + unhappy paths**, not to chase **100%** (which rewards testing trivia + gives false confidence).
  - Prioritize coverage of **domain/data/presentation logic** and **error/edge paths**; don't count generated/trivial code. A pragmatic target (e.g., high coverage of *logic*) beats a blanket 100%.
- **CI gating** ([Module 50](../50%20CI%20CD/README.md)):
  - CI runs **`flutter analyze` + `flutter test` (+ `--coverage`)** on every PR; **`integration_test`** on emulators/device farm (perhaps on merge/nightly due to cost).
  - Monorepo: **`melos run test --since`** for incremental, changed-package-only runs ([Module 45](../45%20Modular%20Architecture/README.md)).
  - **Gate merges** on green tests (+ optionally a coverage threshold/no-regression); flaky tests quarantined, not tolerated.
- **Test organization**: mirror the source structure (`test/features/<name>/{domain,data,presentation}`, `integration_test/`); shared fakes/helpers in a `test/support` or a test package; consistent naming.
- **The payoff**: a **pyramid-shaped, layer-complete, CI-gated, meaningfully-covered** suite → confident refactoring + regression safety + fast feedback — realizing the testability the architecture band designed for ([Module 47](../47%20Scalable%20Applications/README.md)).

## Memory Representation

The suite: unit tests (fakes + assertions) per layer, widget/golden tests (faked state + references), one integration test (real app + seeded data), a coverage report, and CI config. Organized to mirror the feature slice.

## Compiler Behavior

Unit tests compile against interfaces + fakes; widget tests against real widgets + fakes; integration against the real app. Coverage instruments the code; CI compiles + runs everything.

## Runtime Behavior

Unit (ms) → widget (test binding) → integration (device) run in ascending cost; CI runs unit+widget on every PR, integration on emulators (merge/nightly). Coverage collected during test runs. Merges blocked on failures.

## Flutter Engine Behavior

Unit tests don't touch the engine; widget tests use the fake test binding; integration uses the real engine on-device — as in their respective files.

## Dart VM Behavior

Fast unit base parallelizes in CI; incremental (`melos --since`) runs only changed packages' tests — keeping CI quick as the app scales ([Module 45](../45%20Modular%20Architecture/README.md)).

## Examples

```text
Test organization (mirrors the feature slice):
  test/features/profile/
    domain/get_profile_test.dart          (use case + fake repo)
    data/profile_repository_test.dart      (repo + fake sources; mapping/errors)
    presentation/profile_vm_test.dart      (state sequences, fake use case)
    presentation/profile_view_test.dart    (widget: states + interactions)
    presentation/profile_view_golden_test.dart (golden, stable UI)
  integration_test/profile_journey_test.dart (one critical journey)
  test/support/fakes.dart                  (shared fakes/helpers)
```

```yaml
# CI (GitHub Actions sketch) — gate merges on green + coverage
- run: flutter analyze
- run: flutter test --coverage           # unit + widget (+ LCOV)
# - run: melos run test --since=origin/main   # monorepo: changed packages only
- run: flutter test integration_test      # on emulator (merge/nightly)
# upload coverage; fail PR on test failure (and optionally coverage regression)
```

```dart
// Layer coverage at a glance (one test per layer, all fakes)
test('domain: use case maps repo Result', () async { /* fake repo */ });
test('data: repo converts 404 -> NotFoundFailure', () async { /* fake sources */ });
blocTest('presentation: loading -> data', /* fake use case, assert sequence */);
testWidgets('widget: error state shows retry', (t) async { /* faked VM */ });
// integration_test: login -> profile (one critical journey)
```

## Diagrams

```mermaid
flowchart LR
    PR[pull request] --> CI[CI: analyze + unit + widget (+coverage)]
    CI -->|green| Merge[merge allowed]
    CI -->|red| Block[blocked]
    Merge --> Nightly[integration_test on emulators (merge/nightly)]
    Coverage[coverage report] --> CI
```

## Common Mistakes

| Mistake | Why it's wrong | Fix |
|---------|---------------|-----|
| Testing only one layer (e.g., only UI) | Gaps + slow/imprecise | Unit-test each layer (domain/data/presentation) |
| Wrong shape (mostly E2E) | Slow/flaky CI | Pyramid: unit-heavy, thin E2E |
| Chasing 100% coverage | Rewards trivia, false confidence | Meaningful coverage (logic + unhappy paths) |
| Not gating merges on tests | Regressions slip in | CI gate on green tests |
| Running full E2E on every PR | Slow pipelines | E2E on merge/nightly; incremental unit/widget on PR |
| No shared fakes/organization | Duplication, hard to navigate | Mirror structure + shared test support |
| Tolerating flaky tests | Erodes trust in CI | Quarantine + fix fast |
| Not using incremental tests in a monorepo | Slow CI at scale | `melos run test --since` |

## Best Practices

- Build a **pyramid-shaped, layer-complete** suite: **unit-test each layer** (domain/data/presentation with fakes), **widget+golden** the UI, **one integration test** per critical journey.
- Measure **coverage meaningfully** (logic + unhappy paths; not 100% vanity; skip generated/trivial); use it to find gaps.
- **Gate merges in CI** (`flutter analyze` + `flutter test --coverage` on PRs; `integration_test` on emulators at merge/nightly; **`melos --since`** incremental in monorepos); **quarantine flaky** tests.
- **Organize** tests to mirror the source, with shared fakes/helpers; leverage the **testable architecture** so most coverage comes from fast unit tests.

## Performance

The pyramid + incremental CI (`melos --since`) keep the suite fast: unit/widget on every PR (quick feedback), E2E rationed to emulators at merge/nightly. Meaningful coverage avoids wasted effort on trivia. Fast, gated tests = tight, safe iteration ([Module 47](../47%20Scalable%20Applications/README.md)).

## Advantages / Disadvantages

- **+** Full-layer regression safety, confident refactoring, fast feedback (pyramid + incremental CI), meaningful coverage, merge gating.
- **−** Upfront + ongoing test-writing/maintenance, CI setup (device farm for E2E), coverage-target judgment, flake management.

## Interview Questions

1. **🟢 How do you test each architectural layer?** — Domain use cases with fake repos, data repos with fake sources, presentation view models via state sequences with fake use cases — all fast unit tests, plus widget/golden for UI and one E2E for the critical journey.
2. **🟢 What shape should the suite be?** — A pyramid: many unit, some widget, few integration/E2E — keeping CI fast and reliable.
3. **🟡 Why not chase 100% coverage?** — It rewards testing trivia and gives false confidence; aim for meaningful coverage of logic + unhappy paths, skipping generated/trivial code.
4. **🟡 How do you gate merges with tests in CI?** — Run analyze + unit + widget (+coverage) on every PR (block on failure); run E2E on emulators at merge/nightly; incremental (`melos --since`) in monorepos.
5. **🟡 Why run E2E on merge/nightly rather than every PR?** — E2E is slow/flaky; running it on every PR bloats the pipeline — run fast unit/widget on PRs, E2E less frequently.
6. **🔴 How does testable architecture make this easier?** — Clean/MVVM (pure domain, view-model state, repository interfaces + fakes) pushes most logic into fast unit tests, so the pyramid's base is easy to build.
7. **🔴 How do you keep CI fast + trustworthy as the app scales?** — Incremental changed-package test runs (`melos --since`), a unit-heavy pyramid, and aggressive flake quarantine/fix.

## Senior Engineer Tips

- Build the base first: a fast unit test per layer (domain/data/presentation with fakes) delivers most of the safety cheaply; then add widget/golden and exactly one E2E per critical journey.
- Use coverage as a gap-finder, not a target — a green 100% suite that skips unhappy paths is worse than an 80% one that covers errors and edges.
- Gate PRs on fast tests, run E2E less frequently on emulators, use `melos --since` in monorepos, and quarantine flaky tests immediately — a slow or flaky CI is a suite people route around.

## Architect Perspective

This capstone is where the handbook's testable architecture cashes out: a pyramid-shaped suite that unit-tests every layer (thanks to fakes at abstraction boundaries), guards UI behavior + visuals with widget/golden tests, validates critical journeys with a thin E2E tip, measures coverage meaningfully, and gates merges in fast incremental CI. The result is regression safety + confident refactoring + fast feedback at scale — the concrete enabler of everything from clean architecture to scalable applications and CI/CD ([Module 40](../40%20Clean%20Architecture/README.md), [Module 47](../47%20Scalable%20Applications/README.md), [Module 50](../50%20CI%20CD/README.md)).

## Summary

- Assemble a pyramid-shaped, layer-complete suite: unit-test domain/data/presentation (fakes), widget+golden the UI, one integration test per critical journey.
- Measure coverage meaningfully (logic + unhappy paths, not 100% vanity); gate merges in CI (analyze + unit + widget on PRs; E2E at merge/nightly; `melos --since` incremental).
- Mirror source structure + shared fakes; quarantine flakes; the payoff is confident refactoring + regression safety + fast feedback.

## Revision Notes

- Per-layer unit: domain (fake repo), data (fake sources; mapping/errors), presentation (state sequences, fake use case) — isolated, fast. + widget/golden (faked VM, states/interactions/visuals) + 1 integration test (critical journey, deterministic).
- Coverage: `flutter test --coverage` (LCOV) → find gaps (logic + unhappy paths), not 100% vanity; skip generated/trivial.
- CI: analyze + unit + widget (+coverage) on PR (gate merge); `integration_test` on emulators at merge/nightly; `melos run test --since` incremental (monorepo); quarantine flakes; mirror source structure + shared fakes.

## Practice Questions

1. What test type covers each architectural layer, and why?
2. Why measure coverage but not chase 100%?
3. How should tests be gated/run in CI (PR vs merge/nightly)?

## Coding Questions

1. Write one unit test per layer (domain/data/presentation) using fakes.
2. Add a widget test (states + interaction) + a golden, and one integration test.
3. Write the CI config gating PRs on analyze + unit + widget (+coverage), E2E on merge.

## Mini Project

**Layered test suite + CI (capstone — Flutter):** For a feature slice, write: unit tests per layer (use case + fake repo; repo + fake sources incl. error mapping; view model state sequences), widget tests (states + interaction) + one golden, and one integration test for the critical journey — organized to mirror the source with shared fakes. Add coverage (`--coverage`) used to find gaps and a CI config gating PRs on analyze + unit + widget (E2E on merge/nightly; `melos --since` if monorepo). Acceptance: pyramid-shaped, every layer unit-tested with fakes; widget+golden UI; one critical-journey E2E; meaningful coverage (logic + unhappy paths, not 100%); CI gates merges (fast on PR, E2E less often); flakes quarantined; mirrors source structure.
