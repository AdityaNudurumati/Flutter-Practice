# Scalable Integration (Capstone: A Scaling Playbook)

> Synthesize the four dimensions into one **stage-aware scaling playbook**: for a given app stage, it prescribes the **structure** (feature-first→modular), **team practices** (ownership, governance, design system), **runtime discipline** (performance budget + deferral), and **evolution strategy** (debt register + deprecation + strangler-fig) — each **right-sized**, with explicit **"do now / defer"** calls and the **symptoms that trigger the next investment**. The playbook is the deliverable: not maximal architecture, but a diagnosed, proportional plan that keeps codebase, team, runtime, and features healthy as the app grows.

## Introduction

This module capstone assembles the four dimensions + their levers into a practical, stage-aware playbook — the artifact a lead uses to decide what to invest in now versus later. It ties together the whole architecture band as a "how to grow deliberately" guide.

## Why this concept exists

Scaling knowledge is only useful applied *proportionally* to a real app's stage. A playbook converts the dimensions/levers into concrete, staged decisions (with triggers), preventing both over-engineering (max architecture on a small app) and reactive fire-fighting (fixing a dimension only when it's already on fire).

## Real-world analogy

It's a **city master plan with phases**: phase 1 (village) needs basic roads + a shared water source; phase 2 (town) adds districts + zoning + utilities capacity; phase 3 (city) adds transit, governance, and redevelopment plans for aging areas. Each phase is **triggered by measured growth**, invests only what's needed now, and plans the next phase's triggers — not building a metro system for a village.

## Internal Working

```mermaid
flowchart TD
    Stage[app stage (measured)] --> Diagnose[diagnose pressured dimensions]
    Diagnose --> Structure[structure: feature-first -> modular]
    Diagnose --> Team[team: ownership + governance + design system]
    Diagnose --> Runtime[runtime: perf budget + deferral + profiling]
    Diagnose --> Evolution[evolution: debt register + deprecation + strangler-fig]
    Structure & Team & Runtime & Evolution --> Playbook[right-sized plan: do now / defer + triggers]
    Playbook --> Reassess[re-diagnose as app grows]
```

- **Stage-aware, right-sized** ([01_scaling_dimensions.md](01_scaling_dimensions.md)): the playbook adapts to stage — **prototype** (minimal), **growing single-team**, **large multi-team** — applying the **minimum lever** per pressured dimension and **deferring** the rest, with the **symptoms that trigger** the next step.
- **Structure lever** (codebase): start **feature-first** (cohesive slices + `core`); graduate to **modular packages** (enforced boundaries + incremental builds) when build/team pressure appears ([Module 44](../44%20Feature%20First%20Architecture/README.md)/[Module 45](../45%20Modular%20Architecture/README.md)); use **Clean/MVVM** inside slices ([Module 40](../40%20Clean%20Architecture/README.md)/[Module 43](../43%20MVVM/README.md)); apply **DDD** to the complex core only ([Module 46](../46%20Domain%20Driven%20Design/README.md)).
- **Team lever**: **ownership** (CODEOWNERS/packages), **governance** (conventions + lints + import boundaries + CI gates + ADRs + template slice), a **shared design system** — introduced as contributor count grows ([02_codebase_and_team_scaling.md](02_codebase_and_team_scaling.md)).
- **Runtime lever**: a **performance budget** (startup/memory/frame/app-size) enforced by **CI + monitoring**, **deferral-by-default** (lazy DI, on-demand feature/code loading), frame-budget levers (virtualize/scope/const/isolate), bounded caches + disposal, **continuous profiling** ([03_performance_and_runtime_scaling.md](03_performance_and_runtime_scaling.md)/[Module 21](../21%20Performance/README.md)/[Module 52](../52%20Monitoring/README.md)).
- **Evolution lever** (feature/longevity): a **debt register** (classified, interest-prioritized), **continuous paydown** (boy-scout + scheduled capacity + tests-first), **deprecation cycles**, **strangler-fig migrations** — never big-bang ([04_technical_debt_and_evolution.md](04_technical_debt_and_evolution.md)).
- **Cross-cutting hooks**: **CI/CD** (incremental, gated — [Module 50](../50%20CI%20CD/README.md)), **monitoring** (perf/crash/usage — [Module 52](../52%20Monitoring/README.md)), **testing** (regression safety at scale — [Module 49](../49%20Testing/README.md)) — these enforce the playbook.
- **Do-now / defer + triggers**: for each dimension, the playbook states **what to do at this stage**, **what to defer**, and the **measured symptom** that promotes a deferred item to "do now" — making scaling **proactive-but-proportional**, not reactive.
- **Re-diagnose**: the bottleneck moves as the app grows; the playbook is **revisited** periodically against fresh measurements ([01_scaling_dimensions.md](01_scaling_dimensions.md)).

