# Security, Error Handling & Logging — Interview Questions

> How production Flutter apps stay safe and stay observable: secure storage, transport security, code hardening, robust error handling, and disciplined logging. For depth see [37 Security](../37%20Security/README.md), [38 Error Handling](../38%20Error%20Handling/README.md), and [39 Logging](../39%20Logging/README.md).

This topic tests whether you treat a mobile app as an *untrusted client* running on a *hostile device* — someone can root the phone, MITM the network, and decompile your binary. Interviewers probe where you put secrets, how you protect tokens and traffic, how you fail gracefully, and whether your logs help you debug without leaking user data.

## 🟢 Basic

**1. Why shouldn't you store auth tokens (or any secret) in `SharedPreferences`?**
`SharedPreferences` is **plaintext** — on Android it's an unencrypted XML file in the app sandbox, on iOS a plist in `NSUserDefaults`. On a rooted/jailbroken device, or from a device backup, anyone can read it. Tokens, passwords, PII, and encryption keys belong in `flutter_secure_storage`, which is backed by the OS-provided hardware-backed secure store. `SharedPreferences` is fine for non-sensitive UI state (theme, onboarding-seen flag). See [37 Security](../37%20Security/README.md).

**2. What does `flutter_secure_storage` actually use under the hood?**
It delegates to the platform's native secure store: the **iOS Keychain** and the **Android Keystore** (with `EncryptedSharedPreferences` for the encrypted blob). Keys are managed by the OS and can be hardware-backed (Secure Enclave / TEE / StrongBox), so key material never leaves secure hardware. That's the point — you're not rolling your own crypto, you're leaning on OS primitives designed for exactly this.

```dart
const storage = FlutterSecureStorage();
await storage.write(key: 'refresh_token', value: token);
final token = await storage.read(key: 'refresh_token');
```

**3. Is data in the app sandbox already "secure" on modern phones?**
Only against *other apps* on a non-compromised device — app sandboxing isolates storage per app. It is **not** secure against a physically-possessed, rooted/jailbroken device, malware with root, or an unencrypted backup. Full-disk encryption (on by default) protects a powered-off/locked device, but once unlocked the sandbox files are readable to a privileged attacker. So "sandbox" ≠ "encrypted secret store" — sensitive data still needs the Keychain/Keystore.

**4. What is TLS and what does it protect against?**
TLS (HTTPS) encrypts data in transit and authenticates the server via its certificate chain, defending against eavesdropping and tampering (man-in-the-middle). Always use `https://`; never ship an app that talks plaintext HTTP. On Android, cleartext traffic is blocked by default (API 28+) via network security config; on iOS, App Transport Security (ATS) enforces TLS. TLS alone trusts *any* CA the device trusts — which is why high-security apps add certificate pinning on top.

**5. What is certificate pinning and why would you add it?**
Pinning means the app only trusts a **specific** certificate or public key (you embed its hash), rather than any cert signed by a trusted CA. It defends against a compromised/rogue CA and against users who install a custom root CA to MITM traffic (e.g. via Charles/mitmproxy or corporate proxies). You typically pin the leaf or intermediate public-key hash and validate it in an `HttpClient.badCertificateCallback` / Dio interceptor.

**6. What's the difference between an access token and a refresh token?**
An **access token** is short-lived (minutes) and sent with each API request to prove authorization; if it leaks, the blast radius is small. A **refresh token** is long-lived and used *only* to obtain new access tokens from the auth server — it's more sensitive, so it must live in secure storage and never be sent to normal API endpoints. This split limits exposure: access tokens fly over the wire constantly but expire fast; refresh tokens are stored carefully and used rarely. See [17 Authentication](../17%20Authentication/README.md).

**7. Should you ever put API keys or secrets in your Dart code or `.env` bundled with the app?**
No. Anything shipped in the app binary — Dart strings, `.env` assets, `--dart-define` values — is extractable by decompiling the APK/IPA. There is no such thing as a "secret" on the client. Truly secret keys (payment provider secrets, admin keys) must stay server-side; the app calls your backend, which holds them. Client "keys" that must ship (like a Firebase/Maps API key) should be *restricted* (by package name, SHA fingerprint, referrer) so a leaked key is useless elsewhere.

