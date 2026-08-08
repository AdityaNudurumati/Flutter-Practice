# App Architecture — Interview Questions

> How you structure a Flutter app so it stays testable, changeable, and scalable as teams and features grow. For depth see [40 Clean Architecture](../40%20Clean%20Architecture/README.md), [43 MVVM](../43%20MVVM/README.md), [44 Feature First Architecture](../44%20Feature%20First%20Architecture/README.md), [45 Modular Architecture](../45%20Modular%20Architecture/README.md), and [46 Domain Driven Design](../46%20Domain%20Driven%20Design/README.md).

Architecture is the highest-leverage senior/lead signal: it tests whether you can reason about *change* — where a new requirement lands, what a UI-framework swap costs, how a team of ten avoids stepping on each other. Interviewers push from "what is Clean Architecture" toward "when would you *not* use it" and "how do you enforce boundaries at scale".

## 🟢 Basic

**1. Why does architecture matter — isn't a working app enough?**
A working app is table stakes; architecture is about the cost of the *next* change. Good structure makes features land in predictable places, makes code testable without a device, isolates volatile decisions (which HTTP client, which DB, which state library) from stable business rules, and lets multiple people work without merge chaos. The payoff is not day-one velocity — it's month-twelve velocity, when an unarchitected app has calcified into a big ball of mud where every change risks breaking three unrelated screens.

**2. What is "separation of concerns"?**
Each part of the code has one reason to exist and one axis of change. UI code worries about pixels and gestures; business logic worries about rules and workflows; data code worries about I/O, serialization, and caching. When these are tangled — an HTTP call inside a widget's `build`, a JSON key referenced in the UI — a change to one concern forces edits across many files and makes isolated testing impossible. Separation is the precondition for every other architectural benefit.

**3. What is the dependency rule?**
Source-code dependencies point *inward*, toward higher-level policy, and never outward toward detail. Concretely: the domain (business rules) knows nothing about the UI or the database; the data layer depends on the domain, not vice versa. Inner layers define interfaces (e.g. a `UserRepository` abstract class); outer layers implement them. This is what lets you swap Dio for `http`, or REST for GraphQL, or Provider for BLoC, without touching your business logic.

**4. What are the layers in Clean Architecture?**
Three concentric layers:
- **Presentation** — widgets + state holders (ViewModel/BLoC/Notifier). Renders state, dispatches user intent.
- **Domain** — entities, use cases, and repository *interfaces*. Pure Dart, no Flutter, no packages. The stable core.
- **Data** — repository *implementations*, remote/local data sources, DTOs, and mappers. Talks to the outside world.

Presentation and data both depend on domain; domain depends on nothing.

**5. What is a use case (interactor)?**
A single, named unit of application-specific business logic — `LoginUser`, `AddToCart`, `FetchOrderHistory`. It orchestrates entities and repositories to accomplish one user goal, exposing something like a `call()` method. Use cases make the app's capabilities readable as a list, keep the ViewModel thin, and are trivially unit-testable with mocked repositories. In simpler apps you may collapse them and let the ViewModel call the repository directly — that's a legitimate right-sizing choice.

**6. What is an entity vs a DTO/model?**
An **entity** is a domain object expressing a business concept and its invariants (a `User` with an `id` and rules about what a valid user is) — it lives in the domain layer and has no serialization concerns. A **DTO** (data transfer object / data model) mirrors an external shape — a JSON payload or DB row — with `fromJson`/`toJson`. Keeping them separate means an API rename (`user_name` → `login`) changes only the DTO and its mapper, never the entity or the UI that consumes it.

**7. What is a repository?**
An abstraction that hides *where* data comes from behind a domain-friendly interface. The domain declares `abstract class ProductRepository { Future<List<Product>> getProducts(); }`; the data layer implements it, coordinating a remote data source, a local cache, and mappers. The presentation layer asks for products and neither knows nor cares whether they came from the network, SQLite, or memory. It's the seam where the dependency rule is enforced.

