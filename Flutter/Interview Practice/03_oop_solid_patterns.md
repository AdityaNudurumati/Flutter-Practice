# OOP, SOLID & Design Patterns (in Dart) — Interview Questions

> Object-oriented modeling, the SOLID principles, and the design patterns you actually meet in Flutter code. Depth: [03 Object Oriented Programming](../03%20Object%20Oriented%20Programming/README.md), [04 SOLID Principles](../04%20SOLID%20Principles/README.md), [05 Design Patterns](../05%20Design%20Patterns/README.md).

This topic tests whether you can structure non-trivial code so it stays testable and changeable. Interviewers use it to separate people who memorized pattern names from people who know *which* problem each pattern removes — and when applying one is over-engineering.

## 🟢 Basic

**1. What are the four pillars of OOP, in one line each?**
- **Encapsulation** — bundle state with the behavior that guards it, and hide the internals (`_private` in Dart).
- **Inheritance** — a subtype reuses and specializes a supertype (`class Dog extends Animal`).
- **Polymorphism** — one interface, many runtime implementations; the correct override is dispatched dynamically.
- **Abstraction** — expose *what* an object does, hide *how*; model the essential and drop the rest.

**2. How does encapsulation work in Dart specifically?**
Dart has no `private`/`public`/`protected` keywords. Privacy is **library-level**: an identifier prefixed with `_` is visible only within its own `.dart` library, not just the class. So two classes in the same file can touch each other's `_fields`. You expose controlled access through getters/setters instead of public fields, which lets you add validation or computed values later without changing the call site.

**3. What is the difference between a class, an abstract class, and an interface in Dart?**
A **concrete class** can be instantiated. An **abstract class** (`abstract class`) can declare methods without bodies and cannot be instantiated directly — it's meant to be extended or implemented. Dart has **no separate `interface` keyword**: *every class implicitly defines an interface*. When you `implements SomeClass`, you adopt its interface (all members) but inherit none of its implementation and must re-supply everything.

**4. `extends` vs `implements` vs `with` — when do you use each?**

| Keyword | Meaning | Inherits implementation? | Count |
|---|---|---|---|
| `extends` | Subclass a class | Yes | One only |
| `implements` | Adopt a class's interface as a contract | No — you re-implement all members | Many |
| `with` | Mix in reusable behavior | Yes (from the mixin) | Many |

Use `extends` for a true is-a with shared code, `implements` for a pure contract or to fake/mock a type in tests, `with` (mixins) to share behavior across unrelated hierarchies.

**5. What is polymorphism in practice, with a Dart example?**
Calling a method on a supertype reference and having the subtype's version run at runtime.
```dart
abstract class Shape { double area(); }
class Circle implements Shape { final double r; Circle(this.r); double area() => 3.14 * r * r; }
class Square implements Shape { final double s; Square(this.s); double area() => s * s; }

double total(List<Shape> shapes) => shapes.fold(0, (sum, s) => sum + s.area());
// total([Circle(1), Square(2)]) works without total() knowing the concrete types
```
Adding a `Triangle` later requires zero changes to `total()`.

**6. What is composition, and why "composition over inheritance"?**
Composition means an object *holds* other objects and delegates to them (has-a) instead of inheriting from them (is-a). It's preferred because inheritance is rigid: it couples you to the parent's implementation, allows only one superclass, and deep hierarchies become fragile (a change up top ripples down). Composition lets you swap collaborators, mix capabilities freely, and test each piece in isolation. Flutter itself is built on composition — you *nest* widgets, you don't subclass a mega-widget.

**7. Why is `abstract class` used so much in Flutter/Dart architecture?**
To define contracts. A repository or service is declared as an abstract class; the concrete implementation lives elsewhere and is injected. Code depends on the abstraction, so you can swap a real HTTP implementation for a fake in tests without touching callers. It's the enabler for the D in SOLID.

**8. What does SOLID stand for?**
- **S** — Single Responsibility Principle
- **O** — Open/Closed Principle
- **L** — Liskov Substitution Principle
- **I** — Interface Segregation Principle
- **D** — Dependency Inversion Principle

They're guidelines for managing coupling and change, not laws — see [04 SOLID Principles](../04%20SOLID%20Principles/README.md).