**8. What's the difference between an Error and an Exception in Dart?**
An **`Exception`** represents a condition you can reasonably anticipate and recover from (network failure, invalid input, file not found) — you catch and handle it. An **`Error`** represents a programming bug that shouldn't be caught in normal flow (`RangeError`, `StateError`, `TypeError`, failed `assert`) — you fix the code, not catch the symptom. The convention: throw `Exception` for recoverable runtime conditions, let `Error`s crash so you notice them. See [38 Error Handling](../38%20Error%20Handling/README.md).

**9. Walk through `try` / `on` / `catch` / `finally`.**
- `on SomeException` catches a **specific type** (preferred — you handle what you expect).
- `catch (e, st)` catches anything and gives you the object and **stack trace**.
- `finally` always runs (success or throw) — use it for cleanup like closing a stream or file.

```dart
try {
  await repo.fetch();
} on SocketException {
  showOffline();          // specific, expected
} on FormatException catch (e, st) {
  log.severe('bad payload', e, st);
} catch (e, st) {
  log.severe('unexpected', e, st);
  rethrow;                // don't swallow the unknown
} finally {
  hideSpinner();
}
```
Prefer `on Type` over a bare `catch`, and never swallow errors silently — at minimum log and `rethrow`.

**10. Why is `catch (e) {}` (an empty catch) a code smell?**
It **silently swallows** failures — the app carries on in an inconsistent state and you get no crash report, no log, no signal that anything went wrong. These "silent failures" are the hardest bugs to diagnose in production. If you truly can ignore an error, add a comment explaining why and log it at `debug`/`fine`; otherwise handle it or `rethrow`.

**11. What are log levels and why do they matter?**
Log levels rank messages by severity — commonly `trace/finest`, `debug/fine`, `info`, `warning`, `severe/error`, `fatal`. They let you emit verbose detail in development but filter to `warning`+ in production, keeping noise and cost down while still capturing what matters. `print()` has no levels, no structure, and ships to release builds — use `dart:developer`'s `log()` or the `logging` / `logger` package instead. See [39 Logging](../39%20Logging/README.md).

**12. Why must you never log passwords, tokens, or PII?**
Logs get aggregated to remote services (Crashlytics, Sentry, cloud logging), stored, and viewed by many people — a token or personal data in a log is a data breach waiting to happen and often a compliance violation (GDPR/PCI). Redact or omit sensitive fields *before* they hit any sink. Treat logs as potentially public.

**13. What is obfuscation and how do you enable it in Flutter?**
Obfuscation renames Dart symbols (classes, methods) to meaningless identifiers so a decompiled binary is harder to read/reverse-engineer. Enable it at build time:
```bash
flutter build apk --obfuscate --split-debug-info=build/symbols
```
`--split-debug-info` extracts a symbol map so you can later **de-obfuscate** crash stack traces. Note it raises the bar for casual reverse-engineering; it is **not** encryption and doesn't hide strings/secrets — a determined attacker still gets through.

## 🟡 Intermediate

**14. Where exactly should the access token vs refresh token live, and how does rotation work?**
Keep the **refresh token in secure storage** (Keychain/Keystore) always. The **access token** can sit in memory for the session and optionally in secure storage for warm starts. On a 401, an interceptor uses the refresh token to fetch a new access token, retries the failed request, and — with **refresh-token rotation** — the server also issues a *new* refresh token and invalidates the old one. Rotation limits the value of a stolen refresh token: reuse of an old one signals theft and lets the server revoke the whole family. Guard the refresh flow with a mutex so concurrent 401s trigger only one refresh.

**15. What are the risks and operational costs of certificate pinning?**
The big one is **bricking your app on cert rotation**: when the server's cert/key changes and the app still pins the old one, every request fails until users update — you can't fix it server-side. Mitigations: pin the **public key** (survives cert renewal if the key is reused) or the intermediate CA, pin **multiple** keys (current + next/backup), and ship pins you can update via a controlled release. Pinning also complicates your own debugging/proxying. It's a real security win against MITM but demands rotation discipline, so reserve it for high-value apps (banking, health).

