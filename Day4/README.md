# Day 4 — Async Programming (Flutter Interview Prep)

Goal: master the topics Flutter leans on hardest — `Future`, `async`/`await`, and
`Stream` — because APIs, Firebase, databases, and file I/O are all async. Then
revise **Days 1–4** in one capstone. Everything here is written to be **run and
modified**, not just read. Type it out, break it, fix it.

## How to run any file
```bash
dart run Day4/01_futures.dart
```
(No Flutter needed — plain Dart. Install Dart SDK or use the one bundled with Flutter.)

## Files

| # | Topic | File |
|---|-------|------|
| 1 | Futures, `async`/`await`, `Future.delayed`, sequential awaits | [01_futures.dart](01_futures.dart) |
| 2 | `Future.wait` (parallel) + error handling (`try/catch`, `.catchError`, `.timeout`) | [02_future_wait_and_errors.dart](02_future_wait_and_errors.dart) |
| 3 | Streams: `async*`/`yield`, `listen`, `map`/`where`/`take`, `await for`, broadcast | [03_streams.dart](03_streams.dart) |
| 4 | `StreamController`: single/broadcast, `sink`, mini BLoC/Cubit counter | [04_stream_controller.dart](04_stream_controller.dart) |
| 5 | **Capstone 1**: Mini Store — covers every concept from Days 1–4 | [05_capstone_store.dart](05_capstone_store.dart) |
| 6 | **Capstone 2**: Personal Expense Tracker (console app, menu-driven) | [06_capstone_expense_tracker.dart](06_capstone_expense_tracker.dart) |

## Capstone 2 — Personal Expense Tracker
A menu-driven console expense manager (Add / View / Delete / Search / Total /
Category-wise / Monthly / Exit) that exercises almost every Day 1–4 concept:
enums, models with named + factory constructors, an abstract `Entity` base
(inheritance) + `RecurringExpense` subclass, an `ExpenseRepository` interface,
`LoggerMixin`, generic `Storage<T>` + `firstOrNullWhere<T>`, a `toCurrency()`
extension, an `ExpenseFilter` typedef, `where`/`map`/`fold`/`any`/`every`/
`firstWhere`/`sort`, getters/setters with validation, custom exceptions, and
`async`/`Future`.

```bash
dart run Day4/06_capstone_expense_tracker.dart        # scripted demo (all 8 actions)
dart run Day4/06_capstone_expense_tracker.dart -i     # interactive stdin menu
```

## Capstone 1 — Mini Store
A single runnable program that exercises everything from Days 1–4: data types &
null safety, functions (closures/typedef/higher-order), collections + functional
methods, encapsulation, abstract classes, interfaces, inheritance, mixins,
polymorphism, all constructor kinds (incl. `factory fromJson`), generics, enhanced
enums, extensions, exception handling, `async`/`await`, `Future.wait`, and a live
`StreamController` status feed. See the concept→location map and stretch goals at
the bottom of [notes.txt](notes.txt).

## Interview checklist for today
After Day 4 you should be able to answer, out loud, without notes:
- [ ] Does `async`/`await` use threads? Concurrency vs parallelism.
- [ ] The three states of a `Future`; what an `async` function returns.
- [ ] Sequential awaits vs `Future.wait` (parallel) — time difference.
- [ ] How to handle async errors: `try/catch`, `.catchError`, `.whenComplete`, `.timeout`.
- [ ] What happens if one future in `Future.wait` fails?
- [ ] `Future` vs `Stream`; single-subscription vs broadcast.
- [ ] `await for` vs `.listen()`; which stream methods are lazy.
- [ ] What a `StreamController` is, `sink` vs `stream`, why you must `close()`.
- [ ] How `StreamController` powers BLoC/Cubit.

> Tip: don't copy-paste the solutions. Open a blank file, rebuild the capstone from
> memory, then diff against this one. The struggle is the learning.
>
> Per the plan: after this, spend 2–3 more days **solely** on Futures, async/await,
> and Streams — they show up everywhere in Flutter, Firebase, Riverpod, and Bloc.
