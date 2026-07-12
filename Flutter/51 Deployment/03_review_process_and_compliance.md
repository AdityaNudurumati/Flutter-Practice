# Review Process & Compliance

> Both stores **review** submissions against their **policies** before (and after) publishing — **Apple** does thorough **human review** (~a day, stricter, subjective), **Google Play** is faster/more automated (hours–days) but enforces policy just as firmly (with post-publish scanning). The frequent **rejection causes** are predictable: **crashes/bugs/incomplete apps**, **inaccurate privacy/data-safety disclosures**, **missing/incorrect permissions justification**, **payment-policy violations** (using a gateway for digital goods instead of IAP), **guideline breaches** (misleading metadata, prohibited content, broken links), and **incomplete listings**. Compliance — **privacy, permissions, IAP, content, and platform guidelines** — is a first-class release requirement, not an afterthought.

## Introduction

This file covers how review works on each store, the most common rejection reasons and how to avoid them, and the key compliance areas (privacy, permissions, payments, content, guidelines). It's the "getting approved + staying compliant" layer after submission ([02_store_setup_and_submission.md](02_store_setup_and_submission.md)).

## Why this concept exists

Stores gatekeep quality, safety, privacy, and their business rules; a rejection costs days and delays launches, and post-publish violations can get an app **removed** or an account **banned**. Knowing the process + common pitfalls + compliance rules lets you submit **right the first time** and avoid costly, sometimes reputation-damaging, rejections/removals.

## Real-world analogy

Review is **customs + safety inspection** before your product hits shelves: inspectors check it **works, is safe, is truthfully labeled** (privacy/permissions), and follows **trade rules** (payment policy). Apple's inspection is a **thorough manual one** (slower, stricter, some judgment); Google's is **faster/more automated** but still enforced, with **random re-inspections** (post-publish scanning). A mislabeled, buggy, or rule-breaking product is turned away — repeatedly if you don't fix the root cause.

## Internal Working

```mermaid
flowchart TD
    Submit[submit build + listing] --> Review{store review}
    Review -->|Apple| Human[thorough human review (~1 day, stricter)]
    Review -->|Google| Auto[faster/automated + policy checks + post-publish scanning]
    Human & Auto -->|pass| Approved[approved -> release/staged]
    Human & Auto -->|fail| Rejected[rejected -> reason -> fix + resubmit]
    Compliance[compliance: privacy, permissions, IAP, content, guidelines] --> Review
    Note[stay compliant post-publish or risk removal/ban]
```

- **The review process**:
  - **Apple App Store**: **human reviewers** test the app against the **App Store Review Guidelines**; typically **~24h** (variable); **stricter + more subjective** (design/quality/completeness judged). Rejections come with a reason (in App Store Connect **Resolution Center**); you fix + resubmit or appeal.
  - **Google Play**: **faster, largely automated** review (hours to a few days) plus **policy enforcement + ongoing scanning** (malware/policy post-publish). Rejections/warnings via Play Console.
  - **Pre-launch reports / TestFlight**: Play's **pre-launch report** (auto-tests on devices) surfaces crashes before production; TestFlight beta catches issues with real testers.
- **Common rejection causes (know + prevent these)**:
  - **Crashes / bugs / incomplete features**: the #1 cause — test thoroughly (unit/widget/E2E — [Module 49](../49%20Testing/README.md)), handle errors, no placeholder/broken UI, no dead links.
  - **Inaccurate privacy disclosures**: Data Safety/App Privacy **not matching** actual data collection ([02_store_setup_and_submission.md](02_store_setup_and_submission.md)/[Module 37](../37%20Security/README.md)).
  - **Permissions**: requesting permissions **without clear justification/usage strings**, or more than the app needs ([Module 27](../27%20Native%20Android/README.md)/[Module 28](../28%20Native%20iOS/README.md)); Android sensitive-permission declarations.
  - **Payment-policy violations**: using an **external gateway for digital goods** (must use **IAP**) — a top Apple/Google rejection ([Module 31](../31%20Payments/README.md)).
  - **Guideline breaches**: **misleading metadata/screenshots**, prohibited/objectionable content, **spam/duplicate** apps, **misuse of trademarks**, insufficient **account-deletion** support (now required), inadequate **content moderation** for user-generated content.
  - **Design/quality (Apple)**: too-basic "website wrapper" apps, poor UX, non-native feel.
  - **Incomplete listing / demo access**: missing screenshots, or **no test credentials** for a login-gated app (provide a demo account for reviewers).
- **Compliance areas (first-class)**:
  - **Privacy**: privacy policy, accurate disclosures, **ATT** (iOS tracking prompt), **account deletion** path, data-minimization ([Module 37](../37%20Security/README.md)).
  - **Permissions**: request **only what's needed**, with **clear justification/usage strings**, in context ([Module 29](../29%20Device%20Features/README.md)).
  - **Payments**: **IAP for digital goods**, gateways for physical/services ([Module 31](../31%20Payments/README.md)).
  - **Content**: rating accuracy, no prohibited content, moderation + reporting for UGC.
  - **Legal/regional**: age/kids rules (COPPA/Families), GDPR/CCPA, export/encryption declarations, accessibility expectations.
