# Dependency Injection — Interview Questions

> How objects get the collaborators they need instead of building them. For depth see the handbook module [14 Dependency Injection](../14%20Dependency%20Injection/README.md), especially [01_di_fundamentals.md](../14%20Dependency%20Injection/01_di_fundamentals.md) and [02_get_it_and_injectable.md](../14%20Dependency%20Injection/02_get_it_and_injectable.md).

DI is a mid/senior signal: it exposes whether you understand testability, decoupling, and object lifetimes — not just which package you imported. Interviewers push from "what is DI" toward "why is a service locator a smell" and "how do you swap a fake in a test without touching production code".

## 🟢 Basic

**1. What is dependency injection, in one line?**
Giving an object its dependencies from the outside instead of having it create them itself. Rather than `final api = ApiClient();` inside a class, you accept `ApiClient` as a constructor parameter and someone else decides which concrete instance to pass. DI is a *technique*; it does not require any library — passing a collaborator into a constructor is DI.

**2. What is Inversion of Control (IoC), and how does DI relate to it?**
IoC is the general principle that a component does not control the creation or wiring of its collaborators — that control is *inverted* to an outer layer (a composition root, a framework, a container). DI is the most common concrete form of IoC: instead of the class pulling its dependencies, they are pushed to it. The Hollywood principle — "don't call us, we'll call you" — is IoC in a sentence.

**3. Why bother with DI? What does it buy you?**
- **Testability** — you can pass a fake/mock instead of the real network client, so tests are fast and deterministic.
- **Decoupling** — the class depends on an abstraction (`AuthRepository`) not a concrete type, so implementations can change without touching consumers.
- **Single wiring point** — object graphs are assembled in one place (the composition root) instead of scattered `new` calls.
- **Lifetime control** — one place decides whether a dependency is a singleton or created fresh each time.

**4. What are the three kinds of injection?**
- **Constructor injection** — dependencies passed as constructor params. Preferred: makes them explicit, required, and immutable (`final`).
- **Setter/property injection** — assigned after construction via a setter. Use only for genuinely optional dependencies.
- **Method injection** — passed into the specific method that needs them.

Constructor injection is the default answer; the others are exceptions.

**5. Why is constructor injection preferred over the others?**
Because the dependencies become part of the type's public contract — you cannot construct the object in an invalid, half-wired state, and the compiler enforces that everything is provided. They can be `final`, so the object is immutable and thread-safe to read. And reading the constructor tells you exactly what the class needs, which surfaces "this class has 9 dependencies" as the design smell it is.

**6. What is a service locator, and how does it differ from injection?**
A service locator is a global registry you *ask* for dependencies: `getIt<ApiClient>()`. With injection, dependencies are *pushed* to the object (it stays passive); with a locator, the object *pulls* them (it reaches out to a global). `get_it` is a service locator. The distinction matters because pulling hides dependencies — the constructor no longer tells you what the class needs.

**7. What is `get_it`?**
A simple, fast service locator for Dart/Flutter. You register factories/singletons against a type at startup, then resolve them anywhere with `getIt<T>()` — no `BuildContext` needed. It is not a full DI container (no automatic constructor resolution); you wire the graph yourself in the registration calls. See [02_get_it_and_injectable.md](../14%20Dependency%20Injection/02_get_it_and_injectable.md).

```dart
final getIt = GetIt.instance;

void setup() {
  getIt.registerLazySingleton<ApiClient>(() => ApiClient());
  getIt.registerFactory<LoginBloc>(() => LoginBloc(getIt<AuthRepo>()));
}
```

**8. What is a "composition root"?**
The single place — usually near `main()` — where the entire object graph is assembled and lifetimes are decided. Keeping wiring here means the rest of the code depends only on abstractions and never calls `new` on its collaborators. In a `get_it` app it's your `setupLocator()` / `configureDependencies()` function.

**9. Does DI require a package in Flutter?**
No. Passing repositories and services down through constructors — or through the widget tree with `Provider` / `InheritedWidget` — is DI with zero extra dependencies. Packages like `get_it` and `injectable` reduce boilerplate for large graphs, but "DI" is a design idea, not a library.

