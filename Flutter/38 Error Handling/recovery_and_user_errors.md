# Recovery & User-Facing Errors

> Handling a failure isn't done until the app **recovers or communicates** gracefully: **retry with backoff** for transient failures (network blips, 503) — but only for **idempotent/safe** operations and with a cap; **degrade gracefully** (cached data, reduced features, offline mode) rather than blocking; and **map technical failures to clear, actionable user messages** ("You're offline — retry" not "SocketException"). The golden rules: **never leak raw exceptions/stack traces to users, never leave an infinite spinner, always offer a next step** (retry/back/support).

## Introduction

This file is the UX + resilience end of error handling: turning caught failures ([errors_vs_exceptions.md](errors_vs_exceptions.md), [result_and_either.md](result_and_either.md)) into recovery (retry/degrade) and clear messages. It covers retry/backoff, graceful degradation, error→message mapping, and error-state UI patterns.

## Why this concept exists

A failure the code "handles" but the user experiences as a frozen screen or cryptic text is still a bad experience. Transient failures often succeed on retry; missing data can fall back to a cache; and users need to understand what happened and what to do. Good recovery/UX turns inevitable failures into minor bumps instead of dead ends.

## Real-world analogy

A good waiter (the app) doesn't tell you "kitchen exception 500" — they say "the special's sold out, may I suggest the pasta?" (clear message + next step). If the kitchen is briefly slammed they **quietly retry** getting your order in (backoff retry); if an ingredient's out they **substitute** (degrade gracefully). They never just **vanish and leave you staring at an empty table** (infinite spinner).

## Problem Statement

For a data screen: retry a transient fetch failure automatically (capped, backoff) but not a duplicate-charge POST, fall back to cached data when offline, show "You're offline — Retry" (not `SocketException`) with a working retry button, and never leave a spinner forever. You'll implement retry/backoff, degradation, and error→message mapping + UI.

## Internal Working

```mermaid
flowchart TD
    Fail[failure] --> Transient{transient + safe to retry?}
    Transient -->|yes| Retry[retry with backoff (capped) — idempotent only]
    Transient -->|no| Degrade{can degrade?}
    Retry -->|still failing| Degrade
    Degrade -->|yes| Fallback[cached data / reduced features / offline]
    Degrade -->|no| Message[map -> clear user message + next step]
    Message --> UI[error state: message + retry/back, never infinite spinner]
```

- **Retry with backoff**: for **transient** failures (timeouts, 502/503, connection reset), retry a **capped** number of times with **exponential backoff + jitter** (avoid thundering herd). **Only retry idempotent/safe operations** (GET, or POSTs made idempotent via a key — [Module 31](../31%20Payments/README.md)); **never blindly retry** non-idempotent writes (double-charge/double-post). `dio` retry interceptors or a small helper.
- **Graceful degradation**: when the operation can't succeed, **fall back** — serve **cached/stale data** (with a "stale" indicator), disable just the broken feature (not the app), enter **offline mode** ([Module 19](../19%20Offline%20First/README.md)). Failure of one thing shouldn't break everything.
- **Error → message mapping**: translate **typed failures** ([result_and_either.md](result_and_either.md)) into **user-friendly, actionable** copy: offline → "You're offline. Check your connection and retry."; not-found → "This item is no longer available."; server → "Something went wrong on our side. Try again shortly." **Never** show `Exception`/stack traces/error codes as the primary message (a support code is fine, secondary).
- **Error-state UI**: every async view has **loading / data / empty / error** states; the **error state** shows the message + a **retry/back** action. **No infinite spinners** (time out → error), no dead ends. Use snackbars for transient/inline errors, full-screen for blocking ones, banners for degraded/offline.
- **Recovery hooks**: retry re-runs the fetch; on auth failure → refresh token / re-login; on validation → highlight the field. Preserve user input across retries.
- **Report while recovering**: still **log/report** the underlying failure ([Module 52](../52%20Monitoring/README.md)) even when you show a friendly message — the user's experience and your telemetry are separate concerns.

