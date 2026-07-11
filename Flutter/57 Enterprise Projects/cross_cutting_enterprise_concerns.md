# Cross-Cutting Enterprise Concerns

> Enterprise apps carry concerns that touch **every feature** and must be **architected into the shared core, not bolted on**: **auth + RBAC/ABAC** (roles/permissions gating UI + server-enforced), **audit logging** (who did what, when — for compliance), **i18n/l10n** (locales/currencies/dates/RTL), **theming + white-label** (one codebase, many brands/tenants), **config + feature flags + remote config** (change behavior without redeploying; per-tenant/env), and **environment management** (dev/staging/prod + tenant). The rule: put each in a **shared, injectable service/package** so every feature uses it consistently — and enforce the **security-critical ones (RBAC/audit) server-side** (client = UX only).

## Introduction

This file covers the enterprise cross-cutting concerns — auth/RBAC, audit, i18n/l10n, theming/white-label, config/feature flags, environments — and how to architect them into the shared `core`/`platform` layer ([enterprise_architecture_and_structure.md](enterprise_architecture_and_structure.md)). These are exactly what consumer tutorials skip.

## Why this concept exists

These concerns span the whole app, are hard to retrofit, and are often **hard requirements** (compliance/audit, RBAC, multi-tenant). Architecting them **once, in shared services**, gives consistency + a single place to change/secure them; leaving them per-feature yields duplication, drift, and security/compliance gaps. Enterprise success depends on getting them right early.

## Real-world analogy

Cross-cutting concerns are the **building's shared infrastructure** — the **security/access-badge system (RBAC)**, the **CCTV/visitor log (audit)**, **multilingual signage (i18n)**, **tenant-branded lobbies (white-label)**, the **master control panel (config/feature flags)**, and **separate wiring for each floor's environment (envs/tenants)**. You install them **once, centrally**, so every office (feature) uses them consistently — not each office rigging its own ad hoc lock, camera, and sign.

## Internal Working

```mermaid
flowchart TD
    Core[shared core/platform layer] --> Auth[Auth + RBAC/ABAC service (roles/permissions; server-enforced)]
    Core --> Audit[Audit logging service (who/what/when -> backend)]
    Core --> Intl[i18n/l10n (ARB/intl; locales/currencies/dates/RTL)]
    Core --> Theme[Theming + white-label (tokens; per-tenant/brand)]
    Core --> Config[Config + feature flags + remote config (per env/tenant)]
    Core --> Env[Environment management (dev/staging/prod + tenant)]
    Features[every feature] -->|inject + use consistently| Core
    Note[architected in the core, not bolted on; RBAC/audit enforced server-side]
```

- **Auth + RBAC/ABAC** ([Module 17](../17%20Authentication/README.md)/[Module 37](../37%20Security/README.md)):
  - **Authentication** (who you are — SSO/OIDC/tokens — [integration_and_case_studies.md](integration_and_case_studies.md)) + **Authorization** (what you may do): **RBAC** (role→permissions) or **ABAC** (attribute-based). Features check permissions to **gate UI** (`if (user.can('orders.edit'))`) via a shared **`AuthService`/`PermissionService`**.
  - **Server-authoritative** (critical): client-side RBAC is **UX only** — the **server enforces** access on every request (never trust the client — [Module 37](../37%20Security/README.md)). Client gating hides/disables; server rejects unauthorized calls.
  - Centralize in the **platform auth package**; expose permission checks + reactive role/session state.
- **Audit logging** (compliance): record **who did what, when** (user, action, resource, timestamp, outcome) for security/compliance/forensics — typically **server-side** (authoritative), with the client emitting **audit events** for significant actions via a shared audit service. Distinct from ordinary logging ([Module 39](../39%20Logging/README.md)); often a hard regulatory requirement. **No PII beyond policy**; immutable/retained per compliance.
- **Internationalization/localization (i18n/l10n)**:
  - **i18n** = code ready for translation (no hardcoded strings; use **`intl`** + **ARB files** / `flutter gen-l10n`); **l10n** = the actual translations + locale formatting (dates/numbers/currencies via `intl`), **RTL** support (`Directionality`), pluralization/gender. Set up **from the start** (retrofitting hardcoded strings is painful). A shared l10n setup + `AppLocalizations` used everywhere.
