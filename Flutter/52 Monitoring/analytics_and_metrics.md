# Analytics & Custom Metrics

> Analytics answers **"what are users actually doing?"** — you log **events** (`screen_view`, `add_to_cart`, `purchase`) with **parameters + user properties**, then analyze **funnels** (step-by-step conversion), **retention**, and **custom metrics** to drive **product decisions**. The discipline: define a deliberate **event taxonomy** (consistent names/params — not ad hoc), instrument **key user actions + business outcomes** (not everything), respect **privacy/consent** (no PII, honor ATT/GDPR, opt-out), and keep it behind an **abstraction** (an `Analytics` interface) so it's swappable and testable. Analytics is about **learning + deciding**, distinct from crash/perf monitoring (health).

## Introduction

This file covers product analytics: event taxonomy, funnels/retention/custom metrics, privacy/consent, and wrapping analytics behind an interface. It's the "what/why users do" pillar, complementing stability (crashes) and performance monitoring.

## Why this concept exists

Building features without measuring usage is guessing — you can't tell what's used, where users drop off, or whether a change helped. Analytics turns product decisions from opinion into **data**: funnels reveal drop-offs, retention shows stickiness, A/B metrics validate changes. Done with a clear taxonomy + privacy discipline, it's a reliable decision tool; done ad hoc, it's noisy, unanalyzable, and a compliance risk.

## Real-world analogy

Analytics is a **store's foot-traffic + checkout study**: you note where shoppers **enter, browse, add to cart, and pay** (events/funnel), how many **come back** (retention), and which displays convert (custom metrics) — to **rearrange the store** based on evidence, not hunches. But you **don't record identities** (privacy), and you use a **consistent tally sheet** (taxonomy) so the numbers are comparable, and you **ask consent** before tracking.

## Internal Working

```mermaid
flowchart TD
    Actions[key user actions + business outcomes] --> Events[log events: name + params + user properties]
    Events --> Taxonomy[deliberate taxonomy: consistent names/params]
    Events --> Backend[analytics backend: Firebase Analytics / Amplitude / etc.]
    Backend --> Funnel[funnels (step conversion) + retention + custom metrics]
    Funnel --> Decisions[product decisions / A/B validation]
    Privacy[consent + no PII + ATT/GDPR + opt-out] --> Events
    Interface[Analytics interface (swappable/testable)] --> Backend
```

- **Events + parameters + user properties**:
  - **Events**: discrete user/business actions (`screen_view`, `search`, `add_to_cart`, `checkout_start`, `purchase`, `signup`). Each has **parameters** (`item_id`, `value`, `method`) for slicing.
  - **User properties**: durable attributes for segmentation (`plan: pro`, `locale`, `signup_cohort`) — **not PII**.
  - Some events are **auto-collected** (screen views, session start) by SDKs; you add **custom** events for what matters.
- **Event taxonomy (the discipline)**: define a **consistent, documented** naming/parameter scheme **before** instrumenting (snake_case names, standard params, an event dictionary). Ad hoc/inconsistent events (`AddCart` vs `add_to_cart` vs `cart_add`) are **unanalyzable**. Keep it **minimal + meaningful** — instrument **key actions + outcomes**, not every tap (noise + cost + privacy risk).
- **Analysis**:
  - **Funnels**: ordered steps (view → add_to_cart → checkout → purchase) showing **conversion + drop-off** per step — the core product insight.
  - **Retention**: do users **come back** (D1/D7/D30)? Cohorts by signup date/feature.
  - **Custom metrics/dashboards**: business KPIs (activation rate, feature adoption, revenue events).
  - **A/B/experiments**: measure whether a change moves the metric (via Firebase Remote Config/experiments or a dedicated tool).
- **Privacy/consent (non-negotiable)** ([Module 37](../37%20Security/README.md)/[Module 39](../39%20Logging/README.md)):
  - **No PII** in events/properties (no emails/names/precise location); use **opaque ids**; hash where correlation is needed.
  - **Consent**: honor **ATT (iOS tracking prompt)**, **GDPR/CCPA** consent (opt-in/opt-out), and platform data-safety declarations (must match — [Module 51](../51%20Deployment/README.md)). Provide an **opt-out**.
  - **Data minimization**: collect only what informs decisions.
- **Abstraction (swappable/testable)**: put analytics behind an **`Analytics` interface** (`logEvent(name, params)`, `setUserProperty`) with the vendor SDK as one impl — so you can **swap tools**, **fake in tests**, and **centralize redaction/consent gating**. App code calls the interface, not the SDK directly ([Module 39](../39%20Logging/README.md) facade pattern).
- **Analytics ≠ health monitoring**: analytics = **product usage/learning** (what/why users do); crash/perf = **health**. Both are pillars but answer different questions — don't conflate (or over-collect).
- **Tools**: **Firebase Analytics** (free, Flutter-integrated, funnels/retention, ties to Crashlytics/Remote Config), **Amplitude/Mixpanel** (deeper product analytics), backend event pipelines. Wire behind the interface.