**16. Give a concrete example of PII redaction in a logging pipeline.**
Scrub or mask fields before they reach a sink, ideally centrally in an interceptor/formatter so no call site can forget:
```dart
String redact(Map<String, dynamic> json) {
  const secret = {'password', 'token', 'authorization', 'ssn', 'email'};
  final safe = {
    for (final e in json.entries)
      e.key: secret.contains(e.key.toLowerCase()) ? '***' : e.value,
  };
  return jsonEncode(safe);
}
```
Also strip `Authorization` headers from logged requests, mask emails/phones (`a***@x.com`), and never log full request/response bodies of auth endpoints. Redaction at the boundary beats trusting every developer to remember.

**17. Result/Either vs throwing exceptions — when do you use each?**
Throwing is idiomatic Dart and fine for truly exceptional/unexpected conditions. A **`Result`/`Either<Failure, Success>`** (via `dartz`, `fpdart`, or a sealed class) makes failure part of the **return type** — the compiler forces the caller to handle both branches, which is great for *expected* domain failures (validation, "user not found", offline) crossing layer boundaries in Clean Architecture.

```dart
sealed class Result<T> {}
class Ok<T> extends Result<T> { final T value; Ok(this.value); }
class Err<T> extends Result<T> { final Failure failure; Err(this.failure); }
```
Rule of thumb: **exceptions for the exceptional, Result for expected failures** you model as data. Mixing both everywhere just adds noise — pick a convention per layer. See [40 Clean Architecture](../40%20Clean%20Architecture/README.md).

**18. How do you write and use a custom exception well?**
Model a specific failure with enough context to handle it, and implement `toString()` for logs:
```dart
class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}
```
Implement `Exception` (not extend it), keep fields immutable, and make types specific enough that callers can `on ApiException catch` and branch on `statusCode`. Convert low-level errors (`DioException`, `SocketException`) into your domain exceptions at the data-layer boundary so upper layers don't depend on transport details.

**19. What global error handlers exist in Flutter, and what does each catch?**

| Handler | Catches |
|---|---|
| `FlutterError.onError` | Errors **inside the Flutter framework** (build/layout/paint), i.e. widget errors |
| `PlatformDispatcher.instance.onError` | Uncaught **async** errors outside a zone; returns `bool` (handled?) |
| `runZonedGuarded` | Uncaught errors (sync + async) in the **zone** wrapping your app |

A robust setup forwards framework errors into your zone/reporter and reports everything to Crashlytics/Sentry:
```dart
void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      reporter.recordFlutterError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      reporter.recordError(error, stack);
      return true;
    };
    runApp(const MyApp());
  }, (error, stack) => reporter.recordError(error, stack));
}
```
Modern Crashlytics can wire the first two for you (`FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError`), but knowing what each layer covers is the interview signal.

**20. What is an "error boundary" in Flutter and how do you build one?**
Flutter has no React-style error boundary widget, but you get two hooks. `ErrorWidget.builder` lets you replace the ugly red error screen with a friendly fallback in release. For *async/state* errors, catch them in your state layer and render an error state. For build-time isolation you can wrap a subtree and use `ErrorWidget.builder` globally:
```dart
ErrorWidget.builder = (details) => const FriendlyErrorScreen();
```
The pattern is: contain the failure to the smallest UI region, show a recoverable fallback (retry button), and report the error — don't let one widget's exception blank the whole app.

**21. Structured logging vs plain string logs — what's the difference and why care?**
Plain logs are unsearchable text (`"user 42 failed login"`). **Structured logs** emit machine-parseable records — typically JSON with consistent fields (`level`, `timestamp`, `event`, `userId`, `traceId`) — so a log platform can index, filter, aggregate, and alert on them. In production you can then query "all `severe` events for `traceId=abc` in the last hour" instead of grepping. Attach a correlation/trace id to tie a user action across screens, network calls, and the backend together.

