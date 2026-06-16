// =============================================================================
// Day 3 · Part 1 — Constructors (default, named, factory)
// Run: dart run Day3/01_constructors.dart
// =============================================================================
//
// DEFAULT  : the normal constructor; `this.x` shorthand assigns fields directly.
// NAMED    : an extra, descriptive constructor (User.guest()). Always builds new.
// FACTORY  : you control what's returned — parse, cache, or pick a subtype.
//            `fromJson` is the #1 factory you'll write in Flutter.
// =============================================================================

import 'dart:math';

void main() {
  // 1. Default constructor
  final u1 = User('Aditya');
  print('1. ${u1.name}'); // Aditya

  // 2. Named constructor — a preset / alternative way to build a User
  final guest = User.guest();
  print('2. ${guest.name}'); // Guest

  // 3. Factory constructor — build from a Map (decoded JSON)
  final json = {'name': 'Riya', 'age': 28};
  final u2 = User.fromJson(json);
  print('3. ${u2.name} (age ${u2.age})'); // Riya (age 28)

  // 4. Initializer list + assert (runs before the body, sets final fields)
  final p = Point(3, 4);
  print('4. ${p.x},${p.y} dist=${p.distanceToOrigin.toStringAsFixed(2)}');
}

class User {
  String name;
  int? age;

  // Default constructor with field-init shorthand.
  User(this.name, {this.age});

  // Named constructor: delegates nothing, just sets a preset value.
  User.guest() : name = 'Guest';

  // Factory: parses a map and returns a User. May validate / transform first.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(json['name'] as String, age: json['age'] as int?);
  }
}

// Initializer list `: ... ` runs BEFORE the constructor body — required for
// final fields. `assert` guards invalid input in debug mode.
class Point {
  final int x, y;
  Point(this.x, this.y) : assert(x >= 0 && y >= 0, 'coords must be >= 0');
  double get distanceToOrigin => sqrt(x * x + y * y);
}
