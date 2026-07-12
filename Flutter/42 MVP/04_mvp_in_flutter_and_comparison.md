# MVP in Flutter & Comparison

> MVP fits Flutter **worse than MVVM** because its **imperative presenter-drives-view** flow (`view.showX()`) fights Flutter's **declarative rebuild-from-state** model: you end up translating presenter calls back into `setState`/controllers, fighting effect-vs-state re-fires, and juggling attach/detach against the widget lifecycle. MVP's prize — **testable presentation logic via a mockable contract** — is real, but **MVVM delivers the same testability** by asserting **observable state sequences**, without the imperative friction. So in Flutter, MVP is **rarely idiomatic**; prefer MVVM, and understand MVP mainly for the testability lesson and legacy/Android-influenced codebases.

## Introduction

This file assesses MVP against Flutter's grain and compares it to MVC and MVVM, giving a clear recommendation. It's the decision-context before the capstone ([05_mvp_integration.md](05_mvp_integration.md)).

## Why this concept exists

Developers coming from Android (where MVP was popular) or seeking testability may reach for MVP in Flutter. Knowing precisely where MVP's imperative model clashes with Flutter's reactivity — and that MVVM offers equal testability with better fit — prevents adopting a pattern that fights the framework.

## Real-world analogy

MVP in Flutter is like **using a manual film camera's workflow (load, wind, expose each frame imperatively) on a digital camera**: it works, but you're fighting a device designed for continuous live preview. MVVM is the **digital-native workflow** (compose the shot, the screen updates live). Both can produce great photos and both let you review results (testability), but one matches the tool.

## Problem Statement

Decide whether to use MVP for a Flutter feature: weigh its testability against the reactive friction, and compare with MVC and MVVM. You'll evaluate fit and pick the idiomatic pattern.

## Internal Working

```mermaid
flowchart TD
    MVP[MVP: presenter calls view.showX() imperatively] -->|friction| Flutter[Flutter: View = f(state), rebuilds]
    Flutter --> MVVM[MVVM: view binds to observable state (natural)]
    MVP --> Test1[testable via mock view]
    MVVM --> Test2[testable via state-sequence assertions]
    Note[same testability; MVVM fits reactive Flutter better]
```

- **Where MVP strains in Flutter**:
  - **Imperative vs declarative**: MVP presupposes a persistent view you **call methods on**; Flutter **rebuilds** the view from state. You must translate `showItems(...)` into `setState`/holding widget state — re-introducing the very state-in-widget MVP tried to remove.
  - **Effect vs state re-fires**: mapping one-off `navigate/showSnackbar` onto a rebuild model risks re-firing on rebuild ([02_presenter_and_view_contract.md](02_presenter_and_view_contract.md)); you must add command-once handling.
  - **Lifecycle**: attach/detach must track the widget lifecycle (dispose) carefully to avoid calling a gone view — extra bookkeeping Flutter's reactive holders handle more naturally.
  - **Boilerplate**: a view interface per screen + wiring, on top of Flutter's already-declarative UI.
- **What MVP still gives**: a **fully mockable view contract** → exhaustive presentation-logic tests. But…
- **MVVM achieves the same testability differently**: the view model exposes **observable state**; you test by asserting the **emitted state sequence** (loading→data/error), with **no mock view** and **no imperative calls** — and the view **binds** naturally (UI = f(state)). Same guarantee, better fit ([Module 43](../43%20MVVM/README.md)).
- **Comparison**:
  - **MVC** ([Module 41](../41%20MVC/README.md)): looser, controller mediates/view may read model; in Flutter → reactive controller (≈ MVVM). Simpler, less testability discipline than MVP.
  - **MVP**: strict passive view + mockable contract → best explicit testability contract, worst reactive fit + most boilerplate.
  - **MVVM**: observable state the view binds to → **best Flutter fit**, equal testability (state sequences), less imperative friction. **Recommended for Flutter.**
  - **Clean Architecture**: orthogonal layering; combine with MVVM (or MVP) in the presentation layer.
- **Recommendation**: In Flutter, **prefer MVVM**; use **MVP** only for **legacy/ported** codebases or teams with strong MVP conventions who accept the friction. Understand MVP for the **testability principle**, which MVVM carries forward.

