# MVVM Fundamentals (Observable State & Binding)

> MVVM splits UI into **Model** (domain/data + rules), **View** (widgets that **bind** to state and emit intents), and **ViewModel** (exposes **observable state** + **commands**, maps domain → display state). Its defining move: the View doesn't get *told* what to do (MVP) or *poll* the model (MVC) — it **subscribes to observable state and rebuilds when it changes** (`UI = f(state)`). This is exactly how Flutter already works, which is why MVVM is the **natural, idiomatic** Flutter pattern and why most Provider/Riverpod/Bloc apps *are* MVVM.

## Introduction

This file establishes MVVM's roles and its core mechanism — **binding to observable state** — contrasting it with MVC (view reads model) and MVP (presenter drives view). It's the conceptual foundation the rest of the module builds on.

## Why this concept exists

Reactive UIs render from state and rebuild on change. MVVM formalizes this: put the presentation logic + state in a **ViewModel** the View **observes**, so the View stays dumb and the logic stays testable — achieving MVP's separation/testability while matching (not fighting) the reactive framework. It removes MVP's imperative "call view methods" and MVC's ambiguity.

## Real-world analogy

MVVM is a **live dashboard wired to sensors**: the ViewModel is the **sensor hub** publishing readings (observable state); the View is the **display** that **automatically re-renders** whenever a reading changes — nobody manually "updates the screen." You interact by pressing buttons (commands) that tell the hub to do something; the display just reflects the hub's latest state. Compare MVP's puppeteer physically moving a puppet — here the display simply mirrors published state.

## Problem Statement

For a profile screen, assign roles: a ViewModel exposing observable state + commands, a View that binds and rebuilds, and a Model (domain/data). Trace how tapping "refresh" flows and how the View updates. You'll map MVVM's roles and its reactive data flow.

## Internal Working

```mermaid
flowchart TD
    View[View: binds to state, emits intents] -->|command| VM[ViewModel: state + commands]
    VM --> Model[Model: domain use cases / data]
    Model -->|Result| VM
    VM -->|new observable state| View
    Note[View = f(state): subscribes + rebuilds; no polling (MVC) / no imperative calls (MVP)]
```

- **Model**: domain + data — entities, use cases, repositories ([Module 40](../40%20Clean%20Architecture/README.md)). UI-agnostic; holds rules/IO. The ViewModel calls **use cases**, not raw sources.
- **View**: **widgets** that **bind** to the ViewModel's observable state (rebuild on change) and **emit intents/commands** (button → `vm.refresh()`). Dumb: no business logic, no direct model access, no formatting decisions beyond layout. Handles loading/data/empty/error.
- **ViewModel**: exposes **observable state** (an immutable snapshot: loading/data/error + display fields) and **commands** (methods the View calls). It **maps domain results → view state** (entity → view model, failure → message), applies presentation logic (sequencing, formatting), and **delegates rules/IO to use cases**. It **knows nothing about the View** (no view reference, no `BuildContext`) — the View observes *it*.
- **The key mechanism — binding**: the View **subscribes** to the ViewModel; when state changes (via `notifyListeners`/stream/provider), **bound widgets rebuild**. This is **reactive** (`UI = f(state)`), not imperative (MVP) or pull-based (MVC).
- **Direction of knowledge**: MVP presenter **holds** the view (calls it); MVVM ViewModel is **held/observed by** the View (View depends on VM, not vice versa). This inversion is what makes MVVM reactive and the VM independently testable (no mock view needed).
- **Why it fits Flutter**: Flutter rebuilds widgets from state natively — MVVM's binding *is* Flutter's model. No translation layer, no fighting the framework ([Module 41](../41%20MVC/README.md)/[Module 42](../42%20MVP/README.md) friction disappears).
- **Realizations**: `ChangeNotifier` + `ListenableBuilder`, **Provider**, **Riverpod**, **Bloc/Cubit**, GetX — all are ways to expose observable state a View binds to (i.e., MVVM) ([data_binding_and_state.md](data_binding_and_state.md)).

## Memory Representation

The ViewModel holds current **immutable state** + injected use cases + a listener/stream mechanism. The View holds a reference to the VM (observes it) but no logic state. State changes produce new snapshots the View diffs/rebuilds from.

## Compiler Behavior

The ViewModel is plain Dart (only `foundation` for `ChangeNotifier` if used) — no widget imports — so it's testable and the compiler enforces that purity boundary.

