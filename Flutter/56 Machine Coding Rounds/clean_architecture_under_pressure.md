# Clean Architecture Under Pressure

> Under a clock you need **just enough structure** — enough to score "well-structured/extensible" without burning time you need to finish. The reliable middle ground: **MVVM-lite** — separate **UI (thin widgets)** from **logic/state (a view model / `ChangeNotifier` or Cubit)** from **data (a simple repository/service)**, pick the **simplest state approach that fits** (`setState` for trivial local UI; `ChangeNotifier`+`Provider` or a Cubit for anything shared/async), keep a **flat, sensible folder structure**, and **stop layering there** — no full Clean Architecture (use cases/DTOs/interfaces) for a 90-minute app. The rule: **separate concerns, right-sized** — not a god-widget, not five layers.

## Introduction

This file covers right-sized architecture for machine coding: the MVVM-lite separation, choosing state management under time, folder structure, and where to *stop* layering. It applies MVVM/Clean/state-management ([Module 43](../43%20MVVM/README.md)/[Module 40](../40%20Clean%20Architecture/README.md)/[Module 11](../11%20State%20Management/README.md)) with the volume turned down.

## Why this concept exists

The structure axis is scored, but so is finishing — and the two most common failures are **opposite**: a **god-widget** (no separation → unreadable/unextensible → low structure score) and **over-engineering** (full Clean Architecture → no time to finish → low completeness). Right-sizing threads the needle: clear separation of UI/logic/data with the **minimum ceremony**, so you demonstrate architecture *and* finish.

## Real-world analogy

It's **organizing a pop-up shop for a weekend**, not building a permanent department store: you still separate the **counter (UI)**, the **register/logic (state)**, and the **stockroom (data)** so it runs cleanly — but you don't install a full corporate org chart, five management layers, and a logistics ERP for a two-day event. Right-sized separation makes it work + look professional without over-building for the timeframe.

## Internal Working

```mermaid
flowchart TD
    UI[UI: thin widgets (render state + emit intents)] --> VM[logic/state: view model (ChangeNotifier/Cubit)]
    VM --> Data[data: simple repository/service (mock/API/local)]
    State{state approach} --> Choose[setState (trivial local) | ChangeNotifier+Provider / Cubit (shared/async)]
    Stop[STOP layering here: no use cases/DTOs/interfaces for a 90-min app]
    Note[separate concerns, RIGHT-SIZED: not a god-widget, not full Clean Arch]
```

- **The right-sized target — MVVM-lite** ([Module 43](../43%20MVVM/README.md)):
  - **UI (thin widgets)**: render state + forward intents (button → `vm.add()`); no business logic, no direct data calls. Break big screens into small widgets (readable + reusable).
  - **Logic/state (view model)**: a `ChangeNotifier`/Cubit holding state + operations, calling the data layer, exposing observable state the UI binds to. **UI-free** (testable).
  - **Data (simple repository/service)**: a plain class fetching/persisting (mock list, `http`/`dio` call, or local store). Return domain-ish models — **skip DTOs/mappers unless the API demands it**.
  - This gives **clear separation (scored)** with **minimal ceremony (finishable)**.
- **Choosing state management under time** ([Module 11](../11%20State%20Management/README.md)):
  - **`setState`**: fine for **trivial, purely-local** UI state (a toggle, a single screen with no shared/async logic). Don't over-reach for a package when `setState` suffices.
  - **`ChangeNotifier` + `Provider`** (or **Cubit**): the **default** for anything with **shared state, async, or multiple widgets** — clean, low-boilerplate, testable, familiar to interviewers. **Recommended** for most machine-coding prompts.
  - **Bloc/Riverpod**: fine **if you're fluent** and the prompt is complex — but **don't pick an unfamiliar tool under time**; pick what you can move fastest in cleanly. Interviewers care about **clean state handling**, not a specific library.
  - Whatever you pick: **scope rebuilds**, expose **immutable-ish state**, keep the view model UI-free.
