# MVVM Integration (Capstone: MVVM + Clean, End to End)

> Build the idiomatic Flutter stack: a feature where the **View** binds to a **ViewModel** (immutable state + commands), the ViewModel calls **use cases** (domain) over **repositories** (data) — **MVVM as the presentation layer of Clean Architecture** — wired by DI, with **scoped rebuilds**, a **one-off effects channel**, and **state-sequence tests** for the VM plus isolated tests for use cases/repos. This is where the whole presentation-pattern arc lands: reactive, testable, layered, and framework-native.

## Introduction

This module capstone assembles fundamentals, ViewModel design, binding/state, and testing into one working MVVM + Clean feature — the recommended architecture for real Flutter apps. It shows the full wiring, the request flow, and the layered tests.

## Why this concept exists

Individually understanding MVVM's parts isn't enough; the payoff is a complete, testable slice where the presentation pattern (MVVM) and layering (Clean) compose cleanly. This capstone demonstrates the idiomatic stack and serves as the template for feature-first/modular scaling.

## Real-world analogy

It's a **fully instrumented production line for one product**: the control panel (ViewModel) publishes live status the display (View) mirrors; the panel delegates real work to specialized stations (use cases) fed by suppliers (repositories); and quality control can test each station and the panel independently. Everything is observable, delegated, and verifiable — a factory that runs smoothly and can be inspected part by part.

## Problem Statement

Build a "product search" feature: domain (`SearchProducts` use case + `ProductRepository` interface), data (repository impl + DTO mapping + `Result`), presentation (`SearchViewModel` with sealed state + debounced commands + effects channel), View (binds + scoped rebuilds + all UI states), wired by DI, with VM state-sequence tests and isolated data/domain tests. You'll compose every file in this module + Clean layering.

## Internal Working

```mermaid
flowchart TD
    subgraph presentation (MVVM)
      View[View: binds to state, emits commands, scoped rebuilds]
      VM[SearchViewModel: sealed state + commands + effects]
    end
    subgraph domain
      UC[SearchProducts use case]
      RI[ProductRepository interface]
    end
    subgraph data
      RImpl[ProductRepositoryImpl + DTO mapping + Result]
      DS[remote/local sources]
    end
    View --> VM --> UC --> RI
    RImpl -. implements .-> RI
    RImpl --> DS
    DI[DI: bind RImpl->RI; inject UC->VM; provide VM->View] --- VM
```

- **Presentation (MVVM)** ([02_viewmodel_design.md](02_viewmodel_design.md)): `SearchViewModel` exposes **sealed immutable state** (idle/loading/results/empty/error) + **commands** (`search` debounced/`retry`/`clear`), maps domain→view state, delegates to use cases, exposes a **one-off effects channel**, disposes subscriptions — **UI-free**.
- **Domain** ([Module 40](../40%20Clean%20Architecture/README.md)): `SearchProducts` use case + `ProductRepository` interface; rules here; returns `Result`.
- **Data**: `ProductRepositoryImpl` over remote/local sources, DTO↔entity mapping, exception→`Failure` conversion, cache policy.
- **View** ([03_data_binding_and_state.md](03_data_binding_and_state.md)): binds to VM state (chosen tool), **scopes rebuilds** to slices, renders loading/data/empty/error + retry, emits commands, reacts to the **effects channel** (snackbar/nav) once — **dumb**.
- **DI wiring** ([Module 14](../14%20Dependency%20Injection/README.md)): bind repo impl → domain interface, inject use case → VM, provide VM → View subtree (Provider/Riverpod scope or `ChangeNotifierProvider`); dispose with the subtree.
- **Request flow**: command → VM (debounce) → emit loading → use case → repo (map/convert) → `Result` → VM maps → emit data/empty/error → View rebuilds (scoped); effects fire once.
- **Testing (layered)** ([04_mvvm_testing_and_comparison.md](04_mvvm_testing_and_comparison.md)): VM via **state sequences** (fake use cases), use case via **fake repo**, repo via **fake sources** — each isolated, plain Dart; optional widget test per state.
- **Right-sizing**: for a tiny feature, collapse use cases (VM→repo). For real apps, keep the layers; standardize the slice structure (feature-first — [Module 44](../44%20Feature%20First%20Architecture/README.md)).

## Memory Representation

VM holds current immutable state + injected use case + effects channel + debounce timer; repo holds sources/cache; View holds a VM reference (observes). Immutable snapshots flow; DI holds the wired graph.

## Compiler Behavior