**10. How is Provider a form of DI?**
`Provider` injects a value into the widget subtree; descendants resolve it with `context.read<T>()` instead of receiving it through their own constructors. It's scoped DI keyed to the widget tree — the value lives exactly as long as the provider's position in the tree. It doubles as change-notification, but the "expose a dependency to a subtree" half is pure DI.

## 🟡 Intermediate

**11. `registerSingleton` vs `registerLazySingleton` vs `registerFactory` in get_it?**

| Method | When instance is created | How many instances | Use for |
|---|---|---|---|
| `registerSingleton<T>(inst)` | **Eagerly**, at registration | One, shared | Something needed immediately / expensive to defer, must exist at startup |
| `registerLazySingleton<T>(() => ...)` | **Lazily**, on first `get<T>()` | One, shared thereafter | Most singletons — repositories, clients you may not touch on every launch |
| `registerFactory<T>(() => ...)` | **Every** `get<T>()` call | New each time | Stateful objects you want fresh — BLoCs/ViewModels tied to a screen |

The default choice for shared, stateless services is `registerLazySingleton`; for per-use stateful objects, `registerFactory`.

**12. What's the difference between `registerFactory` and `registerFactoryParam`?**
`registerFactoryParam` lets you pass up to two runtime arguments into the factory at resolve time, e.g. `getIt<DetailBloc>(param1: productId)`. Plain `registerFactory` takes no runtime args. Use the param variant when an object needs data only known at the call site (a route argument) rather than at registration.

**13. How do you make DI testable with get_it — resetting between tests?**
Call `await getIt.reset()` in `tearDown` (or `setUp`) so each test starts with a clean container, then register fakes for that test. For a single override you can `unregister<T>()` then re-register, or use `allowReassignment = true`. Because `get_it` is a global, forgetting to reset leaks registrations across tests and causes order-dependent failures.

```dart
setUp(() {
  getIt.registerSingleton<AuthRepo>(FakeAuthRepo());
});
tearDown(() => getIt.reset());
```

**14. What are get_it scopes, and why use them?**
Scopes let you push a named layer of registrations onto a stack (`pushNewScope`) and pop it later (`popScope`), overriding or adding registrations for a bounded lifetime. Classic use: a **user session** — push a scope at login holding user-specific singletons, pop it at logout to dispose them all at once. Resolutions look through the stack top-down, so a scoped registration shadows a lower one.

**15. What is `injectable` and how does it relate to get_it?**
`injectable` is a code-generation layer *on top of* `get_it`. You annotate classes (`@injectable`, `@singleton`, `@lazySingleton`) and it generates the `getIt.registerX` boilerplate via `build_runner`, resolving constructor dependencies for you. You still resolve through `getIt<T>()` at runtime — `injectable` only automates the registration wiring.

```dart
@module
abstract class RegisterModule {
  @lazySingleton
  Dio get dio => Dio();
}

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dio);
  final Dio _dio;
}
```

**16. How do you register an interface-to-implementation binding?**
Register the concrete class *against the abstract type*: `getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(...))`. Consumers resolve `getIt<AuthRepository>()` and never know the implementation. In `injectable`, `@LazySingleton(as: AuthRepository)` does the same. This is what makes swapping a fake in tests a one-line change.

**17. How does Riverpod act as a DI container?**
Every provider *is* a dependency registration: `final apiProvider = Provider((ref) => ApiClient());`, and other providers pull it with `ref.watch(apiProvider)`. Resolution is compile-safe (no runtime "not found"), lifetimes are controlled with `autoDispose`, and — crucially — tests inject fakes via `ProviderContainer(overrides: [...])` with no global mutation. It's a service locator that is type-safe and override-friendly. See [03_provider_riverpod_as_di.md](../14%20Dependency%20Injection/03_provider_riverpod_as_di.md).

**18. Compare get_it and Riverpod as DI mechanisms.**

| Aspect | get_it | Riverpod |
|---|---|---|
| Kind | Global service locator | Provider graph (compile-safe locator) |
| Lookup safety | Runtime — throws if unregistered | Compile-time wiring, no `BuildContext` needed |
| Lifetime control | Singleton / lazy / factory / scopes | `autoDispose`, `family`, `keepAlive` |
| Test override | Global `reset` + re-register | `ProviderContainer(overrides:)` — isolated |
| Coupling to tree | None | None (providers are top-level) |
| Best for | Simple flat wiring, non-widget code | Apps already using Riverpod for state |