- **Folder structure (flat + sensible)**: a small feature-oriented layout — `models/`, `<feature>_view_model.dart` (or a `state/` folder), `<feature>_repository.dart`, `widgets/`, `screens/`. **Don't** create a deep domain/data/presentation × feature matrix for a tiny app — keep it **navigable in seconds**.
- **Where to STOP layering (crucial)**: for a ~90-min app, **skip** full Clean Architecture — **no use cases/interactors, no DTO↔entity mappers, no repository interfaces + DI containers**, unless the prompt is large/senior-level. MVVM-lite (UI/VM/repo) is enough. **Mention** you'd add layers "if this grew" (shows judgment) but **don't build them now**.
- **Right-sizing by prompt/level**: trivial (a counter) → `setState` in a well-organized widget; typical (list+search / todo / form) → **MVVM-lite + ChangeNotifier/Cubit**; large/senior take-home → add a use-case/interface layer + tests if time. **Match structure to scope + level**.
- **Edge cases live in the view model/state** (loading/empty/error as explicit states — [Module 38](../38%20Error%20Handling/README.md)); the UI renders each. This is both structure + functionality points.
- **Testability signal (bonus)**: because the view model is UI-free, a **quick unit test** (or two) of a state transition is a strong signal if time allows — but **finish the feature first** ([Module 49](../49%20Testing/README.md)).

## Memory Representation

Not new structures — a **layer map**: thin widgets ↔ a UI-free view model (state + ops) ↔ a simple repository/service, in a flat feature folder. State lives in the view model (observable); UI holds none. No use-case/DTO/interface layers unless justified.

## Compiler Behavior

The view model is plain Dart (compiles UI-free → testable); the UI binds to it. Keeping separation compile-clean (no widget imports in the VM) is the checkable boundary — cheap to maintain.

## Runtime Behavior

Intent → VM op → (repo) → state update → UI rebuilds (scoped). Same reactive flow as MVVM, just fewer layers. Edge-case states (loading/empty/error) drive the UI.

## Flutter Engine / Dart VM Behavior

Standard (scoped rebuilds; VM logic plain Dart). Not internals-relevant to the round beyond writing efficient rebuilds.

## Examples

```dart
// RIGHT-SIZED (MVVM-lite): thin UI + UI-free view model + simple repo — enough separation, finishable

// data: simple repository (mock or API) — no DTOs/interfaces unless needed
class TodoRepository {
  final _todos = <Todo>[];
  Future<List<Todo>> all() async => List.unmodifiable(_todos);
  Future<void> add(Todo t) async => _todos.add(t);
}

// logic/state: UI-free view model (ChangeNotifier) — state + operations + edge states
class TodoViewModel extends ChangeNotifier {
  final TodoRepository repo;
  TodoViewModel(this.repo);
  TodoState state = const TodoLoading();
  Future<void> load() async {
    state = const TodoLoading(); notifyListeners();
    state = TodoData(await repo.all());              // (add try/catch -> TodoError for edge case)
    notifyListeners();
  }
  Future<void> add(String text) async {
    if (text.trim().isEmpty) return;                 // validation (edge case)
    await repo.add(Todo(text.trim())); await load();
  }
}

// UI: thin widget binds + forwards intents
class TodoScreen extends StatelessWidget {
  const TodoScreen({super.key});
  @override
  Widget build(BuildContext c) {
    final vm = c.watch<TodoViewModel>();
    return switch (vm.state) {
      TodoLoading() => const Center(child: CircularProgressIndicator()),
      TodoData(:final todos) when todos.isEmpty => const Center(child: Text('No todos')),
      TodoData(:final todos) => ListView(children: [for (final t in todos) TodoTile(t)]),
      TodoError() => const Center(child: Text('Something went wrong')),
    };
  }
}
```

```text
Right-size by prompt/level:
  trivial (counter/toggle)     -> setState in a well-organized widget
  typical (todo/list+search/form) -> MVVM-lite + ChangeNotifier/Cubit + simple repo   [DEFAULT]
  large/senior take-home       -> + use-case/interface layer + tests (if time)
STOP: no use cases/DTOs/interfaces/DI for a 90-min app (mention "I'd add them if this grew")
```

