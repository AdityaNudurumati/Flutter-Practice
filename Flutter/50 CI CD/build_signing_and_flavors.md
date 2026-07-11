# Build Signing & Flavors/Environments

> Release builds must be **code-signed** — **Android** with a **keystore** (private key; the upload/app-signing key that proves authorship) and **iOS** with **certificates + provisioning profiles** (via Apple Developer) — and CI must access these **secrets securely** (base64-encoded in the CI encrypted store, never in the repo). Apps also ship in multiple **flavors/environments** (dev/staging/prod) with **distinct bundle ids, config, API endpoints, and icons**, selected at build time (`--flavor` + `--dart-define`/entry point). **Fastlane** commonly automates the signing + build + upload steps that CI invokes.

## Introduction

This file covers the two build-configuration pillars CI/CD needs: **signing** (Android keystore, iOS certs/provisioning, secure secret handling) and **flavors/environments** (dev/staging/prod separation), plus **Fastlane** as the automation glue. It builds on native config ([Module 27](../27%20Native%20Android/README.md)/[Module 28](../28%20Native%20iOS/README.md)) and security ([Module 37](../37%20Security/README.md)).

## Why this concept exists

Stores only accept **signed** builds, and signing keys are **sensitive** (a leaked keystore lets others publish as you) — so CI must handle them securely. And teams need **separate environments** (dev/staging/prod) that coexist on a device with their own backends/config — requiring flavors. Automating these correctly (secrets + flavors + Fastlane) is what lets CI produce shippable, environment-correct, signed artifacts.

## Real-world analogy

**Signing** is your **notarized seal + ID**: the keystore/cert proves *you* made this app; lose control of the seal and impostors can publish as you (guard it in a vault = encrypted secrets). **Flavors** are **product editions off one production line** — the "test kitchen" edition (dev), the "pre-launch" edition (staging), and the "retail" edition (prod) — same base, different labels/ingredients (bundle id/config/endpoint/icon), stamped at packaging time. **Fastlane** is the **automated packaging-and-shipping crew**.

## Internal Working

```mermaid
flowchart TD
    Secrets[CI encrypted secrets: keystore(base64) + passwords / iOS cert+profile] --> Decode[decode at build time -> temp files/env]
    Decode --> Sign[Android: sign with keystore | iOS: cert + provisioning profile]
    Flavor[--flavor dev/staging/prod + --dart-define/entry point] --> Build[flutter build (flavor) -> signed artifact]
    Sign --> Build
    Fastlane[Fastlane lanes: build + sign + upload] --> Build
    Note[secrets NEVER in repo; flavors = distinct bundle id/config/endpoint/icon]
```

- **Android signing**:
  - A **keystore** (`.jks`/`.keystore`) holds the **private signing key**. Configure `signingConfigs`/`buildTypes` in `android/app/build.gradle` reading credentials from **`key.properties`** (path/passwords/alias) — which is **git-ignored**.
  - **Play App Signing** (recommended): you sign with an **upload key**; Google holds/manages the **app signing key**. Protects against upload-key loss.
  - **In CI**: base64-encode the keystore + store it (plus passwords) in **CI encrypted secrets**; at build time **decode to a temp file** and set env/`key.properties`, then `flutter build appbundle --release`. **Never commit the keystore/passwords.**
- **iOS signing** (more involved):
  - Needs a **signing certificate** (identifies the developer/team) + a **provisioning profile** (ties app id + devices + entitlements) from **Apple Developer**. Xcode uses these to sign.
  - **In CI**: store the cert (`.p12`) + profile (base64) + password in **encrypted secrets**; install them into a temporary keychain at build time (Fastlane **match**/`sigh`/`cert` automate this), then `flutter build ipa`. **`match`** stores certs/profiles encrypted in a git repo for team sync.
  - Requires a **Mac runner** (macOS) for iOS builds.