## Memory Representation

Not applicable — comparative. MVP holds view-interface refs + attach/detach state; MVVM holds observable state the view subscribes to. The difference is imperative refs vs reactive subscriptions.

## Compiler Behavior

Both compile against abstractions (MVP: view interface; MVVM: none needed for view — it binds to state). MVP requires implementing the full interface in the widget.

## Runtime Behavior

MVP: presenter calls view methods → widget imperatively updates. MVVM: state changes → bound widgets rebuild. The latter matches Flutter's engine model; the former requires manual translation.

## Flutter Engine Behavior

Flutter is built to rebuild from state; MVVM's binding aligns with the diff/rebuild pipeline, while MVP's imperative calls must be adapted into that pipeline (via `setState`/controllers) — friction, not impossibility.

## Dart VM Behavior

Both keep presentation logic in plain Dart (testable). MVP tests verify mock calls; MVVM tests verify state streams — both fast, device-free.

## Examples

```dart
// Same feature, two flavors:

// MVP (imperative) — presenter drives the view; widget must translate to setState
// presenter.load(); -> view.showLoading(); view.showItems(vms);
// class _S extends State implements ProductListView {
//   @override void showItems(List<ProductVm> v) => setState(() => _items = v); // translate!
// }

// MVVM (reactive) — view model exposes state; widget binds; no imperative calls
class ProductListViewModel extends ChangeNotifier {
  ProductListState state = const ProductListState.loading();
  final GetProducts getProducts;
  ProductListViewModel(this.getProducts);
  Future<void> load() async {
    state = const ProductListState.loading(); notifyListeners();
    final r = await getProducts();
    state = r is Success ? ProductListState.data(r.value.map(ProductVm.from).toList())
                         : const ProductListState.error('Failed');
    notifyListeners();                                   // view rebuilds from state
  }
}
// Test: assert the state sequence [loading, data] — no mock view, no imperative calls.
```

## Diagrams