**9. Explain the Single Responsibility Principle with the smell it fixes.**
A class should have one reason to change. The smell is a **god class** that does networking, parsing, caching, and UI formatting — a bug fix in parsing risks breaking caching, and the class is impossible to test in isolation. Split it: a `UserApi` (fetch), a `UserMapper` (parse), a `UserCache` (store). Each changes for one reason.

**10. What is a design pattern, and why not just write ad-hoc code?**
A design pattern is a named, reusable solution to a recurring design problem. The value is twofold: it's a **vocabulary** ("this is a Repository behind a Factory") that compresses communication, and it encodes a structure that's already been proven to keep coupling low. The risk is cargo-culting — applying a pattern where a plain function would do adds indirection for no benefit.

**11. What is the Singleton pattern and how do you write one in Dart?**
A class with exactly one shared instance. The idiomatic Dart form uses a factory constructor returning a cached static instance:
```dart
class ApiClient {
  ApiClient._internal();                    // private named ctor
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;         // every ApiClient() returns the same object
}
```
Because top-level and `static final` fields in Dart are **lazily initialized** on first access, `static final ApiClient instance = ApiClient._();` is an even simpler idiom.

**12. What is a factory constructor and how does it differ from a generative one?**
A generative constructor always creates a *new* instance and initializes fields. A **`factory`** constructor doesn't have to — it can return a cached instance, a subtype, or an instance built from a computed value. That's why it's used for singletons, caches, and `fromJson` deserialization where the concrete type depends on the data.

## 🟡 Intermediate

**13. Abstract class vs implicit interface — when do you `extends` vs `implements` the same abstract class?**
`extends` when the abstract class provides shared implementation you want to inherit and you only override the abstract bits. `implements` when you want *only the contract* and will supply every member yourself — common in tests to build a fake, or when a class already extends something else (single-inheritance forces you to `implements`). Note: `implements` on an abstract class with concrete methods forces you to re-implement even those methods.

**14. How do you correctly implement value equality in Dart?**
Override **both** `==` and `hashCode` — they must agree (equal objects must have equal hashCodes), or the object misbehaves in `Set`/`Map`.
```dart
class Point {
  final int x, y;
  const Point(this.x, this.y);
  @override bool operator ==(Object other) =>
      other is Point && other.x == x && other.y == y;
  @override int get hashCode => Object.hash(x, y);
}
```
Use `Object.hash(...)` / `Object.hashAll(...)` rather than hand-rolling. In practice, prefer generating this with `freezed`/`equatable` to avoid mistakes. See [07 Equality and Copying](../03%20Object%20Oriented%20Programming/07_equality_and_copying.md).

**15. Why must equal objects have equal hashCodes?**
Hash-based collections (`HashSet`, `HashMap`) first bucket an object by `hashCode`, then compare with `==` only within that bucket. If two `==` objects have different hashCodes they land in different buckets, so a lookup for one won't find the other — you get "I just added it but `contains` says false" bugs. The reverse isn't required: unequal objects *may* share a hashCode (a collision), that's fine.

**16. What is `copyWith` and why is it central to immutable state?**
`copyWith` returns a **new** instance with some fields replaced and the rest copied — the idiomatic way to "mutate" an immutable object.
```dart
User copyWith({String? name, int? age}) =>
    User(name: name ?? this.name, age: age ?? this.age);
```
It's central to state management (BLoC/Riverpod/`setState`) because immutable state means change detection is a cheap identity/`==` check, and old snapshots stay valid (undo, time-travel). Caveat: `name ?? this.name` can't distinguish "leave unchanged" from "set to null" — `freezed` solves this with sentinel values.

**17. Deep copy vs shallow copy — what breaks if you get it wrong?**
A **shallow copy** duplicates the top-level object but shares references to nested objects. A **deep copy** recursively clones nested objects too. If a `copyWith` shallow-copies a `List` field (`this.items`) and a caller mutates that list, *both* the old and new "immutable" objects change — silently corrupting state and breaking equality-based rebuilds. Fix: copy the collection (`List.of(items)`) or, better, use genuinely immutable collections.

**18. Explain the Open/Closed Principle with a Dart example.**
Open for extension, closed for modification: add behavior by adding code, not editing tested code. The smell is a growing `switch`:
```dart
// Violates OCP — every new type edits this method
double price(String type) { switch (type) { case 'a': ...; case 'b': ...; } }
```
Fix with polymorphism — each type implements a `Priceable` interface, and new types are new classes. The pricing engine never changes. See [02 Open/Closed](../04%20SOLID%20Principles/02_ocp_open_closed.md).

