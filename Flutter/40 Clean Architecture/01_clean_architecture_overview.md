# Clean Architecture Overview (Layers & the Dependency Rule)

> Clean Architecture organizes code into concentric layers — **domain** (innermost: entities + business rules), **application/use cases**, and outer **data** and **presentation** — governed by one rule: **the Dependency Rule — source-code dependencies point only inward.** The domain knows nothing of Flutter, HTTP, or SQLite; outer layers depend on inner **abstractions** (interfaces), never the reverse. This keeps business logic **independent, testable, and swappable** — you can change the UI framework, network client, or database without touching the core. Apply it **proportionally**: full ceremony for complex, long-lived apps; lighter for simple ones.

## Introduction

This file establishes the mental model: the layers, the dependency rule (and its DIP underpinning), what "independent domain" buys you, and the honest tradeoffs (boilerplate vs longevity). Everything else in the module is an implementation of these principles.

## Why this concept exists

Without boundaries, business rules get entangled with UI widgets and I/O, so a change to the API or a swap of state library ripples through the whole app, and nothing can be tested without a device/network. Clean Architecture (Uncle Bob's synthesis of hexagonal/onion/ports-and-adapters) makes the **policy** (business rules) independent of the **details** (frameworks, DB, UI), so details can change without disturbing policy.

## Real-world analogy

Think of a **power tool with swappable attachments**: the **motor (domain)** is the valuable core; the **attachments (UI, DB, network)** plug into a **standard socket (interfaces)**. The motor doesn't know or care which attachment is fitted — you can swap a drill bit for a sander (change the database, or Flutter for another UI) without rebuilding the motor. The dependency rule is that **attachments fit the motor's socket**, never the motor reshaped to fit an attachment.

## Problem Statement

For a feature, decide what belongs in each layer, ensure the domain has **zero** framework/IO imports, make outer layers depend on domain **interfaces** (not concretes), and justify when this structure is worth its cost. You'll map responsibilities and enforce the dependency direction.

## Internal Working

```mermaid
flowchart TD
    subgraph Outer
      Pres[Presentation: widgets, state/view models]
      Data[Data: repository impls, data sources, DTOs]
    end
    subgraph Inner [Domain (pure, independent)]
      UC[Use cases (application rules)]
      Ent[Entities (enterprise rules)]
      IF[Repository interfaces]
    end
    Pres -->|depends on| UC
    UC --> Ent
    UC --> IF
    Data -->|implements| IF
    Note[Dependencies point INWARD; domain imports nothing outward]
```

- **Layers (inner → outer)**:
  - **Entities** (enterprise business rules): core domain objects + invariants, the most stable, framework-free.
  - **Use cases / interactors** (application business rules): orchestrate entities to fulfill one app-specific action (`GetProfile`, `PlaceOrder`); depend on **repository interfaces**.
  - **Interface adapters** (data + presentation): **repositories** (impl the domain interfaces, map DTOs↔entities) and **presenters/state** (map domain↔UI).
  - **Frameworks & drivers** (outermost): Flutter, `dio`, `sqflite`, Firebase — the volatile details.
- **The Dependency Rule (the whole point)**: **source dependencies point inward only.** Domain has **no imports** of Flutter/HTTP/DB. Outer layers depend on **inner abstractions** (repository *interfaces* defined in the domain), realized by **Dependency Inversion** ([Module 04](../04%20SOLID%20Principles/README.md)) — the domain declares *what* it needs; the data layer provides *how*.
- **Independence buys**: **testability** (domain/use cases unit-tested with fakes, no device/network), **flexibility** (swap DB/network/UI/state lib without touching domain), **clarity** (business rules in one framework-free place), **longevity** (details churn; policy stays).
- **Crossing boundaries with data**: pass **simple data structures** (entities/DTOs), not framework objects, across boundaries; **map** at the edges (DTO↔entity, entity↔view state) so no layer leaks another's types.
- **Where things go**: business rule → domain; JSON/SQL/HTTP → data; widgets/state → presentation. If the domain imports `package:flutter` or `dio`, the rule is broken.
- **Proportionality (be honest)**: full Clean Architecture adds layers/boilerplate/mapping — worth it for **complex, long-lived, team** apps; **overkill** for a small prototype. Scale the ceremony to the app ([05_clean_architecture_integration.md](05_clean_architecture_integration.md)).

## Memory Representation

Not a runtime structure — a **source-dependency graph**. The invariant is directional: inner layers have no edges to outer ones. Data crossing boundaries is plain objects (entities/DTOs), not framework handles.

## Compiler Behavior

The rule is enforceable at **compile time**: the domain package/folder simply doesn't import Flutter/data packages (tools/linters can assert import boundaries). If it compiles without those imports, the core is independent.

## Runtime Behavior

At runtime, DI wires concrete data/presentation implementations to domain interfaces; calls flow outward→inward (UI → use case → repository interface → impl) while **dependencies** (compile-time) point inward.

## Flutter Engine Behavior

Flutter lives only in the **presentation/outermost** layer; the domain runs on plain Dart (testable in a pure Dart VM, no widget binding).

## Dart VM Behavior

Domain/use-case tests run as fast pure-Dart unit tests (no Flutter binding), because the domain has no framework dependency — a direct benefit of the rule.

## Examples

```dart
// DOMAIN (pure Dart — NO Flutter/dio/sqflite imports)
class Profile { final String id, name; const Profile(this.id, this.name); } // entity

abstract class ProfileRepository {                 // interface lives in the domain
  Future<Result<Profile>> getProfile(String id);
}

class GetProfile {                                 // use case: one app action
  final ProfileRepository repo;                    // depends on the ABSTRACTION
  GetProfile(this.repo);
  Future<Result<Profile>> call(String id) => repo.getProfile(id);
}
```

```dart
// DATA (outer) — implements the domain interface; may import dio/sqflite
class ProfileRepositoryImpl implements ProfileRepository {  // dependency points inward
  final ProfileRemote remote;                              // detail
  ProfileRepositoryImpl(this.remote);
  @override
  Future<Result<Profile>> getProfile(String id) async {
    final dto = await remote.fetch(id);                    // DTO (data-layer type)
    return Success(dto.toEntity());                        // map DTO -> entity at the edge
  }
}
// PRESENTATION (outer) depends on GetProfile (domain), never on ProfileRepositoryImpl directly.
```

## Diagrams

```mermaid
flowchart LR
    UI[Presentation] --> UseCase[Use case (domain)]
    UseCase --> Interface[Repository interface (domain)]
    Impl[Repository impl (data)] -. implements .-> Interface
    Impl --> Sources[remote/local data sources (details)]
    style Interface fill:#eef
    style UseCase fill:#eef
```

## Common Mistakes

| Mistake | Why it breaks Clean Arch | Fix |
|---------|--------------------------|-----|
| Domain imports Flutter/`dio`/`sqflite` | Couples policy to details | Keep domain pure; abstractions only |
| Use case depends on a concrete repo | Violates dependency rule/DIP | Depend on the interface |
| Passing DTOs/framework objects to UI | Leaks data-layer types inward/upward | Map DTO↔entity↔view state at edges |
| Business rules in widgets/repos | Untestable, tangled | Rules in domain (entities/use cases) |
| Interface defined in the data layer | Dependency points outward | Define interfaces in the domain |
| Full ceremony on a tiny app | Needless boilerplate | Scale to complexity |
| Anemic use cases that just pass through | Ceremony w/o value | Add real orchestration or simplify |

## Best Practices

- Keep the **domain pure** (no Flutter/IO imports) — entities, use cases, and repository **interfaces** only; enforce the **dependency rule** (inward-only) via **DIP**.
- **Define interfaces in the domain**, implement them in **data**; cross boundaries with **plain data** (entities/DTOs) and **map at the edges** so no layer leaks types.
- Put **business rules in the domain**, **I/O in data**, **UI/state in presentation**; keep use cases meaningful (real orchestration), not empty pass-throughs.
- **Scale ceremony to complexity** — full structure for complex/long-lived/team apps, lighter for simple ones; verify independence by unit-testing the domain with no device/network.

## Performance

No runtime cost — it's a compile-time/source-organization concern. Indirection (interfaces/mapping) is negligible. The "cost" is developer time (boilerplate/mapping); the payoff is testability + change-resilience, which is why proportionality matters.

## Advantages / Disadvantages

- **+** Independent, testable domain; swap details (DB/network/UI/state) freely; clear separation; long-lived; team-scalable.
- **−** Boilerplate + mapping + more files; overkill for simple apps; learning curve; risk of anemic/ceremonial layers if misapplied.

## Interview Questions

1. **🟢 What is the Dependency Rule?** — Source-code dependencies point only inward; inner layers (domain) know nothing of outer layers (Flutter/DB/network).
2. **🟢 What are the layers?** — Entities → use cases (domain) → interface adapters (data + presentation) → frameworks/drivers (outermost).
3. **🟡 How is the dependency rule enforced technically?** — Via Dependency Inversion: the domain defines repository interfaces; the data layer implements them, so the domain imports nothing outward.
4. **🟡 Why must the domain be framework-free?** — So business rules are testable without a device/network and independent of UI/DB/network churn.
5. **🟡 How does data cross boundaries?** — As plain data (entities/DTOs), mapped at the edges (DTO↔entity↔view state) — no framework objects leak across layers.
6. **🔴 When is Clean Architecture overkill?** — For small/short-lived apps where the boilerplate/mapping cost outweighs the testability/flexibility benefit — scale ceremony to complexity.
7. **🔴 How do runtime call flow and compile-time dependencies differ?** — Calls flow outward→inward (UI→use case→repo impl), while source dependencies point inward (impl depends on the domain interface, wired by DI).

## Senior Engineer Tips

- The one rule that matters: the domain folder imports neither Flutter nor any data package — if it does, you don't have Clean Architecture, you have layers-in-name-only.
- Define repository interfaces in the domain and let DI supply implementations; this single inversion is what makes the whole thing testable and swappable.
- Right-size it: reach for the full structure on complex, long-lived, multi-dev apps, and a lighter version elsewhere — ceremony without payoff is just cost.

## Architect Perspective

Clean Architecture is DIP applied at the module scale: policy (domain) is stable and independent; details (frameworks/DB/UI) are plugins behind interfaces. This is the backbone the rest of the architecture band elaborates — MVVM/feature-first/DDD are variations on the same boundary discipline — and it's what makes large Flutter apps testable, evolvable, and team-scalable. Applied proportionally, it's the difference between software that lasts and software that ossifies ([Module 04](../04%20SOLID%20Principles/README.md), [02_domain_layer.md](02_domain_layer.md), [Module 46](../46%20Domain%20Driven%20Design/README.md)).

## Summary

- Layers: entities → use cases (domain) → data + presentation (adapters) → frameworks (outer); the **Dependency Rule** points inward only.
- Keep the domain pure (no Flutter/IO), define interfaces in the domain (DIP), map plain data at boundaries — buying testability, flexibility, longevity.
- No runtime cost; boilerplate cost → apply proportionally to app complexity.

## Revision Notes

- Layers (in→out): Entities, Use cases (domain), Interface adapters (data/presentation), Frameworks/drivers. Dependency Rule = inward only.
- Domain = pure Dart (no Flutter/dio/sqflite); interfaces defined in domain, implemented in data (DIP); cross boundaries with plain data + map at edges.
- Benefits: testable/independent domain, swappable details, longevity; cost: boilerplate/mapping → scale to complexity; enforced at compile time (imports).

## Practice Questions

1. State the dependency rule and how DIP enforces it.
2. Why can the domain be tested without a device or network?
3. When would you *not* use full Clean Architecture?

## Coding Questions

1. Sketch a pure domain (entity + use case + repository interface) with no framework imports.
2. Implement the interface in a data class that may import `dio`.
3. Identify and fix a dependency-rule violation (domain importing Flutter).

## Mini Project

**Layer map + dependency check (Flutter):** For a feature, produce a layer map (what goes in domain/data/presentation), implement a pure domain (entity + use case + repository interface) and a data impl of the interface, and verify the domain compiles with **no** Flutter/data imports (unit-tested in pure Dart). Write a short tradeoff note on when this structure is worth it. Acceptance: correct per-layer responsibilities; dependency rule holds (domain pure, interfaces in domain, impl inward); data crosses boundaries as plain types; domain unit-tested without device/network; proportionality justified.
