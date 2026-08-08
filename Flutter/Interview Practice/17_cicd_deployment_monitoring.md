# CI/CD, Deployment & Monitoring — Interview Questions

> How you build, sign, ship, and observe a Flutter app in production — from `flutter build` flags to store rollout to crash dashboards. For depth see the handbook modules [50 CI CD](../50%20CI%20CD/README.md), [51 Deployment](../51%20Deployment/README.md), and [52 Monitoring](../52%20Monitoring/README.md).

This topic tests whether you can take a green test suite all the way to a monitored, rollback-able production release. Interviewers escalate from "AAB vs APK" to "your release is crashing 3% of users at 40% rollout — what do you do?" — and the honest answer is not "push a hotfix," because you can't un-install an app off someone's phone.

## 🟢 Basic

**1. What are the three build modes and when is each used?**
- **Debug** (`flutter run`): JIT-compiled, assertions on, hot reload, DevTools, service extensions. Slow and large — never ship it.
- **Profile** (`flutter run --profile`): AOT-compiled like release but keeps some tracing/DevTools hooks so you can measure real performance. Debugging aids are stripped. Used only for performance profiling on a real device (not an emulator).
- **Release** (`flutter build`): AOT-compiled, assertions off, no debugging/observatory, tree-shaken, minified. This is what ships to stores.

The key "why": profile exists because debug's JIT and asserts make timings meaningless, but release strips the tooling you'd need to inspect anything — profile is the honest middle.

**2. AAB vs APK — what's the difference and which do you upload?**
An **APK** is an installable Android package. An **AAB** (Android App Bundle) is a *publishing* format you upload to Play; Google Play then generates and signs optimized, per-device APKs from it (Dynamic Delivery). AAB is mandatory for new Play submissions. Use `flutter build appbundle` for the store, `flutter build apk` for sideloading/CI artifacts/other stores. AABs enable **app thinning** — a device downloads only the density, ABI (arm64 vs x86), and language resources it needs, so download size shrinks.

**3. What is app thinning / split APKs?**
Instead of one fat universal binary carrying every screen density, CPU architecture, and locale, the store delivers only the slices a given device needs. On Android this is Play's split APKs from an AAB (or `flutter build apk --split-per-abi` if you distribute yourself); on iOS it's App Thinning (slicing + on-demand resources). Result: smaller install, faster download, less user churn from "app too big."

**4. What are flavors and why use them?**
Flavors are build variants of the *same* app — typically `dev`, `staging`, `prod` — each with its own app ID (`com.acme.app.dev`), name, icon, and backend config, so all three can sit on one device at once. You configure them natively (Android product flavors in `build.gradle`, iOS schemes/configurations) and select at build time: `flutter build apk --flavor prod -t lib/main_prod.dart`. Why: keep test and production data/keys fully separated and installable side by side.

**5. What is `--dart-define` and what problem does it solve?**
`--dart-define=API_URL=https://api.prod.com` injects a compile-time constant read via `String.fromEnvironment('API_URL')` (also `int`/`bool.fromEnvironment`). It lets you vary config (base URLs, flags, non-secret keys) per build without editing source. Because the value is baked in at compile time, it's `const` and tree-shakeable — but it is **not secret**; anyone can extract it from the binary.

```dart
const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'https://api.dev.com');
```

**6. What is `--dart-define-from-file` and why is it better than many `--dart-define` flags?**
`--dart-define-from-file=config/prod.json` reads a JSON (or `.env`-style) file of key/values in one flag instead of a dozen brittle `--dart-define`s. It keeps CI commands short, lets you version or `.gitignore` config per environment, and pairs naturally with flavors (one file per flavor). Same compile-time semantics as `--dart-define`.

**7. What is versioning in `pubspec.yaml` — version name vs build number?**
`version: 1.4.2+57` — the part before `+` is the **version name** (`1.4.2`, user-facing, semver) and after `+` is the **build number** (`57`, `versionCode`/`CFBundleVersion`). Stores require the build number to strictly increase with every upload even if the version name is unchanged; two uploads can't share a build number. Override at build time with `--build-name` and `--build-number`, which CI usually sets from the pipeline run number.

