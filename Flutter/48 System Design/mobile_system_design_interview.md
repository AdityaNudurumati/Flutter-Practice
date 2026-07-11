# The Mobile System-Design Interview

> Mobile system-design interviews score **structured thinking, communication, and trade-off reasoning** — not a memorized "correct" architecture. Run a **repeatable framework**: (1) **clarify requirements** (functional + non-functional + scope) by asking questions, (2) sketch **high-level architecture + data flow** (client-server contract), (3) **deep-dive** the interesting parts (pagination, real-time, caching, offline/sync, the client architecture), (4) **address mobile constraints** (network/battery/memory/offline), (5) **discuss trade-offs + bottlenecks**. Common prompts ("design the Instagram feed / a chat app / a file-sync app") all reduce to **contract + caching + offline + real-time + client architecture** — communicated out loud, driven by the requirements you clarified.

## Introduction

This file gives a concrete framework + communication approach for mobile system-design interviews, maps common prompts to the design levers, and lists the signals interviewers look for. It operationalizes the fundamentals ([system_design_fundamentals.md](system_design_fundamentals.md)) for the interview setting.

## Why this concept exists

Candidates often freeze or ramble in system-design rounds, jumping to a solution or reciting a diagram. A **framework + communication discipline** turns an open-ended prompt into a structured, senior-sounding conversation — and mobile prompts have a **recognizable shape** (contract/caching/offline/real-time/architecture) you can navigate confidently once you know it.

## Real-world analogy

It's like a **structured consultation**: a good consultant doesn't blurt a solution — they **ask about your situation and constraints** (requirements), **sketch an approach** (high-level design), **dive into the tricky parts** (deep-dives), **flag risks/limits** (constraints/bottlenecks), and **explain the trade-offs** so *you* can decide. The interviewer is evaluating your consulting process, not a single "right" prescription.

## Internal Working

```mermaid
flowchart TD
    Q[prompt: 'design X app'] --> R[1. Clarify requirements (F + NFR + scope) — ASK]
    R --> HL[2. High-level architecture + data flow (client-server contract)]
    HL --> DD[3. Deep-dive: pagination / real-time / caching / offline-sync / client arch]
    DD --> C[4. Mobile constraints: network/battery/memory/offline/security]
    C --> T[5. Trade-offs + bottlenecks + 'what I'd do next']
    Note[communicate out loud; drive from requirements; no single 'right' answer]
```

