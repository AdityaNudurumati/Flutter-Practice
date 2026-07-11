# Performance Monitoring & Alerting

> Lab performance (DevTools on your device) ≠ **field performance** (thousands of real devices/networks) — so monitor it in production: **startup time**, **frame rendering** (slow/frozen frames, jank %), **network** (latency, error rate), and **custom traces** (a checkout's duration), via **Firebase Performance**/**Sentry Performance** or custom metrics. Turn raw numbers into **SLIs** (Service Level Indicators — the measured signals, tracked at **p50/p90/p95/p99**, not averages) with **SLOs** (targets, e.g., "p95 cold start < 2s, 99.5% crash-free"), surfaced on **dashboards** and guarded by **alerts** on **SLO breaches/regressions** — so a bad release or degradation is caught (and staged rollout halted) before wide impact.

## Introduction

This file covers field performance monitoring + alerting: what to measure (startup/frames/network/custom traces), percentiles vs averages, SLIs/SLOs, dashboards, and alerting (including rollout gating). It extends the performance discipline ([Module 21](../21%20Performance/README.md)/[Module 47](../47%20Scalable%20Applications/README.md)) into production.

## Why this concept exists

An app can be smooth on your flagship dev phone and janky/slow on a mid-range device on a 3G network — you only learn this from **real-world data**. And performance **regresses silently** as features land. Field monitoring + SLOs + alerts make performance an **enforced, observable** property (like crash-free rate for stability), catching regressions in production and gating releases.

## Real-world analogy

It's **fleet telemetry vs a single test drive**: your one test car (dev device) says "smooth," but the **whole fleet in real conditions** (traffic, weather, terrain) tells the truth — so you monitor **fuel efficiency, engine temp, braking distance** across all vehicles at the **95th percentile** (worst realistic, not the average). You set **targets (SLOs)**, watch a **dashboard**, and get **alerts** when a model's metrics degrade — pulling that model from wide release before customers are affected.

## Internal Working

```mermaid
flowchart TD
    Field[real devices/networks] --> Measure[measure: startup, frames (slow/frozen), network, custom traces]
    Measure --> SLI[SLIs: signals at p50/p90/p95/p99 (not averages)]
    SLI --> SLO[SLOs: targets (e.g., p95 cold start < 2s; 99.5% crash-free)]
    SLO --> Dash[dashboards: trends, per version/device/network]
    Dash --> Alert[alerts on SLO breach / regression]
    Alert --> Act[act: halt staged rollout / investigate / fix]
```

- **What to measure (mobile field perf)**:
  - **Startup time**: **cold/warm/hot** start, time-to-first-frame/interactive — a top UX + install-retention metric.
  - **Frame rendering**: **slow frames** (>16ms@60 / >8ms@120) and **frozen frames** (>700ms) → **jank %**; the smoothness signal ([Module 21](../21%20Performance/README.md)).
  - **Network**: request **latency**, **error/timeout rate**, payload sizes — per endpoint.
  - **Custom traces**: wrap key operations (checkout, search, image load) to measure **duration + success** in the field.
  - **Resource**: memory/ANRs/battery where available.
- **Percentiles, not averages (critical)**: report **p50/p90/p95/p99** — the **average hides the tail** (a 2s mean can hide many 8s experiences). SLIs/SLOs target **high percentiles** (p95/p99) because that's where users suffer. Slice by **version/device tier/network/region** to find who's affected.
- **SLIs / SLOs / (SLAs)**:
  - **SLI** = the **measured signal** (e.g., p95 cold-start time, crash-free rate, p95 checkout duration).
  - **SLO** = the **target/objective** for an SLI (e.g., "p95 cold start < 2s", "99.5% crash-free", "checkout p95 < 3s"). Your internal quality bar.
  - **SLA** = a **contractual** guarantee (mostly backend/enterprise); mobile teams mostly use SLIs/SLOs internally.
  - SLOs make performance **measurable + enforceable**, not vibes.
- **Dashboards**: visualize SLIs over time, **per version** (release health), device tier, network — to spot **trends + regressions** (a new version's p95 startup climbing) alongside crash-free rate ([crash_reporting.md](crash_reporting.md)).
- **Alerting (the action trigger)**:
  - Alert on **SLO breaches** (crash-free < target, p95 startup > target), **regressions** (metric worse than the previous release), and **spikes** (error-rate/jank surge) — especially **during staged rollout**.
  - **Tune to avoid noise**: alert on **sustained, meaningful** breaches (not single blips); route to the right channel; make each alert **actionable** (maps to a decision: halt rollout / investigate / hotfix).
- **Rollout gating (closes with deployment)**: during **staged/phased rollout**, monitored SLIs (crash-free + perf) decide **promote vs halt** — a regression at 5% stops it before 100% ([Module 51](../51%20Deployment/README.md)).
- **Tools**: **Firebase Performance Monitoring** (auto startup/frame/network traces + custom traces, Flutter-integrated), **Sentry Performance** (transactions/spans + tracing), custom metrics to a backend. Wire behind an interface where practical; keep **low-overhead** (sampling).
- **Overhead + privacy**: performance SDKs sample + batch (low overhead); attach only **non-PII** context (version/device/network) ([Module 37](../37%20Security/README.md)).

## Memory Representation

Not app state — **time-series SLIs** (percentile distributions per version/device/network) + custom-trace spans in the monitoring backend; SLO targets + alert rules are config. On-device: sampled trace/metric collection, batched async.

## Compiler Behavior

Not applicable (SDK-based). Custom traces are code instrumentation; performance data ties to app version/build for release comparison.

## Runtime Behavior

The SDK samples startup/frame/network + custom traces during real use, batches async (low overhead); the backend aggregates percentiles + fires alerts on breaches/regressions. Rollout decisions read these live.

## Flutter Engine Behavior

Frame/startup traces hook engine timings (build/layout/paint/raster + time-to-first-frame); slow/frozen-frame classification comes from the rendering pipeline ([Module 09](../09%20Rendering%20Pipeline/README.md)/[Module 21](../21%20Performance/README.md)).

## Dart VM Behavior

Custom traces measure Dart operation durations; isolate/GC pauses can surface as jank in frame metrics. Sampling keeps overhead low.

## Examples

```dart
// Custom trace (Firebase Performance) — measure a key operation in the field
final trace = FirebasePerformance.instance.newTrace('checkout');
await trace.start();
try {
  await performCheckout();
  trace.putAttribute('result', 'success');
} catch (_) {
  trace.putAttribute('result', 'failure');
} finally {
  await trace.stop();   // duration recorded across real devices/networks
}
// Firebase auto-collects: app start time, slow/frozen frames, HTTP/S network traces.
```

```text
SLIs / SLOs (percentiles, not averages):
  SLI: p95 cold start time      SLO: < 2.0s
  SLI: crash-free users         SLO: >= 99.5%
  SLI: jank % (slow/frozen)     SLO: < 1% of frames
  SLI: p95 checkout duration    SLO: < 3.0s
  SLI: network error rate       SLO: < 1%
  -> report p50/p90/p95/p99, sliced by version/device tier/network; alert on breach/regression

Alerting (actionable, tuned):
  crash-free rate < 99.5% (sustained)      -> HALT staged rollout, investigate
  p95 startup > 2s on new version          -> regression alert -> hold promotion
  network error rate spike on endpoint X   -> investigate backend/contract
```

## Diagrams

```mermaid
flowchart LR
    Field2[field devices] --> SLIs[SLIs @ p95/p99 (startup/frames/network/traces)]
    SLIs --> SLOs[SLOs (targets)]
    SLOs --> Alerts[alerts on breach/regression]
    Alerts --> Rollout[gate staged rollout: promote vs halt]
```

## Common Mistakes

| Mistake | Why it's wrong | Fix |
|---------|---------------|-----|
| Only lab (dev-device) performance | Misses field reality (mid-range/3G) | Monitor in production across devices/networks |
| Averages instead of percentiles | Hides the painful tail | Track p95/p99 (+ p50/p90) |
| No SLIs/SLOs | Performance is "vibes" | Define SLIs + SLO targets |
| No per-version dashboards | Miss release regressions | Slice by version (release health) |
| Alerting on single blips | Alert fatigue → ignored | Alert on sustained/meaningful breaches, actionable |
| Not gating rollout on perf/crash | Bad release hits everyone | Halt staged rollout on SLO breach |
| Heavy/unsampled tracing | Overhead | Sample + batch (low overhead) |
| PII in trace attributes | Privacy breach | Non-PII context only |

## Best Practices

- **Monitor performance in the field** (startup, slow/frozen frames + jank %, network latency/errors, custom traces) across **devices/networks/versions** — not just on your dev device.
- Use **percentiles (p95/p99)**, not averages; define **SLIs + SLOs** (targets) so performance is measurable/enforceable; surface on **per-version dashboards** alongside crash-free rate.
- **Alert on SLO breaches/regressions/spikes** (sustained, actionable, tuned to avoid noise) and **gate staged rollout** on them (halt on regression before wide impact).
- Keep monitoring **low-overhead** (sampling/batching) and **PII-safe**; wrap key operations in **custom traces**; act on alerts (close the loop).

## Performance

Ironically, monitoring must itself be **low-overhead** (sampled/batched) — but its payoff is protecting field performance: catching startup/frame/network regressions the lab misses, enforcing SLOs, and gating releases. Percentile tracking focuses effort where users actually hurt (the tail) ([Module 21](../21%20Performance/README.md)/[Module 47](../47%20Scalable%20Applications/README.md)).

## Advantages / Disadvantages

- **+** Real-world performance visibility, percentile/tail insight, per-version regression detection, SLO enforcement, rollout gating, actionable alerts.
- **−** SDK/backend setup + cost, alert tuning (noise vs signal), SLO definition/maintenance, sampling trade-offs, low-overhead + privacy discipline.

## Interview Questions

1. **🟢 Why monitor performance in production, not just DevTools?** — Lab (your device) ≠ field (thousands of real devices/networks); startup/jank/network vary hugely and regress silently — only field data reveals the truth.
2. **🟢 Why percentiles instead of averages?** — Averages hide the tail; p95/p99 capture the painful worst-case experiences where users actually suffer.
3. **🟡 What are SLIs and SLOs?** — SLI = the measured signal (p95 cold start, crash-free rate); SLO = the target for it (e.g., p95 < 2s, ≥99.5% crash-free) — making performance measurable/enforceable.
4. **🟡 What field metrics do you track for a Flutter app?** — Startup time, slow/frozen frames (jank %), network latency/error rate, custom operation traces, memory/ANRs — sliced by version/device/network.
5. **🟡 How do alerts avoid noise while staying useful?** — Alert on sustained/meaningful SLO breaches/regressions (not single blips), route them, and make each actionable (maps to a decision like halt rollout).
6. **🔴 How does performance monitoring gate deployment?** — During staged rollout, SLI regressions (crash-free/perf) trigger halting/rolling back before 100% exposure ([Module 51](../51%20Deployment/README.md)).
7. **🔴 How do you keep monitoring itself cheap + private?** — Sample + batch traces (low overhead) and attach only non-PII context (version/device/network).

## Senior Engineer Tips

- Define a few meaningful SLIs/SLOs (crash-free rate, p95 cold start, jank %, key custom-trace durations) and put them on a per-version dashboard; that's your release-health cockpit.
- Track percentiles and slice by device tier/network — the average makes a broken mid-range/3G experience invisible, which is exactly the segment that churns.
- Make every alert actionable and tuned; alert on sustained SLO breaches during rollout so you halt before 100%, and delete noisy alerts that trained everyone to ignore them.

## Architect Perspective

Performance monitoring + alerting is the performance sensor of observability: it moves performance from a lab hope to an enforced, field-measured property via SLIs/SLOs at high percentiles, per-version dashboards, and actionable alerts that gate staged rollouts. Together with crash reporting (stability) it forms the release-health signals that make rollouts safe and regressions catchable — the production enforcement of the performance budgets defined earlier ([Module 21](../21%20Performance/README.md), [Module 47](../47%20Scalable%20Applications/README.md), [Module 51](../51%20Deployment/README.md), [crash_reporting.md](crash_reporting.md)).

## Summary

- Monitor field performance (startup, slow/frozen frames + jank %, network, custom traces) across devices/networks/versions — lab ≠ field.
- Use percentiles (p95/p99); define SLIs + SLOs (targets); dashboard per version; alert on breaches/regressions (sustained, actionable) and gate staged rollout.
- Keep monitoring low-overhead (sampled/batched) + PII-safe; act on alerts (close the loop).

## Revision Notes

- Measure (field, not lab): startup (cold/warm/hot, TTFF), frames (slow >16ms/frozen >700ms → jank %), network (latency/error rate), custom traces (checkout/search), memory/ANRs. Firebase Performance/Sentry Performance.
- Percentiles (p50/p90/**p95/p99**) not averages (tail hidden); slice by version/device tier/network. SLI = measured signal; SLO = target (p95 cold start <2s, ≥99.5% crash-free, jank <1%); SLA = contractual (backend).
- Dashboards per version (release health, w/ crash-free); alerts on SLO breach/regression/spike (sustained + actionable + tuned) → gate staged rollout (halt on regression). Low-overhead (sample/batch) + PII-safe context.

## Practice Questions

1. Why report p95/p99 instead of averages?
2. Define SLI vs SLO with mobile examples.
3. How do performance/crash SLIs gate a staged rollout?

## Coding Questions

1. Add a custom trace around a key operation with a success attribute.
2. Define SLIs/SLOs for startup, frames, and a custom trace.
3. Specify alert rules (breach/regression) that halt a staged rollout.

## Mini Project

**Field performance monitoring (Flutter/monitoring):** Wire performance monitoring (Firebase Performance/Sentry): auto startup/frame/network traces + a custom trace around a key flow (e.g., checkout), define SLIs/SLOs (p95 cold start, jank %, crash-free rate, custom-trace p95) tracked at percentiles per version/device/network, build a release-health dashboard, and set actionable alerts (SLO breach/regression) that gate staged rollout — low-overhead + PII-safe. Acceptance: field metrics (startup/frames/network/custom) at percentiles, sliced by version/device/network; SLIs + SLO targets; per-version dashboard (+ crash-free); tuned actionable alerts → rollout halt; low-overhead (sampled/batched) + non-PII context.
