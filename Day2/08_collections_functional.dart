// =============================================================================
// Day 2 · Part 8 — Collections Deep Dive + Functional Programming
// Run: dart run Day2/08_collections_functional.dart
// =============================================================================
//
// Builds on Day 1's collections. Here we go deeper: the lazy Iterable pipeline,
// fold vs reduce, grouping, and chaining transformations functionally (no
// mutation, no manual loops). This style dominates real Flutter data layers.
// =============================================================================

void main() {
  final nums = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

  // 1. map -> transform each (same count). where -> filter. Both LAZY.
  final evenSquares = nums.where((n) => n.isEven).map((n) => n * n);
  print('1. $evenSquares'); // (4, 16, 36, 64, 100) — an Iterable, computed lazily
  print('1. materialized: ${evenSquares.toList()}'); // force into a List

  // 2. reduce: collapse to ONE value, seed = first element. THROWS on empty.
  print('2. sum (reduce) = ${nums.reduce((a, b) => a + b)}'); // 55

  // 3. fold: like reduce but with an explicit SEED, and the result type can
  //    DIFFER from the element type. Safe on empty lists.
  final csv = nums.fold<String>('', (acc, n) => acc.isEmpty ? '$n' : '$acc,$n');
  print('3. fold to String = $csv'); // 1,2,3,...,10
  print('3. fold on empty = ${<int>[].fold<int>(0, (a, b) => a + b)}'); // 0, no throw

  // 4. expand = flatMap: each element -> an iterable, then flatten.
  final pairs = [1, 2, 3].expand((n) => [n, n * 10]);
  print('4. expand = ${pairs.toList()}'); // [1, 10, 2, 20, 3, 30]

  // 5. any / every / firstWhere (with orElse to avoid throwing).
  print('5. any > 8? ${nums.any((n) => n > 8)}'); // true
  print('5. every > 0? ${nums.every((n) => n > 0)}'); // true
  print('5. first > 100? ${nums.firstWhere((n) => n > 100, orElse: () => -1)}'); // -1

  // 6. GROUP BY (no stdlib groupBy without package:collection — do it with fold).
  final words = ['apple', 'avocado', 'banana', 'cherry', 'blueberry'];
  final byFirstLetter = words.fold<Map<String, List<String>>>({}, (map, w) {
    map.putIfAbsent(w[0], () => []).add(w);
    return map;
  });
  print('6. grouped = $byFirstLetter');
  // {a: [apple, avocado], b: [banana, blueberry], c: [cherry]}

  // 7. A functional PIPELINE: filter -> transform -> sort -> take. No mutation.
  final topProducts = [
    Product('Phone', 699, 4.5),
    Product('Case', 19, 4.1),
    Product('Laptop', 1299, 4.8),
    Product('Charger', 29, 3.9),
    Product('Tablet', 499, 4.6),
  ];
  final result = topProducts
      .where((p) => p.rating >= 4.5) // keep highly rated
      .map((p) => '${p.name} (\$${p.price})') // project to a label
      .toList()
    ..sort(); // cascade: sort the resulting list in place
  print('7. top rated = $result');

  // 8. Sum/avg over objects with fold.
  final avgPrice =
      topProducts.fold<double>(0, (sum, p) => sum + p.price) / topProducts.length;
  print('8. avg price = ${avgPrice.toStringAsFixed(2)}');

  // 9. Map iteration: entries / keys / values, and transforming a Map.
  final prices = {'Phone': 699, 'Laptop': 1299};
  final discounted = prices.map((name, price) => MapEntry(name, price * 0.9));
  print('9. discounted = $discounted'); // {Phone: 629.1, Laptop: 1169.1}

  // 10. [GOTCHA] Re-iterating a lazy Iterable RE-RUNS the work each time.
  var calls = 0;
  final lazy = nums.map((n) {
    calls++;
    return n;
  });
  lazy.toList();
  lazy.toList();
  print('10. map callback ran $calls times (20, not 10) — laziness recomputes');
}

class Product {
  final String name;
  final int price;
  final double rating;
  Product(this.name, this.price, this.rating);
}
