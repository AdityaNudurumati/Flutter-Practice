# ViewModel Design (State, Commands, Over Use Cases)

> A good ViewModel exposes exactly two things to the View: **immutable state** (one snapshot describing the whole screen — loading/data/empty/error + display fields) and **commands** (methods the View calls: `search(q)`, `retry()`). It **maps domain results to that state** (entity→view model, `Result`/`Failure`→message), applies **presentation logic** (sequencing, formatting, derived fields), and **delegates all rules/IO to use cases** — never holding a View reference, `BuildContext`, business rules, or raw data sources. Keep it **cohesive and per-screen**; a ViewModel doing everything becomes the god-object MVVM is meant to avoid.

## Introduction

This file details ViewModel craft: modeling state as one immutable snapshot, designing commands, handling loading/error/effects, delegating over use cases, and avoiding fat view models. It's the "how to write a good ViewModel" companion to the fundamentals ([01_mvvm_fundamentals.md](01_mvvm_fundamentals.md)).

## Why this concept exists

The ViewModel is where presentation logic lives; if it's designed poorly (mutable ad-hoc fields, business rules baked in, View coupling, god-object scope) MVVM's benefits evaporate. A disciplined ViewModel — single immutable state, clear commands, delegation downward — is what makes the View trivial and the logic testable.

## Real-world analogy

A ViewModel is a **well-run control panel**: it shows **one coherent status board** (immutable state) rather than scattered blinking lights, offers a few **labeled buttons** (commands), and **delegates the actual machinery** to specialists behind the wall (use cases). A bad control panel wires the buttons directly to every motor (business logic inside), mixes twenty unrelated systems (god-object), and has a wire running to the operator's chair (holds the View) — brittle and unmaintainable.

## Problem Statement

Design a `SearchViewModel`: model its state as one immutable snapshot (idle/loading/results/empty/error), expose `search(query)`/`retry()`/`clear()` commands, debounce input, map domain results, delegate to a `SearchProducts` use case, and expose one-off effects (e.g., a snackbar) without re-firing — all cohesive and testable. You'll design state + commands + delegation.

## Internal Working

```mermaid
flowchart TD
    View -->|commands| VM[ViewModel]
    VM --> State[immutable state snapshot (one object)]
    VM --> Commands[commands: search/retry/clear]
    VM --> Map[map domain -> view state (entity->vm, failure->message)]
    VM --> Delegate[delegate rules/IO -> use cases]
    VM --> Effects[one-off effects channel (snackbar/nav) fire-once]
    Delegate --> UC[use cases (domain)]
```

- **State = one immutable snapshot**: model the **whole screen** as a single immutable value (a sealed union or a state class with `copyWith`) — `SearchState.idle/loading/results(items)/empty/error(msg)`. One source of truth per screen beats scattered `bool isLoading`, `List items`, `String? error` fields (which drift into inconsistent combos).
- **Commands**: public methods the View calls to express intent (`search(q)`, `retry()`, `clear()`, `loadMore()`). Each updates state (via new snapshots + notify) and delegates work. Keep them **intent-named**, not implementation-named.
- **Mapping (presentation logic)**: convert **entities → view models** (formatted/derived fields via `intl`) and **`Result`/`Failure` → messages/error state** ([Module 38](../38%20Error%20Handling/README.md)). The View never sees domain types needing formatting.
- **Delegate rules/IO to use cases**: the ViewModel **orchestrates** (call use case, sequence loading, combine results) but contains **no business rules** (domain) and **no raw I/O** (data) — it depends on **use cases**, injected via DI ([Module 40](../40%20Clean%20Architecture/README.md)/[Module 14](../14%20Dependency%20Injection/README.md)).
- **Loading/error/empty sequencing**: emit `loading` before async work, then `data`/`empty`/`error`; make it correct and testable (the state sequence is the contract — [04_mvvm_testing_and_comparison.md](04_mvvm_testing_and_comparison.md)).
- **One-off effects** (nav/snackbar/toast): don't bake into rebuildable state (re-fires on rebuild); expose via a **one-shot channel** (a stream of events, or a consumed flag) the View reacts to once. State vs effects distinction (as in MVP — [Module 42](../42%20MVP/README.md)).
- **Input handling**: debounce/throttle at the ViewModel (e.g., search) so commands don't hammer use cases.
- **Cohesion / no god-object**: **one ViewModel per screen/feature**, single responsibility; extract shared logic into use cases/services; split when it grows unrelated concerns.
- **Lifecycle**: dispose subscriptions/controllers (`dispose`/`close`) tied to the View/DI lifecycle.