**8. What is a mapper and why not skip it?**
A mapper converts between DTOs and entities (`UserDto.toEntity()` / `User.fromDto()`). Skipping it and using JSON models straight through the app couples your UI to the wire format — every backend change ripples to widgets, and you can't shape data to what the domain actually needs. The mapper is a small, cheap boundary that localizes the blast radius of external change.

**9. What does MVC stand for, and what's the problem with it in Flutter?**
Model–View–Controller: Model holds data, View renders, Controller handles input and updates the model. In Flutter the View (widget tree) and Controller boundary is blurry — widgets already handle both layout and gesture callbacks — so pure MVC maps awkwardly. It tends to produce fat controllers and views that still know too much about models. Most Flutter teams reach for MVVM instead.

**10. What is MVVM and why does it fit Flutter well?**
Model–View–ViewModel: the View (widgets) binds to a ViewModel that exposes observable state and commands; the ViewModel talks to Models/repositories and holds no widget references. It fits Flutter because Flutter is already reactive and declarative — a widget rebuilding from an observable ViewModel *is* data binding. `ChangeNotifier` + `ListenableBuilder`, or a Riverpod `Notifier`, are idiomatic ViewModels. See [43 MVVM](../43%20MVVM/README.md).

**11. What's the difference between feature-first and layer-first folder structure?**
- **Layer-first** groups by technical role: top-level `presentation/`, `domain/`, `data/`, each containing all features. Simple early, but a single feature's files scatter across the tree and it doesn't scale.
- **Feature-first** groups by feature: `features/auth/`, `features/cart/`, each with its own `presentation/domain/data` inside. A feature is self-contained, easy to find, delete, or hand to a team.

Feature-first is the default for anything non-trivial. See [44 Feature First Architecture](../44%20Feature%20First%20Architecture/README.md).

**12. What is dependency injection's role in architecture?**
DI is *how* the dependency rule is realized at runtime: the outer layer's concrete implementations are supplied to the inner layer through its interfaces, rather than constructed inline. A ViewModel receives a `UserRepository` (interface); at composition root you bind it to `UserRepositoryImpl`. This is what makes swapping real for fake possible — and therefore what makes unit testing possible. `get_it`, `injectable`, or Riverpod providers all serve this role.

## 🟡 Intermediate

**13. Contrast MVC, MVP, and MVVM.**

| Aspect | MVC | MVP | MVVM |
|---|---|---|---|
| Mediator | Controller | Presenter | ViewModel |
| View↔mediator coupling | Controller may know View | Presenter holds a View *interface* | View observes ViewModel; VM knows nothing of View |
| UI updates | Controller mutates model, view reads | Presenter calls `view.showX()` | View binds to observable state |
| Testability | Controller often UI-coupled | Good (mock the view interface) | Best (VM is plain, no view ref) |
| Flutter fit | Awkward | Verbose (manual view interface) | Natural (reactive binding) |

MVVM wins in Flutter because the framework supplies the binding mechanism for free; MVP's explicit view interface is redundant boilerplate here.

**14. Show a minimal MVVM ViewModel with `ChangeNotifier`.**
```dart
class ProductsViewModel extends ChangeNotifier {
  ProductsViewModel(this._repo);
  final ProductRepository _repo;

  var _state = const AsyncValue<List<Product>>.loading();
  AsyncValue<List<Product>> get state => _state;

  Future<void> load() async {
    _state = const AsyncValue.loading();
    notifyListeners();
    _state = await AsyncValue.guard(() => _repo.getProducts());
    notifyListeners();
  }
}
// View: ListenableBuilder(listenable: vm, builder: (_, __) => switch on vm.state)
```
The VM holds no `BuildContext` and no widgets — that's what makes it unit-testable and reusable.

**15. Why is Riverpod a good fit for MVVM in modern Flutter?**
A Riverpod `Notifier`/`AsyncNotifier` *is* a ViewModel: it holds state, exposes methods for intent, and its dependencies (repositories) are injected via `ref.watch`. It gives compile-safe DI, automatic disposal, built-in `AsyncValue` for loading/error/data, and testability via provider overrides — without the `context`-coupling of `ChangeNotifierProvider`. So Riverpod delivers MVVM *and* the DI/composition-root role in one tool.