**8. At a high level, why does an app need to be signed?**
Signing cryptographically proves the app came from you and hasn't been tampered with, and it's how the OS decides an update is "the same app" as what's installed. On **Android** you sign with a keystore (a `.jks`/`.keystore` holding your key); losing it (pre–Play App Signing) means you can never update that listing again. On **iOS** you need a signing **certificate** (identifies the developer) plus a **provisioning profile** (ties app ID + certificate + allowed devices/capabilities). Debug builds are auto-signed with a throwaway debug key; release builds must use your real signing config.

**9. What is CI/CD in the context of a Flutter app?**
**CI** (Continuous Integration) runs automated checks on every push/PR — format, analyze, test, build — so broken code never merges. **CD** (Continuous Delivery/Deployment) takes a passing commit and produces/ships a release artifact (to a store track or a distribution service), ideally automatically. The point is a repeatable, auditable path from commit to users that a human can't forget a step in.

**10. What does a typical Flutter CI pipeline run, in order?**
A gated sequence where each stage must pass before the next:
1. `flutter pub get`
2. `dart format --set-exit-if-changed .` (fail on unformatted code)
3. `flutter analyze` (static analysis / lints)
4. `flutter test --coverage` (unit + widget)
5. `flutter build apk/appbundle/ipa` (the build actually compiles)

Ordering is deliberate: cheap, fast checks first so you fail in seconds, not after a 10-minute build.

**11. Name common CI/CD tools for Flutter and what each is good at.**
- **GitHub Actions**: general CI, free-ish for open source, YAML workflows, huge action marketplace; you assemble the Flutter steps yourself.
- **Codemagic**: Flutter-specialized SaaS — understands flavors, signing, and store publishing out of the box; least setup for mobile.
- **Bitrise**: mobile-focused CI with a visual step library and strong signing/deploy support.
- **Fastlane**: not a CI host — a Ruby automation toolkit (lanes) that scripts signing, screenshots, and store uploads; you call it *from* any of the above.

**12. What is Firebase Remote Config in one sentence?**
A cloud key/value store you fetch at runtime to change app behavior (values, thresholds, flags) without shipping an update — the backbone of feature flags and kill switches.

## 🟡 Intermediate

**13. Why can't you just "roll back" a mobile release the way you roll back a web deploy?**
Because the artifact lives on the user's device, not your server. Once someone installs v2.0, you cannot reach into their phone and revert them to v1.9 — stores don't downgrade installed apps, and you can't force-uninstall. So "rollback" on mobile means containing the blast radius of what's already out and stopping it from spreading. Your levers are: **halt/pause the staged rollout** so new users stop getting the bad build, flip a **remote-config kill switch** to disable the broken feature in-place, and if it's truly unusable, ship a **forced-update** prompt pushing everyone to a fixed version. There is no instant undo — which is exactly why staged rollout and feature flags matter.

**14. What is a staged / phased rollout and why use it?**
You release the new version to a small percentage of users first (Play: staged rollout at e.g. 1% → 5% → 20% → 50% → 100%; App Store: phased release over 7 days, auto-stepping daily). You watch crash-free rate and key metrics at each step; if release health degrades, you **halt** before most users ever get it. It converts a potential 100%-of-users incident into a 1%-of-users incident. Always pair it with monitoring — a staged rollout you don't watch is just a slow full rollout.

**15. How do feature flags let you decouple deploy from release?**
Ship the code dark (behind a flag defaulting off), then turn it on via remote config for a cohort without a new build. This means the risky code is already through review and in the store, and "launching" is a config change you can also instantly reverse. It enables canaries, A/B tests, and gradual enablement, and gives you a **kill switch**: if the feature misbehaves, flip the flag off for everyone in seconds — no store review, no update download.

**16. How do you implement a forced update?**
On startup (or resume) the app asks the backend/remote-config for a `minSupportedVersion` (and optionally `latestVersion`). Compare against the running build number/version:
- running `<` minSupported → show a **blocking**, non-dismissible dialog with a store link ("Update required").
- running `<` latest but `≥` minSupported → show a **soft**, dismissible "update available" nudge.

Keep the threshold server-controlled so you can raise the floor the moment a bad version is in the wild. Guard the check so a network failure doesn't lock users out.

