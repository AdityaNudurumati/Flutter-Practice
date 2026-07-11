# Monitoring Fundamentals

> **Monitoring** = watching **known signals** to answer "is the app healthy?" (crash-free rate, error count, frame times). **Observability** = the property that lets you ask **new questions** about *why* — from rich, correlated telemetry — without shipping new code. Both are built on the **three pillars**: **logs** (discrete events — what happened), **metrics** (aggregated numbers over time — how much/how often), and **traces** (the path of one operation across the system — where time/failure went). The point isn't collecting data; it's the **feedback loop**: production signals → detect/diagnose → act (fix/rollback/iterate). Everything must be **PII-safe** and **not degrade the app**.

## Introduction

This file establishes the conceptual frame: monitoring vs observability, the three pillars, and the feedback loop — before the crash/analytics/performance specifics. It clarifies terms teams conflate and sets the "signals → action" mindset.

## Why this concept exists

A live app runs on thousands of devices you can't see. Without instrumentation, you learn about crashes/slowness/drop-offs only from complaints — too late. Monitoring/observability give **visibility** so you can detect regressions fast (esp. during staged rollout), diagnose root causes, and improve based on **data, not guesses**. The three pillars organize *what* you collect; the feedback loop organizes *why*.

## Real-world analogy

Monitoring is the **dashboard gauges** in a car — speed, fuel, temperature — showing known health at a glance. Observability is having **enough sensors + logs** that when something odd happens you can **investigate a new question** ("why did it overheat on hills?") without adding hardware. **Logs** = the trip journal (events), **metrics** = the odometer/averages (aggregates), **traces** = following one journey turn-by-turn (the path). The value is the **driver reacting** — slowing down, refueling, servicing — not the gauges themselves.

## Internal Working

```mermaid
flowchart TD
    App[live app on many devices] --> Pillars{three pillars}
    Pillars --> Logs[LOGS: discrete events (what happened)]
    Pillars --> Metrics[METRICS: aggregates over time (how much/often)]
    Pillars --> Traces[TRACES: one operation's path (where time/failure went)]
    Logs & Metrics & Traces --> Detect[monitor/observe: detect + diagnose]
    Detect --> Act[act: fix / rollback / iterate]
    Act --> App
    Note[correlation ids stitch pillars; PII-safe; low overhead]
```

- **Monitoring vs observability**:
  - **Monitoring**: tracking **predefined signals/thresholds** to answer known questions — "is crash-free rate above 99.5%? are frames within budget?" Alerts fire on threshold breaches. Tells you **something is wrong**.
  - **Observability**: the system emits enough **rich, correlated** telemetry that you can **ask arbitrary new questions** and diagnose **why** — without deploying new instrumentation. Tells you **why it's wrong**.
  - You need both: monitoring to **detect**, observability to **diagnose**.