- **Secret handling (security-critical)** ([Module 37](../37%20Security/README.md)): keystores/certs/passwords/API keys live **only** in the CI provider's **encrypted secrets** (GitHub Secrets/Codemagic env), injected as env vars, decoded to **temp files** deleted after the build. **Never in the repo, logs, or config.**
- **Flavors / environments** (dev/staging/prod):
  - Each flavor has a **distinct application/bundle id** (`com.app.dev`, `com.app.staging`, `com.app`) so they **coexist** on a device, plus its own **app name/icon**, **API endpoint/config**, and Firebase config.
  - **Android**: `productFlavors` in `build.gradle` (+ per-flavor `google-services.json`). **iOS**: **schemes + xcconfig/build configs** (more manual — [Module 28](../28%20Native%20iOS/README.md)).
  - **Flutter side**: select config via **`--flavor <name>`** + **`--dart-define`**/`--dart-define-from-file` (compile-time config) or a **separate entry point** (`main_dev.dart`) — inject the environment (base URL, flags) at build time, **not** hardcoded.
  - Build: `flutter build appbundle --release --flavor prod --dart-define-from-file=env/prod.json`.
- **Fastlane** (automation glue): Ruby-based; **lanes** encapsulate build/sign/upload steps (`gym`/`build_app` for iOS build, `match`/`sigh` for signing, `supply` for Play upload, `pilot` for TestFlight). CI invokes Fastlane lanes; Codemagic/Bitrise offer built-in equivalents. Fastlane centralizes the fiddly signing/store steps.
- **Config-not-secret vs secret**: environment **config** (base URLs, flags) can be in `--dart-define`/env files (non-sensitive); **secrets** (keys/keystores) stay in the encrypted store — don't confuse the two.

## Memory Representation

Not runtime — **build-time config + secrets**: keystore/certs (in encrypted secrets → temp files at build), flavor definitions (gradle/xcconfig), and per-flavor config (`--dart-define`/entry points). The signed artifact embeds the signature + flavor config.

## Compiler / Build Behavior

Flutter/Gradle/Xcode compile per flavor + sign the release artifact using the provided key/cert; `--dart-define` values are compiled in; wrong/missing signing config fails the release build. Pinned toolchains keep it reproducible.

## Runtime Behavior

The signed, flavored artifact runs pointing at its environment's config (endpoint/flags baked in); different flavors coexist (distinct ids). Signature is verified by the store/OS at install.

## Flutter Engine Behavior

Not applicable (build/signing are native tooling); `--dart-define` values are available to Dart at runtime.

## Dart VM Behavior

`--dart-define`/`--dart-define-from-file` inject compile-time constants (tree-shakable) — the idiomatic way to pass environment config without secrets in code.

## Examples

```gradle
// android/app/build.gradle — signing from git-ignored key.properties + flavors
def keystoreProps = new Properties()
file('../key.properties').withInputStream { keystoreProps.load(it) }   // git-ignored
android {
  signingConfigs { release {
    storeFile file(keystoreProps['storeFile']); storePassword keystoreProps['storePassword']
    keyAlias keystoreProps['keyAlias']; keyPassword keystoreProps['keyPassword']
  } }
  buildTypes { release { signingConfig signingConfigs.release } }
  flavorDimensions "env"
  productFlavors {
    dev     { dimension "env"; applicationIdSuffix ".dev"; resValue "string","app_name","App Dev" }
    staging { dimension "env"; applicationIdSuffix ".staging" }
    prod    { dimension "env" }   // com.app
  }
}
```

```yaml
# CI: decode keystore from secret at build time, then build a signed, flavored bundle
- run: echo "$KEYSTORE_BASE64" | base64 -d > android/app/upload.jks   # from CI secret
- run: |
    printf "storeFile=upload.jks\nstorePassword=$STORE_PW\nkeyAlias=$KEY_ALIAS\nkeyPassword=$KEY_PW\n" > android/key.properties
- run: flutter build appbundle --release --flavor prod --dart-define-from-file=env/prod.json
# (KEYSTORE_BASE64/STORE_PW/... come from GitHub encrypted secrets; files cleaned up after)
```