**16. Where does state management sit relative to architecture?**
State management (BLoC, Riverpod, Provider) is a *presentation-layer concern* — it's the machinery of the ViewModel/state-holder, not the architecture itself. A common mistake is thinking "we use BLoC" *is* the architecture. Clean Architecture is agnostic to which you pick; the BLoC/Notifier lives in presentation and depends inward on use cases or repositories. Keep business rules out of your bloc's event handlers.

**17. What is the Result/Either pattern and why prefer it over exceptions?**
It models failure as a value in the return type instead of a thrown control-flow jump: `Future<Result<User, Failure>>` or `Either<Failure, User>`. Benefits: failures become part of the type signature so the compiler forces you to handle them; you distinguish expected domain failures (invalid credentials) from bugs; and repository boundaries return typed failures instead of leaking `DioException` upward. Dart's sealed classes make this clean:
```dart
sealed class Result<T> {}
class Ok<T> extends Result<T> { final T value; Ok(this.value); }
class Err<T> extends Result<T> { final Failure failure; Err(this.failure); }

final r = await repo.getUser();
switch (r) {
  case Ok(:final value): showUser(value);
  case Err(:final failure): showError(failure);
}
```

**18. When should exceptions still be used, not Result?**
For *unrecoverable* or *programmer-error* conditions — a null assertion failing, a bug, an out-of-memory — where there's no meaningful local handling and you want it to crash loudly (and be logged). Result is for *expected, recoverable* domain outcomes the caller must branch on. Wrapping every null check in `Either` is over-engineering; reserve it for the domain/data boundary where failure is a real business outcome.

**19. What is modular (multi-package) architecture?**
Splitting the app into multiple Dart/Flutter packages — e.g. `core`, `feature_auth`, `feature_cart`, `design_system` — each with its own `pubspec.yaml`, tests, and public API. Benefits: enforced boundaries (a package can only import what it declares as a dependency), faster incremental builds, independent testing, and clear ownership. It's feature-first taken to the package level. See [45 Modular Architecture](../45%20Modular%20Architecture/README.md).

**20. What is melos and why use it for a monorepo?**
`melos` is a tool for managing a Dart/Flutter **monorepo** of many local packages: it bootstraps and links inter-package dependencies, and runs commands (test, analyze, build) across all packages with one invocation. It lets you keep modular packages in a single repo with shared CI and atomic cross-package changes, avoiding the versioning pain of publishing each package separately.

**21. How do you actually *enforce* module boundaries?**
Several mechanisms, layered:
- **Package dependencies** — a package physically can't import code it doesn't depend on in `pubspec.yaml`.
- **Public API surface** — expose only through a barrel/`lib/<pkg>.dart`; keep the rest under `lib/src/` which other packages shouldn't import.
- **Lint rules** — custom lints or `import_lint`/`dart_code_metrics` rules banning cross-feature imports.
- **Layer direction** — `feature_x` may depend on `core`, never on `feature_y`; shared needs go into `core`.

Convention alone erodes; the package graph is the enforcement that survives turnover.

**22. What is a "composition root"?**
The single place — typically `main()` or a bootstrap/DI setup — where the concrete object graph is wired: interfaces bound to implementations, singletons created, providers overridden. It's the *only* place allowed to know every concrete class. Keeping wiring here means the rest of the code depends on abstractions, and swapping implementations (real vs mock, dev vs prod) is a one-file change.

**23. How do you decide what goes in `core`/`shared` vs a feature?**
Ask "does more than one feature need this, and is it stable?" Cross-cutting infrastructure (networking client, logger, theme, base failure types, DI setup) goes in `core`. Feature-specific logic stays in the feature. Beware the anti-patterns: a bloated `core` that becomes a dumping ground, and premature sharing of code that two features happen to resemble but will diverge — duplicate first, extract when the third use appears.

## 🔴 Advanced