**17. `--dart-define` vs `--flavor` — when do you use which, and can you use both?**
They're orthogonal and usually combined. **Flavor** = a distinct build variant with its own native identity (app ID, icon, name) — heavier, defined in Gradle/Xcode. **`--dart-define`** = injecting Dart-side config values into a build — lightweight, no native change. Use flavors when you need separate installable apps or different app IDs; use `--dart-define(-from-file)` for the config values inside each. Typical: `flutter build appbundle --flavor prod -t lib/main_prod.dart --dart-define-from-file=env/prod.json`.

**18. Why must you never put secrets (API keys, signing passwords) in `--dart-define` or source?**
`--dart-define` values are compiled into the binary as plain constants — trivially recoverable by decompiling or `strings` on the artifact. Client apps can't hold true secrets; anything on the device is public. Real secrets belong on the backend or in a secrets store (CI secret variables, KMS), and the app should authenticate to a server that holds them. `--dart-define` is fine for *non-secret* config (base URLs, feature toggles, public keys).

**19. How is signing configured securely in CI?**
You never commit the keystore or certificates. Store the keystore/`.p12`/provisioning profile and their passwords as **encrypted CI secrets**, decode them into the runner at build time, and point the build config at the decoded files. On Android, `key.properties` is generated from secrets, not checked in. Prefer **Play App Signing** (Google holds the app signing key; you keep only an upload key you can reset if lost) and iOS **fastlane match** (certs/profiles encrypted in a git repo, synced to CI) so signing is reproducible and a lost laptop isn't a catastrophe.

**20. What's the difference between crash reporting and analytics?**
Crash reporting (Crashlytics, Sentry) captures *failures* — stack traces, device/OS, breadcrumbs — so you can diagnose and prioritize by impact (users affected, crash-free rate). Analytics (Firebase Analytics, Amplitude) captures *intended behavior* — screen views, funnels, feature usage — to inform product decisions. Different questions: crash reporting answers "what's broken and for how many," analytics answers "what are people doing." You want both, plus a way to correlate them (e.g. did the crash tank the checkout funnel).

**21. What is an ANR and how do you catch it?**
An **ANR** (Application Not Responding) is Android detecting that the main/UI thread was blocked too long (~5s for input) and offering to kill the app. In Flutter it usually means heavy work on the platform main thread or a jammed platform channel — not typically pure Dart on the UI isolate, but native plugin work or a synchronous channel call can cause it. You surface ANRs via Play Console's Android vitals and Crashlytics' ANR reporting. Fix by moving work off the main thread (background isolate / `compute`, async platform calls).

**22. What is release health and which metric matters most?**
Release health is the aggregate stability of a specific version: **crash-free users** and **crash-free sessions**, plus ANR rate, adoption, and error volume — tracked per release. **Crash-free users %** is the headline metric for rollout decisions (e.g. "hold rollout if crash-free users drops below 99.5%"). It's per-*user* not per-*session* because one user crash-looping shouldn't look like thousands of independent failures.

**23. What are performance traces and what do you monitor in production?**
Custom traces (Firebase Performance `Trace`, Sentry transactions) measure real-world durations you care about — app start, screen render, a network call, a checkout step — across real devices you'll never own. Firebase Performance auto-captures app start, screen rendering (slow/frozen frames), and HTTP request timing; you add custom traces for domain flows. You monitor p90/p99 (tails, not averages), slow/frozen frame rates, and network success/latency — because a 200ms median hides the users on cheap phones and bad networks who churn.

**24. How do symbols/obfuscation interact with crash reporting?**
Release builds are AOT-compiled and can be obfuscated (`flutter build ... --obfuscate --split-debug-info=build/symbols`), which turns stack traces into meaningless addresses. To get readable traces you must **upload the symbol files** (Dart symbols, plus Android ProGuard/R8 mappings and iOS dSYMs) to your crash service for that exact build. If you obfuscate but forget to upload symbols, every crash report is undebuggable — a very common production footgun.

**25. What is a canary / kill switch and how does remote config provide it?**
A kill switch is a remote-config boolean that instantly disables a feature (or the whole app path) for everyone, without a store update. Because the app reads it at runtime, flipping it in the Firebase console propagates on the next fetch — seconds to minutes. It's your fastest incident-response lever on mobile precisely because store review and forced updates are slow. Design risky features to fail *closed* (flag off = old safe behavior).