```ruby
# Fastlane lane (iOS) — match handles certs/profiles, gym builds, pilot uploads to TestFlight
lane :beta do
  match(type: "appstore")          # sync signing cert + provisioning (encrypted git)
  build_app(scheme: "prod")        # gym: build signed .ipa
  upload_to_testflight             # pilot
end
```

## Diagrams

```mermaid
flowchart LR
    CI[CI encrypted secrets] --> Decode2[decode keystore/cert -> temp]
    Decode2 --> Build2[flutter build --flavor prod (signed)]
    Env[--dart-define / entry point] --> Build2
    Build2 --> Artifact[signed, environment-correct artifact]
    Fastlane2[Fastlane lanes] --> Build2
```

## Common Mistakes

| Mistake | Why it's dangerous/wrong | Fix |
|---------|-------------------------|-----|
| Committing keystore/certs/passwords | Key theft → impostor publishing | Encrypted CI secrets only; git-ignore key files |
| Secrets in logs/`--dart-define` | Leak | Secrets in encrypted store; only non-sensitive config in dart-define |
| No flavors (one bundle id) | Environments collide on device | Distinct bundle ids per flavor |
| Hardcoded API endpoints | Wrong env / rebuild churn | Inject via `--dart-define`/entry point |
| Not using Play App Signing | Upload-key loss = locked out | Enroll in Play App Signing (upload key) |
| Manual iOS signing in CI | Fragile/fails | Fastlane `match`/`sigh` + Mac runner |
| Missing per-flavor Firebase config | Wrong project | Per-flavor `google-services.json`/`GoogleService-Info.plist` |
| Confusing config with secrets | Over/under-protecting | Config (URLs/flags) in dart-define; keys in secrets |

## Best Practices

- **Store all signing material + passwords in the CI encrypted secrets** (base64 keystore, `.p12`/profiles), decode to **temp files at build time**, and **never** commit them or log them; git-ignore `key.properties`.
- Use **Play App Signing** (upload key) on Android and **Fastlane `match`** for iOS certs/profiles; build iOS on a **Mac runner**.
- Define **dev/staging/prod flavors** with **distinct bundle ids + config + endpoints + icons** (`productFlavors`/schemes) and inject environment via **`--dart-define`/entry point** (not hardcoded); per-flavor Firebase config.
- Automate build+sign+upload with **Fastlane lanes** (or Codemagic built-ins); keep **config (non-secret) separate from secrets**.

## Performance

Not runtime perf; the concern is **build reliability + security**. Caching signing tooling/pods speeds iOS builds; per-flavor builds add matrix jobs. The real cost of getting this wrong is a **security incident** (leaked key) or a **broken release**, not slowness.

## Advantages / Disadvantages

- **+** Shippable signed builds, secure secret handling, coexisting environments (dev/staging/prod), automated + reproducible signing/upload (Fastlane).
- **−** Signing setup is fiddly (esp. iOS certs/profiles), secret management discipline, flavor config per platform, Mac runner needed for iOS, Fastlane learning curve.

## Interview Questions

1. **🟢 How are Android and iOS release builds signed?** — Android with a keystore (private signing key; ideally Play App Signing with an upload key); iOS with a certificate + provisioning profile from Apple Developer.
2. **🟢 How do you handle signing secrets in CI?** — Store them (base64 keystore/`.p12`/profiles + passwords) in the CI encrypted secrets, decode to temp files at build time, and never commit or log them.
3. **🟡 What are flavors/environments, and what differs per flavor?** — dev/staging/prod builds with distinct bundle ids (so they coexist), plus their own name/icon, API endpoint/config, and Firebase config.
4. **🟡 How do you inject environment config into a Flutter build?** — `--flavor` + `--dart-define`/`--dart-define-from-file` or a separate entry point (`main_dev.dart`) — compile-time, not hardcoded; keep secrets out of dart-define.
5. **🟡 What is Fastlane, and what does it automate?** — A Ruby tool with "lanes" automating build/sign/upload (`match`/`sigh` for signing, `gym`/`build_app` for build, `supply`/`pilot` for store upload) — invoked by CI.
6. **🔴 Why use Play App Signing?** — You sign with an upload key while Google manages the app signing key — protecting against upload-key loss and easing key rotation.
7. **🔴 What's the difference between environment config and secrets, and how are they handled?** — Config (base URLs/flags) is non-sensitive → `--dart-define`/env files; secrets (keys/keystores/passwords) → encrypted CI store only; don't conflate them.

