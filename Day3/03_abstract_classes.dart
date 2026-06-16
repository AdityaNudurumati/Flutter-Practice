// =============================================================================
// Day 3 · Part 3 — Abstract Classes
// Run: dart run Day3/03_abstract_classes.dart
// =============================================================================
//
// An ABSTRACT class can't be instantiated. It defines a CONTRACT (methods with
// no body) and may also provide SHARED concrete code. Subclasses `extend` it
// and must implement the abstract members.
// =============================================================================

void main() {
  // final a = Animal();   // COMPILE ERROR — can't instantiate an abstract class.

  final animals = <Animal>[Dog(), Cat(), Cow()];
  for (final a in animals) {
    a.describe(); // shared concrete method calls the abstract makeSound()
  }
}

abstract class Animal {
  // Abstract method: no body. Every concrete subclass MUST implement it.
  void makeSound();

  // Concrete SHARED method available to all subclasses (template-method style):
  // it relies on the abstract makeSound() that subclasses fill in.
  void describe() {
    print('$runtimeType says: ');
    makeSound();
  }
}

class Dog extends Animal {
  @override
  void makeSound() => print('Bark');
}

class Cat extends Animal {
  @override
  void makeSound() => print('Meow');
}

class Cow extends Animal {
  @override
  void makeSound() => print('Moo');
}
