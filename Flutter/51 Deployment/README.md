# 51 · Deployment

## Introduction

This module covers **shipping a Flutter app to production**: the **fundamentals** (release channels, store overview, versioning), **store setup & submission** (Play Console / App Store Connect — listings, metadata, assets, build upload), the **review process & compliance** (how review works, common rejections, privacy/policy requirements), and **app-size & build optimization** (App Bundle/thinning, obfuscation, shrinking the download), tied together in a **full release + post-launch** capstone. It's the last mile after CI/CD ([Module 50](../50%20CI%20CD/README.md)) and the handoff to monitoring ([Module 52](../52%20Monitoring/README.md)).

## Why this module exists

Getting an app *into users' hands* is a distinct discipline from building it: the stores have their own **setup, metadata, assets, review, and policy** requirements, releases must be **versioned and staged** correctly, rejected submissions cost days, and a bloated download hurts installs/conversion. Knowing the **store processes, compliance rules, and size-optimization levers** — plus post-launch practices — is what turns a finished build into a live, discoverable, compliant, well-performing product.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [01_deployment_fundamentals.md](01_deployment_fundamentals.md) | Release channels, store overview, versioning, release strategy | 🔵 |
| 2 | [02_store_setup_and_submission.md](02_store_setup_and_submission.md) | Play Console / App Store Connect setup, listing, metadata, assets, upload | 🟡 |
| 3 | [03_review_process_and_compliance.md](03_review_process_and_compliance.md) | Review process, common rejections, privacy/policy compliance | 🔴 |
| 4 | [04_app_size_and_build_optimization.md](04_app_size_and_build_optimization.md) | App Bundle/thinning, obfuscation, size reduction, release build | 🔴 |
| 5 | [05_deployment_integration.md](05_deployment_integration.md) | Capstone: full release checklist + post-launch | 🟡 |

> **Cross-references:** CI/CD (automates build/upload): [Module 50](../50%20CI%20CD/README.md). Monitoring (post-launch): [Module 52](../52%20Monitoring/README.md). Signing/flavors: [50 · build_signing](../50%20CI%20CD/03_build_signing_and_flavors.md). App size/startup: [Module 21](../21%20Performance/README.md). Security/privacy: [Module 37](../37%20Security/README.md). Native config: [Module 27](../27%20Native%20Android/README.md)/[Module 28](../28%20Native%20iOS/README.md). Payments policy: [Module 31](../31%20Payments/README.md).

## Prerequisites

[50 CI CD](../50%20CI%20CD/README.md) (signing/build/release automation), native build config ([27](../27%20Native%20Android/README.md)/[28](../28%20Native%20iOS/README.md)), [21 Performance](../21%20Performance/README.md) (app size).

## What you'll be able to do after this module

- Explain release channels, store distribution, and versioning strategy.
- Set up Play Console / App Store Connect listings with correct metadata + assets and upload builds.
- Navigate the review process, avoid common rejections, and meet privacy/policy requirements.
- Reduce app size (App Bundle/thinning/obfuscation) and produce optimized release builds.
- Run a full release (checklist + staged rollout) and handle post-launch.

## Capstone

**Release + post-launch:** Take an app to production — configure the store listing (metadata, screenshots, privacy details, content rating), upload a signed optimized App Bundle/IPA, submit for review with a compliance checklist, do a staged rollout, and set up post-launch practices (monitoring, responding to reviews, hotfix process) — as a documented release runbook.

## Summary

Deployment is the last mile: version and channel your release, set up compliant store listings with metadata/assets, pass review (avoiding common rejections + meeting privacy/policy), ship an optimized (App Bundle/thinned/obfuscated) build via staged rollout, and run post-launch practices. It turns a finished, CI/CD-built app into a live, discoverable, compliant product.