## Runtime Behavior

Command → VM updates state → notifies/streams → bound widgets rebuild (scoped). No imperative view calls, no polling. Reactive propagation matches the engine's rebuild model.

## Flutter Engine Behavior

State change → rebuild of bound widgets → element diff → repaint changed render objects ([Module 09](../09%20Rendering%20Pipeline/README.md)). MVVM binding aligns with this pipeline natively.

## Dart VM Behavior

ViewModel logic is plain Dart (fast unit tests via state assertions); widget rebuilds run on the UI isolate.

## Examples

```dart
import 'package:flutter/foundation.dart'; // ChangeNotifier only — no material/widgets

// MODEL side: use case (domain)
class GetProfile { final ProfileRepository repo; GetProfile(this.repo);
  Future<Result<Profile>> call(String id) => repo.getProfile(id); }

// VIEWMODEL: observable state + commands; maps domain -> view state; knows nothing of the View
class ProfileViewModel extends ChangeNotifier {
  final GetProfile getProfile;
  ProfileViewModel(this.getProfile);
  ProfileState state = const ProfileState.loading();   // immutable observable state

  Future<void> load(String id) async {                 // command
    state = const ProfileState.loading(); notifyListeners();
    final r = await getProfile(id);
    state = switch (r) {
      Success(:final value) => ProfileState.data(ProfileVm.from(value)), // entity -> view model
      Failure(:final error) => ProfileState.error(messageFor(error)),    // failure -> message
    };
    notifyListeners();                                  // View rebuilds from state
  }
}
```

```dart
// VIEW: binds to state, emits intents — dumb, reactive (UI = f(state))
ListenableBuilder(
  listenable: vm,
  builder: (context, _) => switch (vm.state) {
    Loading() => const CenteredSpinner(),
    Data(:final profile) => ProfileCard(profile),
    Error(:final message) => ErrorView(message: message, onRetry: () => vm.load(id)), // command
  },
);
```

## Diagrams

```mermaid
sequenceDiagram
    participant V as View (binds)
    participant VM as ViewModel
    participant M as Model (use case)
    V->>VM: refresh() (command)
    VM->>VM: state = loading; notify
    VM->>M: getProfile(id)
    M-->>VM: Result
    VM->>VM: map -> data/error state; notify
    VM-->>V: observable state -> rebuild (bound)
```

## Common Mistakes

| Mistake | Why it's wrong | Fix |
|---------|---------------|-----|
| ViewModel holds `BuildContext`/view ref | That's MVP-ish, couples/untestable | VM exposes state; View observes it |
| Business rules/IO in the ViewModel | Wrong layer | Delegate to use cases/repositories |
| View reads the Model directly | Bypasses VM (MVC-ish) | View binds to VM state only |
| Mutable shared state without notify | Stale UI | Immutable snapshots + notify |
| Rendering entities needing formatting | UI shape ≠ domain shape | Map entity → view model in VM |
| Unscoped rebuilds | Whole-tree jank | Scope binding to what changed |
| Leaking `Result`/`Failure` to widgets | Couples UI to domain internals | Map to messages/state in VM |

## Best Practices

- ViewModel exposes **immutable observable state + commands**, **maps domain → view state** (entity→VM, failure→message), and **delegates rules/IO to use cases** — with **no View reference/`BuildContext`**.
- View **binds to state** (rebuilds reactively) and **emits intents**; keep it **dumb** (render + commands, handle loading/data/empty/error).
- Use **immutable state snapshots + notify/streams**; **scope rebuilds** to what changed ([Module 21](../21%20Performance/README.md)).
- Keep the ViewModel **plain Dart** (testable via state assertions); pick a realization (Provider/Riverpod/Bloc/`ChangeNotifier`) that fits ([data_binding_and_state.md](data_binding_and_state.md)).

## Performance

Reactive binding is efficient when rebuilds are **scoped** (bind narrowly, select slices). Immutable snapshots make diffs predictable. Whole-tree rebuilds on every notify are the main pitfall ([Module 21](../21%20Performance/README.md)). ViewModel logic is cheap plain Dart.

## Advantages / Disadvantages

- **+** Natural reactive fit (no friction), testable ViewModel (state sequences, no mock view), dumb reusable views, scoped rebuilds, slots into Clean.
- **−** Binding/observability plumbing, risk of fat ViewModels (mitigate by delegating), must scope rebuilds, state-snapshot boilerplate.

