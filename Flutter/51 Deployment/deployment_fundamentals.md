# Deployment Fundamentals

> Deployment is getting your app to users through the **app stores** — **Google Play** (Android) and the **Apple App Store** (iOS) — which mediate distribution via **release channels/tracks** (internal → beta → production), **review**, and **updates**. The two anchors: **artifact format** — Android ships an **Android App Bundle (`.aab`)** (Google generates optimized per-device APKs via **App Bundle + dynamic delivery**), iOS ships an **`.ipa`** to App Store Connect — and **versioning** — a user-facing **semantic version** (`1.2.0`) plus a **monotonically increasing build number** (stores **reject duplicates**). Plan a **release strategy** (cadence, channels, staged rollout) rather than shipping ad hoc.

## Introduction

This file establishes the deployment landscape: the stores, channels/tracks, artifact formats, versioning, and a release-strategy mindset — the frame for the setup/review/optimization files. It's the "how apps reach users" foundation.

## Why this concept exists

Unlike web (deploy to your server), mobile distribution is **gatekept by stores** with their own formats, review, versioning rules, and update mechanics. Understanding this — App Bundle vs APK, version vs build number, tracks, review latency — prevents the classic failures (rejected uploads, duplicate build numbers, wrong channel) and lets you plan releases deliberately.

## Real-world analogy

The stores are **regulated retailers you must go through** to reach shelves: you can't hand products directly to customers — you submit to the retailer (store), pass **inspection** (review), and stock **back-room test shelves** (internal/beta) before the **main floor** (production). Each product batch needs a unique **lot number** (build number) and a **version label** (semver). You plan **restock cadence + phased shelf placement** (release strategy/staged rollout), not random dumping.

## Internal Working

```mermaid
flowchart TD
    Build[signed release artifact] --> Format{platform format}
    Format -->|Android| AAB[.aab -> Play generates per-device APKs (dynamic delivery)]
    Format -->|iOS| IPA[.ipa -> App Store Connect]
    AAB --> Tracks[Play tracks: internal -> closed/alpha -> open/beta -> production]
    IPA --> AppStore[TestFlight (beta) -> App Store (production)]
    Version[semver 1.2.0 + monotonic build number] --> Build
    Strategy[release strategy: cadence, channels, staged rollout] --> Tracks & AppStore
```

- **The stores**:
  - **Google Play** (Android): Play Console; faster/automated review (hours-days); staged rollout %; multiple tracks.
  - **Apple App Store** (iOS): App Store Connect; human review (typically ~1 day, variable); TestFlight for beta; Phased Release for production.
  - (Others exist — Amazon Appstore, Huawei AppGallery, enterprise/MDM, web/desktop stores — but Play + App Store dominate.)
- **Artifact formats (know these)**:
  - **Android — Android App Bundle (`.aab`)**: the **required** publishing format. You upload one `.aab`; **Google Play generates + serves optimized APKs per device** (dynamic delivery: only the code/resources/density/ABI that device needs) → **smaller downloads**. (Raw `.apk` is for sideload/testing, not Play publishing.) `flutter build appbundle`.
  - **iOS — `.ipa`**: uploaded to App Store Connect (via Xcode/Transporter/Fastlane); Apple handles device optimization (app thinning/slicing). `flutter build ipa`.
- **Release channels / tracks (progressive exposure)** ([Module 50](../50%20CI%20CD/README.md)):
  - **Play**: **internal** (small team, instant) → **closed/alpha** → **open/beta** → **production** (with **staged rollout %**).
  - **App Store**: **TestFlight** (internal + external testers) → **App Store** (production, Phased Release).
  - Promote up as confidence grows; never straight to 100% production.
- **Versioning (get it right or uploads fail)**:
  - **`version: 1.2.0+34`** in `pubspec.yaml` → **version name** (`1.2.0`, user-facing **semver**) + **build number** (`34`, Android `versionCode` / iOS `CFBundleVersion`).
  - The **build number must strictly increase** per upload — stores **reject duplicates/lower**. Automate the bump ([Module 50](../50%20CI%20CD/README.md)).
  - **Semver**: MAJOR.MINOR.PATCH communicates change scope; bump per release.
