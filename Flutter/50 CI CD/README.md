# 50 · CI/CD

## Introduction

This module covers **Continuous Integration & Continuous Delivery/Deployment** for Flutter: the **fundamentals** (what CI/CD is, pipeline stages, principles), building a **CI pipeline** (automated analyze/test/build on every change — GitHub Actions/Codemagic, caching, monorepo/melos), **build signing & flavors/environments** (Android keystore, iOS certs/provisioning, Fastlane, dev/staging/prod flavors), and **CD release automation** (deploying to Play/App Store tracks, staged rollout, versioning), tied together in a capstone. It operationalizes testing ([Module 49](../49%20Testing/README.md)), deployment ([Module 51](../51%20Deployment/README.md)), and the whole build/release workflow.

## Why this module exists

Manual build/test/release is slow, error-prone, and doesn't scale: bugs slip in without automated checks, releases are risky rituals, and signing/store steps are fragile. **CI/CD automates the path from commit to production** — running analyze/test/build on every change (CI), and packaging/signing/releasing automatically (CD) — so teams ship **faster, safer, and repeatably**. It's the delivery backbone that makes testing enforceable, releases routine, and scaling teams possible.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [cicd_fundamentals.md](cicd_fundamentals.md) | What CI/CD is, pipeline stages, principles | 🔵 |
| 2 | [ci_pipeline_and_automation.md](ci_pipeline_and_automation.md) | CI: analyze/test/build automation, GH Actions/Codemagic, caching, monorepo | 🔴 |
| 3 | [build_signing_and_flavors.md](build_signing_and_flavors.md) | Code signing (keystore/certs), flavors/environments, Fastlane | 🔴 |
| 4 | [cd_release_automation.md](cd_release_automation.md) | CD: store/track release, staged rollout, versioning | 🔴 |
| 5 | [cicd_integration.md](cicd_integration.md) | Capstone: a full commit→store pipeline | 🔴 |

> **Cross-references:** Testing (what CI runs): [Module 49](../49%20Testing/README.md). Deployment/stores: [Module 51](../51%20Deployment/README.md). Monitoring (post-release): [Module 52](../52%20Monitoring/README.md). Modular/monorepo (incremental CI): [Module 45](../45%20Modular%20Architecture/README.md). Security (secrets/signing): [Module 37](../37%20Security/README.md). Native config (Android/iOS build): [Module 27](../27%20Native%20Android/README.md)/[Module 28](../28%20Native%20iOS/README.md).

## Prerequisites

[49 Testing](../49%20Testing/README.md), native build config ([27](../27%20Native%20Android/README.md)/[28](../28%20Native%20iOS/README.md)), git/branching basics, [45 Modular Architecture](../45%20Modular%20Architecture/README.md) (monorepo CI).

## What you'll be able to do after this module

- Explain CI/CD, pipeline stages, and the principles behind them.
- Build a CI pipeline (analyze/test/build) with caching and (monorepo) incremental runs.
- Manage code signing (Android keystore, iOS certs) and dev/staging/prod flavors securely.
- Automate releases to Play/App Store tracks with staged rollout and versioning.
- Assemble a full commit→store pipeline with the right gates and secrets handling.

## Capstone

**Full pipeline:** A CI/CD pipeline (GitHub Actions or Codemagic) that on PRs runs `flutter analyze` + tests (incremental via `melos --since` for a monorepo) with caching and merge gating; on tags/merges builds signed release artifacts per flavor (secure keystore/cert secrets), and deploys to internal/beta tracks (Play internal / TestFlight) with staged rollout + auto version bump — documented with the secrets/signing and branching strategy.

## Summary

CI/CD automates commit→production: CI runs analyze/test/build on every change (fast feedback, merge gating); CD packages/signs/releases automatically (repeatable, staged). With caching, flavors, secure signing, and store automation (GH Actions/Codemagic/Fastlane), it lets teams ship faster and safer — the delivery backbone atop testing and deployment.
