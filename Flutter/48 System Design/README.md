# 48 · System Design

## Introduction

This module covers **system design from the mobile/Flutter perspective**: how to design an app-plus-backend system end-to-end — clarifying **requirements** (functional + non-functional), defining **client-server contracts & data flow** (APIs, pagination, real-time, sync), choosing a **caching/offline strategy**, and reasoning about **scalability + trade-offs** — plus how to **approach a mobile system-design interview** ("design the Instagram feed," "design a chat app"). It synthesizes the whole handbook (architecture, networking, offline-first, storage, performance, security) into a design discipline, capped by a capstone.

## Why this module exists

Senior/architect roles require designing systems, not just implementing screens — and **mobile system design is its own discipline** distinct from backend system design: the client is constrained (battery, memory, flaky network, offline), the contract with the server is the crux, and caching/offline/sync dominate the design. Interviews and real projects both demand a structured approach: clarify requirements, sketch the client-server data flow, pick storage/caching/offline strategies, and justify trade-offs. This module teaches that structured, mobile-centric design thinking.

## Module map

| # | File | Topic | Level |
|---|------|-------|-------|
| 1 | [system_design_fundamentals.md](system_design_fundamentals.md) | What mobile system design is; requirements; the process | 🔴 |
| 2 | [client_server_and_data_flow.md](client_server_and_data_flow.md) | API contracts, pagination, real-time, data flow & sync | 🔴 |
| 3 | [caching_offline_and_scale.md](caching_offline_and_scale.md) | Caching strategy, offline-first, scalability & trade-offs | 🔴 |
| 4 | [mobile_system_design_interview.md](mobile_system_design_interview.md) | Interview approach: frameworks, common prompts, communication | 🟡 |
| 5 | [system_design_integration.md](system_design_integration.md) | Capstone: design a feed/chat app end-to-end | 🔴 |

> **Cross-references:** Architecture band: [40](../40%20Clean%20Architecture/README.md)–[47](../47%20Scalable%20Applications/README.md). Networking: [Module 16](../16%20Networking/README.md). Offline-first: [Module 19](../19%20Offline%20First/README.md). Database/caching: [Module 20](../20%20Database/README.md)/[Module 34](../34%20File%20Handling/README.md). Performance: [Module 21](../21%20Performance/README.md). Security: [Module 37](../37%20Security/README.md). Notifications/real-time: [Module 32](../32%20Notifications/README.md).

## Prerequisites

The architecture band ([40](../40%20Clean%20Architecture/README.md)–[47](../47%20Scalable%20Applications/README.md)), [16 Networking](../16%20Networking/README.md), [19 Offline First](../19%20Offline%20First/README.md), [20 Database](../20%20Database/README.md), [21 Performance](../21%20Performance/README.md).

## What you'll be able to do after this module

- Run a structured mobile system-design process from requirements to trade-offs.
- Define client-server contracts + data flow (pagination, real-time, sync) deliberately.
- Choose caching/offline strategies and justify them against constraints.
- Reason about mobile-specific scalability and trade-offs (battery/memory/network).
- Confidently approach a mobile system-design interview end-to-end.

## Capstone

**End-to-end design:** Design a feed or chat app — clarify functional/non-functional requirements, define the client-server API contract + data flow (pagination/real-time), choose storage + caching + offline-sync strategies, address mobile constraints (battery/memory/flaky network), map it onto the app architecture (Clean/feature-first/MVVM), and present the trade-offs — as a written design doc + a whiteboard-style walkthrough.

## Summary

Mobile system design is a structured discipline: clarify requirements, design the client-server contract + data flow, choose caching/offline/sync strategies, and justify trade-offs under mobile constraints (battery/memory/network/offline). It synthesizes the handbook into designing app systems end-to-end — for real projects and interviews alike.
