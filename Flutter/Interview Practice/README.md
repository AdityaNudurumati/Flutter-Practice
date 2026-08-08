# Interview Practice — Flutter/Dart Question Bank

> A consolidated, **topic-wise** interview question bank spanning **🟢 Basic → 🟡 Intermediate → 🔴 Advanced**, with crisp model answers. Complements the per-file *Interview Questions* sections in the [handbook modules](../00%20Repository%20Guide/README.md) by pulling everything into a single drill-ready place.

## How to use this

1. **Pick a topic file** below matching what you're revising or what the role emphasizes.
2. Read top-to-bottom: each file goes **Basic → Intermediate → Advanced**, so you always know your depth.
3. **Answer out loud first**, then check the model answer. Interviews test articulation, not recognition.
4. For depth on any answer, follow the cross-link to the matching handbook module.
5. The night before an interview: skim **[19_rapid_fire_mixed.md](19_rapid_fire_mixed.md)** and the Advanced tier of your target topics.

## Difficulty legend

| Tag | Level | Who it's for |
|-----|-------|--------------|
| 🟢 | **Basic** | 0–1.5 yrs · fundamentals, definitions, "what is X" |
| 🟡 | **Intermediate** | 1.5–4 yrs · "how does X work", tradeoffs, common bugs |
| 🔴 | **Advanced** | 4+ yrs / senior · internals, scaling, design, "why" and "when NOT" |

## Topic index

| # | File | Covers | Handbook modules |
|---|------|--------|------------------|
| 01 | [01_dart_core.md](01_dart_core.md) | Types, null safety, collections, functions, records & patterns | 01 |
| 02 | [02_dart_advanced_async.md](02_dart_advanced_async.md) | Futures, async/await, Streams, isolates, event loop, generics, mixins | 02 |
| 03 | [03_oop_solid_patterns.md](03_oop_solid_patterns.md) | OOP, SOLID, GoF design patterns in Dart | 03, 04, 05 |
| 04 | [04_flutter_internals.md](04_flutter_internals.md) | Widget/Element/RenderObject trees, BuildContext, keys, how Flutter runs | 06, 10 |
| 05 | [05_widgets_layout_lifecycle.md](05_widgets_layout_lifecycle.md) | Widgets, layout & constraints, Stateless/Stateful, State lifecycle | 07, 08 |
| 06 | [06_rendering_performance.md](06_rendering_performance.md) | Rendering pipeline, repaint boundaries, jank, performance tuning | 09, 21 |
| 07 | [07_state_management.md](07_state_management.md) | setState, Provider, Riverpod, BLoC/Cubit, GetX, selection | 11 |
| 08 | [08_navigation_routing.md](08_navigation_routing.md) | Navigator 1.0/2.0, go_router, deep links, guards | 12, 13 |
| 09 | [09_networking_data_storage.md](09_networking_data_storage.md) | REST/GraphQL, JSON, storage, SQLite/Drift/Hive, offline, caching | 15, 16, 19, 20 |
| 10 | [10_dependency_injection.md](10_dependency_injection.md) | DI principles, get_it/injectable, provider/riverpod as DI, testing | 14 |
| 11 | [11_animations_custom_ui.md](11_animations_custom_ui.md) | Implicit/explicit/physics animations, CustomPainter, responsive/adaptive | 22, 23, 24, 25 |
| 12 | [12_architecture.md](12_architecture.md) | Clean, MVC/MVP/MVVM, feature-first, modular, DDD, scalable | 40–47 |
| 13 | [13_testing.md](13_testing.md) | Unit/widget/integration/golden, mocking, TDD | 49 |
| 14 | [14_platform_native_device.md](14_platform_native_device.md) | Platform channels, FFI, native Android/iOS, device, notifications, background | 26–33 |
| 15 | [15_security_error_logging.md](15_security_error_logging.md) | Security, secure storage, error handling, logging | 37, 38, 39 |
| 16 | [16_system_design_mobile.md](16_system_design_mobile.md) | Mobile HLD/LLD, scenario design, scaling a Flutter app | 48 |
| 17 | [17_cicd_deployment_monitoring.md](17_cicd_deployment_monitoring.md) | CI/CD, flavors, signing, store release, monitoring | 50, 51, 52 |
| 18 | [18_behavioral_and_scenarios.md](18_behavioral_and_scenarios.md) | Behavioral, situational, ownership, mentoring, conflict | 58, 60 |
| 19 | [19_rapid_fire_mixed.md](19_rapid_fire_mixed.md) | One-line rapid-fire + mixed mock rounds across topics | all |

## Company focus (quick map)

- **Product companies (Google/Uber/Atlassian):** heavy on 04, 06, 12, 16 + 18.
- **Fintech (Razorpay/PhonePe/CRED):** heavy on 09, 15, 13, 12.
- **Consumer/social (Swiggy/Flipkart/Airbnb):** heavy on 06, 07, 11, 14.

> Company-specific and format-specific prep (rounds, timing, machine-coding) lives in handbook modules **[55 Flutter Interview Preparation](../55%20Flutter%20Interview%20Preparation/README.md)** and **[56 Machine Coding Rounds](../56%20Machine%20Coding%20Rounds/README.md)**. This folder is the **topic drill**; those are the **format drill**.

## Summary

- 19 topic files, each **Basic → Intermediate → Advanced**, model answers included.
- Consolidated drill companion to the per-module interview sections.
- Pair with Modules 55/56 for format/company prep.
