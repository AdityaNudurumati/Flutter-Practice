# The Presenter & View Contract

> MVP's defining feature is the **view contract** — an explicit **interface** listing every way the presenter can affect the UI (`showLoading()`, `showItems(list)`, `showError(msg)`, `navigateTo(route)`). This contract is the **seam**: the presenter depends only on the interface (never the widget), so it's decoupled and mockable, and the passive view's entire job is to **implement the contract**. Designing the contract well — **presentation-oriented** methods (states/effects), not leaky domain/UI types — is what makes MVP clean, testable, and the view swappable.

## Introduction

This file focuses on MVP's core artifact: the view contract (interface) and how the presenter uses it to drive the view. It covers designing good contract methods, the two-way references, one-off effects vs state, and keeping domain/framework types out of the contract — the craft that makes MVP work.

## Why this concept exists

The interface is what converts MVP from "presenter with a widget reference" (untestable, coupled) into "presenter with a mockable contract" (testable, decoupled). It's the application of the Dependency Inversion Principle ([Module 04](../04%20SOLID%20Principles/README.md)) to the presenter↔view relationship: the presenter depends on an abstraction the view implements.

## Real-world analogy

The contract is a **stagehand's cue sheet**: it lists exactly the cues the director (presenter) can call ("lights up," "curtain," "show slide 3") — nothing more. Any stage crew (view implementation) that can perform those cues works, and you can rehearse the director against a **stand-in crew** (mock) that just records which cues were called. A vague or leaky cue sheet ("do whatever with the raw script") breaks the whole arrangement.

## Problem Statement

Design the view contract for a product-list screen: methods for loading/data/empty/error and one-off effects (navigation/snackbar), using presentation types (not domain entities or Flutter widgets), so the presenter drives it and a mock can verify calls. You'll design the interface + presenter interaction.

## Internal Working

```mermaid
flowchart TD
    Presenter[Presenter (depends on interface)] -->|calls contract methods| Contract[View interface: showLoading/showItems/showError/navigate]
    Contract -.implemented by.-> Widget[Real View (widget)]
    Contract -.implemented by.-> Mock[Mock View (test)]
    Widget -->|forwards events| Presenter
    Note[DIP: presenter depends on abstraction; view + mock realize it]
```

- **The contract (view interface)**: an `abstract class` enumerating **every presenter→view action** — typically **state renders** (`showLoading`, `showItems(List<ItemVm>)`, `showEmpty`, `showError(String)`) and **one-off effects** (`navigateTo(route)`, `showSnackbar(msg)`). This is the **entire surface** through which the presenter affects the UI.
- **Presentation-oriented methods**: methods should express **what the UI should do/show**, in **presentation terms** — pass **view models / primitives / messages**, **not** domain entities (leaks domain into UI) or Flutter widgets (leaks framework into the presenter). Map domain → view model in the presenter first.
- **Two-way references**: the **view implements the contract** and holds a **presenter** (to forward events); the **presenter holds the view interface** (to drive it). Wire this at attach time ([01_mvp_fundamentals.md](01_mvp_fundamentals.md)).
- **State vs one-off effects**: **state methods** (loading/data/error) are idempotent renders; **effect methods** (navigate/snackbar/toast) are one-shot. Distinguishing them avoids re-firing effects on re-render (a classic bug) — model effects as commands the view executes once.
- **Contract granularity**: prefer a **small, cohesive** contract (few meaningful methods) over many fine-grained setters; too granular → chatty/brittle, too coarse → leaky. Group by UI state.
- **DIP payoff**: because the presenter depends on the **interface**, you provide the **real widget** in production and a **mock** in tests — the seam that yields MVP's testability ([03_mvp_testability.md](03_mvp_testability.md)).
- **No framework/domain leakage**: contract signatures use presentation types only; keep `BuildContext`, widgets, and raw entities out of the interface.

## Memory Representation

