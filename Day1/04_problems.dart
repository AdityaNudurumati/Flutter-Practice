// =============================================================================
// Day 1 · Part 4 — 3 Dart-only Problems (from scratch)
// Run: dart run Day1/04_problems.dart
// =============================================================================
//
// DO THIS FIRST: open a blank file and try each problem from memory.
// Then come back here and compare. Each problem shows TWO approaches where it
// helps — the "manual loop" version (shows you understand the mechanics) and
// the "idiomatic" version (shows you know the std lib). Interviewers like both.
// =============================================================================

void main() {
  print('--- Problem 1: reverse a string ---');
  print(reverseManual('hello')); // olleh
  print(reverseIdiomatic('Flutter')); // rettulF
  print(reverseManual('')); // (empty)

  print('\n--- Problem 2: find duplicates in a list ---');
  print(findDuplicates([1, 2, 2, 3, 4, 4, 4, 5])); // [2, 4]
  print(findDuplicates(['a', 'b', 'a', 'c', 'c'])); // [a, c]
  print(findDuplicates([1, 2, 3])); // []

  print('\n--- Problem 3: group items by a key ---');
  final people = [
    Person('Alice', 'Mumbai'),
    Person('Bob', 'Delhi'),
    Person('Carol', 'Mumbai'),
    Person('Dan', 'Delhi'),
    Person('Eve', 'Pune'),
  ];
  final byCity = groupBy(people, (p) => p.city);
  byCity.forEach((city, group) {
    print('$city: ${group.map((p) => p.name).toList()}');
  });
}

// -----------------------------------------------------------------------------
// Problem 1 — Reverse a string
// -----------------------------------------------------------------------------
// Key insight: Dart strings are immutable and not directly indexable as a list,
// so convert to a list of chars (or code units), reverse, rejoin.

// (a) Manual: build the result back-to-front. Shows you understand indexing.
String reverseManual(String input) {
  var result = '';
  for (var i = input.length - 1; i >= 0; i--) {
    result += input[i];
  }
  return result;
}

// (b) Idiomatic: split into chars -> reversed iterable -> join.
String reverseIdiomatic(String input) {
  return input.split('').reversed.join();
  // For correctness with emoji/combined chars you'd use input.runes, but
  // .split('') is the expected interview answer for ASCII.
}

// -----------------------------------------------------------------------------
// Problem 2 — Find duplicates in a list
// -----------------------------------------------------------------------------
// Strategy: track what we've SEEN; the first time we see something twice,
// record it as a duplicate (using a Set to avoid reporting it 3+ times).
// Time: O(n). Space: O(n). Beats the naive O(n^2) double-loop.
List<T> findDuplicates<T>(List<T> items) {
  final seen = <T>{};
  final duplicates = <T>{}; // Set keeps each dup once; order preserved by Set
  for (final item in items) {
    if (!seen.add(item)) {
      // .add returns false if item was ALREADY present -> it's a duplicate
      duplicates.add(item);
    }
  }
  return duplicates.toList();
}

// -----------------------------------------------------------------------------
// Problem 3 — Group items by a key into a Map<K, List<V>>
// -----------------------------------------------------------------------------
// This is the pattern behind package:collection's groupBy. Implementing it
// yourself demonstrates you understand putIfAbsent. Generic over item & key type.
Map<K, List<T>> groupBy<T, K>(Iterable<T> items, K Function(T) keyOf) {
  final result = <K, List<T>>{};
  for (final item in items) {
    final key = keyOf(item);
    // Create the bucket list if this key is new, then append.
    result.putIfAbsent(key, () => <T>[]).add(item);
  }
  return result;
}

class Person {
  final String name;
  final String city;
  Person(this.name, this.city);
}