## Memory Representation

ViewModel holds the current immutable state snapshot + injected use cases + subscriptions/effect channel. New snapshots replace old on change; the View rebuilds from the latest. No mutable ad-hoc field soup.

## Compiler Behavior

Sealed state unions give exhaustive `switch` in the View (can't miss a state). ViewModel compiles UI-free (plain Dart) → testable.

## Runtime Behavior

Command → (debounce) → emit loading → call use case → map result → emit data/empty/error (+ maybe a one-off effect). The View rebuilds from state; effects fire once.

## Flutter Engine Behavior

Only the View touches the engine; the VM emits state, bound widgets rebuild ([01_mvvm_fundamentals.md](01_mvvm_fundamentals.md)).

## Dart VM Behavior

VM logic is plain Dart (fast unit tests on state sequences); dispose subscriptions to avoid leaks.

## Examples

```dart
import 'package:flutter/foundation.dart';

// STATE — one immutable snapshot (sealed) describing the whole screen
sealed class SearchState { const SearchState(); }
class SearchIdle extends SearchState { const SearchIdle(); }
class SearchLoading extends SearchState { const SearchLoading(); }
class SearchResults extends SearchState { final List<ProductVm> items; const SearchResults(this.items); }
class SearchEmpty extends SearchState { const SearchEmpty(); }
class SearchError extends SearchState { final String message; const SearchError(this.message); }

// VIEWMODEL — state + commands; maps domain; delegates to a use case; debounces; effects channel
class SearchViewModel extends ChangeNotifier {
  final SearchProducts searchProducts;                 // use case (domain)
  SearchViewModel(this.searchProducts);
  SearchState state = const SearchIdle();
  final _effects = StreamController<VmEffect>.broadcast(); // one-off effects
  Stream<VmEffect> get effects => _effects.stream;
  Timer? _debounce;

  void search(String q) {                              // command (intent-named)
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _run(q)); // debounce
  }
  void retry() { if (state is SearchError) _run(_lastQuery); }
  void clear() { state = const SearchIdle(); notifyListeners(); }

  Future<void> _run(String q) async {
    _lastQuery = q;
    state = const SearchLoading(); notifyListeners();  // sequence: loading first
    final r = await searchProducts(q);                 // delegate rules/IO
    state = switch (r) {
      Success(:final value) when value.isEmpty => const SearchEmpty(),
      Success(:final value) => SearchResults(value.map(ProductVm.from).toList()), // map
      Failure(:final error) => SearchError(messageFor(error)),                    // message
    };
    notifyListeners();
  }
  String _lastQuery = '';
  @override void dispose() { _debounce?.cancel(); _effects.close(); super.dispose(); } // lifecycle
}
```

## Diagrams

```mermaid
flowchart LR
    Intent[View command] --> Debounce[debounce]
    Debounce --> Loading[emit loading]
    Loading --> UC[use case]
    UC --> Map[map -> results/empty/error]
    Map --> Emit[emit state (immutable) + notify]
    UC -.one-off.-> Effect[effects channel (fire once)]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| Scattered `bool/list/error` fields | Inconsistent state combos | One immutable state snapshot (sealed) |
| Business rules/IO in the VM | Wrong layer, untestable | Delegate to use cases/repos |
| VM holds View/`BuildContext` | Couples/untestable (MVP-ish) | VM exposes state; View observes |
| Effects in rebuildable state | Re-fire on rebuild | One-shot effects channel |
| God ViewModel | Unmaintainable | One per screen; split; extract services |
| No debounce on input | Hammers use cases | Debounce/throttle in the VM |
| Not disposing subscriptions | Leaks | `dispose`/`close` tied to lifecycle |
| Rendering unformatted entities | UI shape ≠ domain | Map entity → view model |

## Best Practices

- Model the screen as **one immutable state snapshot** (sealed union / `copyWith`), not scattered fields; expose **intent-named commands**.
- **Map domain → view state** (entity→view model, failure→message) and **delegate all rules/IO to use cases**; keep the VM **UI-free** (no View/`BuildContext`).
- Handle **loading/error/empty sequencing** (the testable contract) and **one-off effects via a separate channel** (fire once); **debounce** input.
- Keep the VM **cohesive/per-screen** (no god-objects); **dispose** subscriptions; inject use cases via **DI**.

## Performance

One immutable snapshot + scoped binding keeps rebuilds predictable/minimal. Debouncing avoids redundant use-case calls. Delegation keeps the VM light. God-objects + unscoped notifies are the pitfalls ([Module 21](../21%20Performance/README.md)).

## Advantages / Disadvantages

- **+** Consistent single-source state, testable VM (state sequences), dumb views, clean delegation, cohesive per-screen logic.
- **−** State-modeling + effects-channel boilerplate, discipline to keep rules/IO out and avoid god-objects, DI wiring.

## Interview Questions

1. **🟢 What should a ViewModel expose to the View?** — Immutable state (one snapshot: loading/data/empty/error + display fields) and commands (intent methods).
2. **🟢 Why one immutable state snapshot vs scattered fields?** — Scattered `bool/list/error` fields drift into inconsistent combinations; one snapshot is a single source of truth that's easy to render and test.
3. **🟡 What does the ViewModel delegate, and to what?** — Business rules and I/O to use cases/repositories; it only orchestrates + maps to view state.
4. **🟡 How do you handle one-off effects (navigation/snackbar)?** — Via a separate one-shot channel (event stream/consumed flag) the View reacts to once — not in rebuildable state (which re-fires).
5. **🟡 Why keep the VM UI-free (no `BuildContext`/View)?** — To keep it reactive (View observes it), testable (plain Dart), and uncoupled from the UI.
6. **🔴 How do you prevent fat/god ViewModels?** — One per screen with a single responsibility; extract shared logic into use cases/services; split when unrelated concerns creep in.
7. **🔴 Why debounce commands like search?** — To avoid hammering use cases/network on every keystroke; debounce/throttle in the VM.

## Senior Engineer Tips

- Model state as a sealed union and switch on it in the View; it eliminates the "loading true but also has error and data" bug class and makes state-sequence tests trivial.
- Keep the VM a thin orchestrator over use cases — no rules, no raw I/O, no `BuildContext`; that's what keeps it testable and prevents the god-object.
- Route navigation/snackbars through a one-shot effects channel, not state; the "snackbar shows twice / navigates on rebuild" bug is always effects-modeled-as-state.

## Architect Perspective

The ViewModel is the presentation-logic unit of MVVM: a cohesive, UI-free orchestrator exposing one immutable state + commands, mapping domain to view state, delegating downward. Designed this way it makes the View trivial, the logic exhaustively testable via state sequences, and slots as the presentation layer over Clean's use cases. Poor VM design (field soup, baked-in rules, god-objects, effects-in-state) is the main way MVVM goes wrong — discipline here is the whole game ([01_mvvm_fundamentals.md](01_mvvm_fundamentals.md), [04_mvvm_testing_and_comparison.md](04_mvvm_testing_and_comparison.md), [Module 40](../40%20Clean%20Architecture/README.md)).

## Summary

- ViewModel exposes one immutable state snapshot + intent commands, maps domain→view state, delegates rules/IO to use cases; UI-free (no View/context).
- Handle loading/empty/error sequencing (testable contract) and one-off effects via a separate channel; debounce input; dispose subscriptions.
- Keep it cohesive/per-screen (no god-objects); inject use cases via DI; sealed state enables exhaustive rendering + easy tests.

## Revision Notes

- Expose: immutable state (sealed union/`copyWith`) + commands (intent-named). Map entity→view model, `Result`/`Failure`→message.
- Delegate rules/IO → use cases (DI); UI-free (no View/`BuildContext`); loading/empty/error sequencing; one-off effects via separate channel (fire once); debounce input; dispose subs.
- One VM per screen (no god-object); sealed state → exhaustive `switch` in View + testable sequences.

## Practice Questions

1. Why model state as one immutable snapshot?
2. What belongs in the VM vs the use case?
3. How do you expose a one-off effect without re-firing?

## Coding Questions

1. Design a sealed state union + a ViewModel with commands over a use case.
2. Add debounced search + loading/empty/error sequencing.
3. Add a one-shot effects channel for navigation and dispose subscriptions.

## Mini Project

**Search ViewModel (Flutter):** Build a `SearchViewModel` with a sealed state (idle/loading/results/empty/error), commands (`search` debounced, `retry`, `clear`), domain mapping (entity→view model, failure→message) over a `SearchProducts` use case, a one-shot effects channel (e.g., "no network" snackbar), and proper disposal — all UI-free. Acceptance: one immutable sealed state; intent commands; debounced; delegates rules/IO to the use case; effects fire once via a separate channel; no View/context; disposes subscriptions; cohesive/per-screen.
