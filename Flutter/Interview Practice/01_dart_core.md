# Dart Core — Interview Questions

> Language fundamentals: variables & finality, the type system, sound null safety, collections, functions & closures, Dart 3 records & patterns, and enums. For depth see [01 Dart Fundamentals](../01%20Dart%20Fundamentals/README.md) and [02 Advanced Dart](../02%20Advanced%20Dart/README.md).

This topic tests whether you actually understand Dart as a language — not just Flutter APIs. Interviewers probe it because null-safety mistakes, `const` misuse, and pattern-matching gaps are the most common source of runtime crashes and rebuild bugs in real apps.

## 🟢 Basic

**1. What is the difference between `var`, `final`, and `const`?**
`var` declares a mutable variable whose type is inferred once at the declaration. `final` means the binding is assigned exactly once and can't be reassigned, but the object it points to can still be mutated. `const` is a stronger `final`: the value must be a *compile-time constant*, so it's frozen deeply and computed before the program runs.
```dart
final list = [1, 2];
list.add(3);   // OK — the reference is final, the List is mutable
const list2 = [1, 2];
list2.add(3);  // runtime error — const collections are deeply immutable
```

**2. When would you choose `final` over `const`?**
Use `const` when the value is fully known at compile time (literals, `const` constructors) — you gain canonicalization and cheaper rebuilds. Use `final` when the value is known only at runtime (e.g. `DateTime.now()`, a value from a function, a constructor arg). If you *can* make it `const`, prefer it; otherwise `final`.

**3. What are Dart's core built-in types?**
`num` (superclass of `int` and `double`), `String`, `bool`, `List`, `Set`, `Map`, `Runes`, and `Symbol`. `int` and `double` are both `num`; note that on the web all numbers are IEEE-754 doubles, so `int` there is a double under the hood. `null` is its own type (`Null`).

**4. What's the difference between `dynamic`, `Object`, and `Object?`?**
`Object?` is the top type — everything, including `null`, is an `Object?`. `Object` is every non-null value. `dynamic` is also a top type but it *disables static type checking*: calls on a `dynamic` are resolved at runtime and can throw `NoSuchMethodError`. Prefer `Object?` when you want "anything but keep type safety"; reserve `dynamic` for genuine interop/JSON cases.

**5. What is sound null safety?**
Types are non-nullable by default; `String` can never hold `null`, only `String?` can. "Sound" means the guarantee is enforced end-to-end — if the type system says a value is non-null, the runtime trusts it (no null checks compiled in), so you can't get a surprise null through a non-nullable variable. This eliminates most `NoSuchMethodError: null` crashes.

**6. Explain `?`, `!`, `??`, and `??=`.**
- `?` — nullable type (`int?`) or null-aware access (`user?.name`, returns null if `user` is null).
- `!` — non-null assertion: `value!` throws if `value` is null, otherwise narrows to non-null.
- `??` — if-null: `a ?? b` returns `a` unless it's null, then `b`.
- `??=` — assign-if-null: `x ??= 5` sets `x` to 5 only when it's currently null.

**7. What does `late` do?**
`late` promises the compiler a non-nullable variable will be initialized before first use, deferring initialization past the declaration. For a `late` with an initializer, it also makes the init *lazy* — computed on first read. Reading a `late` before assignment throws `LateInitializationError`.

**8. How do you write list, set, and map literals?**
```dart
final list = [1, 2, 3];              // List<int>
final set  = {1, 2, 3};              // Set<int>
final map  = {'a': 1, 'b': 2};       // Map<String, int>
final empty = <String>{};            // empty Set (bare {} is a Map)
```
An empty `{}` is a `Map`, not a `Set` — annotate the type to disambiguate.

**9. What is string interpolation?**
Embedding expressions in a string with `$` — `'$name'` for a simple identifier, `'${expr}'` for any expression. It calls `toString()` on the value. Prefer it over concatenation for readability and fewer allocations.

