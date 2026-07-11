# CD & Release Automation

> Continuous Delivery/Deployment automates the last mile: on a **tag/merge**, CI's signed artifact is **uploaded to a store track** — **Play Console tracks** (internal → closed/alpha → open/beta → production) or **App Store Connect / TestFlight** — via **Fastlane** (`supply`/`pilot`) or a mobile CI (Codemagic/Bitrise) built-in, with **automated version/build-number bumping**, **release notes/changelog**, and **staged (phased) rollout** (release to 1% → 100% of users, monitored) so a bad build affects few. Mobile is almost always **Continuous Delivery** (auto to beta, **manual/gated** promotion to production due to **store review** and business timing).

## Introduction

This file covers the CD half: uploading to store tracks, version/build-number management, release notes, staged rollout, and the mobile reality that production release is gated (review + timing). It completes the pipeline started by CI + signing ([ci_pipeline_and_automation.md](ci_pipeline_and_automation.md)/[build_signing_and_flavors.md](build_signing_and_flavors.md)) and precedes deployment specifics ([Module 51](../51%20Deployment/README.md)).

## Why this concept exists

Manual store uploads are slow, error-prone rituals (wrong version, missing notes, forgot a track). Automating release — upload, versioning, notes, staged rollout — makes shipping **routine, repeatable, and safe**, and staged rollout **contains blast radius** so a regression hits 1% not 100%. Mobile's store-review gate makes full Continuous Deployment rare, so the automation targets **beta tracks automatically + a gated production promotion**.

## Real-world analogy

CD is the **automated shipping + phased store rollout**: finished, sealed products (signed artifacts) are automatically sent to the **test shelf** (internal/beta) for staff/testers; a manager then **approves the retail launch**, which the system rolls out **gradually to stores** (1% of regions first, watching for complaints, then wider). Each shipment gets an **auto-incremented lot number** (version/build number) and a **what's-new note**. If early customers report a defect, you **halt the rollout** before it reaches everyone.

## Internal Working

```mermaid
flowchart TD
    Tag[trigger: tag/merge] --> Build[CI: build + sign artifact (flavor)]
    Build --> Version[auto bump version + build number]
    Version --> Upload[upload to store track (Fastlane/CI)]
    Upload --> Beta[beta track auto: Play internal / TestFlight]
    Beta --> Promote{manual gate: promote to production?}
    Promote -->|yes| Staged[staged/phased rollout: 1% -> ... -> 100% (monitored)]
    Staged --> Halt[halt/rollback if crashes spike]
    Note[mobile = Delivery: auto beta, gated prod (store review + timing)]
```

- **Store tracks (progressive exposure)**:
  - **Play Console**: **internal** (fastest, small team) → **closed/alpha** → **open/beta** → **production**. Promote up the tracks as confidence grows.
  - **App Store Connect**: **TestFlight** (internal + external beta testers) → **App Store** (production, after review).
  - CD **auto-uploads to beta** (internal/TestFlight); **production is a gated promotion**.
- **Upload automation**:
  - **Fastlane**: `supply` (Play upload/promote), `pilot` (TestFlight), `deliver` (App Store metadata/submit).
  - **Codemagic/Bitrise**: built-in publishing to Play/App Store tracks (less scripting).
  - Needs **store API credentials** (Play service-account JSON, App Store Connect API key) in **encrypted secrets** ([Module 37](../37%20Security/README.md)).
- **Versioning (automate it)**:
  - **`version` in `pubspec.yaml`** → `versionName+versionCode` (Android) / `CFBundleShortVersionString`+`CFBundleVersion` (iOS): a **user-facing version** (semver `1.2.0`) + a **monotonically increasing build number** (stores **reject duplicate build numbers**).
  - Automate the **build-number bump** (e.g., from CI run number / git commit count / date) so every upload is unique; bump the **semver version** per release (conventional commits/tags). Never upload a duplicate build number.
- **Release notes / changelog**: generate from **conventional commits**/PR titles or a maintained `CHANGELOG`; supply per-track/locale notes (Fastlane `supply`/`deliver` metadata). "What's new" is required for store releases.
- **Staged / phased rollout (containment)**:
  - **Play**: **staged rollout %** (e.g., 5% → 20% → 50% → 100%) — bad build reaches few; **halt** or **roll back** if metrics degrade.
  - **App Store**: **Phased Release** (automatic 7-day gradual rollout for auto-updates) + ability to pause.
  - Pair with **monitoring** (crash-free rate, errors — [Module 52](../52%20Monitoring/README.md)) to decide promote/halt.
- **The manual gate (mobile reality)**: production release is usually **manual/approved** (Continuous Delivery) because of **store review latency**, **release timing/marketing**, and **rollback difficulty on mobile** (users must update). CD automates everything **up to** that gate; the gate is a **one-click promotion**, not a manual build.
- **Rollback reality**: mobile can't instantly roll back a deployed build (users have it) — mitigations: **staged rollout + halt**, **server-side feature flags/kill switches**, **hotfix + expedited release**. Design for **forward-fix**, not easy rollback.
- **Release triggers**: **tag** (`v1.2.0`) → production pipeline; **merge to main** → beta; keeps release intentional + traceable.