**19. Explain the Liskov Substitution Principle and a classic violation.**
A subtype must be usable anywhere its supertype is expected without breaking correctness. Classic violation: `Square extends Rectangle` overriding `setWidth` to also change height — code that sets width and height independently (valid for a Rectangle) now breaks. Also violated when an override **strengthens preconditions** (rejects inputs the parent accepted) or throws `UnsupportedError` for an inherited method. If you find yourself type-checking `if (x is Square)` to work around a subtype, LSP is broken.

**20. Explain Interface Segregation with a Dart smell.**
Don't force a class to implement methods it doesn't use. A fat `Worker` interface with `work()` and `eat()` forces a `RobotWorker` to implement a meaningless `eat()`. Split into `Workable` and `Feedable`; a robot implements only `Workable`. In Dart this maps to keeping abstract classes small and role-focused rather than one giant service interface. See [04 Interface Segregation](../04%20SOLID%20Principles/04_isp_interface_segregation.md).

**21. Explain the Dependency Inversion Principle — and how it differs from dependency injection.**
**DIP** (the principle): high-level modules and low-level modules should both depend on **abstractions**, not on each other. Your `LoginBloc` depends on an `AuthRepository` interface, not on `FirebaseAuth` directly. **Dependency Injection** (the technique/pattern) is *how* you satisfy DIP — you pass the concrete implementation in from outside (constructor, `get_it`, Provider) instead of the class `new`-ing it internally. DIP is the goal; DI is a means. See [05 Dependency Inversion](../04%20SOLID%20Principles/05_dip_dependency_inversion.md) and [14 Dependency Injection](../14%20Dependency%20Injection/README.md).

**22. What is the Strategy pattern and where does it show up in Flutter?**
Encapsulate interchangeable algorithms behind a common interface and pick one at runtime.
```dart
abstract class SortStrategy { List<int> sort(List<int> data); }
class QuickSort implements SortStrategy { ... }
class Sorter { SortStrategy strategy; Sorter(this.strategy); ... }
```
It's OCP in action. In Flutter you see it as pluggable validators, sort/filter selectors, or a `ScrollPhysics` you swap on a `ListView`.

**23. What is the Factory pattern, and how does Flutter/Dart use it?**
A factory centralizes *object creation* so callers don't hardcode concrete types. Dart's `factory` constructor is the language-level form; `Model.fromJson` is the everyday example — it decides what to build from the data. A **Factory Method** returns a subtype based on input (`Notification.from(type)` returning `EmailNotification` or `PushNotification`). See [01 Factory](../05%20Design%20Patterns/01_factory.md).

**24. What is the Builder pattern and where is it in Flutter?**
Construct a complex object step by step, separating construction from representation. Flutter's `...builder` callbacks (`ListView.builder`, `StreamBuilder`, `LayoutBuilder`) are a variant — they defer creating widgets until context/index is known. The classic Builder (a chainable `QueryBuilder().where().limit().build()`) shows up in query/HTTP request builders. See [02 Builder](../05%20Design%20Patterns/02_builder.md).

**25. What is the Repository pattern and why is it standard in Flutter apps?**
A Repository is an abstraction over data sources that gives the domain layer a clean, source-agnostic API (`getUser(id)`), hiding whether data comes from REST, cache, or a local DB. It's standard because it (a) satisfies DIP — BLoCs depend on `UserRepository`, not Dio; (b) makes tests trivial with a fake repo; and (c) localizes the "network-first vs cache-first" decision in one place. See [40 Clean Architecture](../40%20Clean%20Architecture/README.md).

## 🔴 Advanced

**26. Walk through the Observer pattern and where Flutter already implements it.**
A subject maintains a list of observers and notifies them on state change. Flutter is *saturated* with it: `ChangeNotifier`/`notifyListeners()` + `AnimatedBuilder`/`ListenableBuilder`, `ValueNotifier`/`ValueListenableBuilder`, and `Stream`/`StreamBuilder` are all Observer. `setState` is a scoped form. When you use Provider or `flutter_bloc`, the widget subscribes as an observer and rebuilds on notification. Knowing this reframes state management as "who observes what, and how narrowly."

