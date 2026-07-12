# Integration Patterns & Case Studies

> Enterprise apps rarely talk to one clean backend — they integrate with **SSO** (SAML/OIDC identity providers), **multiple backends/microservices** (a BFF or aggregation layer helps), **legacy systems** (odd formats/protocols), and **many third-party services** (payments, analytics, maps, CRMs). The discipline: **wrap every external system behind an interface + an Anti-Corruption Layer (ACL)** so its model/quirks never leak into your clean domain — the client depends on **your abstractions**, adapters translate to each system, and you can swap/version integrations without ripple. This file also walks **case-study architectures** (B2B multi-tenant, super-app, offline-heavy field app) showing how the handbook's pieces + these integration patterns combine in practice.

## Introduction

This file covers enterprise integration patterns (SSO, multi-backend/BFF, legacy via ACL, third-party) and how to keep them from corrupting the domain, then illustrates with real-world case-study architectures. It applies networking ([Module 16](../16%20Networking/README.md)), auth ([Module 17](../17%20Authentication/README.md)), DDD's ACL ([Module 46](../46%20Domain%20Driven%20Design/README.md)), and the enterprise structure ([02_enterprise_architecture_and_structure.md](02_enterprise_architecture_and_structure.md)).

## Why this concept exists

Enterprise systems are heterogeneous + long-lived; integrations are numerous, messy, and change independently. Without disciplined boundaries, external models/quirks (a legacy SOAP schema, a vendor's oddities) **leak into your domain**, coupling you to systems you don't control and making change/replacement painful. The **interface + ACL/adapter** pattern isolates your clean domain from that mess — the core enterprise-integration skill.

## Real-world analogy

Integrations are like a company dealing with **many outside suppliers, some using ancient fax-based ordering (legacy), some via a modern portal (SSO/API)**. You don't let each supplier's weird process invade your internal operations — you have a **procurement department (ACL/adapters)** that speaks each supplier's language externally and hands your internal teams a **clean, standard order** internally. Swap a supplier and only procurement changes; operations are untouched.

## Internal Working

```mermaid
flowchart TD
    Domain[your clean domain (depends on interfaces)] --> IF[integration interfaces (contracts)]
    IF --> ACL{Anti-Corruption Layer / adapters}
    ACL --> SSO[SSO: SAML/OIDC identity provider]
    ACL --> Multi[multiple backends/microservices (via BFF/aggregation)]
    ACL --> Legacy[legacy systems (odd formats/protocols)]
    ACL --> ThirdParty[third-party services (payments/analytics/maps/CRM)]
    Note[external models/quirks translated at the ACL -> never leak into the domain; swap/version without ripple]
```

- **The core pattern — interface + Anti-Corruption Layer (ACL)** ([Module 46](../46%20Domain%20Driven%20Design/README.md)/[Module 40](../40%20Clean%20Architecture/README.md)):
  - Define **integration interfaces** (contracts) your domain depends on; implement each with an **adapter** that talks to the external system and **translates its model → your domain model** (and quirks/errors → your types). The **ACL** is the translation boundary that **protects your domain** from foreign concepts.
  - Result: the domain is **decoupled** from external systems; you can **swap/version** an integration (change vendor, migrate a legacy system) by changing only its adapter.
- **SSO (Single Sign-On)** ([Module 17](../17%20Authentication/README.md)/[Module 37](../37%20Security/README.md)):
  - Enterprise auth is usually **federated**: **OIDC/OAuth2** (+ PKCE) or **SAML** against a corporate **identity provider** (Okta/Azure AD/Auth0/Keycloak). The app redirects to the IdP, receives tokens, and maps IdP claims → your **session + roles (RBAC)**. Wrap behind an **`AuthService`** so features don't know the IdP specifics; handle token refresh/logout/session.
- **Multiple backends / microservices**:
  - Enterprise data spans many services. Options: call each directly (chatty, couples client to service topology) **or** use a **Backend-for-Frontend (BFF)/aggregation layer** that composes services into client-shaped responses (fewer round-trips, insulates the client from service churn — [Module 48](../48%20System%20Design/README.md)). The client's **repositories** hide which backend(s) serve the data.
- **Legacy systems**:
  - Old systems (SOAP/XML, unusual protocols, inconsistent data) are a classic enterprise reality. **Never let their model leak in** — wrap them behind an **adapter/ACL** that translates to clean domain types (ideally the legacy is fronted by a modern API/gateway server-side; if not, the client adapter absorbs the mess). Plan **strangler-fig migration** to replace legacy incrementally ([Module 44](../44%20Feature%20First%20Architecture/README.md)/[Module 47](../47%20Scalable%20Applications/README.md)).
- **Third-party services**:
  - Payments ([Module 31](../31%20Payments/README.md)), analytics/monitoring ([Module 52](../52%20Monitoring/README.md)), maps ([Module 30](../30%20Google%20Maps/README.md)), notifications ([Module 32](../32%20Notifications/README.md)), CRMs, etc. Wrap each behind **your interface** (swappable/testable/consent-gated) — don't scatter vendor SDK calls; centralize in shared services ([02_enterprise_architecture_and_structure.md](02_enterprise_architecture_and_structure.md)).
- **Where integrations live**: in **platform packages** (`platform_auth`, `platform_network` with the ACLs/adapters) behind **contracts** that features + the domain depend on — the enterprise structure ([02_enterprise_architecture_and_structure.md](02_enterprise_architecture_and_structure.md)).
- **Case studies (how it all composes)**:
  - **B2B multi-tenant SaaS**: modular monorepo + feature-first; **SSO** per tenant, **RBAC** per role, **white-label theming** + per-tenant config/flags, **audit** logging, **multi-backend via BFF**; offline read + optimistic writes for key flows; heavy testing + monitoring. (Combines [45](../45%20Modular%20Architecture/README.md)/[03_cross_cutting_enterprise_concerns.md](03_cross_cutting_enterprise_concerns.md)/[Module 48](../48%20System%20Design/README.md).)
  - **Super-app / platform**: many feature modules (some by different teams/vendors), a strong **shared platform** (auth/design system/host), **feature flags** to enable/gate mini-apps, **contracts** between host + features; possibly **dynamic/modular delivery**.
  - **Offline-heavy field app** (logistics/healthcare): **offline-first** (outbox + sync + conflict resolution — [Module 19](../19%20Offline%20First/README.md)), local DB ([Module 20](../20%20Database/README.md)), background sync ([Module 33](../33%20Background%20Services/README.md)), device features ([Module 29](../29%20Device%20Features/README.md)), robust error handling, integration with legacy dispatch systems via ACL. Reliability + data integrity dominate.
  - Each case study is **the handbook's pieces + integration patterns, composed for that domain's dominating NFRs** — reinforcing that enterprise architecture is composition, not invention.
- **The discipline recap**: **interface + ACL/adapter per external system**, integrations in platform packages behind contracts, security (SSO/tokens) server-authoritative, swap/version without domain ripple, and **plan legacy migration incrementally**.

## Memory Representation

Not runtime — an **integration boundary map**: domain/features → integration interfaces (contracts) → adapters/ACLs → external systems (SSO/backends/legacy/third-party), housed in platform packages. Adapters hold the translation; the domain holds only clean types.

## Compiler Behavior

Domain/features compile against **interfaces**; adapters (in platform packages) import vendor SDKs/protocols. Swapping an integration = new adapter, no domain change (DIP). Contracts are compiler-enforced package boundaries ([Module 45](../45%20Modular%20Architecture/README.md)).

## Runtime Behavior

Features call domain interfaces → adapters translate to/from external systems (SSO redirect/token exchange, BFF calls, legacy protocol, vendor SDK); external errors/quirks converted to domain types at the ACL. Offline/sync + monitoring behave as their modules define.

## Flutter Engine / Dart VM Behavior

Not applicable beyond normal networking/SDK behavior; SSO may use platform webviews/deep links ([Module 17](../17%20Authentication/README.md)).

## Examples

```dart
// Interface + ACL/adapter — legacy system wrapped; domain sees only clean types
abstract class OrderGateway { Future<Order> fetch(String id); }   // domain contract

class LegacySoapOrderAdapter implements OrderGateway {            // ACL/adapter (platform_network)
  final SoapClient soap;
  LegacySoapOrderAdapter(this.soap);
  @override
  Future<Order> fetch(String id) async {
    final xml = await soap.call('GetOrder', {'id': id});          // legacy quirks live HERE
    return _toDomain(xml);                                        // translate -> clean Order
  }
  Order _toDomain(XmlDoc xml) => /* map messy legacy XML -> domain Order */ Order(/*...*/);
}
// Swap to a modern REST backend later = new adapter implementing OrderGateway; domain untouched.

// SSO (OIDC) behind AuthService — features don't know the IdP
abstract class AuthService { Future<Session> loginWithSso(); }
// impl: OIDC/PKCE redirect to IdP -> tokens -> map claims -> Session + roles (RBAC)
```

```text
Integration patterns:
  SSO           -> OIDC/OAuth2(+PKCE)/SAML to corporate IdP (Okta/AzureAD/Auth0/Keycloak) -> AuthService
  multi-backend -> BFF/aggregation layer -> repositories hide service topology
  legacy        -> adapter/ACL translates odd formats/protocols -> domain types; strangler-fig migration
  third-party   -> wrap each vendor behind YOUR interface (swappable/testable/consent-gated)
  -> all behind interfaces/contracts in platform packages; domain depends on abstractions

Case studies (handbook pieces + integrations composed for dominating NFRs):
  B2B multi-tenant SaaS | super-app/platform | offline-heavy field app
```

## Diagrams

```mermaid
flowchart LR
    Feature[feature/domain] --> Contract[integration interface]
    Contract -.impl.-> Adapter[ACL/adapter (platform package)]
    Adapter --> External[SSO / backends(BFF) / legacy / third-party]
    Adapter -->|translate model+quirks+errors| Clean[clean domain types]
```

## Common Mistakes

| Mistake | Why it's a problem | Fix |
|---------|-------------------|-----|
| External model leaks into domain | Couples domain to systems you don't control | Interface + ACL/adapter translation |
| Scattering vendor SDK calls | Not swappable/testable | Wrap each behind your interface |
| Client coupled to microservice topology | Chatty/fragile | BFF/aggregation + repositories hide topology |
| Legacy quirks throughout the app | Un-maintainable | Isolate in an adapter; plan migration |
| IdP specifics in features | Hard to change SSO provider | Behind an `AuthService` |
| Big-bang legacy replacement | Risky | Strangler-fig incremental migration |
| Integrations outside platform packages/contracts | Coupling/no boundaries | Platform packages + contracts (Module 45) |
| Trusting external systems' security | Breach risk | Server-authoritative auth; validate inputs |

## Best Practices

- Wrap **every external system behind an interface + an Anti-Corruption Layer/adapter** (in platform packages, behind contracts) so external models/quirks/errors are **translated to clean domain types** and never leak — enabling **swap/version without domain ripple**.
- Handle **SSO** (OIDC/OAuth2+PKCE/SAML to a corporate IdP) behind an **`AuthService`** (features IdP-agnostic; tokens→session+RBAC; server-authoritative); use a **BFF/aggregation layer** for **multiple backends** so repositories hide service topology.
- **Isolate legacy** behind adapters (absorb odd formats/protocols) and **migrate incrementally (strangler-fig)**; wrap **third-party** vendors behind **your interfaces** (swappable/testable/consent-gated).
- Compose the **handbook's pieces + these patterns per the domain's dominating NFRs** (case-study style); keep integrations **in platform packages behind contracts**.

## Performance

Integration boundaries add negligible runtime cost (adapter translation); a **BFF reduces round-trips** (perf win over chatty multi-service calls). The real payoff is **decoupling + evolvability** (swap/migrate without ripple). Offline/sync case studies inherit their modules' perf characteristics.

## Advantages / Disadvantages

- **+** Domain insulated from messy/volatile external systems, swappable/versionable integrations, IdP-agnostic auth, fewer round-trips (BFF), incremental legacy migration, testable (fake adapters).
- **−** Adapter/ACL boilerplate per integration, BFF adds a backend layer, SSO/SAML complexity, legacy translation effort, discipline to keep integrations behind boundaries.

## Interview Questions

1. **🟢 How do you keep external systems from corrupting your domain?** — Wrap each behind an interface + an Anti-Corruption Layer/adapter that translates its model/quirks/errors to clean domain types; the domain depends on your abstractions.
2. **🟢 What is SSO in an enterprise app, and how do you integrate it?** — Federated auth (OIDC/OAuth2+PKCE or SAML) against a corporate IdP; the app gets tokens, maps claims→session+RBAC, all behind an `AuthService` (features IdP-agnostic; server-authoritative).
3. **🟡 How do you handle multiple backends/microservices?** — A BFF/aggregation layer composes services into client-shaped responses (fewer round-trips, insulates from topology); repositories hide which backend serves data.
4. **🟡 How do you integrate a legacy system safely?** — Wrap it in an adapter/ACL that translates its odd formats/protocols to domain types (ideally fronted by a modern gateway server-side), and plan strangler-fig incremental migration.
5. **🟡 How should third-party services be integrated?** — Behind your own interfaces (not scattered vendor SDK calls) — swappable, testable, consent-gated, centralized in shared/platform services.
6. **🔴 Why is the ACL/adapter pattern the core enterprise-integration skill?** — Enterprise systems are heterogeneous, messy, and change independently; the ACL isolates your clean domain so integrations can be swapped/versioned/migrated without domain ripple.
7. **🔴 How do the case studies illustrate enterprise architecture?** — They compose the handbook's pieces + integration patterns for each domain's dominating NFRs (multi-tenant SSO/RBAC/white-label; super-app platform/flags/contracts; offline-first field app) — composition, not invention.

## Senior Engineer Tips

- Put an interface + adapter/ACL in front of every external system (SSO/backends/legacy/third-party) in platform packages behind contracts; the enterprise-integration failure is letting a vendor's or legacy system's model leak into your domain, coupling you to something you don't control.
- Keep SSO behind an `AuthService` and consider a BFF for multi-service data; features shouldn't know the IdP or the microservice topology, so you can change either without touching them.
- Isolate legacy behind adapters and migrate strangler-fig, never big-bang; and wrap third-party SDKs behind your own interfaces so you can swap vendors, test with fakes, and gate consent centrally.

## Architect Perspective

Integration is where enterprise heterogeneity meets your clean architecture: the interface + Anti-Corruption Layer pattern (in platform packages behind contracts) isolates the domain from SSO, multiple backends, legacy systems, and third-party vendors — enabling swap/version/migrate without ripple. The case studies show enterprise architecture is **the handbook's pieces + integration patterns composed for the domain's dominating NFRs**. Mastering integration boundaries is what lets an enterprise app connect to everything without being corrupted by anything ([02_enterprise_architecture_and_structure.md](02_enterprise_architecture_and_structure.md), [Module 46](../46%20Domain%20Driven%20Design/README.md), [Module 17](../17%20Authentication/README.md), [Module 48](../48%20System%20Design/README.md)).

## Summary

- Wrap every external system (SSO, multiple backends, legacy, third-party) behind an **interface + ACL/adapter** (in platform packages, behind contracts) that translates its model/quirks to clean domain types — swap/version/migrate without domain ripple.
- SSO via OIDC/SAML behind an `AuthService` (server-authoritative); multi-backend via BFF (repositories hide topology); legacy isolated + strangler-fig migrated; third-party behind your interfaces.
- Case studies (B2B multi-tenant, super-app, offline field app) = the handbook's pieces + integration patterns composed for each domain's dominating NFRs.

## Revision Notes

- Core pattern: interface + Anti-Corruption Layer/adapter per external system (in platform packages behind contracts) → translate model/quirks/errors → clean domain types; domain depends on abstractions; swap/version without ripple (DIP).
- SSO: OIDC/OAuth2(+PKCE)/SAML → corporate IdP (Okta/AzureAD/Auth0/Keycloak); tokens→session+RBAC behind `AuthService` (IdP-agnostic, server-authoritative). Multi-backend: BFF/aggregation → repositories hide topology (fewer round-trips). Legacy: adapter/ACL absorbs odd formats/protocols; strangler-fig migration. Third-party: wrap behind your interfaces (swappable/testable/consent-gated).
- Case studies: B2B multi-tenant SaaS (SSO/RBAC/white-label/audit/BFF/offline) | super-app/platform (feature modules + shared platform + flags + contracts) | offline-heavy field app (offline-first/local DB/background sync/device/legacy ACL). Composition of handbook pieces + integration patterns per dominating NFRs.

## Practice Questions

1. How does the ACL/adapter pattern protect your domain from external systems?
2. How do you integrate SSO and multiple backends cleanly?
3. How do you safely integrate + migrate a legacy system?

## Coding Questions

1. Define an integration interface + an adapter/ACL translating a legacy/vendor model to a domain type.
2. Wrap SSO behind an `AuthService` (tokens→session+roles) that features consume.
3. Sketch a BFF-backed repository hiding multiple backends.

## Mini Project

**Enterprise integration design (design/build):** For an enterprise app, design the integrations: SSO (OIDC/SAML → corporate IdP) behind an `AuthService` (→ session + RBAC, server-authoritative), multiple backends via a BFF (repositories hide topology), a legacy system wrapped in an adapter/ACL (translating to clean domain types) with a strangler-fig migration plan, and third-party services behind your interfaces — all in platform packages behind contracts. Then pick one case study (B2B multi-tenant / super-app / offline field app) and outline how the handbook's pieces + these patterns compose for its dominating NFRs. Acceptance: each external system behind interface + ACL/adapter (domain uninfected, swappable); SSO behind `AuthService` (server-authoritative); BFF for multi-backend; legacy isolated + migration plan; third-party behind interfaces; a case-study composition tied to dominating NFRs.