**10. What are positional vs named parameters?**
Positional params are matched by order; named params by name in `{}`. Named params are optional by default unless marked `required`. Positional optionals use `[]` with optional defaults.
```dart
void f(int a, [int b = 0]) {}          // b optional positional
void g({required int a, int b = 0}) {} // a required named, b optional
```

**11. What is an arrow function?**
`=>` is shorthand for a function body that's a single expression: `int sq(int x) => x * x;` is equivalent to `{ return x * x; }`. It can only wrap one expression, not statements.

**12. What is an enum in Dart?**
A fixed set of named constant values: `enum Status { active, paused, done }`. Each has `.name`, `.index`, and the type gets `.values`. Enums are commonly used in `switch` for exhaustive handling.

## 🟡 Intermediate

**13. What is flow analysis / type promotion in null safety?**
The compiler tracks control flow to *promote* a nullable variable to non-nullable within a scope where it can't be null.
```dart
void f(String? s) {
  if (s == null) return;
  print(s.length); // s promoted to String here
}
```
Promotion only works on **local variables and parameters**, never on non-final fields or getters (they could change between checks) — a top reason `!` shows up in real code.

**14. Why can't you promote a class field, and what are the workarounds?**
A field could be overridden by a getter or mutated by another isolate/callback between the null check and the use, so the compiler can't prove it stays non-null. Workarounds: copy to a local (`final x = field; if (x != null) x.use();`), make the field `final`, or use `?.`/`!`.

**15. What's wrong with over-using `!`?**
`!` silences the compiler but reintroduces the exact runtime null crashes null safety was designed to prevent. Each `!` is a claim "I know better than the type system"; if you're wrong it throws. Prefer `?.`, `??`, promotion, or fixing the type. Reserve `!` for cases you can genuinely prove non-null (e.g. right after a check the compiler can't follow).

**16. Explain spread, collection-if, and collection-for.**
They build collections declaratively inside a literal:
```dart
final base = [1, 2];
final all = [
  0,
  ...base,                 // spread
  ...?maybeNullList,       // null-aware spread
  if (isAdmin) 99,         // collection-if
  for (final n in base) n * 10, // collection-for
];
```
This avoids imperative `.add()` chains and keeps `const` collections possible.

**17. How do you make a collection immutable?**
Use `List.unmodifiable(source)` / `Map.unmodifiable` / `Set.unmodifiable`, or `const []` for compile-time constants, or `UnmodifiableListView` for a live read-only wrapper. `const` collections are deeply immutable; `unmodifiable` creates a fixed copy at runtime. Returning unmodifiable views from getters prevents callers from mutating your internal state.

**18. What is a closure?**
A function that captures and retains variables from its lexical scope, even after that scope has exited.
```dart
Function counter() {
  var count = 0;
  return () => ++count; // captures `count`
}
final c = counter();
c(); c(); // 1, 2 — state persists in the closure
```
Closures are how callbacks, `Future.then`, and event handlers carry state.

**19. What's the classic closure-in-a-loop pitfall?**
With `var`, all closures could share one variable; Dart avoids this because a `for`-loop variable is fresh per iteration.
```dart
final fns = [for (var i = 0; i < 3; i++) () => i];
print(fns.map((f) => f())); // (0, 1, 2) — each closure captured its own i
```
This differs from older JS `var` semantics — worth stating in an interview.

**20. What are higher-order functions? Give Dart examples.**
Functions that take or return functions. Dart's iterables lean on them: `map`, `where`, `fold`, `reduce`, `sort` (with a comparator), `expand`.
```dart
final evens = [1, 2, 3, 4].where((n) => n.isEven).toList(); // [2, 4]
```

**21. What are records (Dart 3)?**
Anonymous, immutable, fixed-size bundles of values with positional and/or named fields — a lightweight tuple that lets a function return multiple values without a class.
```dart
(int, String) pair() => (1, 'a');
({int x, int y}) point() => (x: 1, y: 2);
final r = pair();
print(r.$1);       // positional field access
print(point().x);  // named field access
```
Records have structural equality — two records with equal fields are `==`.

