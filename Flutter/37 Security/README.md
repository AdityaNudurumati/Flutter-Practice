# 37 · Security

## Introduction

This module covers securing a Flutter app end-to-end: the **security model & OWASP MASVS** (the client is untrusted, defense-in-depth, threat modeling), **secure storage & encryption** (`flutter_secure_storage`, Keychain/Keystore, encryption at rest, crypto do's/don'ts), **network security** (TLS, certificate pinning, secrets/API-key management), and **code hardening & device integrity** (obfuscation, root/jailbreak & tamper detection, anti-reversing) — tied together in a capstone. It builds on auth ([Module 17](../17%20Authentication/README.md)), local storage ([Module 15](../15%20Local%20Storage/README.md)), networking ([Module 16](../16%20Networking/README.md)), and payments' trust rules ([Module 31](../31%20Payments/README.md)).

## Why this module exists

Mobile apps run on **devices you don't control** — attackers can inspect storage, intercept traffic, decompile the binary, and run on rooted/jailbroken hardware. Security isn't a feature you bolt on; it's a discipline: assume the client is hostile, keep secrets and trust on the server, encrypt sensitive data at rest and in transit, and harden the binary to raise the attacker's cost. OWASP MASVS gives the industry checklist. Getting this wrong leaks user data, credentials, and money.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [security_model_and_owasp.md](security_model_and_owasp.md) | Threat model, untrusted client, defense-in-depth, OWASP MASVS | 🔴 |
| 2 | [secure_storage_and_encryption.md](secure_storage_and_encryption.md) | `flutter_secure_storage`, Keychain/Keystore, encryption at rest, crypto | 🔴 |
| 3 | [network_security_and_pinning.md](network_security_and_pinning.md) | TLS, certificate pinning, secrets/API-key management | 🔴 |
| 4 | [code_hardening_and_integrity.md](code_hardening_and_integrity.md) | Obfuscation, root/jailbreak & tamper detection, anti-reversing | 🔴 |
| 5 | [security_integration.md](security_integration.md) | Capstone: layered security behind services, threat-driven | 🔴 |

> **Cross-references:** Auth/tokens: [Module 17](../17%20Authentication/README.md). Secure storage basics: [15 · secure_storage](../15%20Local%20Storage/README.md). Networking/interceptors: [Module 16](../16%20Networking/README.md). Payments trust rules (server-as-truth): [Module 31](../31%20Payments/README.md). Native config (keystore/entitlements): [27](../27%20Native%20Android/README.md)/[28](../28%20Native%20iOS/README.md). App size/obfuscation build flags: [21 · startup_and_app_size](../21%20Performance/README.md).

## Prerequisites

[17 Authentication](../17%20Authentication/README.md), [15 Local Storage](../15%20Local%20Storage/README.md), [16 Networking](../16%20Networking/README.md), basic crypto literacy, native build config ([27](../27%20Native%20Android/README.md)/[28](../28%20Native%20iOS/README.md)).

## What you'll be able to do after this module

- Threat-model an app and apply defense-in-depth against the OWASP MASVS.
- Store secrets/tokens securely (Keychain/Keystore) and encrypt sensitive data at rest correctly.
- Enforce TLS + certificate pinning and manage secrets/API keys without shipping them in the binary.
- Harden the binary (obfuscation) and detect root/jailbreak/tampering — knowing the limits of client-side defenses.
- Layer these behind services with a clear, threat-driven security posture.

## Capstone

**Security hardening slice:** An app that stores tokens in secure storage, encrypts a sensitive local cache, pins the API certificate (with rotation strategy), keeps no hardcoded secrets, obfuscates the release build, and detects root/jailbreak to gate high-risk actions — all threat-driven and layered, with server-side enforcement as the backstop.

## Summary

Security = assume a hostile client, keep trust/secrets on the server, and layer defenses: secure storage + encryption at rest, TLS + pinning, no shipped secrets, obfuscation + integrity checks — guided by OWASP MASVS and threat modeling. Client-side measures raise cost but never replace server-side enforcement.
