# The `logger` Package & Setup

> The `logger` package gives you leveled logging with pluggable **filters** (which levels emit), **printers** (formatting — pretty for dev, compact/JSON for prod), and **outputs** (console, file, remote) — but the key architectural move is to **hide it behind your own logging abstraction** so the rest of the app depends on *your* interface, not the package, and behaves differently per environment (**pretty + verbose in dev, filtered + structured + no-op-or-remote in prod**). Never scatter `Logger()` instances everywhere; inject one facade.

## Introduction

This file covers configuring `logger` (filter/printer/output), the dev-vs-prod split, and — most importantly — wrapping it behind an abstraction injected via DI so logging is centralized, swappable, and environment-aware. It's the practical setup layer over the fundamentals ([logging_fundamentals.md](logging_fundamentals.md)).

## Why this concept exists

Apps need readable logs while developing and lean, structured, filtered logs in production — and they shouldn't be coupled to a specific library (you may swap it or add remote shipping). A configured `logger` behind a facade delivers both: rich dev output, controlled prod output, one injection point, and easy testing/swapping.

## Real-world analogy

`logger` is a **configurable PA system**: a **filter** decides which announcements are loud enough to broadcast (levels), a **printer** decides the wording/format (verbose backstage vs terse public), and **outputs** decide where it plays (backstage speakers vs recorded to tape/remote). Wrapping it behind your own **"announcements service"** means every department calls the same simple interface, and you can re-wire the PA (swap vendor, change format) without changing how departments make announcements.

## Problem Statement

Set up logging that's pretty and verbose in debug, filtered/structured (and remote-ready) in release, accessed through a single injected `AppLogger` interface (not raw `Logger()` calls), so you can swap implementations and test easily. You'll configure `logger` and wrap it behind a facade.

## Internal Working

```mermaid
flowchart TD
    App[app code] --> Facade[AppLogger interface (injected)]
    Facade --> Impl{environment}
    Impl -->|dev| DevLog[Logger: PrettyPrinter, level=debug, console]
    Impl -->|prod| ProdLog[Logger: level=info+, compact/JSON, remote/no-op]
    DevLog & ProdLog --> Parts[Filter (levels) + Printer (format) + Output (sink)]
```

- **`logger` anatomy**: a `Logger` composes a **`LogFilter`** (which levels pass — e.g., `DevelopmentFilter` vs `ProductionFilter`), a **`LogPrinter`** (formatting — `PrettyPrinter` with boxes/emoji/stack for dev; a compact/JSON printer for prod), and a **`LogOutput`** (where it goes — `ConsoleOutput`, file, or a custom remote output — [remote_logging_and_observability.md](remote_logging_and_observability.md)). Call `logger.d/i/w/e/f(...)` by level.
- **Dev config**: `PrettyPrinter` (readable, stack traces, colors), filter at **debug** — rich local diagnostics.
- **Prod config**: filter at **info/warning+**, a **compact/structured (JSON) printer**, output to a **remote sink** or a **no-op** (to strip noise) — lean, searchable, PII-safe ([production_logging_and_redaction.md](production_logging_and_redaction.md)).
- **The abstraction (crucial)**: define **your own `AppLogger` interface** (`debug/info/warn/error(event, fields, error, stack)`); implement it over `logger` (dev/prod variants). App code depends on `AppLogger`, **not** `logger` — so you can swap libraries, add redaction/remote, or use a fake in tests without touching call sites.
- **One instance via DI**: register the environment-appropriate `AppLogger` in your DI container ([Module 14](../14%20Dependency%20Injection/README.md)) and inject it — **don't** `new Logger()` all over.
- **Environment selection**: choose dev vs prod impl by build mode/flavor (`kReleaseMode`/flavor config); dev-only detail is stripped in release.
- **Structured fields**: have your facade accept an **event + fields map**, formatted for humans (dev) or JSON (prod) — consistent structure across environments.

## Memory Representation

One shared logger/facade instance (via DI). Filter/printer/output are small configured objects. Log records flow through printer → output; no accumulation unless a buffering output batches for remote.

## Compiler Behavior