## Memory Representation

Not app state — an **event stream + user-property store** in the analytics backend, aggregated into funnels/retention/metrics. On-device: a small batched queue of events (async upload); consent flags gate emission. The event **taxonomy** is a documented dictionary.

## Compiler Behavior

Analytics is normal code + SDK; the `Analytics` interface lets the compiler enforce dependency on the abstraction (swappable/fake-able).

## Runtime Behavior

Events are queued + uploaded **async/batched** (low overhead); consent gating drops events when not permitted; the backend aggregates into funnels/retention (often with reporting latency — not real-time).

## Flutter Engine Behavior

Screen-view auto-collection may hook navigation/route observers; otherwise analytics is app-level.

## Dart VM Behavior

Not applicable beyond batching being off the critical path.

## Examples

```dart
// Analytics behind an interface (swappable, testable, consent-gated, redacted)
abstract class Analytics {
  Future<void> logEvent(String name, [Map<String, Object?> params = const {}]);
  Future<void> setUserProperty(String key, String value);
}

class FirebaseAnalyticsImpl implements Analytics {
  final FirebaseAnalytics _fa; final Consent _consent;
  FirebaseAnalyticsImpl(this._fa, this._consent);
  @override
  Future<void> logEvent(String name, [Map<String, Object?> params = const {}]) async {
    if (!_consent.analyticsAllowed) return;               // consent gate
    await _fa.logEvent(name: name, parameters: _redact(params).cast()); // no PII
  }
  @override
  Future<void> setUserProperty(String k, String v) =>
      _consent.analyticsAllowed ? _fa.setUserProperty(name: k, value: v) : Future.value();
}

// Deliberate taxonomy — consistent names/params for a funnel
analytics.logEvent('view_item', {'item_id': id, 'category': cat});
analytics.logEvent('add_to_cart', {'item_id': id, 'value': priceCents});
analytics.logEvent('checkout_start', {'cart_size': n});
analytics.logEvent('purchase', {'value': totalCents, 'currency': 'USD'});  // business outcome
// -> funnel: view_item -> add_to_cart -> checkout_start -> purchase (drop-off per step)
```

```text
Event dictionary (documented taxonomy — snake_case, standard params):
  view_item {item_id, category}
  add_to_cart {item_id, value}
  checkout_start {cart_size}
  purchase {value, currency}         # business outcome
  User properties: plan (free|pro), locale, signup_cohort   (NO PII)
```

## Diagrams

```mermaid
flowchart LR
    Action[key action/outcome] --> IF[Analytics interface (consent-gated, redacted)]
    IF --> Vendor[analytics backend]
    Vendor --> Funnels[funnels + retention + custom metrics]
    Funnels --> Decide[product decisions / A-B validation]
```

## Common Mistakes

| Mistake | Why it's wrong | Fix |
|---------|---------------|-----|
| Ad hoc/inconsistent event names | Unanalyzable data | Deliberate documented taxonomy (snake_case, standard params) |
| Logging everything | Noise + cost + privacy risk | Instrument key actions + outcomes only |
| PII in events/properties | Privacy/compliance breach | Opaque ids; no PII; redact |
| Ignoring consent/ATT/GDPR | Illegal tracking / rejection | Consent-gate; honor ATT/GDPR; opt-out |
| Calling the SDK directly everywhere | Not swappable/testable | `Analytics` interface abstraction |
| Conflating analytics with health monitoring | Wrong tool/questions | Analytics = usage; crashes/perf = health |
| Never acting on funnels | Data without decisions | Close the loop: analyze → decide/experiment |
| Mismatched data-safety declarations | Store rejection/removal | Declarations match collected events |

## Best Practices

- Define a **deliberate, documented event taxonomy** (consistent names/params, an event dictionary) and instrument **key actions + business outcomes** — minimal + meaningful, not everything.
- Analyze via **funnels** (conversion/drop-off), **retention**, and **custom metrics**; **close the loop** (decisions/experiments), not just dashboards.
- Enforce **privacy/consent**: **no PII** (opaque ids), honor **ATT/GDPR/CCPA** (opt-in/opt-out), **data-minimize**, and match **store data-safety declarations**.
- Keep analytics **behind an interface** (swappable, testable, centralized consent/redaction); treat analytics (usage) as **distinct from health monitoring**.

## Performance

Analytics is low-overhead: events are batched + async, consent-gated, and sampled if high-volume — must not tax CPU/battery/data. Backend reporting has latency (not real-time). The cost of getting it wrong is privacy/compliance (leaked PII, no consent) more than performance.