The contract is an interface (no state). The presenter holds the interface reference + presentation state it maps from the Model. The view holds the presenter reference + its own widget state. Mock views record method calls/args for assertions.

## Compiler Behavior

The interface + implementations are checked at compile time: the widget and the mock must implement all contract methods. The presenter compiles against the interface, so swapping implementations requires no presenter change.

## Runtime Behavior

Presenter calls contract methods; the bound implementation (widget or mock) executes them. Event forwarding runs the reverse direction. Effects should fire once (view executes them), state methods can be called repeatedly.

## Flutter Engine Behavior

The real view translates contract calls into imperative widget updates (`setState`/controllers) — the friction with reactive Flutter is detailed in [04_mvp_in_flutter_and_comparison.md](04_mvp_in_flutter_and_comparison.md).

## Dart VM Behavior

Interface dispatch is normal virtual calls; the presenter (plain Dart) + interface enable fast, device-free tests.

## Examples

```dart
// VIEW CONTRACT — presentation-oriented; no domain entities / no Flutter types
abstract class ProductListView {
  void showLoading();
  void showItems(List<ProductVm> items);   // view models, NOT domain Product
  void showEmpty();
  void showError(String message);          // message string, NOT a Failure/exception
  void navigateToDetail(String id);        // one-off effect (command)
}

// PRESENTER — maps domain -> view models, drives the contract (depends on interface)
class ProductListPresenter {
  final GetProducts getProducts;           // domain use case
  ProductListView? _view;
  ProductListPresenter(this.getProducts);
  void attach(ProductListView v) => _view = v;
  void detach() => _view = null;

  Future<void> load() async {
    _view?.showLoading();
    final r = await getProducts();
    switch (r) {
      case Success(:final value) when value.isEmpty: _view?.showEmpty();
      case Success(:final value): _view?.showItems(value.map(ProductVm.from).toList()); // map!
      case Failure(:final error): _view?.showError(messageFor(error));                  // message!
    }
  }
  void onItemTapped(String id) => _view?.navigateToDetail(id); // effect
}
```

## Diagrams