- **Theming + white-label**:
  - One codebase serving **many brands/tenants** via **design tokens + `ThemeData`** (colors/typography/logos/spacing) swapped **per tenant** ([Module 25](../25%20Adaptive%20UI/README.md)). White-label = tenant-specific theme + assets + config, resolved at runtime (from config/tenant). Centralize in the **design-system/theming package**; features consume tokens, never hardcode brand values.
- **Config + feature flags + remote config**:
  - **Config**: environment/tenant settings (endpoints, keys, toggles) — non-secret via build config/`--dart-define`, secrets server-side ([Module 50](../50%20CI%20CD/README.md)).
  - **Feature flags**: enable/disable features **without redeploying** (gradual rollout, A/B, kill switches, per-tenant features) — via a **flag service** (Firebase Remote Config / LaunchDarkly / custom). Enables safe rollout + per-tenant customization.
  - **Remote config**: change values/behavior server-side at runtime. Centralize in a **config service**; features read flags/config through it.
- **Environment management**: **dev/staging/prod** (+ per-tenant) via **flavors + `--dart-define`/entry points** ([Module 50](../50%20CI%20CD/README.md)) — distinct endpoints/config/keys/signing per env; never hardcode; inject the environment.
- **The architectural rule (unifying)**: put **each concern in a shared, injectable service/package** in `core`/`platform` (DI — [Module 14](../14%20Dependency%20Injection/README.md)), so **every feature uses it consistently**, it's **testable** (fakes), and it's **changed/secured in one place**. **Bake them in early** ([enterprise_fundamentals.md](enterprise_fundamentals.md)) and **enforce security-critical ones (RBAC/audit) server-side**.

## Memory Representation

Not code — a **shared-services model**: `AuthService`/`PermissionService`, `AuditService`, i18n (`AppLocalizations`), theming (tokens/`ThemeData`), `ConfigService`/flag service, environment config — all in `core`/`platform`, injected into features. Runtime holds current session/roles, locale, tenant theme, and flags/config.

## Compiler Behavior

i18n via codegen (`flutter gen-l10n` from ARB); `--dart-define`/flavors inject env config at build; shared services compile against interfaces (testable/swappable). Hardcoded strings/brand values are the smell these prevent.

## Runtime Behavior

Features query the auth/permission service (UI gating) while the **server enforces** access; audit events emitted for significant actions; locale/currency formatting via `intl`; theme resolved per tenant; flags/config read at runtime (remote config updates behavior without redeploy); environment determines endpoints/config.

## Flutter Engine / Dart VM Behavior

`Directionality`/`intl` handle RTL + locale formatting in the framework; theming flows via `Theme`/`InheritedWidget`. Not internals-specific.

## Examples

```dart
// RBAC — permission gating in the UI (server still enforces every request)
if (auth.can('orders.edit')) EditOrderButton()      // UX gate; server authoritative
// AuthService/PermissionService in platform_auth; exposes reactive session/roles + can(permission)

// Audit — emit a compliance event for a significant action (who/what/when, server-authoritative)
audit.record(action: 'order.cancelled', resource: 'order/42', actor: user.id);   // -> backend audit log

// i18n/l10n — no hardcoded strings; intl + ARB + locale formatting
Text(AppLocalizations.of(context).cancelOrder);                                  // translated
Text(NumberFormat.currency(locale: locale, symbol: '€').format(amount));         // locale currency
// Directionality/RTL handled by the framework + generated l10n

// Feature flag + config (change behavior without redeploy; per env/tenant)
if (flags.isEnabled('new_checkout')) NewCheckout() else LegacyCheckout();
final baseUrl = config.get('api.baseUrl');           // per environment/tenant

// White-label theming — tokens per tenant (no hardcoded brand values)
MaterialApp(theme: tenantTheme(tenant));             // resolved from config/tenant
```

```text
Architect each concern into a shared, injectable service (core/platform):
  AuthService/PermissionService (RBAC/ABAC; server-enforced) | AuditService (who/what/when -> backend)
  AppLocalizations (i18n/l10n; intl+ARB; RTL/currency/date)  | Theming (tokens/ThemeData per tenant/white-label)
  ConfigService + FeatureFlags/RemoteConfig (per env/tenant) | Environment (flavors + --dart-define)
  -> every feature uses them consistently; bake in EARLY; RBAC/audit enforced SERVER-side
```

