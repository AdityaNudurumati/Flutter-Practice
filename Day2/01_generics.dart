// =============================================================================
// Day 2 · Part 1 — Generics
// Run: dart run Day2/01_generics.dart
// =============================================================================
//
// Goal: understand WHY generics exist (type safety + reuse without `dynamic`),
// then write generic functions, generic classes, and bounded type parameters.
// Generics are everywhere in Flutter: List<T>, Future<T>, Stream<T>, Widget
// builders, State<T>. Try writing each from memory FIRST.
// =============================================================================

void main() {
  // 1. Built-in generics: the <...> locks the element/value type at compile time.
  List<int> nums = [1, 2, 3];
  Map<String, int> ages = {'Aditya': 28, 'Sam': 30};
  Set<String> tags = {'dart', 'flutter'};
  // nums.add('hi'); // COMPILE ERROR — type safety from the generic argument.
  print('$nums  $ages  $tags');

  // 2. A generic FUNCTION: <T> makes it work for any type, keeping the type.
  print(firstOrNull<int>([10, 20])); // 10
  print(firstOrNull<String>([])); // null
  // Type inference: you usually don't need to write <int> explicitly.
  print(firstOrNull([1.5, 2.5])); // 1.5 (T inferred as double)

  // 3. A generic CLASS: a type-safe box.
  final intBox = Box<int>(42);
  final strBox = Box<String>('hello');
  print('${intBox.value}  ${strBox.value}');
  print(intBox.map((v) => v * 2).value); // 84 — map returns a Box<int>

  // 4. Multiple type params (like Map<K, V>).
  final pair = Pair<String, int>('age', 28);
  print('${pair.first} = ${pair.second}');

  // 5. BOUNDED type param: T must be a num (so + and compareTo are allowed).
  print(sumOf<int>([1, 2, 3])); // 6
  print(sumOf<double>([1.5, 2.5])); // 4.0
  // sumOf<String>(['a']); // COMPILE ERROR — String is not a num.

  // 6. Generic method on a class using a DIFFERENT type param (R).
  print(Box<int>(5).fold<String>('n=', (acc, v) => '$acc$v')); // n=5
}

// 2. Generic function. <T> is declared after the name; T is the element type.
T? firstOrNull<T>(List<T> items) {
  if (items.isEmpty) return null;
  return items.first;
}

// 3 & 6. Generic class. T is fixed per-instance when you write Box<int>(...).
class Box<T> {
  final T value;
  Box(this.value);

  // Transform the contents, preserving the box. Returns a new Box<T>.
  Box<T> map(T Function(T) f) => Box<T>(f(value));

  // A generic METHOD introducing its own type param R, independent of T.
  R fold<R>(R seed, R Function(R acc, T value) combine) => combine(seed, value);
}

// 4. Two type parameters — exactly how Map<K, V> is declared.
class Pair<A, B> {
  final A first;
  final B second;
  Pair(this.first, this.second);
}

// 5. Bounded generic: `extends num` constrains T so numeric ops are legal.
T sumOf<T extends num>(List<T> values) {
  num total = 0;
  for (final v in values) {
    total += v;
  }
  return total as T;
}