`kReleaseMode`/flavor branches let dead dev-only config be tree-shaken; the facade indirection is free at runtime.

## Runtime Behavior

Below-threshold levels are filtered before formatting (cheap). Dev prints pretty to console; prod emits compact/JSON to sink/remote/no-op. Swapping impls changes behavior app-wide without call-site changes.

## Flutter Engine Behavior

Console output shows in the IDE/DevTools; custom outputs (file/remote) bypass the console.

## Dart VM Behavior

Not applicable beyond tree-shaking dev branches.

## Examples

```dart
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

// Your OWN abstraction — app depends on this, not on `logger`
abstract class AppLogger {
  void debug(String event, [Map<String, Object?>? fields]);
  void info(String event, [Map<String, Object?>? fields]);
  void warn(String event, [Map<String, Object?>? fields]);
  void error(String event, {Object? error, StackTrace? stack, Map<String, Object?>? fields});
}

// Implementation over the `logger` package, configured per environment
class LoggerAppLogger implements AppLogger {
  final Logger _logger;
  LoggerAppLogger._(this._logger);

  factory LoggerAppLogger.dev() => LoggerAppLogger._(Logger(
        filter: DevelopmentFilter(),                 // debug+ in dev
        printer: PrettyPrinter(methodCount: 2),      // readable
        output: ConsoleOutput(),
      ));

  factory LoggerAppLogger.prod({required LogOutput remote}) => LoggerAppLogger._(Logger(
        filter: ProductionFilter(),                  // info+ in prod
        printer: _JsonPrinter(),                     // compact/structured
        output: remote,                              // remote sink (or no-op)
      ));

  @override void debug(String e, [Map<String, Object?>? f]) => _logger.d(_fmt(e, f));
  @override void info(String e, [Map<String, Object?>? f]) => _logger.i(_fmt(e, f));
  @override void warn(String e, [Map<String, Object?>? f]) => _logger.w(_fmt(e, f));
  @override void error(String e, {Object? error, StackTrace? stack, Map<String, Object?>? f}) =>
      _logger.e(_fmt(e, f), error: error, stackTrace: stack);
  Object _fmt(String e, Map<String, Object?>? f) => {'event': e, ...?f}; // structured
}

// DI: register the right impl by environment; inject AppLogger everywhere
// getIt.registerSingleton<AppLogger>(kReleaseMode
//     ? LoggerAppLogger.prod(remote: RemoteLogOutput())
//     : LoggerAppLogger.dev());
```

## Diagrams