**19. Where do you resolve dependencies in Clean Architecture layers?**
Only at the **composition root** and the presentation entry points — never deep inside domain/data classes. Use cases receive repositories via constructor; repositories receive data sources via constructor; the locator wires `DataSource → Repository → UseCase → Bloc` once. Inner layers stay pure and locator-free, so the domain layer has no dependency on `get_it` at all. See [40 Clean Architecture](../40%20Clean%20Architecture/README.md).

**20. How do you swap a fake/mock for a real dependency in a test?**
Because everything depends on an abstraction, you register (or override) the fake at the seam. With constructor injection you just pass it: `LoginBloc(FakeAuthRepo())`. With `get_it` you re-register `AuthRepository` with a fake after `reset()`. With Riverpod you add `authRepoProvider.overrideWithValue(FakeAuthRepo())`. No production code changes — that's the whole point of injecting the abstraction. See [05_testing_with_di.md](../14%20Dependency%20Injection/05_testing_with_di.md).

**21. What does object "lifetime" mean in DI and who should own it?**
Lifetime is how long a resolved instance lives and when it's disposed — per-resolve (factory), whole-app (singleton), or bounded (scope/session). The DI container owns lifetimes so consumers don't guess. Getting this wrong is a common bug: a factory-registered stream controller never disposed leaks; a singleton holding request-specific state bleeds data between users.

## 🔴 Advanced

**22. Why is a service locator often called an anti-pattern despite get_it's popularity?**
Because it **hides dependencies**. A constructor tells you what a class needs; a class that calls `getIt<X>()` internally hides that it needs `X`, defeating the compiler and making the graph invisible until it fails at runtime. It also creates a global that couples every consumer to the locator, complicates test isolation (global state), and lets you resolve anything anywhere, which erodes layering. The pragmatic stance: use `get_it` *at the composition root and presentation edges only*, and still constructor-inject into your domain/data classes — get the ergonomics without smearing the locator through the codebase.

**23. Constructor injection vs service locator — when is each actually appropriate?**
Constructor injection wherever a type is unit-tested or lives in a layer you want pure (domain, data) — dependencies stay explicit and mockable. Service locator at the outer boundary where wiring would otherwise be tedious (getting a BLoC into a widget without prop-drilling, accessing services from non-widget code like background isolates or notification handlers). The senior answer is "both": locate at the edge, inject through the core.

**24. What problems do global mutable singletons cause?**
- **Shared mutable state** — one caller mutates it, another reads unexpected data; the source of "works in isolation, fails together" bugs.
- **Test pollution** — state persists across tests unless explicitly reset, causing order-dependent flakiness.
- **Hidden coupling** — anything can reach the singleton, so the dependency graph is invisible.
- **Lifetime bugs** — a session-scoped value living as an app singleton leaks the previous user's data after logout.

Mitigations: make singletons *stateless* (or immutable), scope stateful ones to a session, and always `reset()` in tests.

**25. What are "hidden dependencies" and why do they hurt?**
Dependencies a type acquires without declaring them — via a service locator call, a global, or reading a static. They hurt because the type's true contract is invisible: you can't tell what it needs to run, tests fail with cryptic "not registered" errors, and refactoring is dangerous because the compiler can't help. The fix is to surface them as constructor parameters so the type is honest about its needs.

**26. How do you detect a circular dependency in a DI graph, and how do you break it?**
With `get_it`, a lazy singleton that resolves its own type during construction blows the stack or throws on first `get`. Break the cycle by: introducing an abstraction one side depends on instead of the concrete other; using lazy/deferred resolution (pass a `() => getIt<T>()` factory or resolve inside a method rather than the constructor); or — usually the real fix — extracting the shared concern into a third type both depend on. A cycle almost always signals a missing seam in the design.

**27. How do you handle async dependencies that must be ready before the app runs?**
Register them with `registerSingletonAsync<T>(() async => await T.init())` and gate startup on `await getIt.allReady()`, or await the init in `main()` before `runApp`. Use `registerSingletonWithDependencies` to order async singletons that depend on each other. Example: `SharedPreferences.getInstance()` or a database `open()` must complete before repositories that use them are resolved.