## Memory Representation

Retry state (attempt count, next delay) is transient. Cached fallback data lives in your cache ([Module 34](../34%20File%20Handling/README.md)/[Module 19](../19%20Offline%20First/README.md)). Error UI is driven by the state's error variant.

## Compiler Behavior

Not applicable.

## Runtime Behavior

Backoff spaces retries (growing delay + jitter); after the cap it surfaces an error state. Degradation swaps in cached data. The UI reflects loading→error/data; a timeout converts a hung request into a handled error.

## Flutter Engine Behavior

Not applicable.

## Dart VM Behavior

Not applicable.

## Examples

```dart
// Retry with exponential backoff + jitter — IDEMPOTENT operations only, capped
Future<T> retry<T>(Future<T> Function() op, {int maxAttempts = 3}) async {
  var attempt = 0;
  while (true) {
    try {
      return await op();
    } on TransientException {
      attempt++;
      if (attempt >= maxAttempts) rethrow;            // give up -> error state
      final delay = Duration(milliseconds: (200 * (1 << attempt)) + _jitter());
      await Future.delayed(delay);                    // backoff
    }
    // Non-transient / non-idempotent failures: do NOT retry here.
  }
}

// Map typed failures -> user-friendly, actionable messages (never raw exceptions)
String messageFor(AppFailure f) => switch (f) {
  NetworkFailure() => "You're offline. Check your connection and retry.",
  NotFoundFailure() => "This item is no longer available.",
  ServerFailure() => "Something went wrong on our side. Please try again shortly.",
  _ => "Something went wrong. Please try again.",
};
```

```dart
// Error-state UI: message + retry, graceful degradation, NO infinite spinner
switch (state) {
  Loading() => const CenteredSpinner(),
  Data(:final items) => ItemList(items, stale: state.fromCache), // degraded/stale banner
  Empty() => const EmptyState('Nothing here yet'),
  Error(:final failure) => ErrorView(
      message: messageFor(failure),
      onRetry: () => bloc.add(Retry()),            // actionable next step
    ),
};
```

## Diagrams

```mermaid
flowchart LR
    Transient[transient + idempotent] --> Backoff[retry w/ backoff (capped)]
    Backoff -->|fail| Degrade[cached/reduced/offline]
    Degrade -->|impossible| Msg[clear message + retry/back]
    Nonidem[non-idempotent write] -.no blind retry.-> Msg
```

## Common Mistakes

| Mistake | Why it's bad | Fix |
|---------|-------------|-----|
| Retrying non-idempotent writes | Double-charge/double-post | Retry only idempotent/keyed ops |
| Retry without cap/backoff | Hammering, battery, herd | Capped exponential backoff + jitter |
| Showing raw exceptions/stacks to users | Confusing/leaky | Map to friendly, actionable copy |
| Infinite spinner on failure | User stuck | Timeout → error state with retry |
| No degradation | One failure breaks everything | Cached fallback / offline / reduced features |
| Dead-end error (no action) | User can't proceed | Always offer retry/back/support |
| Not reporting while recovering | Blind telemetry | Log/report + show friendly message |

## Best Practices

- **Retry transient, idempotent** failures with **capped exponential backoff + jitter**; **never blindly retry** non-idempotent writes (use idempotency keys).
- **Degrade gracefully** (cached/stale data with an indicator, offline mode, disable only the broken feature) instead of blocking the whole app.
- **Map typed failures to clear, actionable messages** (never raw exceptions/stacks); show a **support code** secondarily if needed.
- Give every async view **loading/data/empty/error** states with a **retry/next-step** action — **no infinite spinners**; **report** the underlying failure while showing friendly UX.

## Performance

Backoff prevents retry storms (server + battery friendly); jitter avoids synchronized retries. Serving cache is faster than failing/blocking. Timeouts free hung requests. Good recovery improves both perceived performance and reliability.

