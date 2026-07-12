# System Design Fundamentals (Mobile Perspective)

> Mobile system design is **its own discipline**: unlike backend system design (scaling servers/DBs/load balancers), the mobile designer's focus is the **client and its contract with the server** under harsh constraints — **flaky/offline network, battery, limited memory, small screen, app-store rules, and an untrusted client**. The process is structured: **clarify requirements** (functional + **non-functional** — offline? real-time? scale? latency?), then design **data flow, storage/caching, sync, and client architecture**, justifying **trade-offs** at each step. The recurring theme: **the network is unreliable and the device is constrained**, so caching/offline/sync usually dominate the design.

## Introduction

This file establishes what mobile system design *is*, how it differs from backend system design, the constraints that drive it, and the structured process to run — the frame for the contract/caching/interview files.

## Why this concept exists

Engineers often approach "design X app" like a backend problem (servers, sharding) and miss the mobile essence: the hard parts are the **client-server contract, offline behavior, caching, sync, and device constraints**. A mobile-specific frame + a repeatable process ensures you design what actually matters for an app — and communicate it clearly in interviews and docs.

## Real-world analogy

Backend system design is planning a **city's central infrastructure** (power plants, water mains — scale/throughput). Mobile system design is designing a **well-equipped expedition vehicle** that must operate **far from that infrastructure**: it needs onboard supplies (cache), the ability to keep going when disconnected (offline), fuel efficiency (battery), limited cargo (memory), and a reliable **radio protocol** to sync with base when in range (client-server contract). You design for the harsh field, not the data center.

## Internal Working

```mermaid
flowchart TD
    Req[1. Clarify requirements: functional + NON-functional] --> Flow[2. Data flow: client <-> server contract]
    Flow --> Store[3. Storage + caching strategy]
    Store --> Sync[4. Offline + sync strategy]
    Sync --> Arch[5. Client architecture mapping (Clean/feature/MVVM)]
    Arch --> Trade[6. Trade-offs + constraints (battery/memory/network/security)]
    Note[mobile constraints drive the design at every step]
```

- **Clarify requirements first (never skip)**:
  - **Functional**: what does it do? (feed of posts, send messages, like/comment, search).
  - **Non-functional (the differentiators)**: **offline** support? **real-time**? expected **scale** (users/data volume)? **latency/perf** targets? **consistency** needs? **security/privacy** (PII)? **platforms**? These shape the whole design far more than the feature list.
  - **Scope/assumptions**: state them; ask clarifying questions (in interviews, this is scored heavily).
- **Mobile constraints that drive design**:
  - **Unreliable network** (offline, flaky, slow, metered) → caching + offline-first + sync are usually central ([Module 19](../19%20Offline%20First/README.md)).
  - **Battery + data** → minimize/batched network, push over poll, deferral ([Module 33](../33%20Background%20Services/README.md)/[Module 47](../47%20Scalable%20Applications/README.md)).
  - **Limited memory/CPU** → pagination, list virtualization, bounded caches, isolates ([Module 21](../21%20Performance/README.md)).
  - **Untrusted client** → server-as-source-of-truth, no secrets on device ([Module 37](../37%20Security/README.md)).
  - **App-store/platform** → size, permissions, background limits, review.
- **Backend vs mobile system design (know the difference)**:
  - **Backend**: horizontal scaling, load balancers, DB sharding/replication, caching layers, queues, CAP theorem — server throughput/availability.
  - **Mobile**: **client-server contract**, on-device storage/caching, offline/sync/conflict resolution, pagination/real-time protocols, client architecture, device constraints. You **treat the backend as a given API** and design the **client + contract** (unless asked to design both).
- **The process (repeatable)**: (1) requirements → (2) client-server **data flow + contract** ([02_client_server_and_data_flow.md](02_client_server_and_data_flow.md)) → (3) **storage + caching** → (4) **offline + sync** ([03_caching_offline_and_scale.md](03_caching_offline_and_scale.md)) → (5) **client architecture** mapping (Clean/feature-first/MVVM — [Module 40](../40%20Clean%20Architecture/README.md)/[Module 44](../44%20Feature%20First%20Architecture/README.md)/[Module 43](../43%20MVVM/README.md)) → (6) **trade-offs**. Iterate; there's **no single right answer** — justify choices against requirements/constraints.
- **Trade-offs are the point**: every choice (cache TTL, real-time vs poll, optimistic vs pessimistic, consistency vs availability) has costs; **articulating and justifying** them (not memorizing "the answer") is what senior design demonstrates.