## Interview Questions

1. **🟢 What are MVVM's three roles?** — Model (domain/data + rules), View (binds to state, emits intents), ViewModel (observable state + commands, maps domain→view state).
2. **🟢 What's MVVM's defining mechanism?** — The View **binds** to observable ViewModel state and **rebuilds** on change (`UI = f(state)`) — not polling (MVC) or being driven imperatively (MVP).
3. **🟡 Why does MVVM fit Flutter naturally?** — Flutter already rebuilds widgets from state; MVVM's binding *is* that model, so there's no imperative-to-reactive translation.
4. **🟡 How does the knowledge direction differ from MVP?** — In MVP the presenter holds/drives the view; in MVVM the View observes the ViewModel (VM knows nothing of the View) — enabling reactivity + VM-only tests.
5. **🟡 What does the ViewModel expose and delegate?** — Exposes immutable state + commands; delegates business rules/IO to use cases/repositories; maps domain results to view state.
6. **🔴 Why no `BuildContext`/View reference in the ViewModel?** — To keep it reactive (View observes it), testable (plain Dart), and free of UI coupling/leaks.
7. **🔴 What's the main performance pitfall and fix?** — Unscoped rebuilds on every notify; fix by scoping bindings/selecting state slices.

## Senior Engineer Tips

- Point the dependency arrow correctly: the View knows the ViewModel, never the reverse — that single inversion is what makes MVVM reactive and the VM testable without a mock view.
- Expose immutable state + commands and map domain→view models/messages in the VM; widgets should never see `Result`, `Failure`, or raw entities that need formatting.
- Scope your bindings (select the slice you render); MVVM apps jank when the whole page rebuilds on every `notifyListeners`.

## Architect Perspective

MVVM is the reactive resolution of the MVC/MVP arc: it keeps MVP's separation/testability but inverts the view relationship (View observes state) to match reactive UIs. In Flutter it's not one library but the shape that Provider/Riverpod/Bloc/`ChangeNotifier` all produce — and it's the idiomatic **presentation layer of Clean Architecture**, with the ViewModel calling use cases and mapping to view state. Get the roles and the binding direction right and the framework works *with* you ([Module 42](../42%20MVP/README.md), [viewmodel_design.md](viewmodel_design.md), [Module 40](../40%20Clean%20Architecture/README.md)).

## Summary

- MVVM: Model (domain/data) + View (binds to state, emits intents) + ViewModel (observable state + commands, maps domain→view state, delegates rules/IO).
- Defining mechanism: View **binds** to observable state and rebuilds (`UI = f(state)`) — the natural Flutter fit; VM knows nothing of the View.
- Immutable state + notify/streams, scoped rebuilds, plain-Dart testable VM; realized by Provider/Riverpod/Bloc/`ChangeNotifier`.

## Revision Notes

- Model (domain/data) + View (bind + emit intents, dumb) + ViewModel (immutable observable state + commands, maps domain→view state, delegates rules/IO, no View ref/context).
- Mechanism: View observes VM state → rebuilds (`UI=f(state)`); reactive (not MVC polling / MVP imperative); VM knows nothing of View.
- Immutable snapshots + notify/streams; scope rebuilds; plain-Dart VM (testable); realizations: Provider/Riverpod/Bloc/`ChangeNotifier`/GetX.

## Practice Questions

1. How does the View learn of state changes in MVVM vs MVC vs MVP?
2. Why does the ViewModel not hold a View reference or `BuildContext`?
3. Why is MVVM the natural fit for Flutter?

## Coding Questions

1. Build a ViewModel with observable state + a command over a use case.
2. Bind a View to it that rebuilds and emits intents (all UI states).
3. Map an entity to a view model and a failure to a message in the VM.

## Mini Project

**MVVM role mapping (Flutter):** For a profile screen, build a `ProfileViewModel` (immutable observable state + `load` command over `GetProfile`, mapping entity→view model and failure→message, no View ref/context) and a View that binds (`ListenableBuilder`) rendering loading/data/error + retry and emitting the command. Acceptance: VM exposes observable state + commands, delegates to a use case, has no View/context; View binds + rebuilds + emits intents; entity→VM and failure→message mapping; reactive flow correct.