**24. Walk a request through a Clean Architecture app.**
User taps "Load orders" →
1. **Widget** calls a method/event on the **ViewModel/BLoC** (presentation).
2. VM invokes a **use case** `GetOrders()` (domain).
3. Use case calls `OrderRepository.getOrders()` — an interface (domain).
4. `OrderRepositoryImpl` (data) hits `OrderRemoteDataSource`, gets `OrderDto`s, checks the cache, and **maps** DTOs → `Order` entities.
5. It returns `Result<List<Order>, Failure>` up the chain.
6. VM converts the result into UI state (`AsyncValue`); the widget rebuilds.

Every arrow crosses inward via an interface; nothing inner imports anything outer.

**25. How do you architect an app with 100+ screens and a team of 10+?**
- **Feature-first, modular packages** so features are independently ownable and buildable.
- **A `core`/design-system package** for shared UI and infrastructure; enforce that features never import each other.
- **Consistent per-feature skeleton** (presentation/domain/data) so any engineer can navigate an unfamiliar feature.
- **Typed navigation** (`go_router` with typed routes) and a route registry per feature to decouple navigation from feature internals.
- **A composition root** aggregating each feature's DI module.
- **CI running melos** across packages; codeowners per package; contract tests at repository boundaries.

The goal is that adding feature #101 doesn't require understanding features #1–100.

**26. What is Domain-Driven Design, and how much of it is worth it on mobile?**
DDD is designing software around a rich model of the business domain, using a *ubiquitous language* shared with domain experts. Its tactical building blocks — entities, value objects, aggregates, domain services, repositories — map well to a Flutter domain layer. Pragmatically on mobile you adopt the *tactical* patterns (especially entities + value objects + repositories) where the domain is genuinely complex; the full strategic apparatus (bounded contexts, context maps, event storming) is usually overkill for a client app whose complexity lives server-side. See [46 Domain Driven Design](../46%20Domain%20Driven%20Design/README.md).

**27. Entity vs value object vs aggregate — define each.**
- **Entity** — has identity that persists through change; two users with the same name are different if their `id`s differ. Equality is by identity.
- **Value object** — defined entirely by its attributes, no identity, immutable; `Money(100, 'USD')`, `EmailAddress`, `DateRange`. Equality is by value. Great place to enforce validity ("an EmailAddress cannot be constructed invalid").
- **Aggregate** — a cluster of entities/value objects with one **aggregate root** as the sole entry point, enforcing invariants across the cluster (an `Order` root guarding its `OrderLine`s so totals stay consistent). You reference and load aggregates as a unit.

**28. Why are value objects underrated in Flutter apps?**
They push validation and invariants into the type system instead of scattering `if` checks across UI and services. An `EmailAddress` that can only exist if valid means every function taking one is spared re-validation, and impossible states become unrepresentable. They also give meaningful equality for free (via `==`/`Equatable` or Dart records), which matters for rebuild-diffing and testing. The cost is a bit of boilerplate — worth it for concepts with real rules, skippable for a bare `String label`.

**29. How do you keep the domain layer pure in Flutter?**
The domain package/folder must not import `package:flutter`, `dio`, `hive`, `json_annotation`, etc. Enforce it by putting domain in its own package with only `meta`/`collection`-type deps, or via lint rules banning those imports. Entities are plain immutable Dart; no `fromJson` (that's the DTO's job); no `BuildContext`. Purity is what makes the domain portable, framework-swappable, and testable at pure-Dart speed with no widget or device.

**30. How does architecture help manage technical debt over time?**
Boundaries *contain* debt. When data lives behind repository interfaces, a hacked-together data source is quarantined — you can rewrite it without touching domain or UI. Feature packages let you rewrite one feature without destabilizing others. Clear seams also make debt *visible and measurable* (this repo impl is the messy one), and give safe refactoring points. Without boundaries, debt is systemic: any shortcut can entangle unrelated code, and there's nowhere safe to cut.

**31. When should you deliberately NOT use Clean Architecture?**
When the ceremony costs more than it saves:
- **Prototypes, MVPs, throwaway spikes** — speed matters, longevity doesn't.
- **Genuinely simple apps** — a handful of CRUD screens; the layers/mappers/use-cases become pure overhead.
- **Solo, short-lived projects** — no team-coordination benefit to pay for.