**26. How do you set version name / build number in CI without editing pubspec by hand?**
Pass them at build time: `flutter build appbundle --build-name=1.4.2 --build-number=${{ github.run_number }}`. Deriving the build number from a monotonic CI counter (run number, or commit count) guarantees it always increases and never collides on the store, and keeps `pubspec.yaml` from churning on every release. The version name typically comes from a git tag.

## 🔴 Advanced

**27. Design the rollback/incident-response playbook for "v2.3 crashes 4% of users, currently at 20% staged rollout."**
There's no un-install, so contain and stop the spread:
1. **Halt the rollout immediately** (Play: pause staged rollout; App Store: pause phased release) — new users stop getting v2.3.
2. **Identify the cause** in Crashlytics — is the crash gated behind a feature you flagged?
3. If yes, **flip the remote-config kill switch** — existing v2.3 users stop hitting the crash path without any update.
4. If it's not flaggable, **prepare a hotfix** (v2.3.1) and, once verified, either resume rollout on the fixed build or push it. For a truly unusable build, raise `minSupportedVersion` so v2.3 users get a **forced-update** prompt.
5. Note that Play lets you resume the *previous* good version's rollout to new installs while you fix forward.
6. **Postmortem**: why did staged rollout + monitoring not catch it earlier (was the halt threshold too loose)?

The senior point: prevention (staged rollout %, flags, alert thresholds) is the real answer; once a bad build is installed, all remedies are partial.

**28. Design a CI/CD pipeline from PR to production store for a flavored Flutter app.**
- **On PR**: `pub get` → `dart format --set-exit-if-changed` → `flutter analyze` (fail on infos too, via `analysis_options`) → `flutter test --coverage` → build the dev flavor (proves it compiles). Block merge on any failure; upload coverage.
- **On merge to `main`**: build `staging` flavor, distribute to testers (Firebase App Distribution / TestFlight internal) via Fastlane.
- **On git tag `v*`**: build `prod` AAB/IPA with `--obfuscate --split-debug-info`, **upload symbols/dSYMs** to Crashlytics/Sentry, then Fastlane `supply`/`deliver` to the store on an **internal/testing track first**, promote to a **staged production rollout** (start at 5–10%) gated on a manual approval.
- **Cross-cutting**: signing from encrypted secrets, build number from CI run number, caching pub/gradle for speed, and a required status check so nothing ships unreviewed.

**29. How do you correlate a spike in crashes with a specific release, device, or config?**
Attach context at capture time: set the release/version and flavor, and log **breadcrumbs**, custom keys (feature-flag states, experiment bucket, user tier), and `setUserIdentifier` (anonymized) on your crash SDK. Then in the dashboard you filter/group crashes by app version, OS, device model, and custom key. This is how you discover "only crashes on Android 12 + flag X on = the new payments path," which turns a vague spike into a one-line fix. Also wire non-fatal error logging (`recordError`) for handled exceptions so you see degradation before it becomes a hard crash.

**30. Set up alerting and release-health gating — what fires, and what does it trigger?**
Define SLO-style thresholds per release and alert on breach, not on raw counts:
- Crash-free users drops below, say, 99.5% for the active rollout → page on-call and **auto/assisted halt** the rollout.
- New "velocity"/regression alert (a fresh crash signature spiking) → Slack/PagerDuty.
- ANR rate or slow-frame rate above baseline → warning.
- p99 latency or API error rate regression from Performance Monitoring → warning.

Route via Crashlytics velocity alerts / Sentry alert rules → Slack + PagerDuty. The gate is the important part: an alert that doesn't stop the rollout just tells you calmly that you shipped a fire.