```mermaid
flowchart LR
    Domain[domain entities/Result] --> Map[presenter maps -> view models/messages]
    Map --> Contract[view contract methods]
    Contract --> Real[real widget]
    Contract --> Mock[mock (records calls)]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| Domain entities in the contract | Leaks domain into UI | Pass view models |
| `Failure`/exceptions in the contract | Leaks error internals | Pass mapped message strings |
| `BuildContext`/widgets in the contract | Leaks framework into presenter | Presentation types only |
| Effects modeled as state | Re-fire on re-render | Model effects as one-off commands |
| Too-granular contract (many setters) | Chatty/brittle | Cohesive state-based methods |
| Presenter holds the concrete widget | Untestable/coupled | Depend on the interface |
| View implements logic in contract methods | View not passive | Contract methods just render |

## Best Practices

- Design the contract with **cohesive, presentation-oriented methods** (state renders + one-off effects), passing **view models/primitives/messages** — **no domain entities, `Failure`s, or Flutter types**.
- Have the **presenter depend on the interface** (DIP) and **map domain → presentation** before driving it; keep the **view passive** (contract methods just render).
- **Distinguish state (idempotent) from effects (one-shot)** to avoid re-firing navigation/snackbars on re-render.
- Keep the contract **small and stable**; wire two-way references via **attach/detach**; the interface is the seam enabling **mock-based tests**.

## Performance

Interface dispatch is negligible. The relevant concern is not re-firing effects (correctness) and, in Flutter, translating imperative calls to efficient rebuilds ([04_mvp_in_flutter_and_comparison.md](04_mvp_in_flutter_and_comparison.md)). No architectural perf cost.

## Advantages / Disadvantages

- **+** Decoupled, mockable presenter↔view seam; swappable view; clear, explicit UI surface; DIP-clean.
- **−** Boilerplate (interface + implementations), risk of leaky/over-granular contracts, effect-vs-state handling, imperative feel.

## Interview Questions

1. **🟢 What is the view contract in MVP?** — An interface enumerating every action the presenter can perform on the UI (state renders + effects); the passive view implements it.
2. **🟢 Why does the presenter depend on the interface, not the widget?** — Decoupling + testability (DIP): you can supply a real widget or a mock without changing the presenter.
3. **🟡 What types should contract methods use?** — Presentation types (view models, primitives, messages) — never domain entities, `Failure`s, or Flutter widgets.
4. **🟡 Why distinguish state methods from effect methods?** — State renders are idempotent (safe to repeat); effects (navigate/snackbar) must fire once, or they re-trigger on re-render.
5. **🟡 How coarse/fine should the contract be?** — Cohesive and small (state-based methods); too granular is chatty/brittle, too coarse leaks concerns.
6. **🔴 How does the contract map to Dependency Inversion?** — The presenter (policy) depends on an abstraction (the view interface); the view + mock (details) implement it — dependencies point to the abstraction.
7. **🔴 What's a common effect-related bug and its fix?** — Re-navigating/re-showing snackbars on re-render because effects were modeled as state; model them as one-off commands the view executes once.

## Senior Engineer Tips

- Treat the contract as the presenter's public API to the UI: keep it presentation-only and stable, and it stays mockable and swappable.
- Map domain → view models/messages in the presenter before touching the contract; a `Product` or `Failure` in the interface is a leak that couples UI to domain.
- Separate effects from state explicitly (a one-shot command channel) to kill the "snackbar fires twice / navigates on rebuild" class of bugs.

## Architect Perspective

The view contract is MVP's essence and its DIP realization: an explicit, presentation-typed interface that decouples presenter from view and makes both mockable and swappable. Designing it well (cohesive, leak-free, effects-vs-state) is what delivers MVP's testability. This same "depend on an abstraction, map at the boundary" discipline recurs in Clean Architecture's interfaces and MVVM's observable state — MVP just makes the view side of it explicit ([03_mvp_testability.md](03_mvp_testability.md), [Module 04](../04%20SOLID%20Principles/README.md), [Module 40](../40%20Clean%20Architecture/README.md)).

## Summary

- The view contract (interface) is MVP's core: cohesive, presentation-oriented methods (state + one-off effects) with view models/messages — no domain/Flutter types.
- Presenter depends on the interface (DIP), maps domain→presentation, drives it; view passively implements it; attach/detach wires the two.
- Distinguish idempotent state from one-shot effects; the interface is the seam for mock-based testing.

## Revision Notes

- Contract = interface of presenter→view actions (state renders + one-off effects); passive view implements; presenter depends on it (DIP, mockable).
- Presentation types only (view models/primitives/messages); map domain→presentation in presenter; no entities/`Failure`/`BuildContext`/widgets in contract.
- State (idempotent) vs effects (one-shot command); cohesive/small contract; attach/detach two-way refs.

## Practice Questions

1. Why must contract methods avoid domain entities and Flutter types?
2. How do you prevent navigation/snackbars from re-firing on re-render?
3. How is the contract an application of DIP?

## Coding Questions

1. Design a cohesive view contract (state + effects) for a list screen.
2. Write a presenter that maps domain results to contract calls.
3. Model a one-off effect (navigation) so it fires exactly once.

## Mini Project

**View contract design (Flutter):** For a product-list screen, design a `ProductListView` contract (state: `showLoading/showItems(vm)/showEmpty/showError(msg)`; effect: `navigateToDetail(id)`), a presenter that maps domain results to contract calls, and a widget implementing it passively. Ensure no domain/Flutter types leak into the contract and effects fire once. Acceptance: cohesive presentation-only contract; presenter maps domain→view models/messages and depends on the interface; effects modeled as one-shot; view passive; ready to mock for tests.