- **Handling rejections**: read the **exact reason**, fix the **root cause** (not just symptoms), respond in the **Resolution Center**/appeal with clarification if it's a misunderstanding, and **resubmit**. Repeated same-cause rejections signal you didn't fix the root.
- **Staying compliant post-publish**: policies **evolve**; violations found later → **removal/suspension/ban**. Keep disclosures current, respond to policy notices, and monitor ([Module 52](../52%20Monitoring/README.md)).
- **Reduce risk**: use **pre-launch reports/TestFlight**, submit a **complete, crash-free, honestly-disclosed** app, and **budget review time** (esp. Apple) into release schedules.

## Memory Representation

Not runtime — a **compliance state + review status**: policy adherence (privacy/permissions/IAP/content), submission status, rejection reasons/history. The invariant: the app + listing truthfully comply with current policies.

## Compiler / Build Behavior

Review evaluates the built/signed artifact + listing; some checks (e.g., export-compliance/encryption declarations, entitlements) tie to build config; a crashing build fails review.

## Runtime Behavior

Reviewers/automated tools **run the app** (Apple manual, Play pre-launch report) — so runtime **crashes/broken flows** are caught. Post-publish scanning continues at runtime scale.

## Flutter Engine Behavior

Not applicable beyond the app running normally under review.

## Dart VM Behavior

Not applicable.

## Examples

```text
Top rejection causes -> preventions:
  crashes/incomplete/broken links  -> thorough testing (unit/widget/E2E), no placeholders, working links
  inaccurate privacy disclosures   -> Data Safety/App Privacy MATCH actual behavior
  unjustified/excess permissions   -> request only needed + clear usage strings/justification
  gateway for DIGITAL goods         -> use IAP (Module 31)
  misleading metadata/screenshots  -> honest, representative listing
  login-gated app, no demo creds   -> provide reviewer test account + notes
  UGC without moderation/reporting -> add moderation + report/block + account deletion
```

```text
Review reality:
  Apple:  human review, ~24h (variable), stricter/subjective (quality/design/completeness)
  Google: faster/automated (hours-days) + policy scanning post-publish
  -> budget review time (esp. Apple); use pre-launch report / TestFlight to catch issues first
```

## Diagrams

```mermaid
flowchart LR
    Prep[complete + crash-free + honestly-disclosed app] --> Submit3[submit]
    Submit3 --> Rev[review (Apple human / Play automated)]
    Rev -->|reject| Fix[fix ROOT cause -> resubmit / appeal]
    Rev -->|approve| Release[release/staged]
    Release --> Post[stay compliant post-publish (policies evolve)]
```

## Common Mistakes

| Mistake | Why it's rejected/risky | Fix |
|---------|------------------------|-----|
| Crashes/incomplete/placeholder UI | #1 rejection cause | Test thoroughly; no broken flows/links |
| Inaccurate privacy/data-safety | Rejection/removal | Disclosures match real behavior |
| Excess/unjustified permissions | Rejection | Request only needed + clear justification/usage strings |
| Gateway for digital goods | Payment-policy violation | Use IAP (Module 31) |
| Misleading metadata/screenshots | Guideline breach | Honest, representative listing |
| No reviewer demo credentials (login app) | Reviewer can't test → reject | Provide test account + review notes |
| UGC without moderation/reporting/deletion | Policy breach | Add moderation, reporting, account deletion |
| Ignoring root cause on resubmit | Repeated rejections | Fix root cause, respond in Resolution Center |
| No review-time budget | Missed launch dates | Budget review latency (esp. Apple) |

## Best Practices

- Submit a **complete, crash-free** app (thorough testing, working links, no placeholders) and **honest, accurate disclosures** (privacy/data-safety matching behavior, correct ratings).
- Request **only necessary permissions** with **clear justification/usage strings**; use **IAP for digital goods**; keep **metadata/screenshots truthful**; support **account deletion** + **UGC moderation/reporting** where applicable.
- Provide **reviewer demo credentials + notes** for gated apps; use **pre-launch reports/TestFlight** to catch issues first; **budget review time** (esp. Apple).
- On rejection, **fix the root cause** + respond/appeal in the Resolution Center; **stay compliant post-publish** (policies evolve) and monitor.

## Performance

Not runtime perf — but **crash-free + performant** apps pass review (crashes are the top rejection) and avoid post-publish removal, so quality/monitoring feed compliance ([Module 49](../49%20Testing/README.md)/[Module 52](../52%20Monitoring/README.md)). Review latency affects **release cadence** (budget it).

## Advantages / Disadvantages