Right-sizing is itself a senior skill: start with feature-folders + a ViewModel + repositories, and *introduce* use cases, value objects, and package splits only when complexity or team size demands them. Over-architecting a to-do app is as much a mistake as under-architecting a banking app.

**32. How do you evolve architecture incrementally instead of a big rewrite?**
Refactor at the seams you already have. Introduce a repository interface in front of an existing direct API call; move business logic out of a fat widget into a ViewModel; extract a stable, reused chunk into a `core` package; add use cases only where a VM has grown complex orchestration. Each step is independently shippable and test-covered. The dependency rule tells you the *direction* to refactor toward (push detail outward, policy inward); you don't need a green-field rewrite to get there.

**33. How do error models flow across layers?**
The data layer catches raw, technology-specific errors (`DioException`, `SocketException`, `HiveError`) at its boundary and maps them to domain `Failure` types (`NetworkFailure`, `AuthFailure`, `CacheFailure`), returning `Result`/`Either`. The domain and presentation layers only ever see `Failure`s — they never import Dio. The presentation layer maps `Failure` → user-facing message/UI state. This keeps the inner layers ignorant of transport details and gives you one exhaustive place per layer to handle problems. Pair with [38 Error Handling](../38%20Error%20Handling/README.md).

**34. How do you unit-test each layer in isolation?**
- **Domain** — pure Dart tests; construct a use case with a *fake* repository, assert behavior. No Flutter binding needed.
- **Data** — test repository impls with mocked data sources; assert DTO→entity mapping, cache logic, and failure mapping.
- **Presentation** — test the ViewModel/BLoC with mocked use cases/repositories; assert emitted states for given intents; widget-test the View against a fake VM.

The whole point of the layering is that each of these needs no real network, DB, or device. See [49 Testing](../49%20Testing/README.md).

## ⚡ Rapid-fire (one-liners)

| Question | Answer |
|---|---|
| Direction of dependencies in Clean Arch? | Inward — toward domain/policy |
| What does the domain layer depend on? | Nothing (pure Dart) |
| Where do `fromJson`/`toJson` live? | DTOs in the data layer |
| Entity vs DTO? | Business concept vs wire/DB shape |
| Best-fit MV* for Flutter? | MVVM |
| Is BLoC "the architecture"? | No — it's a presentation-layer state holder |
| Feature-first vs layer-first default? | Feature-first for non-trivial apps |
| What enforces module boundaries? | The package dependency graph + lints |
| Tool for a Dart monorepo? | melos |
| Value object equality is by? | Value, not identity |
| Aggregate entry point is called? | The aggregate root |
| Result/Either models failure as? | A return value, not a throw |
| Where is the object graph wired? | The composition root |
| When to skip Clean Architecture? | Prototypes, tiny/short-lived apps |
| Use case (interactor) is? | One unit of app-specific business logic |
| A repository hides? | Where the data comes from |

## Follow-up drills

1. **Design** the package/folder structure for a 120-screen fintech app with 4 squads — justify feature-first vs layer-first, what goes in `core`, and how you enforce that squads don't import each other's features.
2. **Refactor** a 900-line `HomeScreen` `StatefulWidget` that does HTTP, JSON parsing, caching, and UI into a Clean-ish structure — describe the sequence of safe, shippable steps.
3. **Right-size**: given a 6-screen internal tool built by one engineer in 3 weeks, argue what architecture you'd *deliberately omit* and why.
4. **Model** a `Cart` domain with an aggregate root enforcing "total never negative" and "max 20 line items" — show entities, value objects, and where the invariants live.
5. **Design** the error-handling contract for a repository: enumerate the `Failure` types, where raw exceptions are caught and mapped, and how the ViewModel surfaces each to the UI.
6. **Debug**: a teammate put business logic (discount calculation) inside a BLoC event handler and API JSON keys inside widgets — explain the concrete problems this causes and how you'd untangle it.