## Advantages / Disadvantages

- **+** Data-driven product decisions (funnels/retention/experiments), feature-adoption insight, swappable/testable (interface), privacy-respecting.
- **−** Taxonomy discipline + upkeep, privacy/consent complexity (ATT/GDPR), backend cost, easy to over-collect (noise/risk), reporting latency.

## Interview Questions

1. **🟢 What does analytics measure, vs crash/perf monitoring?** — Analytics = product usage/behavior (what/why users do: events/funnels/retention) for decisions; crash/perf = app health (stability/performance).
2. **🟢 Why is an event taxonomy important?** — Consistent, documented names/params make data analyzable; ad hoc events (`AddCart` vs `add_to_cart`) can't be aggregated meaningfully.
3. **🟡 What is a funnel, and why is it the core insight?** — An ordered sequence of steps (view→cart→checkout→purchase) showing conversion + drop-off per step, revealing where users abandon.
4. **🟡 How do you handle privacy/consent in analytics?** — No PII (opaque ids), honor ATT/GDPR/CCPA (opt-in/opt-out), data-minimize, match store data-safety declarations; consent-gate emission.
5. **🟡 Why put analytics behind an interface?** — Swappability (change vendors), testability (fake), and a single place for consent gating + redaction — app code depends on the abstraction.
6. **🔴 What should you instrument, and what not?** — Key user actions + business outcomes (meaningful, minimal); not every tap (noise + cost + privacy risk).
7. **🔴 How do you avoid analytics being wasted?** — Close the loop: analyze funnels/retention → make product decisions / run experiments; dashboards nobody acts on are wasted.

## Senior Engineer Tips

- Design the event taxonomy + dictionary before instrumenting and enforce it in review; inconsistent event names are the #1 reason analytics data is unusable later.
- Route all analytics through an interface that gates on consent and redacts, so PII can't leak and you can swap Firebase↔Amplitude without touching features.
- Instrument outcomes + funnel steps that map to decisions, and actually review them; a wall of vanity events you never analyze is cost + privacy risk with no payoff.

## Architect Perspective

Analytics is the product-learning pillar of observability: a deliberate event taxonomy feeding funnels/retention/custom metrics that drive decisions, kept privacy-safe and behind a swappable interface. Distinct from health monitoring (crashes/perf), it answers "what/why users do" and closes the product feedback loop (measure → decide → experiment). Architecturally it's the same discipline as logging — an abstraction, consent/redaction centralized, minimal + meaningful — applied to behavior rather than diagnostics ([monitoring_fundamentals.md](monitoring_fundamentals.md), [Module 39](../39%20Logging/README.md), [Module 37](../37%20Security/README.md)).

## Summary

- Analytics logs deliberate events (taxonomy) + user properties to analyze funnels/retention/custom metrics for product decisions — distinct from health monitoring.
- Instrument key actions + outcomes (minimal/meaningful); enforce privacy/consent (no PII, ATT/GDPR, opt-out, match data-safety); keep behind a swappable interface.
- Close the loop (analyze → decide/experiment); low-overhead (async/batched/consent-gated).

## Revision Notes

- Events (name + params) + user properties (opaque, no PII); auto + custom; deliberate documented taxonomy (snake_case, standard params, event dictionary); instrument key actions + business outcomes (minimal).
- Analyze: funnels (conversion/drop-off), retention (D1/D7/D30 cohorts), custom metrics/dashboards, A/B experiments (Remote Config). Analytics = usage (decisions), not health.
- Privacy: no PII, consent (ATT/GDPR/CCPA opt-in/out), data-minimize, match store data-safety; behind `Analytics` interface (swappable/testable/consent-gated/redacted); async/batched. Tools: Firebase Analytics/Amplitude/Mixpanel.

## Practice Questions

1. Why is a consistent event taxonomy essential?
2. How do privacy/consent constrain analytics, and how do you comply?
3. Why wrap analytics behind an interface?

## Coding Questions

1. Define an `Analytics` interface + a consent-gated, redacted vendor impl.
2. Instrument a purchase funnel with a consistent taxonomy.
3. Add a user property + a custom business-outcome event (PII-safe).

## Mini Project

**Product analytics (Flutter/monitoring):** For an e-commerce-ish flow, define an event taxonomy + dictionary (view_item → add_to_cart → checkout_start → purchase + user properties), instrument it behind an `Analytics` interface (consent-gated + redacted vendor impl, no PII), and describe the funnel/retention analysis + a resulting product decision/experiment. Ensure ATT/GDPR consent + data-safety alignment. Acceptance: deliberate taxonomy (consistent/documented); key actions + outcomes instrumented (minimal); behind a swappable/testable interface; consent-gated + PII-safe + data-safety-aligned; funnel + a data-driven decision; analytics distinguished from health monitoring.
