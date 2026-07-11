# Approach & Time Management

> Machine coding is won by a **disciplined approach under a clock**: **(1) clarify + scope** (5–10 min: confirm requirements, list must-haves vs nice-to-haves, state assumptions), **(2) plan** (sketch data model, state approach, widget breakdown, increments), **(3) build incrementally** (a working vertical slice first, then layer features — always keep it running/compiling), **(4) handle edge cases** (loading/empty/error/invalid), **(5) polish + finish** (reserve time; leave nothing broken), communicating throughout. The golden rules: **build a working thing early and keep it working**, **prioritize core over gold-plating**, **time-box aggressively**, and **always finish with something solid**.

## Introduction

This file is the process for executing a machine-coding round within the time box: clarify/scope → plan → incremental build → edge cases → polish, with time-boxing and communication. It operationalizes the "finish clean, right-sized" mindset ([machine_coding_fundamentals.md](machine_coding_fundamentals.md)).

## Why this concept exists

Without a plan, candidates thrash: they mis-scope, start coding blind, over-build one part, and run out of time with a broken app. A repeatable approach + aggressive time-boxing ensures you **always have a working, finishable submission** and spend effort on what's scored — the difference between a polished feature and a half-done mess at the buzzer.

## Real-world analogy

It's a **timed kitchen service**: first confirm the order + plan the courses (clarify/scope/plan), get a **simple plate out fast and keep the line moving** (working slice early), then add courses (incremental features), taste for problems (edge cases), and **plate + garnish before time's up** (polish/finish) — narrating to the judges throughout. Chefs who start cooking without a plan, or perfect one dish while others burn, fail the service.

## Internal Working

```mermaid
flowchart TD
    Clock[time box ~90 min] --> S1[1. clarify + scope (5-10 min): must-haves vs nice-to-haves + assumptions]
    S1 --> S2[2. plan: data model + state approach + widget breakdown + increments]
    S2 --> S3[3. build incrementally: working vertical slice FIRST -> layer features, keep it running]
    S3 --> S4[4. edge cases: loading/empty/error/invalid]
    S4 --> S5[5. polish + finish (reserve time): nothing broken]
    S1 & S3 & S5 -.communicate throughout.-> Comm[think aloud + explain]
```

