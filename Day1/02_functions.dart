// =============================================================================
// Day 1 · Part 2 — Functions
// Run: dart run Day1/02_functions.dart
// =============================================================================
//
// Goal: write 10 small functions covering positional params, named params,
// optional params, default values, arrow syntax, first-class functions,
// closures, and typedefs. Try writing each from memory FIRST.
// =============================================================================

// --- typedef: give a function signature a reusable name ---------------------
// Useful for callbacks (you'll see this everywhere in Flutter: VoidCallback,
// ValueChanged<T>, etc. are all typedefs).
typedef IntTransform = int Function(int value);
typedef Validator = bool Function(String input);

void main() {
  // 1. Basic positional params
  print(add(2, 3)); // 5

  // 2. Arrow function (single-expression body)
  print(square(4)); // 16

  // 3. Named parameters (order doesn't matter, self-documenting at call site)
  print(greet(name: 'Aditya', greeting: 'Hi')); // Hi, Aditya!
  print(greet(name: 'Sam')); // Hello, Sam!  (greeting has a default)

  // 4. Required named parameter
  print(createUser(name: 'Riya', age: 28));

  // 5. Optional POSITIONAL parameters [in square brackets]
  print(buildPath('usr')); // usr
  print(buildPath('usr', 'local', 'bin')); // usr/local/bin

  // 6. Function returning a function (first-class + closure)
  final addTen = makeAdder(10);
  print(addTen(5)); // 15

  // 7. Passing a function as an argument (typedef in action)
  print(applyTwice(3, square)); // square(square(3)) = 81
  print(applyTwice(3, (n) => n + 1)); // anonymous fn: 5

  // 8. Higher-order: validate with an injected rule
  print(isValid('hello@x.com', (s) => s.contains('@'))); // true

  // 9. Closure capturing mutable state — a counter
  final counter = makeCounter();
  print(counter()); // 1
  print(counter()); // 2
  print(counter()); // 3

  // 10. Named + default + nullable combined (realistic signature)
  print(formatPrice(99.5)); // $99.50
  print(formatPrice(99.5, currency: '€', decimals: 0)); // €100
}

// 1. Two positional params, explicit return type.
int add(int a, int b) {
  return a + b;
}

// 2. Arrow function: `=> expr` is sugar for `{ return expr; }`.
int square(int n) => n * n;

// 3. Named params with a default. Wrap in {} ; without `required` they're optional.
String greet({required String name, String greeting = 'Hello'}) {
  return '$greeting, $name!';
}

// 4. `required` forces the caller to supply the named arg (compile-time checked).
String createUser({required String name, required int age}) {
  return 'User($name, $age)';
}

// 5. Optional positional params use [ ]. They must have a nullable type OR a default.
String buildPath(String first, [String? second, String? third]) {
  final parts = [first, if (second != null) second, if (third != null) third];
  return parts.join('/');
}

// 6. Returns a closure that "remembers" `amount`.
IntTransform makeAdder(int amount) {
  return (int value) => value + amount;
}

// 7. Takes a function param (typed via the typedef). Demonstrates first-class fns.
int applyTwice(int value, IntTransform fn) => fn(fn(value));

// 8. Higher-order function with an injected validation rule.
bool isValid(String input, Validator rule) => rule(input);

// 9. Closure over a private mutable variable — each call mutates captured state.
int Function() makeCounter() {
  int count = 0; // captured by the returned closure
  return () => ++count;
}

// 10. Mixed: positional required + named optional with defaults.
String formatPrice(double amount, {String currency = '\$', int decimals = 2}) {
  return '$currency${amount.toStringAsFixed(decimals)}';
}