**27. What is the Decorator pattern and how does it differ from inheritance?**
Decorator wraps an object to add behavior *at runtime* while keeping the same interface — composition, not a compile-time subclass. Flutter's widget tree is decoration by nesting: `Padding(child: DecoratedBox(child: ...))` each adds one responsibility around the child. The advantage over inheritance is combinatorial: you compose `Padding + Opacity + GestureDetector` in any order instead of needing a `PaddedOpaqueTappableWidget` subclass for every combination. See [06 Decorator](../05%20Design%20Patterns/06_decorator.md).

**28. What is the Adapter pattern and when do you reach for it?**
Adapter converts one interface into another so incompatible classes can collaborate — you reach for it at boundaries you don't control. Example: a third-party analytics SDK exposes `logEvent(Map)`, but your app defines an `AnalyticsService.track(Event)` interface; a `FirebaseAnalyticsAdapter implements AnalyticsService` translates between them. This keeps the vendor SDK out of your domain, so swapping vendors touches only the adapter. See [05 Adapter](../05%20Design%20Patterns/05_adapter.md).

**29. Contrast Adapter, Decorator, and Proxy — they all wrap an object.**
All three hold a reference to a wrapped object, but their *intent* differs:

| Pattern | Interface vs wrapped | Intent |
|---|---|---|
| **Adapter** | Different | Make an incompatible interface fit |
| **Decorator** | Same | Add responsibilities without changing the type |
| **Proxy** | Same | Control access — lazy-load, cache, authorize, log |

Same mechanics, three different problems. Naming the intent is what interviewers listen for.

**30. Give a concrete Dart example of the Dependency Injection pattern with a testable seam.**
```dart
abstract class Clock { DateTime now(); }
class SystemClock implements Clock { DateTime now() => DateTime.now(); }

class SessionService {
  final Clock _clock;
  SessionService(this._clock);            // injected — the seam
  bool isExpired(DateTime issued) => _clock.now().difference(issued).inMinutes > 30;
}
// prod:  SessionService(SystemClock());
// test:  SessionService(FakeClock(fixed: someInstant));  // deterministic
```
The injected `Clock` turns an untestable `DateTime.now()` into a controllable dependency. `get_it`/`injectable` and Provider automate wiring this at scale — see [14 Dependency Injection](../14%20Dependency%20Injection/README.md).

**31. Is Singleton an anti-pattern? Defend your answer.**
It's a *smell* more than an outright anti-pattern. Problems: it's global mutable state (hard to reason about), it hides dependencies (a class secretly uses `ApiClient()` instead of declaring it), and it's hard to reset/mock between tests. The fix isn't "never one instance" — it's registering a single instance in a DI container (`get_it.registerSingleton`) and *injecting* it, so lifetime is controlled and tests can override it. So: one instance = fine; global static access to it = the smell.

**32. What is a god class / god object and how do you refactor one?**
A class that accumulates too many responsibilities and knows too much — hundreds of lines, dozens of fields, imports from every layer. It violates SRP, is a merge-conflict magnet, and can't be unit-tested. Refactor by (1) grouping methods/fields that change together, (2) extracting each group into a focused collaborator, (3) having the original delegate, then (4) inverting dependencies so it holds abstractions. In Flutter this is the 2,000-line `StatefulWidget` that does fetching, business logic, and layout — split into repository, controller/BLoC, and dumb widgets.

**33. What is tight coupling, how do you detect it, and how do you loosen it?**
Tight coupling is when a change in one class forces changes in another. Detection signals: `new`/direct construction of concrete collaborators inside a class, reaching through object chains (`a.b.c.d` — Law of Demeter violation), and widespread `import` of a concrete type. Loosen it by depending on abstractions (DIP), injecting collaborators, and using events/streams so producer and consumer don't reference each other. Measure of success: you can unit-test the class with fakes and no real network/DB.

**34. How do abstract classes, `sealed`, and mixins differ for modeling a closed hierarchy?**
- **`abstract class`** — a contract/base; open for anyone to extend or implement.
- **`sealed class`** (Dart 3) — abstract *and* the subtypes are known at compile time within the library, so `switch` over them is **exhaustively checked** — the compiler errors if you miss a case. Ideal for state unions and the modern alternative to a `Result`/`Either` hierarchy.
- **`mixin`** — reusable behavior grafted onto classes via `with`, without an is-a relationship.