**22. What's the difference between logging and observability?**
**Logging** is one signal — discrete event records. **Observability** is the broader ability to understand *why* a system behaves as it does from its outputs, built on three pillars: **logs** (what happened), **metrics** (aggregate numbers over time — crash-free rate, p95 latency), and **traces** (the path of one request across components). Crashlytics gives you crash metrics; Sentry adds performance traces and breadcrumbs; Firebase Performance adds metrics. Interviewers want to hear that logs alone don't tell you the health of the system. See [52 Monitoring](../52%20Monitoring/README.md).

**23. Crashlytics vs Sentry — how do you choose?**

| | Crashlytics | Sentry |
|---|---|---|
| Focus | Crash reporting (Firebase) | Errors + performance + tracing |
| Cost | Free | Free tier, paid scaling |
| Ecosystem | Deep Firebase/Google integration | Platform-agnostic, backend + frontend |
| Breadcrumbs/context | Custom keys, logs | Rich breadcrumbs, releases, traces |

Both capture uncaught errors with de-obfuscated stack traces (upload your symbol files). Crashlytics is the default if you're already on Firebase; Sentry when you want unified error+performance across mobile *and* your backend. Either way, upload `--split-debug-info` symbols so obfuscated traces are readable.

**24. What is root/jailbreak detection good for, and what are its limits?**
It flags a device where the OS security model is compromised (attacker can read your Keychain/Keystore, hook functions, MITM freely) so you can degrade gracefully — warn, block high-risk actions, or refuse to run (common in banking). The hard limit: it's a **cat-and-mouse** check running *on* the very device it's trying to assess, so a rooted device can spoof the check (Magisk Hide, Frida). Treat it as **defense-in-depth / risk signaling**, never as a security guarantee — the real protection is server-side validation and not trusting the client.

**25. What is App Check / Play Integrity and what problem do they solve?**
They provide **attestation** that a request comes from a genuine, untampered instance of *your* app on a genuine device — not a script, emulator farm, or repackaged clone hitting your backend. **Play Integrity** (Android) and **App Attest / DeviceCheck** (iOS), surfaced through **Firebase App Check**, mint a token your backend verifies before serving sensitive APIs. Because the attestation is validated **server-side** by Google/Apple, it resists the client-side spoofing that defeats root detection. It reduces abuse/bot traffic but isn't user auth — it attests the *app*, not the *user*.

## 🔴 Advanced

**26. Design a secure token lifecycle for a Flutter app from login to logout.**
- **Login**: backend returns short-lived access token + long-lived refresh token. Store refresh (and optionally access) in `flutter_secure_storage`; keep access in memory.
- **Requests**: an interceptor attaches the access token. On **401**, a single-flight (mutex-guarded) refresh exchanges the refresh token for a new pair (**rotation**), updates secure storage, and retries queued requests.
- **Reuse detection**: server tracks refresh-token families; a replayed old token revokes the family (theft response).
- **Logout**: call server revoke endpoint, then wipe secure storage and in-memory state; clear any cached user data.
- **Hardening**: TLS + optional pinning, App Check on the refresh endpoint, biometric gate before releasing the token on app resume for sensitive apps.
The theme: minimize token lifetime and exposure, store the sensitive one in hardware-backed storage, and make theft detectable and revocable.

**27. Why does `runZonedGuarded` need `WidgetsFlutterBinding.ensureInitialized()` inside the same zone, and what's the common bug?**
The binding must be initialized in the **same zone** that runs the app, because Flutter asserts that the zone used to schedule frames is the zone the binding was created in. If you call `ensureInitialized()` outside `runZonedGuarded` (or in a different zone) you get a "Zone mismatch" assertion or silently lose error capture. The fix is to put *both* `ensureInitialized()` and `runApp()` inside the same `runZonedGuarded` callback. With `PlatformDispatcher.onError` now available, many teams skip the zone entirely for global capture — but if you use a zone, keep initialization inside it.

**28. Uncaught async error handling changed across Flutter versions — explain the current recommended setup.**
Historically `runZonedGuarded` was the only way to catch uncaught *async* errors, because `FlutterError.onError` only covers the framework's synchronous build/layout/paint. Since Flutter 3.3, **`PlatformDispatcher.instance.onError`** catches uncaught async errors at the engine level with lower overhead and without a custom zone. The current recommendation: set `FlutterError.onError` for framework errors and `PlatformDispatcher.instance.onError` for everything else, reserving `runZonedGuarded` for cases where you must also capture errors from third-party code that reports into the current zone. Route all three to one reporter.