```mermaid
flowchart LR
    Choose{Flutter feature}
    Choose -->|recommended| MVVM2[MVVM: binds to state, same testability]
    Choose -->|legacy/ported| MVP2[MVP: mock-view tests, imperative friction]
    Choose -->|tiny/simple| MVCr[MVC-reactive (≈MVVM-lite)]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| Choosing MVP for testability in Flutter | MVVM gives it with better fit | Prefer MVVM |
| Fighting reactivity with imperative view calls | Reintroduces state-in-widget | Bind to state (MVVM) |
| Ignoring effect-once in MVP | Re-fires on rebuild | Command-once handling |
| Sloppy attach/detach | Calls to disposed view | Track lifecycle carefully |
| Treating Clean as an MVP alternative | Orthogonal | Combine layering + presentation pattern |
| Porting Android MVP verbatim | Framework mismatch | Adapt to MVVM in Flutter |

## Best Practices

- In Flutter, **prefer MVVM** (view binds to observable state) — it gives **MVP-equal testability** (state-sequence assertions) **without** the imperative friction/boilerplate.
- Use **MVP only** for legacy/ported code or strong-convention teams accepting the friction; if you do, add **effect-once** handling and careful **attach/detach**.
- Keep presentation logic in **plain-Dart, testable** units regardless of pattern; **combine** the chosen presentation pattern with **Clean layering** as needed.
- Take MVP's **lesson** (mockable, testable presentation logic) forward into MVVM; **don't fight** Flutter's reactive model.

## Performance

No inherent perf difference; MVVM's scoped bindings can be very efficient, while MVP's imperative updates still ultimately rebuild widgets. The friction is developer-facing (boilerplate/bugs), not runtime. Scope rebuilds regardless ([Module 21](../21%20Performance/README.md)).

## Advantages / Disadvantages

- **MVP +** explicit contract, strong mockable testability, truly passive view; **−** imperative friction in Flutter, boilerplate, effect/lifecycle handling.
- **MVVM +** reactive fit, equal testability, less friction; **−** binding plumbing (minor). **In Flutter, MVVM wins.**

## Interview Questions

1. **🟢 Why does MVP fit Flutter worse than MVVM?** — Its imperative presenter-drives-view flow fights Flutter's declarative rebuild-from-state; you must translate calls into `setState`, reintroducing widget state.
2. **🟢 What's MVP's main advantage, and does MVVM share it?** — Testable presentation logic via a mockable contract; yes — MVVM achieves equal testability via state-sequence assertions.
3. **🟡 How do MVP and MVVM test presentation logic differently?** — MVP verifies imperative calls on a mock view; MVVM asserts the emitted observable-state sequence (no mock view).
4. **🟡 What extra concerns does MVP add in Flutter?** — Effect-once handling (avoid re-fire on rebuild) and careful attach/detach against the widget lifecycle.
5. **🟡 When is MVP justified in Flutter?** — Legacy/ported (e.g., Android) codebases or teams with strong MVP conventions accepting the friction.
6. **🔴 Is Clean Architecture an alternative to MVP?** — No — it's orthogonal layering; combine it with a presentation pattern (MVVM recommended).
7. **🔴 What's the recommendation and why?** — Prefer MVVM in Flutter: same testability, natural reactive fit, less boilerplate/friction than MVP.

## Senior Engineer Tips

- Reach for MVVM by default in Flutter; if someone proposes MVP "for testability," point out MVVM gives the same guarantee via state-sequence tests without fighting rebuilds.
- If you must maintain MVP (ported code), add explicit one-shot effect handling and rigorous attach/detach — those are where MVP-in-Flutter bugs cluster.
- Keep the transferable lesson: presentation logic in a plain-Dart testable unit — MVP taught it, MVVM delivers it idiomatically.

## Architect Perspective

MVP and MVVM share a goal (testable presentation logic, dumb view) but differ in mechanism: MVP's **imperative contract** vs MVVM's **reactive binding**. Flutter's declarative engine makes MVVM the natural realization, so MVP's value in Flutter is mostly conceptual/legacy. The architectural takeaway is pattern-agnostic and enduring: isolate presentation logic in a testable unit and let a dumb view reflect it — with MVVM the idiomatic Flutter form and Clean Architecture the orthogonal layering ([03_mvp_testability.md](03_mvp_testability.md), [Module 43](../43%20MVVM/README.md), [Module 40](../40%20Clean%20Architecture/README.md)).

## Summary

- MVP's imperative presenter-drives-view clashes with Flutter's declarative rebuild-from-state (friction + boilerplate + effect/lifecycle handling).
- MVP's testability (mock view) is matched by MVVM via state-sequence assertions — with better reactive fit.
- In Flutter, prefer **MVVM**; use MVP only for legacy/ported code; combine any presentation pattern with Clean layering.

## Revision Notes

- MVP imperative (`view.showX()`) vs Flutter declarative (View=f(state)) → friction: translate to `setState`, effect-once, attach/detach lifecycle, boilerplate.
- Testability: MVP mocks the view; MVVM asserts state sequence (same guarantee, reactive fit, less ceremony).
- Comparison: MVC (loose→reactive), MVP (strict contract, worst fit), MVVM (recommended); Clean = orthogonal layering; prefer MVVM in Flutter, MVP for legacy only.

## Practice Questions

1. Precisely where does MVP's flow conflict with Flutter's?
2. How does MVVM match MVP's testability without a mock view?
3. When, if ever, would you choose MVP in Flutter?

## Coding Questions

1. Rewrite an MVP presenter+view as an MVVM view model + bound view.
2. Show the MVP effect-once problem and its fix.
3. Write the equivalent test both ways (mock-view calls vs state sequence).

## Mini Project

**MVP vs MVVM comparison (Flutter):** Implement the same list feature twice — MVP (view interface + presenter driving it + widget translating calls, with effect-once + attach/detach) and MVVM (view model with observable state + bound view) — and write the equivalent test for each (mock-view call verification vs state-sequence assertion). Document the friction points and recommend one. Acceptance: both implemented + tested; MVP friction (imperative translation, effect-once, lifecycle) demonstrated; MVVM shown as the idiomatic fit with equal testability; recommendation justified.