## Memory Representation

Not runtime — a **release pipeline** (build → version → upload → track → rollout) + release metadata (version, build number, notes, rollout %). Store-side: tracks with staged-rollout state; monitoring feeds promote/halt decisions.

## Compiler / Build Behavior

CD consumes the signed artifact from CI ([build_signing_and_flavors.md](build_signing_and_flavors.md)); version/build number are set at build (via `--build-name`/`--build-number` or pubspec) and embedded in the artifact.

## Runtime Behavior

Beta uploads are automatic; production is gated then rolled out gradually; a bad release can be **halted** at a low % before wide exposure. Users receive the update progressively (auto-update/phased).

## Flutter Engine Behavior

Not applicable (store distribution). The shipped artifact runs normally per flavor.

## Dart VM Behavior

Not applicable.

## Examples

```ruby
# Fastlane — auto-bump build number, upload to beta, staged production promote
lane :beta do
  build_number = number_of_commits            # unique, monotonic
  build_app(scheme: "prod")
  upload_to_testflight(build_number: build_number)      # iOS beta
  # Android beta: supply(track: 'internal', aab: '...')
end
lane :production do
  supply(track: 'production', rollout: '0.05')  # Play staged rollout 5%
  # promote later: supply(track: 'production', rollout: '1.0') after monitoring
end
```

```yaml
# CI release job (on tag) — build signed, bump build number, deploy to beta
on: { push: { tags: ['v*'] } }
steps:
  - run: flutter build appbundle --release --flavor prod \
         --build-name=${{ github.ref_name }} --build-number=${{ github.run_number }}
  - run: bundle exec fastlane beta         # upload to Play internal / TestFlight
# production promotion = manual approval step (environment protection) -> staged rollout
```

```text
Release flow (Continuous Delivery, mobile):
  tag v1.2.0 -> CI build+sign -> auto build-number bump -> upload BETA (internal/TestFlight)
  -> [MANUAL one-click promote] -> PRODUCTION staged rollout 5% -> monitor -> 20% -> ... -> 100%
  (halt/rollback via rollout pause + feature flags if crash-free rate drops)
```

## Diagrams

```mermaid
flowchart LR
    CI3[signed artifact] --> Ver[auto version/build-number bump]
    Ver --> BetaT[auto upload -> beta track]
    BetaT --> Gate2[manual promote gate]
    Gate2 --> Rollout[staged rollout 5%->100% (monitored)]
    Rollout --> Halt2[halt/forward-fix if metrics degrade]
```

## Common Mistakes

| Mistake | Why it's a problem | Fix |
|---------|-------------------|-----|
| Duplicate build number | Store rejects upload | Auto-bump unique monotonic build number |
| Full 100% release immediately | Bad build hits everyone | Staged/phased rollout + monitor |
| Manual store uploads | Slow/error-prone ritual | Automate (Fastlane/CI publishing) |
| Auto-deploy straight to prod (mobile) | Ignores review/timing/rollback | Continuous Delivery: gated prod promotion |
| No release notes/changelog | Store requires "what's new" | Generate from commits/CHANGELOG |
| Expecting easy rollback | Users already have the build | Staged rollout + flags + forward-fix |
| Store credentials in repo | Security breach | Encrypted secrets (service account/API key) |
| No monitoring during rollout | Can't detect a bad release | Watch crash-free rate; halt if degraded |

## Best Practices

- Automate **upload to beta tracks** (Play internal / TestFlight) on merge/tag via **Fastlane (`supply`/`pilot`)** or CI built-ins; **gate production** as a **one-click promotion** (Continuous Delivery — store review/timing).
- **Auto-bump a unique monotonic build number** (CI run/commit count) + semver `version`; **never upload a duplicate build number**; generate **release notes** from commits/CHANGELOG.
- Use **staged/phased rollout** (5% → 100%) with **monitoring** (crash-free rate — [Module 52](../52%20Monitoring/README.md)) and **halt** on degradation; design for **forward-fix + feature flags/kill switches** (mobile rollback is hard).
- Store **store API credentials in encrypted secrets**; trigger production releases from **tags** for traceability.

## Performance

Not runtime perf; the concern is **release safety + speed**: automation removes slow manual steps, and staged rollout **contains blast radius** (a bad build monitored at 5% beats a 100% incident). Monitoring-driven promote/halt is the safety mechanism ([Module 52](../52%20Monitoring/README.md)).

## Advantages / Disadvantages

- **+** Fast, repeatable releases; automatic beta distribution; safe production via staged rollout + monitoring; auto versioning/notes; traceable (tag-triggered).
- **−** Mobile can't easily roll back (forward-fix), store-review latency/gate, store-credential + metadata setup, staged-rollout monitoring discipline.

