# Result / Either (Explicit Failure in the Type System)

> Instead of throwing for **expected** failures (which the compiler can't force callers to handle), return the outcome as a value: a **`Result<T>`** / **`Either<Failure, T>`** — usually a **sealed class** with `Success(value)` / `Failure(error)` variants — so failure is **part of the return type**, callers **must** handle both cases (exhaustive `switch`), and business logic stays free of `try/catch`. Exceptions still exist for bugs and at boundaries; `Result` is for the *modeled, recoverable* failures that flow through your domain.

## Introduction

This file covers functional error handling: representing success-or-failure as a typed value (`Result`/`Either`) via sealed classes, why it beats throwing for expected failures, and how to compose it (map/flatMap/fold) across layers. It's the type-system complement to the errors/exceptions distinction ([01_errors_vs_exceptions.md](01_errors_vs_exceptions.md)).

## Why this concept exists

Dart has **no checked exceptions**, so a thrown exception is invisible in a function's signature — callers forget to handle it and the app crashes. Encoding failure in the **return type** makes it impossible to ignore: the compiler forces you to handle both branches. This turns "hope everyone remembers the try/catch" into "the types guarantee it," and keeps happy-path logic clean.

## Real-world analogy

Throwing is like a **fire alarm** — it interrupts everything and someone up the chain must catch it (but nothing forces them to). A `Result` is like a **delivery that arrives either as the package or as a "delivery failed" slip in the same box** — you literally cannot open the box without seeing which one you got, so you always decide what to do. Failure is handed to you, not hurled past you.

## Problem Statement

Make a repository method's failures impossible to ignore: return `Result<User>` (or `Either<Failure, User>`) instead of throwing, map network/parse exceptions into typed `Failure`s at the boundary, and force the caller (bloc/UI) to handle success and each failure explicitly. You'll define a sealed `Result`, convert exceptions at the edge, and consume it exhaustively.

## Internal Working

```mermaid
flowchart TD
    Boundary[data source: may throw] --> Convert[catch at boundary -> Failure]
    Convert --> Result[Result<T> = Success(T) | Failure(err)]
    Result --> Consume[caller MUST handle both (exhaustive switch)]
    Consume --> Map[map / flatMap to transform success]
    Consume --> Fold[fold(onSuccess, onFailure) -> value/UI]
```

- **Sealed `Result`/`Either`**: a **sealed class** with two subtypes — `Success<T>(value)` and `Failure(error)` (or `Either<L,R>` with `Left`=failure, `Right`=success). Sealed → the compiler enforces **exhaustive** handling in `switch` (Dart 3 patterns). Use a package (`dartz`, `fpdart`, `result_dart`, `multiple_result`) or a tiny hand-rolled type.
- **Convert at the boundary**: the **data source** (which genuinely throws — network/DB/file) is wrapped so its exceptions become **typed `Failure`s** (`NetworkFailure`, `NotFoundFailure`, `ValidationFailure`) — a small `try/catch` at the edge, then `Result` flows inward. Domain/UI never `try/catch`.
- **Typed failures**: model failures as a **sealed `Failure` hierarchy** so callers branch and map to UX ([04_recovery_and_user_errors.md](04_recovery_and_user_errors.md)) — richer than a string.
- **Composition**: `map` (transform success), `flatMap`/`then` (chain fallible steps, short-circuiting on the first failure), `fold`/`when`/`switch` (collapse to a value/UI). Chains read linearly without nested try/catch.
- **When to use which**: **`Result`/`Either`** for **expected, recoverable** failures crossing layers (the domain's normal outcomes); **exceptions** for **bugs** and unforeseeable errors, caught at boundaries/globally. Don't wrap *everything* in `Result` (bugs should crash) and don't throw for *expected* failures.
- **Async**: return `Future<Result<T>>`; still awaited normally, but the value carries the outcome. No uncaught-exception surprises.
- **Tradeoff**: more ceremony/boilerplate vs guaranteed handling + clean happy path; teams pick a convention and apply it consistently.

## Memory Representation

A `Result` is a small object holding either a value or an error (one of two variants). Sealed hierarchies enable exhaustive pattern matching at compile time. No stack unwinding (unlike throwing).

## Compiler Behavior

**Sealed classes + `switch` give exhaustiveness checking** — omit a case and it won't compile. This is the whole point: the type system *forces* failure handling that thrown exceptions can't.

## Runtime Behavior

No exception propagation for modeled failures — control flows normally, carrying the outcome. Chains short-circuit on the first `Failure` (with `flatMap`). Faster/predictable vs throw/catch for expected paths.

## Flutter Engine Behavior

Not applicable; pure Dart pattern.

## Dart VM Behavior

No stack unwinding for `Result` failures (cheaper than throwing). Bugs still throw as `Error`s.

## Examples

```dart
// Minimal sealed Result (or use dartz/fpdart/result_dart)
sealed class Result<T> {
  const Result();
  R fold<R>(R Function(T) onOk, R Function(Failure) onErr) => switch (this) {
        Success<T>(:final value) => onOk(value),
        Failure(:final error) => onErr(error as Failure), // (typed in real code)
      };
}
class Success<T> extends Result<T> { final T value; const Success(this.value); }
class Failure<T> extends Result<T> { final Object error; const Failure(this.error); }

// Sealed failure hierarchy (branchable, UX-mappable)
sealed class AppFailure {}
class NetworkFailure extends AppFailure {}
class NotFoundFailure extends AppFailure { final String what; NotFoundFailure(this.what); }

// Repository: convert exceptions -> Result AT THE BOUNDARY
Future<Result<User>> getUser(String id) async {
  try {
    final res = await api.get('/users/$id');
    if (res.statusCode == 404) return Failure(NotFoundFailure('user $id'));
    return Success(User.fromJson(res.data));
  } on SocketException {
    return Failure(NetworkFailure());       // expected failure as a value
  }
}

// Caller MUST handle both — no forgotten try/catch, exhaustive switch
final result = await repo.getUser(id);
final ui = switch (result) {
  Success(:final value) => ProfileView(value),
  Failure(error: NetworkFailure()) => const OfflineBanner(),
  Failure(error: NotFoundFailure(:final what)) => NotFound(what),
  Failure() => const GenericError(),
};
```

## Diagrams

```mermaid
flowchart LR
    Throw[throw (invisible in signature)] -->|caller may forget| Crash[uncaught -> crash]
    Result[Result<T> in signature] -->|compiler forces| Handle[exhaustive handling]
    Handle --> Clean[clean happy path, no scattered try/catch]
```

## Common Mistakes

| Mistake | Why | Fix |
|---------|-----|-----|
| Throwing for expected failures | Callers forget to catch → crash | Return `Result`/`Either` |
| Wrapping bugs in `Result` too | Hides defects that should crash | `Result` for conditions; let bugs throw |
| `try/catch` in domain/UI | Leaks boundary concern inward | Convert to `Result` at the data boundary |
| String errors, not typed failures | Can't branch/map to UX | Sealed `Failure` hierarchy |
| Non-sealed result type | No exhaustiveness check | Sealed classes + `switch` |
| Ignoring the `Failure` branch | Silent wrong behavior | Handle both (compiler-enforced if sealed) |
| Over-abstracting (heavy FP) | Team friction | Keep it simple + consistent |

## Best Practices

- Return **`Result`/`Either`** (sealed) for **expected, recoverable** failures so the **compiler forces** handling; keep **exceptions for bugs** and boundaries.
- **Convert exceptions → typed `Failure`s at the data boundary**; keep domain/UI **free of `try/catch`**; model failures as a **sealed hierarchy** for branching/UX.
- **Compose** with `map`/`flatMap`/`fold` (short-circuit on failure) for linear, clean flows; consume with **exhaustive `switch`**.
- Pick **one convention** (package or tiny type) and apply consistently; don't over-engineer or wrap *everything*.

## Performance

`Result` avoids stack unwinding — cheaper/more predictable than throwing for expected paths (relevant in hot/loopy code). Slight allocation per result; negligible vs I/O. The bigger win is correctness (no forgotten handling), not raw speed.

## Advantages / Disadvantages

- **+** Failure explicit in the type; compiler-enforced handling; clean happy path; branchable typed failures; no uncaught surprises; cheaper than throwing.
- **−** Boilerplate/ceremony, a new convention to learn, easy to over-apply (wrapping bugs), composition operators have a learning curve.

## Interview Questions

1. **🟢 Why return `Result`/`Either` instead of throwing?** — Dart has no checked exceptions, so thrown failures are invisible and forgettable; encoding failure in the return type forces callers to handle it.
2. **🟢 What makes handling exhaustive?** — A sealed `Result`/`Failure` hierarchy + `switch` — the compiler errors if a case is missing.
3. **🟡 Where do you convert exceptions to `Result`?** — At the data boundary (where I/O genuinely throws); domain/UI then stay `try/catch`-free.
4. **🟡 When do you still use exceptions?** — For programming bugs and truly unforeseeable errors, caught at boundaries/globally — `Result` is for expected, recoverable failures.
5. **🟡 What do `map`/`flatMap`/`fold` do?** — Transform success, chain fallible steps (short-circuiting on failure), and collapse to a value/UI — enabling linear flows without nested try/catch.
6. **🔴 Why is `Result` cheaper than throwing for expected paths?** — No stack unwinding — control flows normally carrying the outcome.
7. **🔴 What's the downside, and how do you manage it?** — Boilerplate/ceremony; manage by choosing one library/convention, applying it consistently, and not wrapping bugs.

## Senior Engineer Tips

- Draw the line clearly: `Result` for expected domain failures, exceptions for bugs — wrapping everything in `Result` (or throwing everything) both defeat the purpose.
- Convert at the boundary once and keep the inner layers throw-free; a `try/catch` deep in a bloc is a sign the boundary leaked.
- Model failures as a sealed hierarchy from day one so the UI can branch (offline vs not-found vs generic); string errors force stringly-typed UX later.

## Architect Perspective

`Result`/`Either` is how clean architecture makes failure a first-class, type-checked concern: data sources convert exceptions to typed failures at the boundary, the domain composes `Result`s, and the UI exhaustively renders outcomes — no scattered `try/catch`, no forgotten handling. It pairs with the errors/exceptions distinction (bugs still throw) and feeds directly into user-facing error mapping and testable failure paths ([01_errors_vs_exceptions.md](01_errors_vs_exceptions.md), [04_recovery_and_user_errors.md](04_recovery_and_user_errors.md), [Module 40](../40%20Clean%20Architecture/README.md)).

## Summary

- Return sealed `Result`/`Either` for expected failures so the compiler forces exhaustive handling; keep exceptions for bugs/boundaries.
- Convert exceptions → typed `Failure`s at the data boundary; domain/UI stay `try/catch`-free; compose with map/flatMap/fold.
- Cheaper than throwing for expected paths; pick one convention; don't wrap bugs or over-engineer.

## Revision Notes

- Sealed `Result<T>` = `Success(value)` | `Failure(error)` (or `Either<L,R>`); `switch` → exhaustive (compiler-enforced).
- Convert exceptions → typed `Failure` at data boundary; domain/UI `try/catch`-free; sealed `Failure` hierarchy for UX branching.
- `map`/`flatMap`/`fold` (short-circuit on failure); `Future<Result<T>>` for async; `Result` for expected failures, exceptions for bugs; one convention (dartz/fpdart/result_dart/hand-rolled).

## Practice Questions

1. Why is a thrown exception "invisible" and a `Result` not?
2. Where should exception→`Result` conversion happen?
3. When should you still throw instead of returning `Result`?

## Coding Questions

1. Define a sealed `Result<T>` + sealed `Failure` hierarchy.
2. Convert a throwing repository method to return `Future<Result<User>>`.
3. Consume it with an exhaustive `switch` rendering per-failure UI.

## Mini Project

**Typed failures with `Result` (Flutter):** Refactor a repository to return `Future<Result<T>>` with a sealed `Failure` hierarchy (Network/NotFound/Validation/Generic), converting exceptions at the data boundary, keeping domain/UI `try/catch`-free, composing with `map`/`flatMap`, and consuming via exhaustive `switch` that renders per-failure UI. Acceptance: failures explicit in return types (compiler-enforced handling); exceptions converted at boundary; typed sealed failures branched in UI; no domain/UI `try/catch`; bugs still throw; one consistent convention.