- **1. Clarify + scope (5–10 min — don't skip)**:
  - **Confirm requirements**: ask about the feature, data source (API/mock/local), constraints, and expected behavior — **don't assume**; misreading the spec is fatal.
  - **List must-haves vs nice-to-haves**: identify the **core** (the thing that must work) and defer extras. **State assumptions** aloud ("I'll assume local data, no persistence").
  - This upfront time **pays back** by preventing building the wrong thing.
- **2. Plan (brief, explicit)**:
  - Sketch the **data model** (entities), the **state approach** (setState/ChangeNotifier/Provider/Bloc — right-sized — [clean_architecture_under_pressure.md](clean_architecture_under_pressure.md)), the **widget breakdown** (screens/components), and the **increment order** (what to build first→last).
  - A 2–3 min plan prevents thrashing; announce it (communication + a shared roadmap with the interviewer).
- **3. Build incrementally (the core discipline)**:
  - **Get a working vertical slice out fast** — the simplest end-to-end thing (e.g., a static list rendering, then add data, then interactions). **Always keep it compiling/running** so you're never far from a demoable state.
  - **Layer features** one at a time (add → verify → next), core first. Avoid long stretches of broken/non-compiling code.
  - This guarantees you **always have something to show** and can stop at any point with a working submission.
- **4. Handle edge cases**: once the happy path works, add **loading/empty/error** states, **input validation**, and boundary handling ([Module 38](../38%20Error%20Handling/README.md)). These are scored under **functionality** and often neglected.
- **5. Polish + finish (reserve time)**: **budget the last ~10–15%** for polish — remove dead code, fix naming, tidy UI, quick self-test, and ensure **nothing is broken**. A finished, clean submission is the goal; a broken half-feature isn't.
- **Time-boxing (aggressive)**:
  - Roughly: **~10% clarify/plan, ~60% core build, ~15% edge cases, ~15% polish/finish** (adjust to length). **Watch the clock**; if behind, **cut nice-to-haves**, not correctness/finishing.
  - **Don't rabbit-hole**: if stuck on one detail, **stub/simplify it** and move on (note it aloud) — finishing the whole > perfecting one part.
- **Communicate throughout** (scored): narrate your plan, decisions, trade-offs, and what you're cutting; ask when unsure; respond to hints. It shows engineering judgment + collaboration.
- **If time runs short**: **finish a smaller scope cleanly** rather than leaving the full scope broken — always land on a working, polished slice.

## Memory Representation

Not code — a **time-boxed plan**: phase budget (clarify/plan/build/edge/polish), a must-have/nice-to-have list, a data-model/state/widget/increment sketch, and a running-slice checkpoint you protect. The submission stays demoable at every step.

## Compiler / Runtime Behavior

Keeping the app **compiling/running** at each increment is the discipline — you're never in a "big broken refactor" with no working state. Run it frequently to verify.

## Flutter Engine / Dart VM Behavior

Not applicable beyond running your Flutter app normally (hot reload speeds the incremental loop).

## Examples

```text
Time box (~90 min) — phase budget:
  0-10   clarify + scope (must-haves vs nice-to-haves, assumptions) + plan (model/state/widgets/increments)
  10-65  build core incrementally (working slice first, layer features, keep it running)
  65-80  edge cases (loading/empty/error/invalid)
  80-90  polish + finish (dead code, naming, UI, self-test — nothing broken)
  throughout: communicate (plan, decisions, cuts)

Increment order example (searchable list):
  1) render a static list  2) load data (mock)  3) show loading/empty/error
  4) add search filter  5) polish UI  (+pagination only if time = nice-to-have)
  -> app RUNS after every step; stop anytime with a working submission
```

```text
Rules:
  working thing EARLY + keep it working | core before gold-plating | time-box aggressively |
  don't rabbit-hole (stub + move on) | reserve polish time | ALWAYS finish something solid |
  communicate + state assumptions throughout
```

## Diagrams

```mermaid
flowchart LR
    Slice[working vertical slice EARLY] --> Layer[layer features (core first, keep running)]
    Layer --> Edge[edge cases]
    Edge --> Polish[reserve time -> polish + finish]
    Clock2[watch clock: cut nice-to-haves if behind, never correctness/finish]
```

## Common Mistakes

| Mistake | Why it fails | Fix |
|---------|-------------|-----|
| Skipping clarify/scope | Builds the wrong thing | 5-10 min clarify + must/nice-to-have + assumptions |
| Coding with no plan | Thrashing, wasted time | Brief plan (model/state/widgets/increments) |
| Big broken stretches (not running) | Nothing to show if time ends | Incremental slices, keep it compiling/running |
| Gold-plating before core works | Wrong priorities, no finish | Core happy path first; extras only if time |
| Rabbit-holing one detail | Blows the budget | Stub/simplify + move on (note it) |
| No time reserved for polish | Messy/broken at buzzer | Reserve last ~10-15% for polish/finish |
| Ignoring edge cases | Fails functionality | Add loading/empty/error/invalid |
| Silent execution | Misses communication | Narrate plan/decisions/cuts throughout |

## Best Practices

- **Clarify + scope first** (5–10 min: must-haves vs nice-to-haves + assumptions), then **plan** (data model, state approach, widget breakdown, increment order) — announce both.
- **Build incrementally**: a **working vertical slice early**, then **layer features (core first)** while **keeping it running** — so you're always demoable.
- **Handle edge cases** (loading/empty/error/invalid) after the happy path; **reserve ~10–15% for polish/finish** (nothing broken); **time-box aggressively** and **cut nice-to-haves (not correctness/finishing)** if behind.
- **Don't rabbit-hole** (stub/simplify + move on); **communicate throughout**; if short on time, **finish a smaller scope cleanly**.

## Performance

Not runtime perf — the "performance" is finishing a clean feature within the box. The approach maximizes it: upfront scoping avoids wasted work, incremental slices keep you demoable, aggressive time-boxing prevents the buzzer catching you broken. Hot reload keeps the build loop fast.

## Advantages / Disadvantages

- **+** Always-demoable submission, correct scoping, finished + polished result, effort on scored axes, calm execution under pressure.
- **−** Requires discipline (resisting gold-plating/rabbit-holes), upfront scoping/planning time, honest time-boxing + cutting scope when behind.

## Interview Questions

1. **🟢 What's the first thing you do in a machine-coding round?** — Clarify requirements + scope (must-haves vs nice-to-haves, state assumptions) — 5–10 min — before coding, to avoid building the wrong thing.
2. **🟢 Why build a working vertical slice early?** — So the app is always demoable/runnable; you can stop at any point with something working, rather than risk a broken half-feature at the buzzer.
3. **🟡 How do you time-box a ~90-min round?** — Roughly ~10% clarify/plan, ~60% core build, ~15% edge cases, ~15% polish/finish; watch the clock and cut nice-to-haves (not correctness/finishing) if behind.
4. **🟡 What do you do when stuck on one detail?** — Stub/simplify it and move on (noting it aloud); finishing the whole feature beats perfecting one part.
5. **🟡 When do you add edge cases + polish?** — Edge cases (loading/empty/error/invalid) after the happy path works; reserve the last ~10–15% for polish/finish so nothing is broken.
6. **🔴 What if you're running out of time?** — Finish a smaller scope cleanly (cut nice-to-haves) rather than leaving the full scope broken — always land on a working, polished slice.
7. **🔴 Why communicate throughout, and what do you communicate?** — It's scored (judgment/collaboration): narrate your plan, decisions, trade-offs, assumptions, and what you're cutting; ask when unsure.

## Senior Engineer Tips

- Spend the first 5–10 minutes clarifying + planning and announce your scope/increments; it feels like "not coding" but it's the highest-ROI time — it prevents building the wrong thing and shows judgment.
- Keep the app compiling/running after every small increment and reserve the last chunk for polish; the candidates who fail usually have a broken, half-refactored app when time is called.
- Resist rabbit holes and gold-plating: stub the hard/optional bits, finish the core cleanly, and cut nice-to-haves before correctness — a smaller finished feature always beats an ambitious broken one.

## Architect Perspective

The approach is time-boxed engineering discipline: scope tightly, plan briefly, build in always-running increments (core first), handle edge cases, and reserve time to finish + polish — communicating throughout. It's the same prioritization + right-sizing the handbook teaches, compressed under a clock, ensuring you always deliver a clean, working, finishable feature. Combined with right-sized architecture and practiced patterns, it makes machine-coding outcomes consistent rather than luck-of-the-clock ([clean_architecture_under_pressure.md](clean_architecture_under_pressure.md), [common_problems_and_patterns.md](common_problems_and_patterns.md), [machine_coding_fundamentals.md](machine_coding_fundamentals.md)).

## Summary

- Approach: clarify + scope (must/nice-to-have + assumptions) → plan (model/state/widgets/increments) → build incrementally (working slice first, keep running, core first) → edge cases → reserve time to polish + finish.
- Time-box aggressively (~10/60/15/15), don't rabbit-hole (stub + move on), cut nice-to-haves (not correctness/finishing) if behind, and communicate throughout.
- Always finish something solid — a smaller clean feature beats an ambitious broken one.

## Revision Notes

- Phases (time-box ~90min): clarify+scope 5-10min (must/nice-to-have + assumptions) → plan (data model/state approach/widget breakdown/increment order) → build incrementally (working vertical slice FIRST, layer core-first, keep compiling/running) → edge cases (loading/empty/error/invalid) → polish+finish (reserve ~10-15%, nothing broken).
- Rules: working thing early + keep working; core before gold-plating; aggressive time-box (~10/60/15/15); don't rabbit-hole (stub+move on); cut nice-to-haves not correctness/finish if behind; ALWAYS finish something solid; communicate (plan/decisions/cuts/assumptions) throughout; hot reload speeds the loop.

## Practice Questions

1. What's the phase breakdown + time budget for a ~90-min round?
2. Why keep the app running at every increment?
3. What do you cut when behind, and what do you never cut?

## Coding Questions

1. For a given prompt, write the clarify questions + scope + increment plan.
2. Order the build increments so the app runs after each step.
3. Define the phase time budget + what you'd cut if 20 min behind.

## Mini Project

**Timed approach plan (prep):** For a common prompt (e.g., a searchable list), write a full execution plan for a ~90-min box: clarify questions + scope (must vs nice-to-have + assumptions), a brief plan (data model/state approach/widget breakdown), an ordered increment list (app runs after each), an edge-case list, a reserved polish/finish step, and the time budget + what you'd cut if behind. Acceptance: clarify-first + scoped (must/nice-to-have + assumptions); increment order keeps the app running (working slice early, core first); edge cases + reserved polish; time-boxed with a cut-list (never correctness/finishing); communication points noted.
