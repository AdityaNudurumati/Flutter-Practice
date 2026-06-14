// =============================================================================
// Day 1 · Part 3 — Collections: List, Map, Set
// Run: dart run Day1/03_collections.dart
// =============================================================================
//
// Interview framing of the iterable methods (KNOW THESE COLD):
//   map()    -> transform each element, returns a NEW iterable (same length)
//   where()  -> filter, returns elements matching a predicate
//   fold()   -> reduce to a single value WITH an initial seed (type can change)
//   reduce() -> like fold but no seed; seed is the first element (THROWS if empty)
//   forEach()-> side effects only, returns nothing
//   any()/every() -> boolean checks
//
//   Note: map/where are LAZY (return Iterable). Call .toList() to materialize.
// =============================================================================

void main() {
  lists();
  sets();
  maps();
  transformations();
}

// -----------------------------------------------------------------------------
// List — ordered, indexable, allows duplicates
// -----------------------------------------------------------------------------
void lists() {
  print('\n=== LIST ===');

  final numbers = <int>[1, 2, 3, 4, 5];

  // Create / add / insert / remove
  numbers.add(6);
  numbers.insert(0, 0); // [0,1,2,3,4,5,6]
  numbers.remove(3); // removes the VALUE 3 -> [0,1,2,4,5,6]
  numbers.removeAt(0); // removes INDEX 0 -> [1,2,4,5,6]

  // Access
  print('first=${numbers.first} last=${numbers.last} length=${numbers.length}');
  print('contains 4? ${numbers.contains(4)}');
  print('indexOf 5 = ${numbers.indexOf(5)}');

  // Iterate
  var running = 0;
  for (final n in numbers) {
    running += n; // for-in: cleanest when you only need the element
  }
  for (var i = 0; i < numbers.length; i++) {
    // classic for: use when you need the index i
  }
  print('sum via for-in = $running');

  // Spread + collection-if/for (very common in Flutter widget lists)
  final more = [0, ...numbers, if (numbers.length > 3) 99, for (var n in [7, 8]) n * 10];
  print('built with spread/if/for: $more');

  // Sorting (in place)
  final words = ['banana', 'apple', 'cherry'];
  words.sort(); // alphabetical
  print('sorted: $words');
  words.sort((a, b) => b.length.compareTo(a.length)); // by length desc
  print('by length desc: $words');
}

// -----------------------------------------------------------------------------
// Set — unordered, UNIQUE elements, fast membership test
// -----------------------------------------------------------------------------
void sets() {
  print('\n=== SET ===');

  final a = {1, 2, 3, 4};
  final b = {3, 4, 5, 6};

  print('a = $a');
  print('union           = ${a.union(b)}'); // {1,2,3,4,5,6}
  print('intersection    = ${a.intersection(b)}'); // {3,4}
  print('difference a-b  = ${a.difference(b)}'); // {1,2}
  print('contains 3?     = ${a.contains(3)}'); // O(1) lookup

  // Dedupe a list quickly: list -> set -> list
  final dupes = [1, 1, 2, 3, 3, 3, 4];
  final unique = dupes.toSet().toList();
  print('deduped $dupes -> $unique');
}

// -----------------------------------------------------------------------------
// Map — key/value pairs, unique keys
// -----------------------------------------------------------------------------
void maps() {
  print('\n=== MAP ===');

  final scores = <String, int>{'alice': 90, 'bob': 75};

  // Add / update / read
  scores['carol'] = 85;
  scores['alice'] = 95; // overwrites
  print('alice = ${scores['alice']}'); // 95
  print('missing key = ${scores['dan']}'); // null (value type is int? on lookup)

  // Safe read with default
  final danScore = scores['dan'] ?? 0;
  print('danScore (default) = $danScore');

  // putIfAbsent — compute & insert only if key missing
  scores.putIfAbsent('dan', () => 50);
  print('after putIfAbsent: $scores');

  // update — modify existing, with ifAbsent fallback
  scores.update('bob', (v) => v + 5, ifAbsent: () => 0);
  print("bob after update: ${scores['bob']}"); // 80

  // Iterate
  scores.forEach((key, value) => print('  $key -> $value'));
  print('keys   = ${scores.keys.toList()}');
  print('values = ${scores.values.toList()}');
  print('entries: ${scores.entries.map((e) => '${e.key}=${e.value}').join(', ')}');
}

// -----------------------------------------------------------------------------
// map / where / fold / reduce in anger
// -----------------------------------------------------------------------------
void transformations() {
  print('\n=== TRANSFORMATIONS ===');

  final nums = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

  // map: square each
  final squares = nums.map((n) => n * n).toList();
  print('squares = $squares');

  // where: keep evens
  final evens = nums.where((n) => n.isEven).toList();
  print('evens = $evens');

  // Chained: squares of evens
  final evenSquares = nums.where((n) => n.isEven).map((n) => n * n).toList();
  print('even squares = $evenSquares');

  // fold: sum with a seed of 0 (result type controlled by the seed)
  final sum = nums.fold<int>(0, (acc, n) => acc + n);
  print('sum (fold) = $sum'); // 55

  // fold changing the type: build a comma string from ints
  final joined = nums.fold<String>('', (acc, n) => acc.isEmpty ? '$n' : '$acc,$n');
  print('joined (fold) = $joined');

  // reduce: product (no seed — uses first element; would THROW on empty list)
  final product = nums.reduce((acc, n) => acc * n);
  print('product (reduce) = $product');

  // any / every
  print('any > 9?  ${nums.any((n) => n > 9)}'); // true
  print('every > 0? ${nums.every((n) => n > 0)}'); // true

  // expand: flatten nested
  final nested = [[1, 2], [3, 4], [5]];
  final flat = nested.expand((inner) => inner).toList();
  print('flattened = $flat'); // [1,2,3,4,5]
}