## Diagrams

```mermaid
flowchart LR
    God[god-widget (no separation)] -->|low structure| Bad2[bad]
    Over[full Clean Arch (over-engineered)] -->|no finish| Bad3[bad]
    RightSized[MVVM-lite: thin UI + UI-free VM + simple repo] -->|structure + finishes| Good2[good]
```

## Common Mistakes

| Mistake | Why it scores low | Fix |
|---------|-------------------|-----|
| God-widget (logic/state in `build`) | No separation, unreadable | MVVM-lite: thin UI + UI-free view model |
| Full Clean Arch (use cases/DTOs/interfaces/DI) | Over-engineered, no time to finish | Right-size: UI/VM/repo only |
| Picking an unfamiliar state tool under time | Slow, error-prone | Use what you're fluent in (ChangeNotifier/Cubit) |
| `setState` for shared/async state | Tangled, hard to manage | ChangeNotifier/Provider or Cubit |
| Deep folder matrix for a tiny app | Navigation overhead | Flat, feature-oriented folders |
| Business logic in the UI | Untestable/tangled | Logic in the view model |
| DTOs/mappers for a mock/simple API | Wasted time | Skip unless the API demands it |
| Edge-case states as ad hoc booleans | Inconsistent UI | Explicit loading/data/empty/error state |

## Best Practices

- Target **MVVM-lite**: thin **UI** (render + intents) ↔ **UI-free view model** (state + operations + edge-case states) ↔ **simple repository/service** — clear separation with **minimal ceremony**.
- Pick the **simplest state approach that fits** and that you're **fluent in**: `setState` (trivial local), **ChangeNotifier+Provider / Cubit** (shared/async — default); don't adopt an unfamiliar tool under time.
- Keep a **flat, feature-oriented folder structure**; **stop layering at UI/VM/repo** (no use cases/DTOs/interfaces/DI for a ~90-min app) — **mention** you'd add them "if it grew."
- Model **edge cases as explicit states** (loading/empty/error) in the VM; keep the **VM UI-free** (bonus: a quick state-transition **test** if time) — but **finish the feature first**; **right-size to prompt + level**.

## Performance

Not runtime perf — the right-sizing *is* the win: enough structure to score, little enough to finish. MVVM-lite keeps the VM testable + UI thin (scoped rebuilds) without the boilerplate that eats your clock. Over/under-structuring both cost you points; the middle finishes clean.

## Advantages / Disadvantages

- **+** Scores structure (clear separation, sensible state) *and* finishes (minimal ceremony); testable VM; readable/extensible; fast to build if practiced.
- **−** Requires judgment (where to stop layering), fluency in a state tool, discipline to resist both god-widgets and full Clean Arch under stress.

## Interview Questions

1. **🟢 How much architecture do you use in a machine-coding round?** — Right-sized MVVM-lite: separate thin UI, a UI-free view model (state + ops), and a simple repository — enough to score structure without over-engineering that prevents finishing.
2. **🟢 Which state management do you pick, and why?** — The simplest that fits and you're fluent in: `setState` for trivial local; ChangeNotifier+Provider or Cubit for shared/async (default) — interviewers care about clean state handling, not a specific library.
3. **🟡 Where do you stop layering, and why?** — At UI/VM/repo — skip use cases/DTOs/interfaces/DI for a ~90-min app; mention you'd add them if it grew (judgment), but building them wastes finish-time.
4. **🟡 What are the two opposite failure modes?** — God-widget (no separation → low structure) and full Clean Architecture (over-engineered → no finish); right-sizing avoids both.
5. **🟡 How do you handle edge cases architecturally?** — As explicit states (loading/empty/error + validation) in the view model, rendered by the UI — scoring both structure and functionality.
6. **🔴 Why not adopt Bloc/Riverpod if you don't use it daily?** — Under time pressure, an unfamiliar tool slows you and risks errors; use the one you can move fastest in cleanly.
7. **🔴 How does structure scale with the prompt/level?** — Trivial → `setState` in an organized widget; typical → MVVM-lite; large/senior → add a use-case/interface layer + tests if time.

