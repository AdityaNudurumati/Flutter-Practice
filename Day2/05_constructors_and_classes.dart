// =============================================================================
// Day 2 · Part 5 — Named / Factory Constructors, Abstract Classes, Interfaces
// Run: dart run Day2/05_constructors_and_classes.dart
// =============================================================================
//
// NAMED constructor   : an extra constructor with a name (ClassName.named).
//                       Always creates a fresh instance.
// FACTORY constructor : controls what gets returned — may return a CACHED
//                       instance, a SUBTYPE, or null-path logic. Has no
//                       initializer list and need not create a new object.
// ABSTRACT class      : can't be instantiated; defines a contract + shared code.
// INTERFACE           : every class is an implicit interface; `implements`
//                       forces you to reimplement EVERY member (no code reuse).
// =============================================================================

void main() {
  // 1. Default + NAMED constructors.
  final p1 = Point(1, 2);
  final origin = Point.origin(); // named constructor
  final p2 = Point.fromJson({'x': 3, 'y': 4}); // named, parses a map
  print('$p1  $origin  $p2');

  // 2. FACTORY returning a CACHED instance (flyweight / simple cache).
  final a = Color('red');
  final b = Color('red');
  print('same cached instance? ${identical(a, b)}'); // true — factory reused it

  // 3. FACTORY returning a SUBTYPE based on input (polymorphic creation).
  final dog = Animal.create('dog');
  final cat = Animal.create('cat');
  dog.speak(); // Woof
  cat.speak(); // Meow

  // 4. ABSTRACT class: can't do `Shape()`, but can hold subtypes & shared code.
  final shapes = <Shape>[Circle(2), Rectangle(3, 4)];
  for (final s in shapes) {
    print('${s.runtimeType}: area=${s.area.toStringAsFixed(2)}, ${s.describe()}');
  }

  // 5. INTERFACE via `implements`: Robot is NOT a Duck but satisfies its contract.
  greet(Robot());
}

// 1. Named constructors. `:` initializer list sets final fields before the body.
class Point {
  final int x, y;
  Point(this.x, this.y); // default
  Point.origin() : x = 0, y = 0; // named
  Point.fromJson(Map<String, int> j) : x = j['x']!, y = j['y']!; // named
  @override
  String toString() => '($x, $y)';
}

// 2. Factory with a static cache. The factory decides whether to build anew.
class Color {
  final String name;
  static final Map<String, Color> _cache = {};

  // Private generative constructor — only the factory can build new instances.
  Color._(this.name);

  factory Color(String name) {
    return _cache.putIfAbsent(name, () => Color._(name));
  }
}

// 3. Factory returning different SUBTYPES — common for parsing/config.
abstract class Animal {
  void speak();
  factory Animal.create(String kind) {
    switch (kind) {
      case 'dog':
        return Dog();
      case 'cat':
        return Cat();
      default:
        throw ArgumentError('unknown animal: $kind');
    }
  }
}

class Dog implements Animal {
  @override
  void speak() => print('Woof');
}

class Cat implements Animal {
  @override
  void speak() => print('Meow');
}

// 4. Abstract class: `area` is abstract (no body); `describe` is shared code.
abstract class Shape {
  double get area; // contract — subclasses MUST implement
  String describe() => 'A shape with area ${area.toStringAsFixed(2)}'; // shared
}

class Circle extends Shape {
  final double r;
  Circle(this.r);
  @override
  double get area => 3.14159 * r * r;
}

class Rectangle extends Shape {
  final double w, h;
  Rectangle(this.w, this.h);
  @override
  double get area => w * h;
}

// 5. Implicit interface: any class can be `implements`-ed. You inherit the
//    CONTRACT only — no implementation — so you must define every member.
class Duck {
  String sound() => 'Quack';
}

class Robot implements Duck {
  @override
  String sound() => 'Beep (pretending to quack)';
}

void greet(Duck d) => print(d.sound()); // accepts anything that IS-A Duck contract
