// =============================================================================
// Day 2 · Part 4 — Mixins & Extensions
// Run: dart run Day2/04_mixins_extensions.dart
// =============================================================================
//
// MIXIN: reuse a bundle of methods/fields across UNRELATED classes without
//   inheritance. Used with `with`. Flutter: SingleTickerProviderStateMixin,
//   ChangeNotifier-style behavior, etc.
// EXTENSION: add methods to a type you DON'T own (String, int, List, a 3rd-party
//   class) without subclassing or wrapping it.
// =============================================================================

void main() {
  // --- MIXINS ----------------------------------------------------------------
  final bird = Bird();
  bird.fly(); // from Flyable mixin — Bird "HAS-A" flying ability, not "IS-A" Flyable

  final duck = Duck();
  duck.swim(); // from Swimmer mixin
  duck.fly(); // from Flyable mixin
  duck.quack(); // its own method

  final fish = Fish();
  fish.swim(); // same Swimmer mixin reused by an unrelated class
  // fish.fly(); // not available — Fish doesn't mix in Flyable.

  // `on` clause: a mixin can require its host to be a subtype, unlocking that
  // type's members inside the mixin.
  Plane().fly();
  Plane().describe(); // uses name from Vehicle via the `on Vehicle` constraint

  // --- EXTENSIONS ------------------------------------------------------------
  print('hello world'.capitalize()); // Hello world
  print('the lord of the rings'.toTitleCase()); // The Lord Of The Rings
  print('a@b.com'.isValidEmail); // true   (extension GETTER)
  print('nope'.isValidEmail); // false
  print('racecar'.isPalindrome); // true (extension GETTER)
  print(5.times('hi')); // [hi, hi, hi, hi, hi]
  print(42.isEven ? 'even' : 'odd'); // even (built-in, for contrast)
  print([1, 2, 3, 4].secondOrNull); // 2 — extension on List<T> (generic)
}

// ---- Mixins ----------------------------------------------------------------
// Declared with `mixin`. Cannot be instantiated; only mixed in with `with`.
mixin Swimmer {
  void swim() => print('$runtimeType is swimming');
}

mixin Flyable {
  void fly() => print('$runtimeType is flying');
}

// WHY `with` and NOT `extends`?
//   - `extends` = an IS-A relationship + single inheritance. A Bird can only
//     extend ONE class, so if you used `extends Flyable` you'd "spend" your one
//     parent slot on it and couldn't also extend, say, Animal.
//   - Flying isn't an identity — it's a capability you want to SHARE across
//     unrelated types (Bird, Plane, Insect). `with` mixes that capability in
//     WITHOUT claiming Bird IS-A Flyable and without using up inheritance.
//   - You can mix in MANY mixins (`with A, B, C`) but extend only one class.
class Bird with Flyable {}

// A class can mix in MULTIPLE mixins. Conflicts resolve by linearization
// (the LAST mixin in the `with` list wins).
class Duck with Swimmer, Flyable {
  void quack() => print('Quack!');
}

class Fish with Swimmer {}

// `on` constrains where a mixin can be used and lets it call the host's members.
class Vehicle {
  String get name => 'Vehicle';
}

mixin Flyer2 on Vehicle {
  void fly() => print('$name is flying'); // can use `name` because of `on Vehicle`
  void describe() => print('I am a $name that flies');
}

class Plane extends Vehicle with Flyer2 {
  @override
  String get name => 'Plane';
}

// ---- Extensions ------------------------------------------------------------
// Add methods/getters to String without modifying or subclassing it.
extension StringX on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  // Capitalize the first letter of EVERY word ("the lord" -> "The Lord").
  String toTitleCase() => split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  // A getter that validates an email with a simple regex. Getters take no
  // parentheses at the call site: `email.isValidEmail`.
  bool get isValidEmail =>
      RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(this);

  bool get isPalindrome {
    final s = toLowerCase().replaceAll(' ', '');
    return s == s.split('').reversed.join();
  }
}

extension IntX on int {
  List<String> times(String s) => List.filled(this, s);
}

// Extensions can be GENERIC too.
extension ListX<T> on List<T> {
  T? get secondOrNull => length >= 2 ? this[1] : null;
}