## Memory Representation

Not runtime — a **design artifact**: a requirements list (functional + non-functional), a data-flow/contract diagram, storage/caching/sync decisions, an architecture mapping, and a trade-off analysis. The artifact evolves as you iterate.

## Compiler / Runtime / Engine / VM Behavior

Not applicable — system design is a **conceptual/architectural** activity (the resulting code lives across the handbook's modules). Its "behavior" is the reasoning process + documented decisions.

## Examples

```text
Requirements clarification (design "a news feed app"):
  Functional:      list posts, infinite scroll, like, view detail, pull-to-refresh
  Non-functional:  offline read? YES (cache last feed) | real-time? partial (new-post badge)
                   scale? 1M users | latency? feed < 1s perceived | consistency? eventual
                   security? auth + no PII in logs | platforms? iOS+Android
  Assumptions:     backend REST API exists; images via CDN; ~20 posts/page
  -> these NFRs drive: pagination, cache-first read, offline snapshot, push for new-post signal

The mobile-design process (say it out loud in an interview):
  requirements -> data flow/contract -> storage+caching -> offline+sync -> client arch -> trade-offs
```

```text
Mobile vs backend focus:
  Backend Q "design Twitter": fan-out, timeline service, sharding, caches, queues.
  Mobile  Q "design Twitter feed (client)": API contract, pagination, cache-first + offline snapshot,
           real-time new-tweet signal, image loading/memory, optimistic likes, client architecture.
```

## Diagrams

```mermaid
flowchart LR
    Start[design prompt] --> Clarify[clarify requirements (F + NFR)]
    Clarify --> Constraints[apply mobile constraints]
    Constraints --> Design[data flow -> storage/cache -> offline/sync -> client arch]
    Design --> Tradeoffs[justify trade-offs]
    Tradeoffs --> Iterate[iterate / deep-dive]
```

## Common Mistakes

| Mistake | Why it's wrong | Fix |
|---------|---------------|-----|
| Jumping to a solution without requirements | Designs the wrong thing | Clarify functional + NFRs first |
| Ignoring non-functional requirements | NFRs drive the design | Ask offline/real-time/scale/latency/security |
| Treating it like backend system design | Misses the mobile essence | Focus on client + contract + offline/caching |
| Ignoring device constraints | Battery/memory/network bite | Design under network/battery/memory limits |
| Presenting one "answer" without trade-offs | Misses the point of design | Justify choices; state trade-offs |
| Designing the backend when asked for the client | Off-scope | Treat backend as a given API (unless asked) |
| No structure (rambling) | Poor communication | Follow the repeatable process |

## Best Practices

- **Clarify requirements first** — functional **and** non-functional (offline/real-time/scale/latency/consistency/security/platforms) + assumptions; ask questions.
- Focus on the **mobile essence**: **client-server contract, storage/caching, offline/sync, client architecture** under **device constraints** (network/battery/memory/untrusted client).
- Follow a **repeatable process** (requirements → data flow/contract → storage/caching → offline/sync → client arch → trade-offs) and **iterate**.
- **Justify trade-offs** at every step (no single right answer); treat the backend as a **given API** unless asked to design it too.

## Performance

Not a runtime topic, but performance is a **first-class design input**: latency targets, memory/battery budgets, and network efficiency shape caching/pagination/sync choices ([Module 21](../21%20Performance/README.md)/[Module 47](../47%20Scalable%20Applications/README.md)). Good design bakes performance in from requirements, not after.

## Advantages / Disadvantages

- **+** (Structured mobile design) designs what matters, communicates clearly, justifies trade-offs, produces implementable + resilient systems.
- **−** Requires broad synthesis (whole handbook), judgment (no formula), and disciplined communication; easy to over/under-scope.

## Interview Questions

1. **🟢 How does mobile system design differ from backend system design?** — Mobile focuses on the client + its contract with the server under device constraints (offline/battery/memory/untrusted), treating the backend as a given API; backend focuses on server scaling (LB/sharding/queues).
2. **🟢 What's the first step in any system design?** — Clarify requirements — functional and especially non-functional (offline/real-time/scale/latency/security) — plus assumptions.
3. **🟡 Why do non-functional requirements matter so much?** — They (offline, real-time, scale, consistency) drive the whole design (caching/sync/protocols) far more than the feature list.
4. **🟡 What mobile constraints shape the design?** — Unreliable network (offline/flaky), battery/data, limited memory/CPU, untrusted client, and app-store/platform limits.
5. **🟡 What's the repeatable process?** — Requirements → client-server data flow/contract → storage/caching → offline/sync → client architecture → trade-offs (iterate).
6. **🔴 Why is there "no single right answer"?** — Every choice trades off (consistency vs availability, real-time vs battery, cache freshness vs offline) — design is about justified trade-offs, not one answer.
7. **🔴 When would you design the backend too?** — Only if the prompt asks; otherwise treat the backend as a given API and design the client + contract.

## Senior Engineer Tips

- Spend real time clarifying requirements (especially offline/real-time/scale) before drawing anything; interviewers and projects both reward this, and it prevents designing the wrong system.
- Frame the problem as "client + contract under constraints," not "scale a backend"; the mobile signal is caching/offline/sync/device-limits reasoning, not sharding.
- Narrate the process and the trade-offs out loud; senior design is judged on structured thinking and justified choices, not on reciting a canonical architecture.

## Architect Perspective

Mobile system design is the synthesis discipline of the whole handbook: it takes requirements + device constraints and composes networking, storage, caching, offline-first, performance, security, and the architecture band into a coherent, justified system centered on the client-server contract. Its distinguishing marks — network-unreliability and device-constraint reasoning, caching/offline/sync at the core, and trade-off articulation — are exactly what separate a senior mobile architect from an implementer. The process is repeatable; the value is judgment ([02_client_server_and_data_flow.md](02_client_server_and_data_flow.md), [03_caching_offline_and_scale.md](03_caching_offline_and_scale.md), [Module 19](../19%20Offline%20First/README.md)).

## Summary

- Mobile system design = designing the client + its server contract under device constraints (network/battery/memory/untrusted) — distinct from backend (server scaling).
- Process: clarify requirements (functional + NFRs) → data flow/contract → storage/caching → offline/sync → client architecture → trade-offs; iterate.
- Caching/offline/sync usually dominate; treat the backend as a given API (unless asked); justify trade-offs (no single answer).

## Revision Notes

- Mobile ≠ backend design: focus = client + server contract + storage/caching + offline/sync + client arch, under constraints (unreliable network, battery/data, memory/CPU, untrusted client, store limits). Backend = given API unless asked.
- Process: requirements (functional + NFR: offline/real-time/scale/latency/consistency/security/platforms) → data flow/contract → storage/caching → offline/sync → client architecture (Clean/feature/MVVM) → trade-offs; iterate.
- No single answer → justify trade-offs; NFRs + constraints drive the design; performance is a design input.

## Practice Questions

1. What questions do you ask to clarify a "design app X" prompt?
2. Why is mobile system design different from backend system design?
3. Which mobile constraints most shape the design, and how?

## Coding Questions

1. Write a requirements list (functional + NFR + assumptions) for a given app.
2. Outline the mobile-design process for that app.
3. Identify the constraint-driven decisions (caching/offline/sync) it implies.

## Mini Project

**Requirements + process (Flutter/design):** For a chosen app (e.g., a news feed or notes app), write a clarified requirements list (functional + non-functional + assumptions), identify the mobile constraints that shape it, and outline the design process (data flow → storage/caching → offline/sync → client arch → trade-offs) at a high level. Acceptance: functional + NFRs (offline/real-time/scale/latency/security) + assumptions stated; mobile constraints identified + linked to design decisions; repeatable process outlined; framed as client+contract (backend given); trade-off mindset evident.