```mermaid
flowchart LR
    Code[app code] --> IF[AppLogger interface]
    IF -->|dev impl| Pretty[PrettyPrinter + console + debug]
    IF -->|prod impl| Json[JSON printer + remote/no-op + info+]
    IF -->|test| Fake[FakeLogger (asserts)]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| `new Logger()` scattered everywhere | Coupled, inconsistent, untestable | One `AppLogger` facade via DI |
| Same config dev + prod | Noisy/leaky or unreadable | Environment-specific filter/printer/output |
| App depends on `logger` directly | Can't swap/redact/remote centrally | Depend on your interface |
| PrettyPrinter in prod | Verbose/perf, not structured | Compact/JSON prod printer |
| No prod threshold | Log spam/cost | Filter at info/warning+ |
| Unstructured facade | Not searchable | Event + fields map |
| Can't fake in tests | Coupled to real logger | Interface → fake impl |

## Best Practices

- Depend on **your own `AppLogger` interface**, not the package; implement it over `logger` with **environment-specific** filter/printer/output.
- **Dev**: PrettyPrinter, debug threshold, console. **Prod**: compact/JSON printer, info/warning+ threshold, remote sink or no-op.
- Register **one instance via DI** and inject it (no scattered `Logger()`); select dev/prod impl by **build mode/flavor**.
- Make the facade **structured** (event + fields), enabling **swap/redaction/remote/testing** without touching call sites.

## Performance

Filtering below threshold before formatting keeps prod cheap; PrettyPrinter is dev-only. The facade adds negligible indirection. Remote/buffering outputs should batch (async) so logging never blocks — covered in [remote_logging_and_observability.md](remote_logging_and_observability.md).

## Advantages / Disadvantages

- **+** Readable dev + lean prod logs, one injection point, swappable/testable, structured, environment-aware.
- **−** Setup + facade boilerplate, must pick/maintain config per environment, discipline to route all logging through the facade.

## Interview Questions

1. **🟢 What three parts make up a `logger` `Logger`?** — A filter (which levels emit), a printer (formatting), and an output (sink) — configured per environment.
2. **🟢 Why wrap `logger` behind your own interface?** — So the app depends on your abstraction (swap library, add redaction/remote, fake in tests) rather than the package, from one place.
3. **🟡 How should dev vs prod logging differ?** — Dev: PrettyPrinter + debug threshold + console; prod: compact/JSON + info/warning+ threshold + remote/no-op.
4. **🟡 Why not `new Logger()` throughout the app?** — It's coupled, inconsistent, and untestable; register one `AppLogger` via DI and inject it.
5. **🟡 How do you select the environment config?** — By build mode/flavor (`kReleaseMode`/flavor), branching to dev/prod impls (dev config tree-shaken in release).
6. **🔴 How does the facade enable redaction/remote later?** — All logging flows through one implementation, so you add redaction/remote output there without touching call sites.
7. **🔴 How do you test logging?** — Inject a fake `AppLogger` and assert on captured events/levels — impossible if code calls `Logger()` directly.

## Senior Engineer Tips

- Define the `AppLogger` interface first and treat `logger` as an implementation detail; this one indirection is what lets you add redaction, remote shipping, and tests later without a refactor.
- Configure prod deliberately (threshold + structured printer + remote/no-op) rather than shipping dev's PrettyPrinter — the default dev config is a perf/noise/leak liability in release.
- Register one logger in DI and inject it everywhere; scattered `Logger()` instances are the reason logging config drifts and can't be centrally redacted.

## Architect Perspective

The facade + environment config is the seam that makes logging manageable: app code speaks one structured interface, while the implementation varies by environment and can grow redaction, sampling, and remote shipping without ripple. Injected via DI and swappable for a fake, it's testable and future-proof — the foundation the production and remote layers extend ([production_logging_and_redaction.md](production_logging_and_redaction.md), [remote_logging_and_observability.md](remote_logging_and_observability.md), [Module 14](../14%20Dependency%20Injection/README.md)).

## Summary

- `logger` = filter (levels) + printer (format) + output (sink); configure dev (pretty/debug/console) vs prod (JSON/info+/remote or no-op).
- Depend on your own `AppLogger` interface (structured event+fields), inject one instance via DI, select impl by build mode/flavor.
- The facade enables swap/redaction/remote/testing without touching call sites.

## Revision Notes

- `Logger(filter, printer, output)`; `DevelopmentFilter`/`ProductionFilter`, `PrettyPrinter` (dev) vs compact/JSON (prod), `ConsoleOutput`/file/remote.
- Wrap in `AppLogger` interface (debug/info/warn/error, event+fields); one instance via DI; select by `kReleaseMode`/flavor.
- Dev: pretty/debug/console; prod: structured/info+/remote or no-op; facade enables redaction/remote/testing (fake) without call-site changes.

## Practice Questions

1. What do a `logger` filter, printer, and output each control?
2. Why depend on your own logging interface instead of the package?
3. How do dev and prod logger configs differ?

## Coding Questions

1. Define an `AppLogger` interface + a `logger`-backed impl.
2. Provide dev (pretty/console/debug) and prod (JSON/remote/info+) factories.
3. Register the right impl via DI by build mode and inject it.

## Mini Project

**Logging facade (Flutter):** Build an `AppLogger` interface (structured event + fields) implemented over the `logger` package with dev (PrettyPrinter/console/debug) and prod (JSON printer/remote-or-no-op/info+) configurations, selected by build mode and registered once via DI. Add a fake for tests. Acceptance: app depends on `AppLogger` (no direct `Logger()` calls); dev is pretty+verbose, prod is structured+filtered; one injected instance; environment-selected; fake logger enables tests.
