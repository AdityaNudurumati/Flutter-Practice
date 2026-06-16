// =============================================================================
// Day 3 · Part 7 — Generics (MOST IMPORTANT)
// Run: dart run Day3/07_generics.dart
// =============================================================================
//
// Generics = type PARAMETERS. One class/function works over many types while
// keeping COMPILE-TIME type safety. Flutter uses them everywhere: List<T>,
// Future<T>, Stream<T>, State<T>, ValueNotifier<T>, etc.
//   <T>     -> one type parameter
//   <K, V>  -> two (e.g. Map<K, V>)
//   <T extends X> -> bounded (T must be an X)
// =============================================================================

void main() {
  // 1. Generic COLLECTIONS: the <...> locks the element/value type.
  List<String> names = ['Aditya', 'Riya'];
  Map<String, int> ages = {'Aditya': 28};
  // names.add(1); // COMPILE ERROR — type-safe thanks to the generic argument.
  print('1. $names  $ages');

  // 2. Generic CLASS — a type-safe box.
  Box<int> intBox = Box(100);
  Box<String> strBox = Box('hello');
  print('2. ${intBox.value}  ${strBox.value}'); // 100  hello

  // 3. Two type params (like Map<K, V>).
  final entry = Pair<String, int>('age', 28);
  print('3. ${entry.key} = ${entry.value}');

  // 4. Generic FUNCTION — keeps the caller's type (inferred, no <...> needed).
  print('4. ${firstOrNull([1, 2, 3])}'); // 1     (T = int)
  print('4. ${firstOrNull<String>([])}'); // null  (T = String)

  // 5. Bounded generic — T must be a num so arithmetic is allowed.
  print('5. sum = ${sumOf([1, 2, 3, 4])}'); // 10
}

// 2. Generic class. T is fixed per instance: Box<int>, Box<String>, ...
class Box<T> {
  T value;
  Box(this.value);

  // A generic METHOD with its own type param R, independent of T.
  R map<R>(R Function(T) f) => f(value);
}

// 3. Two type parameters.
class Pair<K, V> {
  final K key;
  final V value;
  Pair(this.key, this.value);
}

// 4. Generic function: <T> after the name; returns the same type it's given.
T? firstOrNull<T>(List<T> items) => items.isEmpty ? null : items.first;

// 5. Bounded generic: `extends num` lets us use `+` on T.
T sumOf<T extends num>(List<T> values) {
  num total = 0;
  for (final v in values) {
    total += v;
  }
  return total as T;
}