Reach for `sealed` when you want the compiler to enforce that every case is handled — it makes OCP-vs-exhaustiveness a deliberate choice rather than an accident.

**35. When is applying a design pattern the wrong call?**
When it adds indirection that outlives no real variation point. A Strategy with exactly one implementation, a Factory that just calls one constructor, or an interface with a single forever-implementation are speculative generality — they cost readability now for flexibility you may never need (YAGNI). Introduce the pattern at the moment a *second* case appears, guided by the smell it removes, not preemptively. Senior signal: you can name both the pattern *and* the condition under which it's premature.

**36. How does immutability interact with equality and Flutter rebuild performance?**
Immutable objects with value equality let Flutter skip work: `const` widgets are canonicalized (one instance reused), and equality-based diffing (BLoC's `buildWhen`, Riverpod `select`, `Equatable`) rebuilds only when a value actually changed rather than on every new-but-equal instance. But it only holds if equality is correct and copies are deep enough — a shared mutable list inside a "value" object defeats both the `==` check and `const`-ness, causing missed or excess rebuilds. This is why `freezed` (immutable + generated `==`/`hashCode`/`copyWith`) is the default for state classes. See [21 Performance](../21%20Performance/README.md).

**37. Design a payment system that's open to new providers but closed to modification — which principles and patterns apply?**
- **DIP + Strategy**: define `abstract class PaymentGateway { Future<Result> pay(Amount a); }`; each provider (`StripeGateway`, `RazorpayGateway`) is a strategy implementing it.
- **Factory**: a `PaymentGatewayFactory.forMethod(method)` selects the implementation, so callers stay decoupled from concretes.
- **OCP**: adding PayPal = a new class + one factory registration; the checkout flow never changes.
- **Adapter**: each gateway class adapts the vendor SDK to your `PaymentGateway` interface.
- **DI**: the factory/gateway is injected so tests use a `FakeGateway`.

That's four patterns collaborating, each removing a specific coupling — and it's the kind of layered answer senior interviews reward.

## ⚡ Rapid-fire (one-liners)

| Question | Answer |
|---|---|
| Dart's access modifier? | `_` prefix = library-private; no `public`/`protected` keywords |
| Is there an `interface` keyword? | No — every class defines an implicit interface |
| `extends` count limit? | One superclass; `implements`/`with` allow many |
| Override `==`, must also override…? | `hashCode` (they must agree) |
| Idiomatic hashCode combine? | `Object.hash(a, b)` / `Object.hashAll(list)` |
| Why `copyWith`? | Immutable "mutation" — new instance, rest copied |
| Shallow copy risk? | Shared nested references mutate both objects |
| S in SOLID? | Single Responsibility — one reason to change |
| OCP mechanism in Dart? | Polymorphism replaces a growing `switch` |
| LSP red flag? | Overrides that throw or need `is` type-checks |
| DIP vs DI? | DIP = depend on abstractions (goal); DI = pass them in (means) |
| Dart singleton idiom? | `factory` returning a `static final` instance |
| `fromJson` is which pattern? | Factory |
| `ListView.builder` is which pattern? | Builder (lazy construction) |
| `ChangeNotifier`/`Stream` is which pattern? | Observer |
| Nested widgets are which pattern? | Decorator (composition) |
| Repository solves? | Source-agnostic data access + DIP + testability |
| God class fix? | Extract responsibilities, delegate, invert deps |
| `sealed class` benefit? | Exhaustive `switch` checked at compile time |

## Follow-up drills

1. **Design** a notification system supporting email, SMS, and push that a new channel can join without editing existing code — name the patterns and principles at each seam.
2. **Refactor** a 1,500-line `StatefulWidget` that fetches data, holds business rules, and builds UI into a testable structure; describe the extraction order and the seams you introduce.
3. **Debug this scenario:** a value object is added to a `Set`, but `set.contains(equalObject)` returns `false`. Diagnose the root cause and the exact fix.
4. **Decide:** you have one implementation of a service and no second one in sight — justify whether to introduce an interface + DI now or later, using YAGNI vs testability.
5. **Contrast** using `sealed class` + exhaustive `switch` versus polymorphic dispatch for modeling a set of app states — trade-offs of each for adding new states.
6. **Design** a caching layer in front of a remote API without changing any caller — pick between Proxy and Decorator and defend the choice.