## Senior Engineer Tips

- Default to MVVM-lite (thin UI + UI-free ChangeNotifier/Cubit + simple repo) for almost every prompt; it's the sweet spot that scores structure and lets you finish, and it's fast once practiced.
- Say out loud where you'd add layers "if this grew" while deliberately not building them now; that demonstrates architectural judgment without spending the time that full Clean Architecture would cost.
- Model loading/empty/error as explicit states in the view model and keep it UI-free; you get structure + functionality points cheaply, plus the option of a quick unit test if time remains.

## Architect Perspective

Right-sizing under pressure is the handbook's proportionality lesson at its sharpest: MVVM-lite (UI/VM/repo) gives clear, testable separation with minimal ceremony, scoring the structure axis while leaving time to finish — avoiding both the god-widget and full-Clean-Architecture extremes. Choosing a familiar state tool and stopping layering at the right depth (while signaling you *could* go further) is exactly the judgment machine coding rewards, mirroring real-world "scale architecture to the problem" ([Module 43](../43%20MVVM/README.md), [Module 40](../40%20Clean%20Architecture/README.md), [Module 11](../11%20State%20Management/README.md), [approach_and_time_management.md](approach_and_time_management.md)).

## Summary

- Use MVVM-lite: thin UI ↔ UI-free view model (state + ops + edge states) ↔ simple repository — clear separation, minimal ceremony.
- Pick the simplest state tool you're fluent in (`setState` trivial; ChangeNotifier/Cubit default); flat feature folders; stop layering at UI/VM/repo (no use cases/DTOs/interfaces/DI) — mention you'd add them if it grew.
- Model edge cases as explicit states; keep the VM testable; right-size to prompt/level; finish first, test if time.

## Revision Notes

- Target: MVVM-lite — UI (thin: render + intents) ↔ view model (UI-free: state + operations + loading/empty/error states) ↔ simple repository/service (skip DTOs/interfaces/mappers unless API demands). Clear separation, minimal ceremony.
- State: `setState` (trivial local) | ChangeNotifier+Provider / Cubit (shared/async — DEFAULT) | Bloc/Riverpod only if fluent + complex. Use the fastest-clean tool you know; scope rebuilds; VM UI-free/testable.
- Folders: flat, feature-oriented. STOP layering at UI/VM/repo for ~90min app (no use cases/DTO/interfaces/DI — mention "if it grew"). Right-size by prompt/level (trivial→setState; typical→MVVM-lite; large/senior→+use-case/interface+tests). Edge cases as explicit states; quick VM test if time (finish first). Avoid god-widget + over-engineering (opposite failures).

## Practice Questions

1. What does MVVM-lite look like, and why is it the sweet spot?
2. Which state approach do you pick for trivial vs shared/async state?
3. Where do you stop layering in a 90-min app, and how do you signal judgment?

## Coding Questions

1. Refactor a god-widget prompt into thin UI + UI-free view model + simple repo.
2. Choose + justify a state approach for a given prompt (and reject over-engineering).
3. Model loading/empty/error as explicit states in the view model.

## Mini Project

**Right-sized structure (prep):** For a typical prompt (todo or list+search), implement MVVM-lite: thin UI widgets, a UI-free `ChangeNotifier`/Cubit view model (state + operations + explicit loading/empty/error states + validation), and a simple repository (mock/API) — in a flat feature folder, stopping layering at UI/VM/repo (note where you'd add layers "if it grew"), and add one quick VM unit test if time. Acceptance: clear UI/VM/repo separation (not a god-widget, not full Clean Arch); fluent state tool chosen + justified; edge cases as explicit states; VM UI-free/testable; flat folders; right-sized to prompt/level with a "would add layers if it grew" note.