- **The framework (drive it explicitly, out loud)**:
  1. **Clarify requirements** (spend real time here): functional (features to support) + **non-functional** (offline? real-time? scale/users? latency? consistency? platforms? security?) + **scope** (what's in/out). **Ask questions** — interviewers reward it and it prevents designing the wrong thing.
  2. **High-level design + data flow**: sketch client ↔ server (the **contract**), major components (API, cache/DB, real-time channel), and the **read/write data flow**. Keep it high-level first, then zoom in.
  3. **Deep-dives** (pick the interesting ones for the prompt): **pagination** (cursor), **real-time** (push/WebSocket), **caching + freshness** (SWR/etc.), **offline + sync + conflicts**, **client architecture** (Clean/feature-first/MVVM + repository/cache), image/media handling. Go deep where the prompt is hard.
  4. **Mobile constraints**: explicitly address **flaky/offline network, battery, memory, small screen, untrusted client, app-store/background limits** — this is the mobile signal.
  5. **Trade-offs + bottlenecks**: state the tensions (consistency vs availability, freshness vs battery, real-time vs cost, optimistic vs pessimistic), identify bottlenecks (network, image memory), and say **what you'd measure/do next**.
- **Common prompts → the same levers**:
  - **Instagram/Twitter feed**: cursor pagination, cache-first/SWR feed, offline snapshot, real-time new-post *signal* (push), image loading/memory, optimistic likes, repository/cache client arch.
  - **Chat/messaging (WhatsApp)**: **WebSocket** real-time, **offline-first** message queue (outbox) + sync + ordering, delivery/read receipts, local DB of messages, pagination of history, conflict/ordering handling.
  - **File sync (Dropbox/Drive)**: **offline-first** with sync engine + **conflict resolution** (versioning), chunked upload/download, background sync, bounded local cache.
  - **Maps/ride-hailing**: real-time location (stream), map tiles/markers + clustering, battery-aware location, offline caching of tiles.
  - All reduce to **contract + caching + offline/sync + real-time + client architecture** under **constraints**.
- **Communication (heavily scored)**: think out loud, **state assumptions**, structure the conversation (announce which step you're in), **draw diagrams** (boxes + arrows for data flow), invite the interviewer to steer, and **manage time** (breadth first, then depth on the key parts).
- **Signals interviewers look for**: requirements-first discipline, mobile-specific reasoning (offline/caching/battery — not backend sharding), clear data-flow diagrams, justified trade-offs, and structured communication. **Red flags**: jumping to a solution, ignoring NFRs/constraints, backend-only focus, one "answer" with no trade-offs, disorganized rambling.
- **No single right answer**: the goal is a **coherent, justified** design for the clarified requirements — defend choices, acknowledge alternatives.

## Memory Representation

Not runtime — an **interview playbook**: the 5-step framework, a mapping of prompts→levers, a diagram habit, and a communication checklist. Internalize it so the open-ended prompt becomes a structured walk.

## Compiler / Runtime / Engine / VM Behavior

Not applicable — this is a communication/reasoning skill; the underlying tech is the rest of this module + handbook.

## Examples

```text
5-step walkthrough (prompt: "design the Instagram feed"):
  1. Clarify: offline read? (yes, last feed) real-time? (new-post badge) scale? (100M) media? (images+video)
             latency? (feed<1s) -> assumptions stated.
  2. High-level: App <-REST/GraphQL-> API; local DB cache; CDN for media; WebSocket/push for new-post signal.
                 Read: cache-first + refresh. Write (like): optimistic + queued.
  3. Deep-dives: cursor pagination; SWR feed cache; offline snapshot; image memory (resized + bounded cache);
                 optimistic likes + reconcile; client arch = MVVM + repository + cache.
  4. Constraints: flaky net -> cache-first + retry; battery -> push not poll; memory -> virtualized list + image cache.
  5. Trade-offs: eventual consistency for feed (acceptable); freshness vs battery; what I'd measure (frame/startup, cache hit rate).
```

```text
Prompt -> dominant levers cheat-sheet:
  feed         -> cursor pagination + SWR cache + offline snapshot + real-time signal + image memory
  chat         -> WebSocket + offline-first outbox + ordering + local DB + receipts + history pagination
  file sync    -> offline-first sync engine + conflict/versioning + chunked transfer + background sync
  maps/ride    -> location stream + tiles/markers/clustering + battery-aware + offline tiles
```

## Diagrams

```mermaid
sequenceDiagram
    participant You
    participant Interviewer
    You->>Interviewer: clarify requirements (ask F + NFR + scope)
    You->>Interviewer: high-level design + data-flow diagram
    You->>Interviewer: deep-dive key parts (pagination/real-time/cache/offline/arch)
    You->>Interviewer: address mobile constraints
    You->>Interviewer: trade-offs + bottlenecks + next steps
    Note over You,Interviewer: think out loud; invite steering; manage time
```

## Common Mistakes

| Mistake | Why it hurts | Fix |
|---------|-------------|-----|
| Jumping to a solution/diagram | Designs the wrong thing; poor signal | Clarify requirements first (ask) |
| Ignoring non-functional requirements | Misses design drivers | Ask offline/real-time/scale/latency/security |
| Backend-only focus (sharding/LB) | Wrong for a mobile round | Client + contract + caching/offline/battery |
| One "answer," no trade-offs | Misses the point | State tensions + alternatives + justify |
| Silent thinking | Interviewer can't follow | Think out loud; announce steps |
| No diagrams | Hard to communicate data flow | Draw boxes + arrows |
| Poor time management (deep too early) | Runs out of time | Breadth first, then depth on key parts |
| Ignoring constraints | Misses mobile signal | Explicitly address network/battery/memory |

## Best Practices

- Run the **5-step framework out loud**: clarify requirements (ask, F + NFR + scope) → high-level design + **data-flow diagram** → **deep-dive** the hard parts → **mobile constraints** → **trade-offs/bottlenecks/next steps**.
- Recognize that common prompts reduce to **contract + caching + offline/sync + real-time + client architecture**; pick the **dominant levers** for the prompt.
- **Communicate** deliberately: state assumptions, structure the conversation, draw diagrams, invite steering, **manage time** (breadth → depth).
- Emphasize **mobile-specific reasoning** (offline/caching/battery/memory/untrusted client) and **justify trade-offs** — there's **no single right answer**.

## Performance

The interview tests design *thinking*, but performance reasoning is a scored sub-signal: mention latency/battery/memory budgets, cache-hit rates, and what you'd measure — showing you design with performance in mind ([Module 21](../21%20Performance/README.md)/[Module 47](../47%20Scalable%20Applications/README.md)).

## Advantages / Disadvantages

- **+** (Framework) confident, structured, senior-sounding designs; adaptable to any prompt; strong communication/trade-off signals.
- **−** Requires practice + breadth (whole handbook); still needs genuine depth on deep-dives; over-scripting can feel rote if not adapted to the prompt.

## Interview Questions

1. **🟢 What's the first thing you do in a system-design interview?** — Clarify requirements (functional + non-functional + scope) by asking questions — never jump to a solution.
2. **🟢 What's the 5-step framework?** — Clarify requirements → high-level design/data flow → deep-dive key parts → mobile constraints → trade-offs/bottlenecks/next steps.
3. **🟡 What do common mobile prompts reduce to?** — Client-server contract + caching + offline/sync + real-time + client architecture, under device constraints.
4. **🟡 How does a mobile round differ from a backend round?** — Focus on the client + contract + offline/caching/battery/memory, not server sharding/LB — treat the backend as a given API unless asked.
5. **🟡 What are interviewers actually scoring?** — Structured thinking, requirements-first discipline, mobile-specific reasoning, clear data-flow diagrams, justified trade-offs, and communication.
6. **🔴 Design a chat app's offline behavior briefly.** — Local DB of messages, an outbox for sends, WebSocket for real-time, sync + ordering on reconnect, delivery/read receipts, history pagination — offline-first with idempotent sync.
7. **🔴 Why is "no single right answer" important to convey?** — Because senior design is about justified trade-offs for the clarified requirements; defending choices + acknowledging alternatives is the signal, not a canonical diagram.

## Senior Engineer Tips

- Spend the first few minutes clarifying requirements and stating assumptions; it's the highest-ROI thing you can do and the most common thing candidates skip.
- Lead with a high-level data-flow diagram, then deep-dive the two or three genuinely hard parts (pagination/real-time/offline) — breadth first, depth where it matters, watch the clock.
- Keep the conversation mobile: reason about offline/caching/battery/memory and justify trade-offs out loud; drifting into backend sharding is the classic mobile-round miss.

## Architect Perspective

The mobile system-design interview is a proxy for real architectural work: taking an ambiguous prompt, clarifying requirements, designing the client + contract + caching/offline/real-time under constraints, and justifying trade-offs — communicated clearly. The framework isn't a script to recite but a **thinking structure** that mirrors how a senior actually designs. Mastering it (over the whole handbook's substance) is what lets you turn any "design app X" into a coherent, defensible, mobile-centric design — the culmination this module builds toward ([system_design_fundamentals.md](system_design_fundamentals.md), [client_server_and_data_flow.md](client_server_and_data_flow.md), [caching_offline_and_scale.md](caching_offline_and_scale.md)).

## Summary

- Run the 5-step framework out loud: clarify requirements → high-level design/data flow → deep-dive → mobile constraints → trade-offs/bottlenecks.
- Common prompts reduce to contract + caching + offline/sync + real-time + client architecture under device constraints; pick the dominant levers.
- Interviewers score structured thinking, mobile-specific reasoning, diagrams, justified trade-offs, and communication — no single right answer.

## Revision Notes

- Framework (out loud): 1) clarify requirements (F+NFR+scope, ASK) 2) high-level design + data-flow diagram 3) deep-dive (pagination/real-time/caching/offline-sync/client arch) 4) mobile constraints (network/battery/memory/offline/untrusted) 5) trade-offs/bottlenecks/next-steps.
- Prompts → contract + caching + offline/sync + real-time + client arch (feed/chat/file-sync/maps). Backend = given API unless asked.
- Scored: requirements-first, mobile reasoning, diagrams, justified trade-offs, communication. Red flags: jump-to-solution, ignore NFRs/constraints, backend-only, one-answer-no-tradeoffs, rambling. No single right answer.

## Practice Questions

1. Walk the 5-step framework for "design the Instagram feed."
2. What dominant levers does a chat-app prompt require?
3. What signals (and red flags) do interviewers watch for?

## Coding Questions

1. Produce a clarifying-questions list for a given prompt (F + NFR + scope).
2. Draw a high-level data-flow diagram for a feed app.
3. Deep-dive one hard part (real-time, offline-sync, or pagination) with trade-offs.

## Mini Project

**Interview walkthrough (Flutter/design):** Pick a prompt (feed, chat, or file-sync) and produce a full 5-step written walkthrough: clarifying questions + assumptions (F + NFR + scope), a high-level data-flow diagram (client-server contract), two deep-dives on the hard parts (e.g., real-time + offline-sync, or pagination + caching), explicit mobile constraints, and a trade-offs/bottlenecks/next-steps section. Acceptance: requirements clarified first (questions + assumptions); high-level diagram; ≥2 substantive deep-dives with trade-offs; mobile constraints addressed; trade-offs/bottlenecks stated; mobile-centric (not backend-sharding); communicates structure clearly.