- **+** (Compliance) smooth first-pass approval, avoided removals/bans, user trust, predictable release schedule.
- **−** Review latency (esp. Apple) + subjectivity, evolving policies to track, per-store rules, rejection back-and-forth if unprepared.

## Interview Questions

1. **🟢 How do Apple and Google review differ?** — Apple: thorough human review (~a day, stricter/subjective on quality/design); Google: faster/more automated (hours-days) with post-publish policy scanning.
2. **🟢 What's the #1 rejection cause and how to avoid it?** — Crashes/bugs/incomplete apps — prevent with thorough testing (unit/widget/E2E), no placeholders/broken links, and pre-launch reports/TestFlight.
3. **🟡 What compliance areas matter most?** — Privacy (accurate disclosures, ATT, account deletion), permissions (only needed + justified), payments (IAP for digital goods), content (rating/moderation), and platform guidelines.
4. **🟡 Why do inaccurate privacy disclosures get apps removed?** — Data Safety/App Privacy must match actual data behavior; mismatches are a policy violation → rejection or post-publish removal.
5. **🟡 How do you help reviewers test a login-gated app?** — Provide demo/test credentials and review notes so the reviewer can access the full app.
6. **🔴 What happens if you use a payment gateway for digital goods?** — Rejection — digital goods must use IAP; gateways are only for physical goods/services.
7. **🔴 How do you handle a rejection?** — Read the exact reason, fix the root cause (not symptoms), respond/appeal in the Resolution Center if it's a misunderstanding, and resubmit — repeated same-cause rejections mean the root wasn't fixed.

## Senior Engineer Tips

- Ship complete and crash-free with honest disclosures; the vast majority of rejections are crashes, inaccurate privacy answers, or payment-policy violations — all preventable before submitting.
- Always include reviewer demo credentials + notes for gated apps and use Apple's + Google's pre-launch tooling; "reviewer couldn't log in" and "crashed on launch" are needless multi-day delays.
- Budget Apple review time into release schedules and fix the root cause on rejection (not the symptom); and keep privacy/policy disclosures current post-launch, since policies evolve and violations get apps pulled.

## Architect Perspective

Review and compliance are the gate between a built app and a live one: quality (crash-free/tested), truthful privacy/permissions, correct payments (IAP), and guideline adherence. Treating compliance as a first-class release requirement — baked into testing, privacy disclosures, permission design, and payment architecture — turns review into a formality rather than a blocker, and prevents the costlier post-publish removals. It ties the whole handbook's quality/security/payments work to the moment of shipping ([Module 49](../49%20Testing/README.md), [Module 37](../37%20Security/README.md), [Module 31](../31%20Payments/README.md)).

## Summary

- Stores review submissions against policy (Apple: human/stricter ~1 day; Google: faster/automated + post-publish scanning); rejections cost days.
- Top rejections: crashes/incomplete, inaccurate privacy disclosures, unjustified permissions, gateway-for-digital-goods, misleading metadata, no reviewer demo creds, UGC without moderation.
- Compliance (privacy/permissions/IAP/content/guidelines) is first-class; submit complete + honest, provide demo access, use pre-launch tools, fix root causes, stay compliant post-publish.

## Revision Notes

- Review: Apple human (~24h, stricter/subjective, Resolution Center) vs Google faster/automated (hours-days) + ongoing policy scanning; pre-launch report (Play)/TestFlight catch issues first.
- Top rejections: crashes/incomplete/broken links; inaccurate privacy/data-safety; unjustified/excess permissions; gateway-for-digital-goods (use IAP); misleading metadata; no reviewer demo credentials (login apps); UGC without moderation/reporting/account-deletion.
- Compliance: privacy (accurate disclosures + ATT + account deletion), permissions (only needed + justification/usage strings), payments (IAP digital), content (rating/moderation), legal/regional. Fix root cause on rejection; budget review time (Apple); stay compliant post-publish (removal/ban risk).

## Practice Questions

1. What are the most common rejection causes and their preventions?
2. How does Apple review differ from Google Play review?
3. What compliance areas must you get right, and what happens if you don't?

## Coding Questions

1. Build a pre-submission compliance checklist (privacy/permissions/IAP/content/quality).
2. Draft reviewer notes + demo-credential handling for a login-gated app.
3. Given a rejection reason, outline the root-cause fix + resubmission response.

## Mini Project

**Compliance + review readiness (Flutter/deployment):** For an app, produce a review-readiness package: a compliance checklist (crash-free/tested, accurate privacy disclosures, minimal justified permissions, IAP-for-digital-goods, honest metadata, account deletion, UGC moderation if applicable), reviewer demo credentials + notes for a gated flow, a pre-launch-testing plan (Play pre-launch report/TestFlight), and a rejection-handling process (root-cause fix + Resolution Center response) with review-time budgeting. Acceptance: covers top rejection causes + preventions; accurate privacy/permissions/payments/content compliance; reviewer demo access; pre-launch testing; root-cause rejection handling + review-time budget; post-publish compliance noted.