## Diagrams

```mermaid
flowchart LR
    Feature[every feature] --> Services[shared injectable services (core/platform)]
    Services --> RBAC[auth/RBAC (server-enforced)]
    Services --> Audit2[audit (compliance)]
    Services --> I18n[i18n/l10n]
    Services --> White[theming/white-label]
    Services --> Flags[config/feature flags/remote config]
    Services --> Envs[environments/tenants]
```

## Common Mistakes

| Mistake | Why it's a problem | Fix |
|---------|-------------------|-----|
| Client-only RBAC | Bypassable | Server-authoritative; client = UX gate |
| No/late audit logging | Compliance failure | Audit service (who/what/when), server-side, early |
| Hardcoded strings | i18n retrofit is painful | i18n from start (intl/ARB) + RTL/locale formats |
| Hardcoded brand/theme values | Can't white-label | Design tokens + per-tenant `ThemeData` |
| Per-feature ad hoc concerns | Duplication/drift/gaps | Shared injectable services in core/platform |
| Redeploy for every behavior change | Slow/risky | Feature flags + remote config |
| Hardcoded endpoints/env | Config bleed | Flavors + `--dart-define` per env/tenant |
| PII in audit/logs beyond policy | Compliance breach | Redact; retain per policy |

## Best Practices

- Architect **each cross-cutting concern into a shared, injectable service/package** in `core`/`platform` (DI) so every feature uses it **consistently, testably, and changeably in one place** — **bake them in early**.
- **Enforce security-critical concerns server-side**: **RBAC/ABAC** (client gating = UX only, server authoritative) and **audit logging** (who/what/when, compliance-grade, no PII beyond policy).
- Set up **i18n/l10n from the start** (`intl`/ARB, no hardcoded strings, locale/currency/date formatting, RTL) and **theming via design tokens** for **white-label/multi-tenant** (no hardcoded brand values).
- Use **feature flags + remote config** (change behavior without redeploy; per env/tenant; gradual rollout/kill switches) and **environment management** (flavors + `--dart-define`, never hardcoded).

## Performance

Not primarily perf — these are correctness/compliance/flexibility concerns. Feature flags + remote config also enable **safe gradual rollouts** ([Module 51](../51%20Deployment/README.md)). Centralized services avoid duplicated work; i18n/theming have negligible runtime cost. The payoff is consistency + compliance + configurability, not speed.

## Advantages / Disadvantages

- **+** Consistent, compliant, configurable, multi-tenant/global-ready app; concerns changed/secured in one place; testable; safe rollouts (flags).
- **−** Upfront architecture + setup (services/i18n/theming/flags/envs); server-side enforcement needed for RBAC/audit; discipline to route everything through shared services; compliance overhead.

## Interview Questions

1. **🟢 What are the key cross-cutting enterprise concerns?** — Auth + RBAC/ABAC, audit logging, i18n/l10n, theming/white-label, config + feature flags + remote config, and environment management.
2. **🟢 Where should RBAC be enforced, and what's the client's role?** — Server-authoritative (every request); the client only gates UI (hide/disable) for UX — client-side checks are bypassable.
3. **🟡 How do you architect cross-cutting concerns?** — As shared, injectable services/packages in core/platform (DI), so every feature uses them consistently, testably, and changeably in one place — baked in early.
4. **🟡 What's the difference between i18n and l10n, and why start early?** — i18n = making code translatable (no hardcoded strings, `intl`/ARB); l10n = the translations + locale formatting (dates/currency/RTL); retrofitting hardcoded strings is painful, so set it up from the start.
5. **🟡 How do feature flags + remote config help enterprise apps?** — Change behavior/enable features without redeploying (gradual rollout, A/B, kill switches, per-tenant features) — safer, more flexible releases.
6. **🔴 What is audit logging, and how does it differ from ordinary logging?** — Compliance-grade records of who did what, when (actor/action/resource/timestamp/outcome), server-authoritative + retained per policy — vs diagnostic logging for debugging.
7. **🔴 How do you support white-label/multi-tenant theming?** — Design tokens + per-tenant `ThemeData`/assets resolved at runtime (from config/tenant) — features consume tokens, never hardcode brand values.