## Memory Representation

Not runtime — a **living document**: per-dimension current-state, chosen levers (do-now), deferred items + triggers, and cross-cutting hooks. Revisited as measurements change.

## Compiler Behavior

Structure/governance levers are compile/build-enforced (modular boundaries, lints); the rest are process/runtime/monitoring — together they make much of the playbook automatically enforced.

## Runtime Behavior

Only the runtime lever affects runtime (budget/deferral/profiling); the others shape build/dev/team/evolution. Monitoring feeds runtime + evolution decisions.

## Flutter Engine Behavior

Runtime levers interact with the engine (rebuilds/rasterization/memory — [Module 21](../21%20Performance/README.md)); others don't.

## Dart VM Behavior

Modular structure enables incremental builds; runtime levers touch isolates/GC; the rest are org/process.

## Examples

```text
Scaling playbook (excerpt) — do-now / defer / trigger, per stage:

STAGE: growing single-team app
  Structure   DO NOW: feature-first + core + Clean/MVVM inside slices
              DEFER: modular packages         TRIGGER: builds >5min OR 2nd team joins
  Team        DO NOW: conventions + lints + CI gates + a lightweight design system
              DEFER: strict CODEOWNERS/packages TRIGGER: >~8 contributors / merge-conflict pain
  Runtime     DO NOW: perf budget + deferral defaults + continuous profiling
              DEFER: on-demand code loading (web deferred imports) TRIGGER: cold start > budget
  Evolution   DO NOW: debt register + boy-scout + tests-first refactoring
              DEFER: formal deprecation policy TRIGGER: first public/shared contract
  Cross-cut   DO NOW: CI (analyze/test) + basic monitoring (crash/perf)

STAGE: large multi-team app -> promote most "defer" items to "do now" (modular packages,
       CODEOWNERS, design-system package, on-demand loading, deprecation cycles, incremental CI).
```

```text
Reassessment loop:
  measure (build time, conflict rate, frame/startup/memory, regression rate)
  -> re-diagnose pressured dimension -> promote a deferred lever -> update playbook
```

## Diagrams