**22. What is destructuring / pattern matching?**
Patterns pull values out of records, lists, maps, and objects in one step.
```dart
final (a, b) = (1, 2);            // record destructure
final [first, _, third] = [1, 2, 3]; // list pattern, _ discards
final {'id': id} = json;         // map pattern
var Point(x: px, y: py) = point; // object pattern
```
Patterns work in variable declarations, `switch`, and `if-case`.

**23. What are enhanced enums?**
Since Dart 2.17, enums can have fields, constructors, methods, and implement interfaces.
```dart
enum Planet {
  earth(9.8), mars(3.7);
  const Planet(this.gravity);
  final double gravity;
  bool get isHeavy => gravity > 5;
}
```
This replaces the old "enum + extension" workaround for attaching data/behavior.

**24. Difference between `==` and `identical()`?**
`==` is value/logical equality and can be overridden. `identical(a, b)` checks reference identity — whether they're the exact same object in memory, and cannot be overridden. For two separate list literals with equal contents, `==` is false (default identity) but `identical` is also false; for canonicalized `const` values, both are true.

## 🔴 Advanced

**25. Explain `const` canonicalization.**
Identical `const` expressions are *canonicalized* to a single shared instance at compile time. So `const Point(1, 2)` used in ten places allocates one object, and `identical(const [1], const [1])` is `true`. In Flutter this is why `const` widgets are cheap: the framework can skip rebuilding a subtree when it receives the *same instance* it already has.

**26. Why does making Flutter widgets `const` improve performance?**
A `const` widget is a canonicalized, immutable instance. During rebuilds, when a parent hands its child the identical `const` object, `Element.updateChild` short-circuits — same `Widget` instance means no `updateShouldNotify`/`build` work for that subtree. It also reduces allocations. Hence the `prefer_const_constructors` lint.

**27. What are the requirements for an expression to be a compile-time constant?**
All inputs must themselves be constants: literals, other `const` values, `const` constructors invoked with `const` args, and a limited set of operations (arithmetic, string concat, `==` on primitives, ternaries, `identical`). No method calls on runtime objects, no `DateTime.now()`, no non-const constructor. A class needs `const` constructor with all-`final` fields to be constructible as `const`.

**28. What makes a class support a `const` constructor?**
Every instance field must be `final`, and the constructor must be declared `const` with no body that mutates state (initializer list only). Subclasses can add their own `const` constructors only if the superclass has one. This immutability is what allows canonicalization.

**29. How does `switch` exhaustiveness work with sealed classes?**
Marking a class `sealed` makes it abstract and restricts subclassing to the same library, so the compiler knows the *complete* set of subtypes. A `switch` over a sealed type is then checked for exhaustiveness — miss a case and you get a **compile-time** error, no `default` needed.
```dart
sealed class Shape {}
class Circle extends Shape {}
class Square extends Shape {}

double area(Shape s) => switch (s) {
  Circle() => 3.14,
  Square() => 4.0,
  // add a third subtype → this switch stops compiling until handled
};
```
This gives you compiler-verified handling of every state — huge for modeling API/UI states.

**30. What are guard clauses and `when` in patterns?**
A `when` clause adds a boolean condition to a pattern case; it must match *and* the guard must be true.
```dart
final result = switch (value) {
  int n when n > 0 => 'positive',
  int n when n < 0 => 'negative',
  int _ => 'zero',
  _ => 'not an int',
};
```
Unlike a nested `if`, a failed guard falls through to the next case rather than exiting the switch.

**31. Explain `if-case` and where it shines.**
`if (x case Pattern)` matches and destructures in one condition, binding variables scoped to the branch.
```dart
if (json case {'user': {'id': int id}}) {
  print(id); // id is int, only reachable when the shape matches
}
```
It's the cleanest way to validate-and-extract nested JSON without a cascade of null checks.

**32. What's the difference between `late final` and `final`?**
`final` must be initialized at declaration or in the constructor initializer list. `late final` defers that single assignment to any point before first read, still enforcing write-once. Useful for fields whose value depends on `this` or on async setup, or for lazy computation. Beware: `late final` without an initializer throws if read before assignment, and offers no compile-time guarantee of initialization.