**31. Play App Signing vs uploading your own signed AAB — what actually changes?**
With **Play App Signing**, Google holds the *app signing key* and re-signs the per-device APKs; you sign uploads with a separate **upload key**. Benefits: if you lose the upload key you can reset it (you can't reset a legacy standalone signing key — that ends the app), the app signing key is stored in Google's KMS, and it's required for AAB. The trade-off is Google technically holds the key, and the delivered APK's signature differs from your local build's — matters for anything that pins the signing certificate (e.g. some SDKs, API key restrictions). You register the app signing SHA in those consoles, not your upload SHA.

**32. Why is per-user crash-free rate a better rollout gate than total crash count, and where does it mislead?**
Total count scales with traffic — a big release naturally has more absolute crashes without being worse, so you can't threshold on it. Crash-free *users* normalizes by audience and reflects felt pain. Where it misleads: (a) it hides severity — 0.5% of users each crashing 50 times a session is worse than the number suggests, so also watch crash-free *sessions*; (b) low-traffic early rollout stages have tiny denominators, so 2 crashes look like a 5% regression — wait for statistical significance before halting; (c) it ignores non-crash breakage (frozen UI, failed checkout) that needs analytics/ANR/error signals too.

**33. How do you keep obfuscation, symbol upload, and versioning correct across an automated multi-flavor release?**
Each build must produce and archive its own symbol artifacts keyed to its exact version+flavor+platform: run with `--obfuscate --split-debug-info=symbols/<flavor>/<version>`, then upload Dart symbols + Android mapping.txt + iOS dSYMs to the crash service tagged with the identical version/build number the store shows. Automate it in the same CI job that builds (never manually) so the symbols always match the shipped binary, and store the symbol files as build artifacts for the retention window in case you need to symbolicate an old crash. The failure mode to prevent: a rebuilt binary with regenerated symbols no longer matching the store's copy — so build once, upload the symbols from that same build.

**34. A staged rollout looks healthy on your metrics but users complain the app is "broken." What's likely happening and how do you catch it?**
Crash-free rate only measures *crashes* — an app can be fully broken while never crashing: a failing network call handled with an empty state, a feature flag misconfigured, a silent auth failure, or frozen (not crashed) frames. Catch it by monitoring beyond crashes: non-fatal/handled-error logging, funnel/conversion analytics (did checkouts drop?), API error-rate and latency from performance monitoring, ANR/frozen-frame rate, and in-app feedback. The lesson: release health is crashes **plus** business metrics **plus** performance — gate on the union, because the worst outages are the quiet ones.

## ⚡ Rapid-fire (one-liners)

| Q | A |
|---|---|
| Store upload format for Android? | AAB (`flutter build appbundle`) |
| Build mode for perf profiling? | profile (AOT + tracing, real device) |
| Read a `--dart-define` value? | `String.fromEnvironment('KEY')` |
| One flag for many defines? | `--dart-define-from-file=env.json` |
| Are `--dart-define` values secret? | No — baked into the binary, extractable |
| `1.4.2+57` — what's `57`? | build number (`versionCode`), must increase |
| iOS signing needs? | certificate + provisioning profile |
| Fastest incident lever on mobile? | remote-config kill switch |
| Can you un-install a bad release remotely? | No — halt rollout / kill switch / forced update |
| Headline rollout gate metric? | crash-free users % |
| What's an ANR? | Android main thread blocked too long |
| Flag to obfuscate a release? | `--obfuscate --split-debug-info=...` |
| Forgot to upload symbols → ? | unreadable/obfuscated crash traces |
| CI stage order? | format → analyze → test → build |
| Flutter-specialized CI SaaS? | Codemagic |
| Fastlane is…? | store-automation toolkit, not a CI host |
| Lets you deploy ≠ release? | feature flags (ship dark, toggle on) |
| iOS phased release length? | 7 days, auto-stepping daily |
| Recover a lost Android signing key? | only with Play App Signing (reset upload key) |

## Follow-up drills

1. Design the full GitHub Actions workflow (jobs, secrets, caching) that takes a flavored Flutter app from PR to a staged Play production rollout, including symbol upload.
2. Your prod release is crashing 6% of users at 30% rollout, and the crash is *not* behind a feature flag. Walk through every option and their trade-offs.
3. Implement a forced-update + soft-update system: define the remote schema, the startup check, and the failure/offline behavior.
4. Optimize a 14-minute CI pipeline that runs on every PR — where do you cut time without losing safety?
5. Design release-health alerting for a payments app: thresholds, what auto-halts vs pages a human, and how you avoid false alarms in early low-traffic rollout stages.
6. You inherit an app with no monitoring. Prioritize what you instrument first (crash, ANR, analytics, performance, flags) and justify the order.
7. Explain how you'd manage signing for a team of 8 iOS developers plus CI so nobody's laptop is a single point of failure.