Domain pure (no framework); VM UI-free (plain Dart); sealed state → exhaustive rendering + assertions; dependencies point inward (View→VM→use case→domain interface).

## Runtime Behavior

Reactive throughout: command → state emissions → scoped rebuilds; effects once; failures → error state + retry. Swapping the binding tool or a repo impl doesn't touch the VM/domain.

## Flutter Engine Behavior

Only the View touches the engine; scoped state changes rebuild minimal subtrees ([Module 09](../09%20Rendering%20Pipeline/README.md)).

## Dart VM Behavior

VM/use case/repo tests are fast plain Dart; only widget tests use the binding.

## Examples

```dart
// DI: Clean wiring under MVVM
void registerSearchFeature() {
  getIt.registerLazySingleton<ProductRemote>(() => ProductRemoteImpl(getIt()));
  getIt.registerLazySingleton<ProductRepository>(() => ProductRepositoryImpl(getIt())); // impl->interface
  getIt.registerFactory(() => SearchProducts(getIt<ProductRepository>()));              // use case
  getIt.registerFactory(() => SearchViewModel(getIt<SearchProducts>()));                // view model
}

// VIEW: binds to VM state (scoped), emits commands, reacts to effects once
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SearchViewModel>();
    return Column(children: [
      SearchField(onChanged: vm.search),                        // command
      Expanded(child: switch (vm.state) {                       // bind to sealed state
        SearchIdle() => const Hint('Type to search'),
        SearchLoading() => const CenteredSpinner(),
        SearchEmpty() => const EmptyState('No results'),
        SearchResults(:final items) => ResultList(items),
        SearchError(:final message) => ErrorView(message: message, onRetry: vm.retry),
      }),
    ]);
    // Elsewhere: listen to vm.effects (snackbar/nav) once, not in build.
  }
}
```

```dart
// LAYERED TESTS — each isolated with fakes (no device)
blocTest<SearchCubit, SearchState>('loading -> results',
  build: () => SearchCubit(FakeSearchProducts(Success([Product('1','A')]))),
  act: (c) => c.search('a'), wait: const Duration(milliseconds: 350),
  expect: () => [isA<SearchLoading>(), isA<SearchResults>()]);
test('repo maps 404 -> NotFoundFailure', () async {
  final repo = ProductRepositoryImpl(FakeRemote(status: 404));
  expect(await repo.search('x'), isA<Failure>());
});
```

## Diagrams

