// =============================================================================
// Day 3 · Part 6 — Extension Methods
// Run: dart run Day3/06_extensions.dart
// =============================================================================
//
// Extensions add methods/getters/operators to a type you DON'T own (String,
// int, List, a package's class) WITHOUT subclassing or wrapping it.
// Resolved STATICALLY on the static type (not virtual / overridable).
// =============================================================================

void main() {
  // On String
  print('aditya'.capitalize()); // Aditya
  print('hello world'.toTitleCase()); // Hello World
  print('a@b.com'.isValidEmail); // true

  // On int
  print(3.isEven ? 'even' : 'odd'); // odd
  print(5.squared); // 25
  print(3.repeat('ab')); // ababab

  // On List<T> (generic extension)
  print([10, 20, 30].secondOrNull); // 20
  print(<int>[].secondOrNull); // null
}

extension StringExtension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  String toTitleCase() => split(' ').map((w) => w.capitalize()).join(' ');

  bool get isValidEmail =>
      RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(this);
}

extension IntExtension on int {
  int get squared => this * this;
  String repeat(String s) => s * this;
}

// Generic extension: works for List of any element type T.
extension ListExtension<T> on List<T> {
  T? get secondOrNull => length >= 2 ? this[1] : null;
}