## Advantages / Disadvantages

- **+** Transient failures auto-recover, app stays usable (degradation), users understand + can act, better retention, telemetry preserved.
- **−** Must classify transient/idempotent correctly, backoff/state-machine complexity, message-mapping upkeep, cache/degradation infra.

## Interview Questions

1. **🟢 When is it safe to retry, and how?** — For transient failures on idempotent/safe operations, with a capped exponential backoff + jitter — never blindly for non-idempotent writes.
2. **🟢 Why never show raw exceptions to users?** — They're confusing and can leak internals; map failures to clear, actionable messages (with an optional support code).
3. **🟡 What is graceful degradation?** — Falling back (cached/stale data, offline mode, disabling just the broken feature) so a failure doesn't block the whole app.
4. **🟡 Why is an infinite spinner a bug?** — It leaves users stuck; add timeouts and always resolve to a data/empty/error state with a next step.
5. **🟡 How do you retry safely for a payment/POST?** — Make it idempotent (idempotency key) so a retry can't double-charge; otherwise don't auto-retry.
6. **🔴 What UI states must an async view handle?** — Loading, data, empty, and error (with retry) — never just loading→data.
7. **🔴 Should you still report errors you recover from?** — Yes — user-facing recovery and telemetry are separate; log/report the underlying failure regardless.

## Senior Engineer Tips

- Classify failures as transient vs permanent and idempotent vs not before adding retries; a retry on a non-idempotent write is a money/data bug, not a resilience feature.
- Kill infinite spinners with timeouts and a mandatory error state + retry; "stuck loading" is the single most common user-reported failure.
- Keep a central error→message map so UX copy is consistent and no `toString()` of an exception ever reaches a user.

## Architect Perspective

Recovery/UX is where the error strategy pays off for users: typed failures ([result_and_either.md](result_and_either.md)) become retry/degradation decisions and clear messages, driven by explicit UI states, while the underlying failures still flow to monitoring. Centralizing retry policy, degradation, and error→message mapping (behind services/state) makes resilience consistent and testable — the user-facing complement to global capture ([global_error_handling.md](global_error_handling.md), [Module 19](../19%20Offline%20First/README.md), [Module 52](../52%20Monitoring/README.md)).

## Summary

- Retry transient, idempotent failures with capped backoff + jitter; never blindly retry non-idempotent writes.
- Degrade gracefully (cache/offline/reduced) and map typed failures to clear, actionable messages — never raw exceptions or infinite spinners.
- Every async view has loading/data/empty/error states with a next step; report underlying failures while showing friendly UX.

## Revision Notes

- Retry: transient + idempotent only, capped exponential backoff + jitter; non-idempotent → idempotency key or no auto-retry.
- Degrade: cached/stale (indicator), offline mode, disable only broken feature; error→message map (friendly + actionable, optional support code, never raw exception/stack).
- UI states: loading/data/empty/error + retry; no infinite spinner (timeouts); report underlying failure to monitoring while showing friendly UX.

## Practice Questions

1. Which failures should you retry, and how do you avoid a double-charge?
2. What does graceful degradation look like for an offline data screen?
3. Why is an infinite spinner considered an error-handling bug?

## Coding Questions

1. Implement capped exponential-backoff retry for idempotent ops only.
2. Build an error→message mapper over a sealed `Failure` hierarchy.
3. Render loading/data/empty/error states with a working retry.

## Mini Project

**Resilient data screen (Flutter):** For a fetch screen, implement capped exponential-backoff retry (idempotent GET only), graceful degradation to cached data (with a stale banner) when offline, a typed-failure→message mapper, and full loading/data/empty/error UI with a retry action — no infinite spinner, and report underlying failures to a (stub) monitor. Acceptance: transient failures auto-retry (backoff+jitter, capped); non-idempotent ops not blindly retried; offline degrades to cache; friendly actionable messages (no raw exceptions); all UI states + retry; no infinite spinner; failures reported.