- **The three pillars**:
  - **Logs**: **discrete, timestamped events** (an error, a login, a request) — the granular "what happened," searchable/filterable ([Module 39](../39%20Logging/README.md)). Structured + leveled.
  - **Metrics**: **numeric measurements aggregated over time** (crash-free %, active users, p95 startup, frame-drop rate) — cheap to store, ideal for dashboards/alerts/trends.
  - **Traces**: the **end-to-end path of a single operation** across components (a request/user-action's spans + timings) — shows **where latency/failure occurred**; stitched by a **correlation/trace id** ([Module 39](../39%20Logging/README.md)).
  - Together they answer what (logs), how much (metrics), and where (traces) — and **correlate** via shared ids (a crash links to its logs/breadcrumbs and the request's trace).
- **The feedback loop (the actual point)**: **collect** (instrument) → **detect** (monitor/alert) → **diagnose** (observe: logs/traces/context) → **act** (fix/hotfix, halt staged rollout, iterate on product) → back to collect. Monitoring without action is wasted; the loop is what makes it valuable ([monitoring_integration.md](monitoring_integration.md)).
- **What to observe (mobile)**: **stability** (crashes/ANRs — [crash_reporting.md](crash_reporting.md)), **performance** (startup/frames/network — [performance_monitoring_and_alerting.md](performance_monitoring_and_alerting.md)), **product usage** (events/funnels — [analytics_and_metrics.md](analytics_and_metrics.md)), and **errors** (handled failures). Attach **context** (app version, device, session) for slicing.
- **Constraints (non-negotiable)**:
  - **Privacy/PII-safe**: telemetry ships off-device to vendors — **never** log PII/secrets; redact + follow consent/regulation ([Module 37](../37%20Security/README.md)/[Module 39](../39%20Logging/README.md)).
  - **Low overhead**: monitoring must **not** noticeably harm performance/battery/data — sample, batch, async (as with remote logging).
  - **Correlation**: use ids to stitch pillars per user action/session.
- **Tools (overview)**: **Firebase Crashlytics** (crashes) + **Analytics** (events) + **Performance Monitoring** (traces/metrics) — integrated, common for Flutter; **Sentry** (crashes + performance + logs, cross-platform); plus custom/backend telemetry. Choice covered in later files.

## Memory Representation

Not runtime state you own — a **telemetry model**: logs (event stream), metrics (time-series), traces (span trees), correlated by ids + context (version/device/session). On-device, a small buffer batches telemetry for async upload; the analysis lives in the monitoring backend/dashboards.

## Compiler Behavior

Not applicable (instrumentation is normal code + SDKs). Release builds are obfuscated → crash reports need **symbolication** with the archived mapping ([Module 51](../51%20Deployment/README.md)/[crash_reporting.md](crash_reporting.md)).

## Runtime Behavior

Telemetry is captured during use and shipped **async/batched** (low overhead); the backend aggregates into metrics/dashboards and fires **alerts** on thresholds; correlation ids link a crash to its breadcrumbs/trace.

## Flutter Engine Behavior

Performance monitoring hooks frame timings/startup from the engine ([Module 21](../21%20Performance/README.md)); crash SDKs capture native + Dart errors.

## Dact VM Behavior

Uncaught Dart errors + isolate errors are captured by crash SDKs ([Module 38](../38%20Error%20Handling/README.md)); telemetry batching runs off the critical path.

## Examples

```text
The three pillars answering different questions:
  LOGS:    "checkout_failed event at 12:03 for session X (NetworkFailure)"      -> what happened
  METRICS: "crash-free rate 98.7% (down from 99.6%); p95 startup 2.1s"          -> how much/trend
  TRACES:  "checkout took 3.4s: 3.1s in POST /order (server) + 0.3s render"     -> where the time went
  -> correlation id ties the crash -> its breadcrumbs (logs) -> the request trace

Monitoring vs observability:
  Monitoring:    alert when crash-free rate < 99.5% (KNOWN signal/threshold)
  Observability: after the alert, slice by version/device/screen to find WHY (NEW questions), no redeploy
```

```text
Feedback loop:
  collect (instrument) -> detect (monitor/alert) -> diagnose (observe: logs/traces/context) -> act (fix/rollback/iterate) -> repeat
  (monitoring WITHOUT the "act" step is wasted)
```

## Diagrams

```mermaid
flowchart LR
    Collect[collect: logs+metrics+traces (PII-safe, low overhead)] --> Detect2[detect: monitor + alert]
    Detect2 --> Diagnose[diagnose: observe (why) via correlated telemetry]
    Diagnose --> Act2[act: fix/hotfix/halt rollout/iterate]
    Act2 --> Collect
```

## Common Mistakes

| Mistake | Why it's wrong | Fix |
|---------|---------------|-----|
| Collecting data but never acting | Monitoring without the loop is waste | Close the loop: detect→diagnose→act |
| Confusing monitoring with observability | Different capabilities | Monitor to detect; observability to diagnose |
| Logging PII/secrets in telemetry | Privacy/compliance breach | Redact; PII-safe; consent (Module 37/39) |
| Heavy synchronous telemetry | Harms perf/battery/data | Async, batched, sampled |
| No correlation ids | Can't stitch crash↔logs↔trace | Correlation/trace ids + context |
| Only one pillar (e.g., only crashes) | Blind spots | Use logs + metrics + traces together |
| No alerting thresholds | Regressions unnoticed | Alert on key signals (crash-free/SLOs) |
| Unsymbolicated release crashes | Unreadable stacks | Symbolicate with archived mapping |

## Best Practices

- Use **monitoring to detect** (known signals/thresholds/alerts) and **observability to diagnose** (rich, correlated telemetry answering new questions); you need **both**.
- Instrument the **three pillars** (logs/metrics/traces) with **correlation ids + context** (version/device/session) so a crash links to its breadcrumbs and trace.
- **Close the feedback loop**: collect → detect → diagnose → **act** (fix/hotfix/halt rollout/iterate) — monitoring without action is wasted.
- Keep telemetry **PII-safe** (redact, consent) and **low-overhead** (async/batched/sampled); symbolicate release crashes with the archived mapping.

## Performance

Monitoring must be **cheap**: async, batched, and sampled so it doesn't tax CPU/battery/data — the same discipline as remote logging ([Module 39](../39%20Logging/README.md)). Metrics are cheap to aggregate; traces/logs are sampled at volume. The payoff is catching real **performance/stability** regressions in production ([Module 21](../21%20Performance/README.md)).

## Advantages / Disadvantages

- **+** Production visibility, fast detection + diagnosis, data-driven fixes/iteration, safe staged rollouts, closes the delivery loop.
- **−** Instrumentation + backend cost/setup, privacy discipline, overhead if done naively, alert tuning (noise vs signal), tool choice/integration.

## Interview Questions

1. **🟢 Monitoring vs observability?** — Monitoring watches known signals/thresholds to detect that something's wrong; observability is having rich correlated telemetry to ask new questions and diagnose why — without redeploying.
2. **🟢 What are the three pillars?** — Logs (discrete events — what), metrics (aggregates over time — how much/trend), traces (one operation's path — where time/failure went).
3. **🟡 How do the pillars work together?** — Correlation/trace ids + context stitch them: a metric alert leads to logs (events) and a trace (path) for the same action to find the cause.
4. **🟡 What is the monitoring feedback loop, and why does it matter?** — Collect → detect → diagnose → act (fix/rollback/iterate); monitoring without acting on signals is wasted effort.
5. **🟡 What constraints apply to mobile telemetry?** — PII-safe (redact/consent) and low-overhead (async/batched/sampled) so it doesn't leak data or harm performance/battery.
6. **🔴 Why must release crashes be symbolicated, and how?** — Obfuscated release stacks are unreadable; symbolicate with the archived `--split-debug-info` mapping.
7. **🔴 What should a mobile app observe?** — Stability (crashes/ANRs), performance (startup/frames/network), product usage (events/funnels), and handled errors — with slicing context (version/device/session).

## Senior Engineer Tips

- Always design for the "act" step: pick signals + alerts that map to a decision (halt rollout, hotfix, prioritize a fix), or you're just collecting dashboards nobody uses.
- Thread a correlation id through logs → requests → crash context from day one; stitching crash ↔ breadcrumbs ↔ trace is the single biggest diagnosis multiplier.
- Keep telemetry async/batched/sampled and PII-free; monitoring that harms performance or leaks data is worse than none.

## Architect Perspective

Monitoring/observability is the sensory system of a live app: the three pillars (logs/metrics/traces), correlated and contextual, let you **detect** (monitoring) and **diagnose** (observability), and the feedback loop turns those signals into action — safe rollouts, fast fixes, data-driven iteration. Built on the logging/error-handling foundation and feeding deployment's staged rollouts, it closes the build→ship→observe→improve cycle. The discipline is PII-safety + low overhead + acting on signals, not merely collecting them ([crash_reporting.md](crash_reporting.md), [Module 39](../39%20Logging/README.md), [Module 51](../51%20Deployment/README.md)).

## Summary

- Monitoring detects (known signals/thresholds/alerts); observability diagnoses (rich correlated telemetry, new questions) — you need both.
- Three pillars: logs (events/what), metrics (aggregates/how much), traces (path/where) — correlated by ids + context.
- Close the feedback loop (collect→detect→diagnose→act); keep telemetry PII-safe + low-overhead; symbolicate release crashes.

## Revision Notes

- Monitoring = watch known signals/thresholds (detect); observability = ask new questions from rich correlated telemetry (diagnose why) w/o redeploy. Need both.
- Pillars: logs (discrete events, what — Module 39), metrics (aggregates/time-series, how much/trend, alerts/dashboards), traces (one operation's spans, where latency/failure). Correlate via ids + context (version/device/session).
- Feedback loop: collect→detect→diagnose→act (fix/hotfix/halt rollout/iterate); PII-safe (redact/consent), low overhead (async/batched/sampled); symbolicate release crashes (archived mapping). Tools: Firebase Crashlytics/Analytics/Performance, Sentry.

## Practice Questions

1. Distinguish monitoring from observability with an example.
2. What question does each of the three pillars answer?
3. Why is the "act" step essential, and what breaks without correlation ids?

## Coding Questions

1. Classify a set of telemetry into logs/metrics/traces.
2. Show how a correlation id stitches a crash to its logs + a request trace.
3. Sketch the feedback loop for a crash-free-rate regression.

## Mini Project

**Observability model (Flutter/monitoring):** For an app, define its observability model: which signals map to logs vs metrics vs traces, the correlation-id + context strategy (version/device/session), the key monitored signals + thresholds (e.g., crash-free rate, p95 startup), and the feedback loop (collect→detect→diagnose→act) — with PII-safety + low-overhead constraints. Acceptance: three pillars applied with correct signal classification; correlation + context strategy; monitored signals/thresholds tied to actions; documented feedback loop; PII-safe + low-overhead; monitoring-vs-observability distinction clear.