```mermaid
flowchart LR
    Measure[measure symptoms] --> Diagnose[diagnose dimensions]
    Diagnose --> DoNow[do-now levers (min per dimension)]
    Diagnose --> Defer[defer + record triggers]
    DoNow --> Enforce[CI + monitoring + governance enforce]
    Enforce --> Reassess[re-diagnose periodically]
    Reassess --> Diagnose
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| One-size playbook (max architecture) | Over-engineers small apps | Stage-aware, right-sized do-now/defer |
| No triggers for deferred items | Reactive fire-fighting later | Define measured symptoms that promote items |
| Investing in a non-bottleneck dimension | Wasted effort | Diagnose from symptoms first |
| Playbook as a one-time doc | Bottleneck moves | Living doc; re-diagnose periodically |
| No enforcement hooks | Levers erode | Wire CI/monitoring/governance |
| Ignoring evolution/debt | Calcifies at scale | Include debt register + migration strategy |
| Skipping measurement | Dogma over data | Measure build/conflict/frame/regression |

## Best Practices

- Produce a **stage-aware, right-sized playbook**: per dimension, state **do-now** levers, **deferred** items, and the **measured trigger** that promotes each — proactive but proportional.
- Cover all four dimensions with the band's levers (**feature-first→modular + Clean/MVVM/DDD**; **ownership + governance + design system**; **perf budget + deferral + profiling**; **debt register + deprecation + strangler-fig**).
- **Enforce** via cross-cutting hooks (**CI, monitoring, testing, governance**); **measure** symptoms and **re-diagnose** as the app grows.
- **Never over-engineer** (max architecture on a small app) or **fire-fight** (fix only when on fire); manage the tradeoffs continuously.

## Performance

The playbook itself optimizes **investment ROI**: effort goes to the pressured dimension, deferred elsewhere, so the app scales without wasted work or gradual rot. Runtime performance is one dimension it governs (budget/deferral); the others govern dev/team/evolution velocity.

## Advantages / Disadvantages

- **+** Proportional, diagnosed, proactive-but-not-wasteful scaling across all four dimensions; clear triggers; enforced + revisited; avoids over/under-engineering.
- **−** Requires measurement + judgment + upkeep (living doc); no formulaic answer; needs org buy-in for governance/ownership/budget enforcement.

## Interview Questions

1. **🟢 What is a scaling playbook?** — A stage-aware, right-sized plan covering all four scaling dimensions with do-now levers, deferred items, and measured triggers to promote them.
2. **🟢 Why stage-aware/right-sized rather than one-size?** — To avoid over-engineering small apps and fire-fighting large ones; invest the minimum in the pressured dimension and defer the rest.
3. **🟡 Which levers cover the four dimensions?** — Structure (feature-first→modular + Clean/MVVM/DDD), team (ownership + governance + design system), runtime (perf budget + deferral + profiling), evolution (debt register + deprecation + strangler-fig).
4. **🟡 What promotes a deferred item to "do now"?** — A measured symptom/trigger (e.g., builds >5min → modularize; cold start > budget → on-demand loading; >N contributors → CODEOWNERS/design-system).
5. **🟡 How is the playbook enforced?** — Cross-cutting hooks: CI (incremental/gated), monitoring (perf/crash/usage), testing (regression safety), and automated governance.
6. **🔴 Why is the playbook a living document?** — The bottleneck moves as the app grows; you re-measure and re-diagnose periodically, promoting deferred levers as triggers fire.
7. **🔴 How does the playbook synthesize the architecture band?** — It sequences Clean/MVVM/feature-first/modular/DDD + performance/testing/CI/monitoring as staged, dimension-targeted investments — proportional application of the whole band.

## Senior Engineer Tips

- Write the playbook as do-now/defer/trigger per dimension and keep it living; the triggers are what turn scaling from reactive panic into scheduled, proportional investment.
- Diagnose from measurements (build time, conflict rate, frame/startup/memory, regression rate) before investing; most "we need to re-architect everything" is one dimension away from a targeted fix.
- Enforce every lever with a hook (CI, monitoring, governance) — an un-enforced playbook decays into aspiration; and revisit it each time the app crosses a growth threshold.

## Architect Perspective

The scaling playbook is the architect's synthesis of the entire band: a stage-aware, measured, proportional plan that invests in the pressured dimension, defers the rest with explicit triggers, and enforces itself through CI/monitoring/governance. It reframes "architecture" from a fixed choice to a **continuous, diagnosed practice** — applying Clean/MVVM/feature-first/modular/DDD + performance/testing/evolution exactly when and where they pay off. Done well, an app grows to hundreds of features and many teams while staying navigable, ownable, fast, and changeable — the definition of a scalable application ([01_scaling_dimensions.md](01_scaling_dimensions.md), [Module 45](../45%20Modular%20Architecture/README.md), [Module 50](../50%20CI%20CD/README.md), [Module 52](../52%20Monitoring/README.md)).

## Summary

- A scaling playbook is a stage-aware, right-sized plan across the four dimensions, with do-now levers, deferred items, and measured triggers.
- Levers: feature-first→modular + Clean/MVVM/DDD; ownership + governance + design system; perf budget + deferral + profiling; debt register + deprecation + strangler-fig.
- Enforce via CI/monitoring/testing/governance; measure + re-diagnose continuously; avoid over-engineering and fire-fighting.

## Revision Notes

- Playbook = stage-aware, right-sized, per-dimension do-now/defer/trigger (proactive-but-proportional; living doc).
- Levers: structure (feature-first→modular + Clean/MVVM/DDD-core-only), team (ownership/governance/design system), runtime (perf budget + deferral + profiling), evolution (debt register + deprecation + strangler-fig).
- Enforce via CI/monitoring/testing/governance; measure symptoms (build/conflict/frame/startup/memory/regression) → re-diagnose → promote deferred levers; never over-engineer or fire-fight.

## Practice Questions

1. What does a scaling playbook contain, and why do-now/defer/trigger?
2. Which levers map to which dimensions?
3. How is the playbook enforced and kept current?

## Coding Questions

1. Draft a do-now/defer/trigger playbook for a given app stage.
2. Map measured symptoms to the levers they should promote.
3. List the CI/monitoring/governance hooks that enforce the playbook.

## Mini Project

**Scaling playbook (capstone — Flutter):** For a chosen app stage (e.g., growing single-team heading toward multi-team), produce a scaling playbook covering all four dimensions: structure (feature-first now, modular deferred + trigger), team (governance/design-system now, CODEOWNERS/packages deferred + trigger), runtime (perf budget + deferral + profiling now, on-demand code loading deferred + trigger), and evolution (debt register + boy-scout/tests-first now, formal deprecation deferred + trigger) — plus CI/monitoring/testing hooks and a reassessment loop. Acceptance: all four dimensions covered with do-now/defer/measured-trigger; right-sized to the stage (no over-engineering); enforcement hooks (CI/monitoring/governance); living-doc reassessment loop; synthesizes the architecture band proportionally.