## Interview Questions

1. **🟢 What are the store tracks, and how does CD use them?** — Play: internal→closed/alpha→open/beta→production; App Store: TestFlight→App Store. CD auto-uploads to beta; production is a gated promotion.
2. **🟢 Why is mobile usually Continuous Delivery, not Deployment?** — Store review latency, release timing, and hard rollback make production a gated (manual one-click) promotion rather than fully automatic.
3. **🟡 Why must the build number auto-increment, and how?** — Stores reject duplicate build numbers; derive it from CI run number/commit count/date so each upload is unique + monotonic.
4. **🟡 What is staged/phased rollout and why use it?** — Releasing to a growing % of users (5%→100%) while monitoring, so a bad build reaches few and can be halted — blast-radius containment.
5. **🟡 How do you automate store uploads?** — Fastlane (`supply` for Play, `pilot`/`deliver` for App Store) or Codemagic/Bitrise built-ins, using store API credentials from encrypted secrets.
6. **🔴 How do you handle a bad release given mobile can't easily roll back?** — Staged rollout + halt, server-side feature flags/kill switches, and a forward-fix (hotfix + expedited release) — plan for forward-fix, not rollback.
7. **🔴 What triggers a production release, and why?** — A version tag (`v1.2.0`) → the production pipeline (after a manual promote), keeping releases intentional + traceable.

## Senior Engineer Tips

- Automate to beta, gate to production: wire tag→beta automatically and make prod a one-click promote with a staged rollout; that's the safe, standard mobile CD shape.
- Auto-bump a unique build number from the CI run/commit count and never think about it again; duplicate-build-number rejections are a needless recurring release failure.
- Always release staged + monitored and design for forward-fix (flags/kill switches + hotfix path); assuming you can "just roll back" a mobile release is how a 5% issue becomes a 100% incident.

## Architect Perspective

CD/release automation is the last mile that makes shipping routine and safe: signed artifacts flow automatically to beta with auto-versioning/notes, production is a gated one-click promotion, and staged rollout + monitoring contain risk in a world where rollback is hard. Embracing Continuous Delivery (not Deployment) for mobile, with forward-fix and feature-flag strategies, turns releases from fragile rituals into a controlled, observable process — the culmination of the CI/signing pipeline and the handoff to deployment + monitoring ([ci_pipeline_and_automation.md](ci_pipeline_and_automation.md), [Module 51](../51%20Deployment/README.md), [Module 52](../52%20Monitoring/README.md)).

## Summary

- CD auto-uploads signed artifacts to beta tracks (Play internal/TestFlight) via Fastlane/CI, with auto build-number bump + release notes; production is a gated one-click promotion (mobile = Continuous Delivery).
- Use staged/phased rollout (5%→100%) with monitoring + halt; design for forward-fix + feature flags/kill switches (mobile rollback is hard).
- Store credentials in encrypted secrets; trigger production from tags for traceability.

## Revision Notes

- Tracks: Play internal→closed/alpha→open/beta→production; App Store TestFlight→production. CD: auto beta, gated (manual one-click) prod (store review/timing) = Continuous Delivery.
- Upload: Fastlane `supply`(Play)/`pilot`+`deliver`(App Store) or Codemagic/Bitrise built-in; store API creds (Play service-account JSON / ASC API key) in encrypted secrets.
- Versioning: pubspec `version` → versionName+versionCode/CFBundle*; auto-bump unique monotonic build number (CI run/commit count); never duplicate. Release notes from commits/CHANGELOG.
- Staged rollout 5%→100% + monitoring (crash-free) + halt; mobile rollback hard → forward-fix + feature flags/kill switches; production triggered by tag.

## Practice Questions

1. Why is production release gated (Delivery) on mobile?
2. How and why do you auto-increment build numbers?
3. How do you contain the risk of a bad release given hard rollback?

## Coding Questions

1. Write a Fastlane lane uploading to a beta track with an auto build number.
2. Configure a staged production rollout (e.g., Play 5%) + promotion step.
3. Add a CI release job (tag-triggered) that builds signed + deploys to beta with a manual prod gate.

## Mini Project

**Release automation (Flutter/CI-CD):** Design a CD flow: on tag, CI builds a signed prod artifact with an auto-bumped unique build number + generated release notes, uploads to beta (Play internal/TestFlight) automatically, and gates production behind a manual one-click promotion that does a **staged rollout** (5%→100%) with crash-free-rate monitoring + halt — using Fastlane (`supply`/`pilot`) and store credentials from encrypted secrets. Note the forward-fix/feature-flag rollback strategy. Acceptance: auto beta upload + gated prod (Continuous Delivery); unique monotonic build number + release notes; staged rollout + monitoring + halt; credentials in encrypted secrets; forward-fix/flags rollback plan; tag-triggered + traceable.