## Senior Engineer Tips

- Put every cross-cutting concern behind a shared injectable service and route all features through it; the enterprise failure mode is per-feature ad hoc RBAC/i18n/theming that drifts and leaves security/compliance gaps.
- Enforce RBAC + audit server-side and treat audit as a first-class, compliance-grade feature from day one; "client-side role checks" and "we'll add the audit trail later" are classic, costly enterprise mistakes.
- Set up i18n (no hardcoded strings) + design-token theming + feature flags + flavor-based environments early; each is dramatically cheaper to architect in than to retrofit once dozens of features exist.

## Architect Perspective

Cross-cutting concerns are the enterprise infrastructure layer: auth/RBAC, audit, i18n/l10n, theming/white-label, config/feature-flags, and environments — architected once into shared, injectable core/platform services so every feature uses them consistently, with the security-critical ones (RBAC/audit) enforced server-side. Baking them in early (not bolting them on) is what makes an enterprise app compliant, global, multi-tenant, and configurable over its long life — the concerns that distinguish enterprise engineering from consumer apps ([enterprise_architecture_and_structure.md](enterprise_architecture_and_structure.md), [Module 17](../17%20Authentication/README.md), [Module 37](../37%20Security/README.md), [Module 25](../25%20Adaptive%20UI/README.md)).

## Summary

- Cross-cutting concerns (auth/RBAC, audit, i18n/l10n, theming/white-label, config/feature flags, environments) touch every feature and must be architected into shared injectable core/platform services — baked in early, not bolted on.
- Enforce RBAC + audit server-side (client = UX/emit events); set up i18n + token-based theming from the start; use feature flags + remote config for redeploy-free behavior changes; manage environments via flavors + `--dart-define`.
- One place per concern → consistency, compliance, configurability, testability across all features.

## Revision Notes

- Auth + RBAC/ABAC (Module 17/37): authn (SSO/OIDC/tokens) + authz (role→permissions); client gates UI (UX), **server enforces** every request. Audit: who/what/when/resource/outcome, server-authoritative, compliance-grade, retained per policy, no PII beyond policy (≠ diagnostic logging Module 39).
- i18n/l10n: no hardcoded strings; `intl` + ARB (`flutter gen-l10n`) + locale/currency/date formatting + RTL (`Directionality`); set up early. Theming/white-label: design tokens + per-tenant `ThemeData`/assets (Module 25); no hardcoded brand values.
- Config/feature flags/remote config (Firebase Remote Config/LaunchDarkly/custom): change behavior without redeploy, gradual rollout/kill switch/A-B/per-tenant. Environments: flavors + `--dart-define`/entry points (dev/staging/prod + tenant). Rule: each concern = shared injectable service in core/platform (DI), used consistently, RBAC/audit server-side, baked in EARLY.

## Practice Questions

1. Where is RBAC enforced, and what does the client do?
2. Why architect cross-cutting concerns into shared services + bake them in early?
3. What's audit logging, and how does it differ from ordinary logging?

## Coding Questions

1. Build a `PermissionService` with `can(permission)` (UI gate) + note server enforcement.
2. Set up i18n (intl/ARB) + a per-tenant themed `MaterialApp`.
3. Wire a feature-flag service gating a feature + flavor-based environment config.

## Mini Project

**Cross-cutting concerns (design/build):** For an enterprise app, architect the cross-cutting concerns into shared injectable core/platform services: `AuthService`/`PermissionService` (RBAC UI gating + documented server enforcement), an `AuditService` (who/what/when → backend), i18n/l10n (intl/ARB + locale formatting + RTL, no hardcoded strings), per-tenant white-label theming (design tokens), a config + feature-flag/remote-config service, and flavor-based environment management (dev/staging/prod + tenant) — each used consistently across features via DI. Acceptance: each concern as a shared injectable service (used consistently); RBAC + audit server-enforced (client = UX/emit); i18n + token theming set up (no hardcoded strings/brand); feature flags + remote config; environments via flavors/`--dart-define`; baked in early.