**29. How do you make obfuscated production crashes debuggable end to end?**
Build with `--obfuscate --split-debug-info=<dir>`, which produces a per-build symbol map keyed by an app-id/build-id. Upload those symbols to your crash reporter (Crashlytics: the Flutter symbol upload / Gradle plugin; Sentry: `sentry-cli debug-files upload`) as part of CI. At runtime the device reports **obfuscated** frames; the backend **symbolicates** them using the matching build's symbols. Critical rule: symbol files are **per build** — a mismatched or missing upload yields unreadable traces, so wire the upload into your release pipeline, not a manual step. See [50 CI CD](../50%20CI%20CD/README.md).

**30. What do you actually implement to cover the OWASP Mobile Top 10 in a Flutter app?**
A pragmatic mapping:
- **M1 Improper credential/platform usage** → correct permissions, no misuse of platform APIs, biometrics done right.
- **M2 Inadequate supply chain** → audit/pin dependencies, verify plugin provenance.
- **M3 Insecure auth/authz** → short-lived tokens, server-side authz, refresh rotation.
- **M4 Insufficient input/output validation** → validate server-side; sanitize deep links/WebView input.
- **M5 Insecure communication** → TLS everywhere, optional pinning, no cleartext.
- **M6 Inadequate privacy** → minimize + redact PII, secure storage, clear on logout.
- **M7 Insufficient binary protection** → `--obfuscate`, integrity/attestation checks.
- **M8 Security misconfiguration** → no debug flags/verbose logs in release, locked-down network config.
- **M9 Insecure data storage** → Keychain/Keystore for secrets, never `SharedPreferences`.
- **M10 Insufficient cryptography** → use vetted libraries/OS crypto, never hand-rolled or hardcoded keys.
The senior point: it's a checklist to *reason with*, and the recurring theme is "never trust the client — enforce on the server."

**31. A screenshot of your app in the recent-apps switcher leaks a token/PII. How do you fix it, and what class of problem is this?**
This is **insecure data exposure via the OS**, not your storage. Prevent the OS from snapshotting sensitive screens: on Android set `FLAG_SECURE` on the window (blocks screenshots and hides the app in the recents thumbnail); on iOS overlay a blur/splash on `didEnterBackground` and remove it on resume. Also consider hiding sensitive fields when the app is backgrounded and clearing the clipboard. It's a reminder that "secure storage" doesn't cover *rendered* data — the screen, clipboard, backups, and logs are all exfiltration surfaces.

**32. How do you prevent sensitive data from leaking through logs in a large team, structurally?**
Don't rely on discipline — build guardrails:
- **Centralize** logging behind one facade; forbid raw `print`/`debugPrint` via a lint rule (custom `analysis_options.yaml` rule or `avoid_print`).
- **Redact at the sink**: a single formatter masks known-sensitive keys and headers so no call site can leak them.
- **Strip in release**: gate verbose/debug logs behind `kDebugMode`; ship only `warning`+ to remote.
- **Type your log events** (structured) so you log fields deliberately, not whole objects (`toString()` of a User model can dump everything).
- **Review + test**: a redaction unit test on the formatter, and PR review of new log statements.
The structural fix is making the *safe* path the *only* easy path.

