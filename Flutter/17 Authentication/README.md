# 17 · Authentication

## Introduction

Authentication proves *who* a user is and maintains their *session*. This module covers auth fundamentals, token-based auth (JWT + access/refresh), OAuth 2.0 / social login, biometrics, and secure session management — integrating secure storage ([15](../15%20Local%20Storage/secure_storage.md)), interceptors ([16](../16%20Networking/rest_client_and_interceptors.md)), and route guards ([13](../13%20Routing/guards_and_redirects.md)).

## Why this module exists

Auth is security-critical and error-prone: tokens leaking to prefs/logs, no refresh flow, sessions that don't clear on logout, insecure OAuth. Getting it right protects users and is a frequent interview/architecture topic.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [auth_fundamentals.md](auth_fundamentals.md) | AuthN vs AuthZ, session models | 🔵 |
| 2 | [token_auth_jwt.md](token_auth_jwt.md) | JWT, access/refresh, auto-refresh | 🔴 |
| 3 | [oauth_and_social_login.md](oauth_and_social_login.md) | OAuth 2.0, PKCE, Google/Apple sign-in | 🔴 |
| 4 | [biometric_auth.md](biometric_auth.md) | `local_auth`, fingerprint/face | 🔵 |
| 5 | [session_management.md](session_management.md) | Token storage, guards, logout, lifecycle | 🔴 |

> **Cross-references:** Secure storage: [15 · secure_storage](../15%20Local%20Storage/secure_storage.md). Interceptors/refresh: [16 · rest_client_and_interceptors](../16%20Networking/rest_client_and_interceptors.md). Route guards: [13 · guards_and_redirects](../13%20Routing/guards_and_redirects.md). Firebase Auth: [Module 18](../18%20Firebase/README.md). Security/threat model: [Module 37](../37%20Security/README.md). State (auth state): [Module 11](../11%20State%20Management/README.md).

## Prerequisites

[15 Local Storage](../15%20Local%20Storage/README.md), [16 Networking](../16%20Networking/README.md), [13 Routing](../13%20Routing/README.md).

## What you'll be able to do after this module

- Distinguish authentication from authorization and choose a session model.
- Implement JWT access/refresh with an auto-refresh interceptor.
- Integrate OAuth 2.0 / social login securely (PKCE).
- Add biometric authentication.
- Manage sessions end-to-end: secure storage, guards, logout, expiry.

## Capstone

**Secure auth flow:** Login → store tokens in secure storage → auto-attach + refresh via interceptor → guard routes by auth state → biometric unlock → logout that clears everything — a production-grade session backbone.

## Summary

Authentication is a security-critical pipeline: prove identity, issue/refresh tokens, store them securely, guard access, and clear on logout. Build it once, correctly, behind an auth repository the app depends on.
