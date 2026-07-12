# 31 · Payments

## Introduction

This module covers accepting money in a Flutter app: the **security/PCI ground rules** (never touch raw card data; the server is the source of truth), **payment gateways** for physical goods/services (Stripe, Razorpay — the `PaymentIntent`/order flow), **in-app purchases** for digital goods (Apple App Store / Google Play, consumables/non-consumables/subscriptions), **wallets** (Google Pay / Apple Pay), and **server-side verification** (webhooks, receipt validation) that ties it together securely.

## Why this module exists

Payments are where bugs cost real money and mistakes create fraud/compliance liability. The rules differ sharply by *what* you sell: **digital goods must use the platform IAP billing** (Apple/Google take a cut and mandate it), while **physical goods/services must use a gateway** (and are *banned* from IAP). Getting the flow, the store rules, and the security model right is essential and non-obvious.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [01_payments_overview_and_security.md](01_payments_overview_and_security.md) | Payment models, PCI/security, IAP-vs-gateway rule, server-as-source-of-truth | 🔴 |
| 2 | [02_payment_gateways.md](02_payment_gateways.md) | Stripe/Razorpay, `PaymentIntent`/order flow, cards & wallets for goods/services | 🔴 |
| 3 | [03_in_app_purchases.md](03_in_app_purchases.md) | `in_app_purchase`, consumables/non-consumables/subscriptions, store setup | 🔴 |
| 4 | [04_wallets_google_apple_pay.md](04_wallets_google_apple_pay.md) | Google Pay / Apple Pay integration & when they apply | 🟡 |
| 5 | [05_payments_integration.md](05_payments_integration.md) | Capstone: server verification, webhooks, receipts, reconciliation | 🔴 |

> **Cross-references:** Networking (calling your backend): [Module 16](../16%20Networking/README.md). Auth (identifying the buyer): [Module 17](../17%20Authentication/README.md). Secure storage (tokens, never cards): [Module 15](../15%20Local%20Storage/README.md). Error handling: [Module 38](../38%20Error%20Handling/README.md). Firebase (Cloud Functions for webhooks): [Module 18](../18%20Firebase/README.md). Deployment/store review: [Module 51](../51%20Deployment/README.md).

## Prerequisites

[16 Networking](../16%20Networking/README.md), [17 Authentication](../17%20Authentication/README.md), [15 Local Storage](../15%20Local%20Storage/README.md) (secure storage), a backend you control (or Cloud Functions — [Module 18](../18%20Firebase/README.md)).

## What you'll be able to do after this module

- Choose the correct payment path (IAP vs gateway) for what you're selling and pass store review.
- Integrate a gateway (Stripe/Razorpay) with the client-secret/order flow — no raw card data in your app.
- Implement in-app purchases (consumables, non-consumables, subscriptions) with restore.
- Add Google Pay / Apple Pay where appropriate.
- Verify payments server-side (webhooks, receipt validation) as the source of truth.

## Capstone

**Payment slice:** A checkout that (a) buys a **digital** item via IAP with server receipt verification and (b) pays for a **physical** order via a gateway using a server-created `PaymentIntent`, with the backend confirming via webhook and unlocking entitlement/fulfilling the order — client never trusts its own success callback.

## Summary

Payments = pick the right rail (IAP for digital, gateway for physical), never handle raw card data, and make the **server the source of truth** via webhooks/receipt verification. This module covers the flows, the platform store rules, wallets, and the security/verification backbone.