**33. Your app must run on rooted devices (you can't just block them) but protect a payment flow. What's your layered strategy?**
Assume the device is compromised and push trust to the server:
- **Attestation**: require Play Integrity / App Attest tokens (via App Check) on payment endpoints — validated server-side.
- **Don't trust client checks**: root detection only *signals risk* (step-up auth, extra verification), never gates security alone.
- **Minimize on-device secrets**: keep payment secrets server-side; the client holds only short-lived, scoped tokens in secure storage.
- **Server-side enforcement**: authorize every payment on the backend with idempotency keys and anomaly detection; the client can't be the source of truth.
- **Transport**: TLS + pinning to stop MITM of the payment call.
- **Sensitive UI hardening**: `FLAG_SECURE`, biometric confirmation, no PANs in logs.
The core answer interviewers want: *the client is untrusted; security is enforced and verified on the server.* See [31 Payments](../31%20Payments/README.md).

**34. How do you handle errors across Clean Architecture layers so the UI shows meaningful messages without leaking internals?**
Map errors at each boundary. The **data layer** catches transport errors (`DioException`, `SocketException`, platform exceptions) and converts them into domain **`Failure`** types or domain exceptions — the domain never imports Dio. The **domain/use-case layer** returns `Either<Failure, T>` (or throws domain exceptions). The **presentation layer** maps each `Failure` to a user-facing message and state (offline banner, retry, "session expired → re-login"), and reports the original error + stack to Crashlytics. This keeps stack traces and internal details *out* of the UI while preserving them for observability, and gives users actionable, non-leaky messages. See [40 Clean Architecture](../40%20Clean%20Architecture/README.md).

**35. `--dart-define` vs a bundled `.env` file for configuration and "secrets" — compare.**
`--dart-define`/`--dart-define-from-file` injects values at **compile time** as constants (tree-shakeable, usable in `const`), whereas a `.env` asset is read at **runtime** and shipped as a bundled file. `.env` files are trivially extractable from the asset bundle; `--dart-define` values are compiled in but still **recoverable from the binary** (strings/decompilation). So for *config* (base URLs, feature flags, environment name) either works and `--dart-define` is cleaner and per-flavor; for actual **secrets, neither is safe** — the only correct place is the server. The interview trap is claiming `--dart-define` "hides" secrets: it doesn't.

## ⚡ Rapid-fire (one-liners)

| Question | Answer |
|---|---|
| Where do refresh tokens go? | `flutter_secure_storage` (Keychain/Keystore), never `SharedPreferences`. |
| `SharedPreferences` encrypted? | No — plaintext; UI state only. |
| Access token vs refresh token? | Short-lived, sent every request vs long-lived, only refreshes access. |
| Why is a client secret impossible? | Anything in the binary is extractable — keep it server-side. |
| Command to obfuscate? | `flutter build apk --obfuscate --split-debug-info=<dir>`. |
| Does obfuscation encrypt/hide strings? | No — just renames symbols; not a secret store. |
| Certificate pinning risk? | Bricks the app on cert rotation if pins aren't updated. |
| `Error` vs `Exception`? | Bug you fix vs recoverable condition you catch. |
| Catch a specific type? | `on ExceptionType catch (e, st)`. |
| What always runs? | `finally`. |
| Catch uncaught async errors? | `PlatformDispatcher.instance.onError` (or `runZonedGuarded`). |
| Catch framework build errors? | `FlutterError.onError`. |
| Result/Either vs throw? | Expected failures as data vs the truly exceptional. |
| Never log what? | Tokens, passwords, PII. |
| Structured logging? | Machine-parseable JSON records with consistent fields. |
| Three pillars of observability? | Logs, metrics, traces. |
| Root detection guarantee? | No — it's a risk signal, spoofable on-device. |
| App Check / Play Integrity verifies? | That the request is from a genuine app instance — server-side. |
| Hide sensitive screen in recents? | `FLAG_SECURE` (Android) / blur overlay (iOS). |

## Follow-up drills

1. **Design** the full network interceptor stack for a banking app: token attach, single-flight refresh with rotation, cert pinning, App Check header, retry, and PII-safe logging.
2. **Debug this scenario**: production crashes show only obfuscated frames like `MidsizeA.b()`. Walk through why and fix the pipeline end to end.
3. **Optimize** a logging setup that's costing too much and leaking PII into Sentry — redesign levels, redaction, and remote sampling.
4. **Design** an error-handling contract across data/domain/presentation layers so the UI never shows a raw exception yet every error reaches Crashlytics with a trace id.
5. **Threat-model** a Flutter app against the OWASP Mobile Top 10 and rank which mitigations you'd ship first for a fintech MVP.
6. **Debug this scenario**: after adding `runZonedGuarded`, the app throws a "Zone mismatch" assertion at startup — diagnose and fix.