**28. How do you scope dependencies to a user session and dispose them on logout?**
Push a get_it scope at login holding user-specific singletons (`getIt.pushNewScope(scopeName: 'session', init: (g) {...})`) and `popScope()` at logout, which disposes everything registered in it. In Riverpod, put session state in `autoDispose` providers or a `family` keyed by user, and invalidate on logout. The goal is that no logged-in user's data can survive into the next session. See [04_scopes_and_lifetimes.md](../14%20Dependency%20Injection/04_scopes_and_lifetimes.md).

**29. Why prefer `ProviderContainer(overrides:)` over resetting a global in Riverpod tests?**
Because each `ProviderContainer` is an isolated graph — overrides apply only to that container, so tests can't leak state into one another and can run in parallel. There's no global to forget to reset. This is the structural advantage Riverpod has over `get_it` for testing: isolation is the default, not something you bolt on with `tearDown`.

**30. How does `injectable`'s environment feature help with DI?**
`@Environment('dev')` / `@Environment('prod')` (and the `@dev`/`@prod`/`@test` shortcuts) let you register different implementations per environment, selected by the environment string you pass to `configureDependencies`. So a `@Environment('test')` fake repository replaces the real one without conditional code in production. It moves environment branching into declarative annotations resolved at wiring time.

**31. A widget deep in the tree needs a service. Constructor-inject it down, use Provider, or use get_it — how do you decide?**
Prop-drilling through many layers is noise and couples intermediate widgets to a type they don't use — avoid past a level or two. `Provider`/`InheritedWidget` is right when the value is genuinely tree-scoped (theme, a screen-scoped controller) and you want it disposed with that subtree. `get_it`/Riverpod is right for app-wide services (repositories, clients) that aren't tied to any widget's position — resolve them at the point of use without threading them through the tree. Decision axis: is the lifetime tied to the widget tree (Provider) or the app/session (locator)?

## ⚡ Rapid-fire (one-liners)

| Q | A |
|---|---|
| DI in one line? | Pass dependencies in instead of creating them inside. |
| DI vs IoC? | DI is a concrete form of IoC (control of wiring inverted outward). |
| Preferred injection type? | Constructor injection. |
| Injection vs service locator? | Push (passive object) vs pull (object asks a global). |
| Is get_it DI or a locator? | A service locator. |
| Lazy vs eager singleton? | Created on first `get` vs at registration. |
| Factory registration gives you? | A new instance every resolve. |
| Register a BLoC per screen as? | `registerFactory`. |
| Reset get_it between tests? | `await getIt.reset()` in tearDown. |
| get_it scopes are for? | Bounded lifetimes, e.g. a user session. |
| What is injectable? | Codegen registration layer on top of get_it. |
| Bind interface to impl in injectable? | `@LazySingleton(as: AbstractType)`. |
| Async singleton before startup? | `registerSingletonAsync` + `await allReady()`. |
| Riverpod as DI? | Providers are registrations; `ref.watch` resolves. |
| Override a dep in Riverpod test? | `ProviderContainer(overrides:)`. |
| Main service-locator smell? | Hidden dependencies / global coupling. |
| Where to resolve in Clean Arch? | Composition root + presentation edge only. |
| Swap a fake in a test? | Override the abstraction at the seam — no prod change. |
| Fix a circular dependency? | Add an abstraction or defer resolution; extract shared type. |

## Follow-up drills

1. **Design** the DI wiring for a Clean Architecture feature (data source → repository → use case → bloc) using `get_it` + `injectable` — show the composition root and where each lifetime is chosen.
2. **Refactor** a class that calls `getIt<X>()` in three methods into constructor injection, and explain what testability you just gained.
3. **Debug** a test suite that passes individually but fails when run together — trace it to un-reset global singleton state and fix it two different ways.
4. **Migrate** an app's DI from a hand-rolled `get_it` setup to `injectable` codegen incrementally without a big-bang rewrite.
5. **Implement** session-scoped dependencies that are created at login and fully disposed at logout, and prove no data leaks into the next session.
6. **Justify** to a teammate why you'd keep `get_it` only at the edges while constructor-injecting through the core — with a concrete example where the pure-locator approach bites.
