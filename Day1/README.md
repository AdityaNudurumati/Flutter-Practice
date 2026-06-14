# Day 1 — Dart Fundamentals (Flutter Interview Prep)

Goal: Be fluent in core Dart so Flutter concepts later feel obvious. Everything here is
written to be **run and modified**, not just read. Type it out, break it, fix it.

## How to run any file
```bash
dart run Day1/01_variables_types_null_safety.dart
```
(No Flutter needed — plain Dart. Install Dart SDK or use the one bundled with Flutter.)

## Schedule & files

### Morning · 60 min
| Time   | Topic | File |
|--------|-------|------|
| 20 min | Variables, types, null safety (`?`, `!`, `late`), `var`/`final`/`const` | [01_variables_types_null_safety.dart](01_variables_types_null_safety.dart) |
| 20 min | All data types, nullable vs non-nullable, type inference | (same file) |
| 20 min | Functions: named/optional params, arrow fns, typedef — 10 small functions | [02_functions.dart](02_functions.dart) |

### Afternoon · 60 min
| Time   | Topic | File |
|--------|-------|------|
| 30 min | Collections: List, Map, Set — create, iterate, `where`/`map`/`fold` | [03_collections.dart](03_collections.dart) |
| 30 min | 3 Dart-only problems: reverse string, find duplicates, group by key | [04_problems.dart](04_problems.dart) |

### Evening · 60 min
| Time   | Topic | File |
|--------|-------|------|
| 60 min | OOP: `BankAccount` + `SavingsAccount` subclass with interest | [05_oop_bank_account.dart](05_oop_bank_account.dart) |

## Interview checklist for today
After Day 1 you should be able to answer, out loud, without notes:
- [ ] Difference between `final` and `const` (compile-time vs runtime).
- [ ] What does `?`, `!`, and `late` each actually do? When does `!` throw?
- [ ] Difference between `var`, `dynamic`, and `Object?`.
- [ ] When is a named param required vs optional? How do default values work?
- [ ] `List` vs `Set` vs `Map` — when to reach for each.
- [ ] Difference between `map`, `where`, `fold`, `reduce`.
- [ ] What is a getter, and why use one over a public field?
- [ ] How does `super` work in a constructor? What is constructor initializer list order?

> Tip: don't copy-paste the solutions. Open a blank file, attempt from memory, then diff
> against these. The struggle is the learning.
