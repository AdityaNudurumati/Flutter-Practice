// =============================================================================
// Day 3 · Part 4 — Interfaces (implements)
// Run: dart run Day3/04_interfaces.dart
// =============================================================================
//
// Dart has NO `interface` keyword. EVERY class is an implicit interface.
// `class A implements B` adopts B's CONTRACT only — you inherit NO code and
// must reimplement EVERY member. A class can implement MANY interfaces.
//
// extends vs implements:
//   extends    -> inherit the implementation (one parent, super available).
//   implements -> inherit only the contract (reimplement everything).
// =============================================================================

void main() {
  // Both satisfy the Animal contract, but share none of its code.
  final List<Animal> animals = [Dog(), Robot()];
  for (final a in animals) {
    a.sound();
  }

  // Implementing MULTIPLE interfaces: Duck must provide every member of both.
  final duck = Duck();
  duck.sound(); // from Animal contract
  duck.swim(); // from Swimmer contract
}

// These act as interfaces (contracts). Bodies here are ignored by implementers.
class Animal {
  void sound() {}
}

class Swimmer {
  void swim() {}
}

// Dog adopts the Animal CONTRACT (no code inherited) — must define sound().
class Dog implements Animal {
  @override
  void sound() => print('Bark');
}

// A Robot is NOT an Animal, but can satisfy the same contract.
class Robot implements Animal {
  @override
  void sound() => print('Beep');
}

// Implement TWO interfaces at once — must implement members of BOTH.
class Duck implements Animal, Swimmer {
  @override
  void sound() => print('Quack');
  @override
  void swim() => print('Duck paddles');
}