**33. What are the runtime costs and hazards of `late`?**
Each read of a `late` variable compiles to a check "has this been initialized?", so there's a small per-access overhead and the risk of `LateInitializationError`. A `late` field with an initializer runs that initializer lazily on first access — meaning side effects fire at an unpredictable time. Don't use `late` to paper over a design where a value genuinely might be absent; use `?` instead.

**34. How does numeric behavior differ between the VM and web?**
On the native VM, `int` is a true 64-bit integer. On the web (compiled to JS), all numbers are IEEE-754 doubles, so `int` is emulated — large integers lose precision beyond 2^53, and `is int` / `is double` checks can behave unexpectedly (`1.0 is int` can be true on web). For cross-platform correctness with big IDs, use `BigInt` or strings.

**35. When should you actually use `dynamic`, and what's the safer alternative?**
Use `dynamic` only for genuine dynamism: decoded JSON before typing, reflection-like interop, or `noSuchMethod` forwarding. Everywhere else prefer `Object?` — you keep the "any value" flexibility but the compiler forces you to check the type (`is`) or cast before calling methods, catching mistakes at compile time instead of runtime `NoSuchMethodError`.

**36. How do you implement value equality correctly for a class?**
Override both `==` and `hashCode` consistently — equal objects must have equal hash codes, or `Set`/`Map` break.
```dart
class P {
  final int x, y;
  const P(this.x, this.y);
  @override
  bool operator ==(Object other) =>
      other is P && other.x == x && other.y == y;
  @override
  int get hashCode => Object.hash(x, y);
}
```
Use `Object.hash`/`Object.hashAll` for combining. In practice, prefer records or a codegen tool (freezed/equatable) to avoid mistakes.

**37. Records vs a data class — when to pick which?**
Records are ideal for *ephemeral, local* groupings: multiple return values, a temporary key, destructuring. They give free structural equality and less boilerplate. Choose a named class when the bundle has identity/behavior, is part of your domain model, needs documentation, named construction validation, or will be widely referenced — a record's positional fields (`$1`, `$2`) hurt readability across a codebase.

## ⚡ Rapid-fire (one-liners)

| Question | Answer |
|---|---|
| Default value of an uninitialized nullable field? | `null` |
| Is bare `{}` a Set or Map? | Map (empty) |
| Does `final` make the object immutable? | No — only the binding |
| Can you promote a non-final field? | No |
| Top type in Dart? | `Object?` |
| `identical(const [1], const [1])`? | `true` (canonicalized) |
| Operator you must override alongside `==`? | `hashCode` |
| Keyword for compile-time exhaustive switch? | `sealed` |
| Access second positional record field? | `.$2` |
| What throws if a `late` var is read too early? | `LateInitializationError` |
| Null-aware spread operator? | `...?` |
| `a ??= b` means? | assign `b` to `a` only if `a` is null |
| Is `int` a subtype of `num`? | Yes |
| Can enums have methods in modern Dart? | Yes (enhanced enums) |
| Difference `Object` vs `Object?`? | `Object?` includes `null` |

## Follow-up drills

1. Design an immutable `Money` value type with correct `==`/`hashCode`, a `const` constructor, and arithmetic that returns new instances — then justify each `const`/`final` choice.
2. Model a network request result as a `sealed` class hierarchy (`Loading`/`Success`/`Error`) and write an exhaustive `switch` UI mapper; show how adding a new state fails compilation until handled.
3. Refactor a JSON-parsing function riddled with `!` into safe `if-case` pattern matching and explain each null-safety improvement.
4. Debug: a widget rebuilds every frame despite "looking const" — walk through how a missing `const`, a non-`const` field, or a broken `==` could cause it.
5. Explain to a junior why type promotion works on a local copy of a field but not the field itself, with a concrete race/override example.
6. Optimize a hot list-building path using spread/collection-for and `const` sub-collections; measure what canonicalization saves.