- **Release strategy (plan, don't wing it)**: decide **cadence** (weekly/biweekly/on-demand), **channel flow** (internal→beta→prod), **staged rollout** (5%→100% + monitoring — [Module 52](../52%20Monitoring/README.md)), and **who approves production** (gated — [Module 50](../50%20CI%20CD/README.md)). Mobile releases are **hard to roll back** (users must update) → **forward-fix + staged rollout**.
- **Accounts/enrollment (prereqs)**: **Google Play Developer** account (one-time fee) + **Apple Developer Program** (annual fee); Apple requires a **Mac + Xcode** for building/uploading iOS.
- **Automate via CI/CD**: build/sign/upload to tracks are automated ([Module 50](../50%20CI%20CD/README.md)); this module is the store-side knowledge that automation targets.

## Memory Representation

Not runtime — a **release plan + artifacts**: the `.aab`/`.ipa`, version+build-number metadata, track/channel state, and a cadence/rollout strategy. Stores hold the track state + review status.

## Compiler / Build Behavior

`flutter build appbundle`/`ipa` produce signed release artifacts (AOT-compiled, per flavor); version/build number embed at build; App Bundle enables Play's per-device APK generation.

## Runtime Behavior

Users download the store-optimized artifact (smaller via App Bundle/thinning); production rolls out progressively (staged/phased); updates arrive via store auto-update. No instant rollback.

## Flutter Engine Behavior

Release builds ship AOT-compiled Dart + the engine; App Bundle strips unneeded ABIs/resources per device ([app_size_and_build_optimization.md](app_size_and_build_optimization.md)).

## Dart VM Behavior

Release = AOT (no JIT/VM overhead in prod); tree-shaking/obfuscation reduce size ([Module 21](../21%20Performance/README.md)).

## Examples

```yaml
# pubspec.yaml — version name + build number (build number MUST increase per upload)
version: 1.2.0+34    # 1.2.0 = semver (user-facing), 34 = build number (versionCode/CFBundleVersion)
```

```text
Build artifacts:
  flutter build appbundle --release --flavor prod   # Android -> .aab (Play publishing format)
  flutter build ipa       --release --flavor prod   # iOS     -> .ipa (App Store Connect)
  # (flutter build apk = sideload/test only, NOT for Play publishing)

Channel/track flow (never straight to 100% prod):
  Play:      internal -> closed/alpha -> open/beta -> production (staged 5%->100%)
  App Store: TestFlight (internal/external) -> App Store (Phased Release)
```

```text
Release strategy checklist:
  cadence (e.g., biweekly) | channel flow (internal->beta->prod) | staged rollout % + monitoring
  | gated prod approval | auto build-number bump | forward-fix plan (mobile rollback is hard)
```

## Diagrams

```mermaid
flowchart LR
    App[finished app] --> Artifact[signed .aab / .ipa (versioned)]
    Artifact --> Beta[internal/beta track]
    Beta --> Prod[gated production]
    Prod --> Staged[staged/phased rollout + monitoring]
```

## Common Mistakes

| Mistake | Why it's a problem | Fix |
|---------|-------------------|-----|
| Uploading a raw APK to Play | Not the publishing format | Build/upload an App Bundle (`.aab`) |
| Duplicate/lower build number | Store rejects upload | Auto-increment a unique monotonic build number |
| Straight to 100% production | Bad build hits everyone | Staged/phased rollout + monitoring |
| No release strategy (ad hoc) | Chaotic, risky releases | Plan cadence/channels/rollout/approval |
| Expecting easy rollback | Users already have the build | Forward-fix + staged rollout + flags |
| Confusing version vs build number | Rejected/mislabeled releases | semver = user-facing; build number = unique/increasing |
| No Mac for iOS | Can't build/upload iOS | Mac + Xcode (or Mac CI runner) |

## Best Practices

- Ship the right **artifact**: Android **App Bundle (`.aab`)** (Play generates per-device APKs → smaller downloads); iOS **`.ipa`** to App Store Connect.
- Version correctly: **semver version name** + a **strictly increasing build number** (`1.2.0+34`); **automate the build-number bump**; never reuse/lower it.
- Use **channels/tracks** (internal → beta → production) and **staged/phased rollout** with **monitoring**; **gate production**; plan **cadence + approval** (a real release strategy).
- Design for **forward-fix** (mobile rollback is hard); automate build/sign/upload via **CI/CD** ([Module 50](../50%20CI%20CD/README.md)); ensure prereqs (developer accounts, Mac for iOS).

## Performance

Deployment affects install/runtime performance: **App Bundle/thinning** shrink the download (higher install conversion), **AOT release builds + obfuscation/tree-shaking** reduce size + startup ([app_size_and_build_optimization.md](app_size_and_build_optimization.md)/[Module 21](../21%20Performance/README.md)). Staged rollout limits the blast radius of a bad release.

## Advantages / Disadvantages

- **+** Reaches users via trusted stores, per-device-optimized downloads (App Bundle/thinning), staged safe rollout, structured channels.
- **−** Store gatekeeping (review latency/policy), hard rollback, versioning strictness, account/Mac prerequisites, per-store processes.

## Interview Questions

1. **🟢 What artifact do you publish on each platform?** — Android: an Android App Bundle (`.aab`) — Play generates optimized per-device APKs; iOS: an `.ipa` to App Store Connect.
2. **🟢 Version name vs build number?** — Version name = user-facing semver (`1.2.0`); build number = a strictly increasing integer (`versionCode`/`CFBundleVersion`) — stores reject duplicates.
3. **🟡 Why an App Bundle instead of an APK for Play?** — Play uses it for dynamic delivery — serving only the code/resources/density/ABI each device needs → smaller downloads; raw APK is for sideload/testing.
4. **🟡 What are release channels/tracks, and why progressive?** — Play internal→beta→production, App Store TestFlight→App Store; promote up as confidence grows and roll out staged, so a bad build reaches few.
5. **🟡 Why can't you easily roll back a mobile release?** — Users already have the installed build; you mitigate with staged rollout + halt, feature flags, and forward-fix (hotfix).
6. **🔴 What does a release strategy include?** — Cadence, channel flow, staged rollout % + monitoring, gated production approval, auto build-number bump, and a forward-fix plan.
7. **🔴 What are the prerequisites to publish?** — Google Play Developer + Apple Developer Program accounts, and a Mac + Xcode (or Mac CI runner) for iOS builds/uploads.

## Senior Engineer Tips

- Always publish an App Bundle and auto-increment the build number in CI; "uploaded an APK" and "duplicate versionCode" are the two most common first-release failures.
- Never go straight to 100% production — internal→beta→staged rollout with monitoring is the standard, and it's your main defense given mobile's hard rollback.
- Write a release runbook (cadence, channels, rollout, approval, forward-fix) early; ad hoc releases are where avoidable incidents happen.

## Architect Perspective

Deployment fundamentals frame mobile's store-gatekept distribution: the right artifact (App Bundle/`.ipa`), correct versioning (semver + monotonic build number), progressive channels, and a deliberate staged, gated release strategy built around forward-fix (since rollback is hard). Getting these right — and automating them via CI/CD — turns a built app into a reliably shippable product and sets up the store-setup, review, and optimization work that follows ([store_setup_and_submission.md](store_setup_and_submission.md), [Module 50](../50%20CI%20CD/README.md), [Module 52](../52%20Monitoring/README.md)).

## Summary

- Publish via stores: Android App Bundle (`.aab`, per-device APKs) / iOS `.ipa`; version = semver name + strictly increasing build number (`1.2.0+34`).
- Use channels (internal→beta→production) + staged/phased rollout + monitoring; gate production; plan a real release strategy (cadence/approval).
- Mobile rollback is hard → forward-fix + staged rollout + flags; automate build/sign/upload via CI/CD; need dev accounts + Mac for iOS.

## Revision Notes

- Stores: Google Play (`.aab`, dynamic delivery → per-device APKs; faster review; staged rollout %) / Apple App Store (`.ipa`, App Store Connect, TestFlight beta, Phased Release; human review; needs Mac/Xcode).
- Version: `pubspec version: 1.2.0+34` → name (semver, user-facing) + build number (versionCode/CFBundleVersion, strictly increasing — no duplicates); auto-bump.
- Channels: Play internal→closed/alpha→open/beta→production; App Store TestFlight→App Store; staged/phased rollout + monitoring; gated prod. Rollback hard → forward-fix/flags. Prereqs: Play Developer + Apple Developer accounts, Mac for iOS. Automate via CI/CD.

## Practice Questions

1. Why publish an App Bundle rather than an APK on Play?
2. What's the difference between version name and build number, and why does it matter?
3. What does a good release strategy include?

## Coding Questions

1. Set `pubspec` version + build number correctly and build both platform artifacts.
2. Outline the channel/track flow from internal to production for both stores.
3. Draft a release-strategy checklist (cadence/channels/rollout/approval/forward-fix).

## Mini Project

**Release plan (Flutter/deployment):** For an app, define the deployment plan: artifact formats (`.aab`/`.ipa`), versioning scheme (semver name + auto-incrementing build number), channel/track flow (internal→beta→staged production for both stores), staged-rollout + monitoring + gated-approval strategy, and a forward-fix rollback plan — plus prerequisites (accounts, Mac). Acceptance: correct artifacts + versioning (unique/increasing build number); progressive channel flow (not straight-to-prod); staged rollout + monitoring + gated approval; forward-fix plan; prerequisites listed; CI/CD-automatable.
