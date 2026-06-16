# Day 3 — OOP, Generics & Enums (Flutter Interview Prep)

Goal: lock down the OOP + generics + enum concepts Flutter leans on hardest, then
revise everything in one capstone project. Everything here is written to be **run
and modified**, not just read. Type it out, break it, fix it.

## How to run any file
```bash
dart run Day3/01_constructors.dart
```
(No Flutter needed — plain Dart. Install Dart SDK or use the one bundled with Flutter.)

## Files

| # | Topic | File |
|---|-------|------|
| 1 | Constructors: default, named, factory (`fromJson`), initializer list | [01_constructors.dart](01_constructors.dart) |
| 2 | Encapsulation: private `_fields`, getters, setters, validation | [02_encapsulation.dart](02_encapsulation.dart) |
| 3 | Abstract classes: contract + shared code (`Animal`/`Dog`) | [03_abstract_classes.dart](03_abstract_classes.dart) |
| 4 | Interfaces: `implements`, multiple interfaces, vs `extends` | [04_interfaces.dart](04_interfaces.dart) |
| 5 | Mixins: `with`, why not `extends`, multiple mixins (`Logger`) | [05_mixins.dart](05_mixins.dart) |
| 6 | Extension methods on String / int / List | [06_extensions.dart](06_extensions.dart) |
| 7 | **Generics** (most important): `Box<T>`, `<K,V>`, bounded, generic fns | [07_generics.dart](07_generics.dart) |
| 8 | Exception handling: `try/catch/on/finally`, custom, `rethrow` | [08_exceptions.dart](08_exceptions.dart) |
| 9 | Enums: basic + enhanced (fields, const ctor, methods) | [09_enums.dart](09_enums.dart) |
| 10 | **Practice project**: Student Management System (revises all of the above) | [10_student_management.dart](10_student_management.dart) |

## Practice project — Student Management System
`Student` (id, name, marks) with: add, remove, search, find topper, average marks,
group by grade. Built on a generic `Repository<T>`, uses `List`, `Map`, an enhanced
`Grade` enum, encapsulation, and exceptions. See the bottom of
[notes.txt](notes.txt) for stretch goals.

## Interview checklist for today
After Day 3 you should be able to answer, out loud, without notes:
- [ ] Default vs named vs factory constructor; why `fromJson` is a factory.
- [ ] How is privacy done in Dart? Getter vs setter vs public field.
- [ ] Abstract class vs interface; `extends` vs `implements`.
- [ ] What problem do mixins solve? Why `with` and not `extends`?
- [ ] What is an extension method? Are extensions polymorphic? (No.)
- [ ] Why generics over `dynamic`? `<T>` vs `<K,V>` vs `<T extends X>`. Reified?
- [ ] Exception vs Error; `rethrow` vs `throw e`; what `finally` guarantees.
- [ ] Why an enum over constants? What is an enhanced enum?

> Tip: don't copy-paste the solutions. Open a blank file, attempt the Student
> Management System from memory, then diff against this one. The struggle is the learning.