```mermaid
sequenceDiagram
    participant V as View
    participant VM as SearchViewModel
    participant UC as SearchProducts
    participant R as ProductRepository
    V->>VM: search(q) (debounced)
    VM->>VM: emit loading
    VM->>UC: call(q)
    UC->>R: search(q)
    R-->>UC: Result (mapped/converted)
    UC-->>VM: Result
    VM->>VM: map -> results/empty/error; emit
    VM-->>V: state -> scoped rebuild
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| VM holds View/context or rules/IO | Couples/untestable/wrong layer | UI-free VM; delegate to use cases |
| Unscoped rebuilds | Jank | Scope to slices (`select`/`buildWhen`) |
| Effects in rebuildable state | Re-fire | One-off effects channel |
| Presentation depends on repo impl | Violates dependency rule | Bind impl→interface; VM uses use cases |
| Skipping layered tests | Loses payoff | Test VM/use case/repo isolated |
| Over-layering a tiny feature | Boilerplate | Right-size (VM→repo) |
| Coupling widgets to one tool's types | Hard to switch | Keep VM tool-agnostic |

## Best Practices

- Use **MVVM as the presentation layer of Clean**: View binds to VM (state+commands), VM calls **use cases** over **repositories**; wire via **DI** (impl→interface, use case→VM, VM→View).
- Keep the **VM UI-free** (delegate rules/IO), **scope rebuilds**, route **one-off effects via a channel**, and **dispose** subscriptions.
- **Test each layer isolated** with fakes (VM via state sequences); **right-size** layering; standardize the **feature-first** slice.
- Keep the **VM tool-agnostic** so Provider/Riverpod/Bloc is a swap; render all **UI states + retry**.

## Performance

Scoped reactive rebuilds + immutable state keep the UI smooth; debounce avoids redundant calls; delegation keeps the VM light. No architectural overhead beyond negligible DI/indirection. Perf hinges on rebuild scoping ([Module 21](../21%20Performance/README.md)).

## Advantages / Disadvantages

- **+** Idiomatic reactive Flutter, fully testable per-layer, dumb views, scoped rebuilds, swappable tools, scales feature-first.
- **−** Layering + DI + state boilerplate, discipline to keep VM clean + rebuilds scoped, right-sizing judgment.

## Interview Questions

1. **🟢 How does MVVM fit into Clean Architecture?** — The ViewModel is the presentation layer, calling use cases (domain) over repositories (data); presentation and layering are orthogonal and composed.
2. **🟢 Trace a search request through the stack.** — Command → VM (debounce, emit loading) → use case → repo (map/convert→`Result`) → VM maps → emit data/empty/error → View scoped-rebuild; effects once.
3. **🟡 How is each layer tested?** — VM via state sequences (fake use cases), use case via fake repo, repo via fake sources — isolated, plain Dart.
4. **🟡 How do you keep rebuilds efficient?** — Scope bindings to slices (`select`/`buildWhen`/`BlocSelector`) and use immutable state; route effects via a listener channel.
5. **🟡 Why keep the VM UI-free and tool-agnostic?** — Testability (plain Dart) and swappability (Provider/Riverpod/Bloc without touching logic).
6. **🔴 When do you collapse layers?** — For tiny features — VM calls the repo directly, skipping use cases (right-sizing).
7. **🔴 Why is MVVM + Clean the recommended Flutter stack?** — MVVM matches reactivity with state-sequence testability; Clean isolates + tests layers; together they're idiomatic, testable, and scalable.

## Senior Engineer Tips

- Build one exemplary MVVM + Clean slice (domain/data/presentation + DI + per-layer tests) and template it; consistency across features is what keeps a large Flutter app navigable and testable.
- Keep the VM UI-free, tool-agnostic, rebuild-scoped, and effects-channeled; those four disciplines are the difference between clean MVVM and a janky god-VM.
- Right-size the layering per feature and standardize the slice structure — the bridge to feature-first/modular architecture.

## Architect Perspective

This capstone is the destination of the presentation-pattern arc and the marriage with the layering backbone: **MVVM (reactive, testable presentation) + Clean (independent, testable layers)**, wired by DI, scoped for performance. It resolves the MVC/MVP friction (reactive-native), delivers per-layer testability, and templates the feature-first/modular scaling that follows. For real Flutter apps, this is the recommended architecture — chosen proportionally, kept disciplined ([Module 40](../40%20Clean%20Architecture/README.md), [Module 44](../44%20Feature%20First%20Architecture/README.md), [Module 49](../49%20Testing/README.md)).

## Summary

- MVVM = presentation layer of Clean: View binds to VM (state+commands), VM calls use cases over repos; DI-wired (impl→interface, use case→VM, VM→View).
- UI-free VM, scoped rebuilds, one-off effects channel, dispose; test each layer isolated (VM via state sequences); right-size; tool-agnostic.
- The idiomatic, reactive, testable, scalable Flutter architecture — the arc's conclusion.

## Revision Notes

- Stack: View (bind + commands, scoped rebuilds, effects listener) → ViewModel (sealed state + commands, UI-free, delegates) → use cases (domain) → repositories (data); DI binds impl→interface, use case→VM, VM→View.
- Flow: command → loading → use case → repo (map/convert→`Result`) → map → data/empty/error → scoped rebuild; effects once.
- Test per layer with fakes (VM state sequences); right-size; tool-agnostic VM; feature-first slice; MVVM+Clean = recommended.

## Practice Questions

1. Where does MVVM sit in Clean Architecture, and what does the VM depend on?
2. How do you test the VM, use case, and repo separately?
3. What keeps the MVVM UI smooth and the VM clean?

## Coding Questions

1. Wire the full MVVM + Clean search slice via DI.
2. Bind the View with scoped rebuilds + an effects listener.
3. Write layered tests (VM state sequence, use case, repo) with fakes.

## Mini Project

**MVVM + Clean feature (capstone — Flutter):** Build "product search" end-to-end: domain (`SearchProducts` + `ProductRepository`), data (impl + DTO mapping + `Result`), presentation (`SearchViewModel` sealed state + debounced commands + effects channel, UI-free), View (binds + scoped rebuilds + all UI states + effect listener), wired by DI (impl→interface, use case→VM, VM→View), with your chosen tool. Write layered tests (VM state sequences, use case, repo) with fakes. Acceptance: MVVM presentation over Clean layers; VM UI-free + delegates + tool-agnostic; scoped rebuilds; effects once; DI-wired inward; each layer unit-tested with fakes (no device); feature-first structure; runs end-to-end.