## Senior Engineer Tips

- Treat the keystore/certs like production credentials: base64 into encrypted CI secrets, decode to a temp file per build, clean up, and never let them touch the repo or logs — a leaked keystore is a publish-as-you incident.
- Enroll in Play App Signing and use Fastlane `match` for iOS from the start; both eliminate the fragile, manual signing that breaks CI at the worst time (and `match` makes team signing reproducible).
- Set up dev/staging/prod flavors with distinct bundle ids and inject endpoints via `--dart-define`; hardcoded environments and single-id apps are recurring release/config bugs.

## Architect Perspective

Signing + flavors are the build-configuration layer CI/CD depends on: secure secret handling turns sensitive keys into safely-injected temp files, and flavors give coexisting, environment-correct builds — with Fastlane automating the fiddly signing/store steps. Done right (encrypted secrets, Play App Signing/match, `--dart-define` config, per-flavor separation), it lets CI produce shippable, correct artifacts repeatably and securely — the bridge from a green build to an actual release ([cd_release_automation.md](cd_release_automation.md), [Module 51](../51%20Deployment/README.md), [Module 37](../37%20Security/README.md)).

## Summary

- Sign releases: Android keystore (Play App Signing/upload key), iOS certs + provisioning (Fastlane `match`), on a Mac runner for iOS; secrets in encrypted CI store → temp files at build, never committed/logged.
- Flavors (dev/staging/prod): distinct bundle ids + name/icon + endpoint/config + Firebase config; inject env via `--flavor` + `--dart-define`/entry point (not hardcoded).
- Automate build+sign+upload with Fastlane lanes (or Codemagic built-ins); separate non-secret config from secrets.

## Revision Notes

- Android: keystore (private key) + `signingConfigs` from git-ignored `key.properties`; Play App Signing (upload key). iOS: cert + provisioning profile (Apple Dev), Fastlane `match`/`sigh`, Mac runner.
- CI secrets: base64 keystore/`.p12`/profiles + passwords in encrypted store → decode to temp at build → clean up; never in repo/logs.
- Flavors: `productFlavors` (Android)/schemes+xcconfig (iOS) → distinct bundle id + name/icon + endpoint + Firebase config; Flutter `--flavor` + `--dart-define`/entry point (config, not secrets). Fastlane lanes (`match`/`gym`/`supply`/`pilot`) automate build+sign+upload.

## Practice Questions

1. How do you get a signing keystore into CI without committing it?
2. What differs between dev/staging/prod flavors, and how is env config injected?
3. What does Fastlane automate, and why use `match`/Play App Signing?

## Coding Questions

1. Configure Android signing from a git-ignored `key.properties` + a release `signingConfig`.
2. Define dev/staging/prod `productFlavors` (distinct ids) and a `--dart-define-from-file` build command.
3. Write a CI step decoding a base64 keystore secret and building a signed, flavored bundle.

## Mini Project

**Signing + flavors (Flutter/CI-CD):** Configure Android signing (git-ignored `key.properties` + release `signingConfig`, Play-App-Signing-ready), dev/staging/prod flavors (distinct bundle ids + names + per-flavor endpoint via `--dart-define-from-file`), and a CI step that decodes a base64 keystore from an encrypted secret to build a signed prod bundle — plus a Fastlane lane sketch for iOS (`match` + `gym` + `pilot`). Acceptance: signing from git-ignored/encrypted secrets (never committed/logged); Play App Signing considered; dev/staging/prod flavors with distinct ids + injected (not hardcoded) endpoints; CI decodes keystore securely + builds signed flavored artifact; Fastlane lane for iOS; config vs secrets separated.
