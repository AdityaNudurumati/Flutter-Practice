// =============================================================================
// 01 · DART FUNDAMENTALS — ALL-IN-ONE PRACTICAL FILE
// =============================================================================
// Runnable companion to the 10 notes files in this folder. Every "Revision
// Notes" bullet from each file has a live, printable demonstration here.
//
//   Run:      dart run "11_practicals_all_in_one.dart"
//   Analyze:  dart analyze "11_practicals_all_in_one.dart"
//
// Map of sections -> source notes file:
//   1  Variables & Mutability .......... 01_variables_and_mutability.md
//   2  Data Types ...................... 02_data_types.md
//   3  Operators ....................... 03_operators.md
//   4  Control Flow ................... 04_control_flow.md
//   5  Functions ...................... 05_functions.md
//   6  Collections .................... 06_collections.md
//   7  Null Safety .................... 07_null_safety.md
//   8  Enums ........................... 08_enums.md
//   9  Records & Patterns ............. 09_records_and_patterns.md
//   10 Exception Handling ............. 10_exception_handling.md
//   11 Mini Projects (one per file, condensed)
// =============================================================================

import 'dart:collection';

void main() {
  section1VariablesAndMutability();
  section2DataTypes();
  section3Operators();
  section4ControlFlow();
  section5Functions();
  section6Collections();
  section7NullSafety();
  section8Enums();
  section9RecordsAndPatterns();
  section10ExceptionHandling();
  section11MiniProjects();
}

// -----------------------------------------------------------------------------
// Small output helpers (keeps the demos readable).
// -----------------------------------------------------------------------------
void section(String title) => print('\n${'=' * 74}\n$title\n${'=' * 74}');
void topic(String title) => print('\n-- $title ${'-' * (60 - title.length)}');
void show(String label, Object? value) => print('  $label: $value');

/// Hides a value from the analyzer's flow analysis.
///
/// Several demos below deliberately show what happens with a null value or a
/// `false` condition. If the analyzer can *see* the literal, it folds the
/// branch away and reports "dead code" / "receiver can't be null". Routing the
/// value through these functions keeps the runtime behaviour identical while
/// keeping `dart analyze` clean — real code gets its nullables from JSON,
/// databases, and platform channels, which are opaque in exactly this way.
T? opaque<T>(T? value) => value;
bool opaqueBool(bool value) => value;

// =============================================================================
// SECTION 1 — VARIABLES & MUTABILITY  (var / final / const / late)
// =============================================================================
// Points covered:
//   * var + type inference, explicit types, reassignment
//   * final = runtime-once binding; const = compile-time + canonicalized +
//     deeply immutable
//   * `final list.add()` works (binding is fixed, the object is not)
//   * const collections are truly immutable -> UnsupportedError on mutation
//   * const canonicalization: identical() is true for equal const values
//   * late = deferred non-null init; read-before-write -> LateInitializationError
//   * late final = lazy one-time initialization (expensive work on first read)
// =============================================================================

void section1VariablesAndMutability() {
  section('SECTION 1 · VARIABLES & MUTABILITY');

  topic('var and type inference');
  var counter = 0; // inferred int
  counter = counter + 1; // reassignable
  var name = 'Aditya'; // inferred String
  int explicitlyTyped = 42; // explicit annotation
  show('counter (${counter.runtimeType})', counter);
  show('name (${name.runtimeType})', name);
  show('explicitlyTyped', explicitlyTyped);

  topic('final — the BINDING is fixed, not the object');
  final createdAt = DateTime(2026, 1, 1); // runtime value, assigned once
  final tags = <String>['dart']; // final list...
  tags.add('flutter'); // ...but the LIST is mutable
  tags.addAll(['mobile']);
  // tags = [];   // COMPILE ERROR: a final variable can't be reassigned.
  show('createdAt', createdAt.toIso8601String().substring(0, 10));
  show('tags after mutation', tags);

  topic('const — compile-time, canonicalized, DEEPLY immutable');
  const appName = 'Dart Practicals';
  const maxRetries = 3;
  const timeoutSeconds = maxRetries * 2; // computed at compile time
  const frozen = [1, 2, 3];
  show('appName', appName);
  show('timeoutSeconds (compile-time math)', timeoutSeconds);
  try {
    frozen.add(4); // deeply immutable -> throws at runtime
  } on UnsupportedError catch (e) {
    show('frozen.add(4) threw', e.runtimeType);
  }

  topic('const canonicalization — same value = same instance');
  const p1 = ConstPoint(1, 2);
  const p2 = ConstPoint(1, 2);
  final p3 = ConstPoint(1, 2); // `const` ctor invoked without `const`
  show('identical(p1, p2)  // canonicalized', identical(p1, p2));
  show('identical(p1, p3)  // new instance', identical(p1, p3));

  topic('final vs const — the deciding question');
  final runtimeValue = DateTime(2026, 8, 17).year; // known only at runtime
  // const bad = DateTime.now().year;  // COMPILE ERROR: not a constant.
  show('final can hold runtime values', runtimeValue);

  topic('late — deferred non-null initialization');
  final demo = LateDemo();
  try {
    print('  reading before write -> ${demo.description}');
  } on Error catch (e) {
    show('LateInitializationError', e.toString().split('\n').first);
  }
  demo.description = 'now initialized';
  show('after write', demo.description);

  topic('late final — lazy, runs at most once');
  final lazy = LateDemo();
  show('first read  (computes)', lazy.expensiveValue);
  show('second read (cached)', lazy.expensiveValue);
  show('compute call count', LateDemo.computeCalls);

  topic('Rules of thumb');
  print('  * Default to `final`. Reach for `var` only when you reassign.');
  print('  * Use `const` for compile-time constants and const widgets.');
  print('  * Use `late` for "definitely set before use, just not here".');
  print('  * Lints: prefer_final_locals, prefer_const_constructors.');
}

/// A `const`-constructible value type — used to demonstrate canonicalization.
class ConstPoint {
  final int x;
  final int y;
  const ConstPoint(this.x, this.y);
  @override
  String toString() => 'ConstPoint($x, $y)';
}

/// Demonstrates `late` (deferred) and `late final` (lazy) initialization.
class LateDemo {
  static int computeCalls = 0;

  /// Non-nullable, but assigned later. Reading it first throws
  /// `LateInitializationError`.
  late String description;

  /// Initializer runs on FIRST READ only, then the result is cached.
  late final int expensiveValue = _expensiveComputation();

  int _expensiveComputation() {
    computeCalls++;
    var sum = 0;
    for (var i = 1; i <= 1000; i++) {
      sum += i;
    }
    return sum;
  }
}

// =============================================================================
// SECTION 2 — DATA TYPES  (num, int, double, String, bool, dynamic, Object?)
// =============================================================================
// Points covered:
//   * num is the supertype of int and double
//   * `/` always yields double, `~/` yields int, `%` and .remainder()
//   * int/double conversions, parse vs tryParse, precision & rounding
//   * String is IMMUTABLE -> use StringBuffer to build strings
//   * String interpolation, raw strings, multi-line, common methods
//   * bool: no truthy/falsy in Dart
//   * dynamic = no static checks (crashes at runtime)
//     Object? = safe top type (must check/cast before use)
//   * Web int == JS double (precision loss) -> money in smallest integer unit
// =============================================================================

void section2DataTypes() {
  section('SECTION 2 · DATA TYPES');

  topic('num is the supertype of int and double');
  num anyNumber = 10; // holds an int...
  show('num holding int', '$anyNumber (${anyNumber.runtimeType})');
  anyNumber = 10.5; // ...and a double
  show('num holding double', '$anyNumber (${anyNumber.runtimeType})');
  final Object boxedInt = 10;
  final Object boxedDouble = 10.5;
  show('an int is a num', boxedInt is num);
  show('a double is a num', boxedDouble is num);
  show('an int is NOT a double', boxedInt is double);

  topic('Division: `/` -> double, `~/` -> int');
  show('7 / 2   (double division)', 7 / 2);
  show('7 ~/ 2  (truncating division)', 7 ~/ 2);
  show('7 % 2   (modulo)', 7 % 2);
  show('-7 ~/ 2 (truncates toward zero)', -7 ~/ 2);
  show('-7 % 2  (always non-negative)', -7 % 2);
  show('(-7).remainder(2) (keeps sign)', (-7).remainder(2));

  topic('Conversions, parsing, rounding');
  show('3.99.toInt()   (truncates)', 3.99.toInt());
  show('3.5.round()', 3.5.round());
  show('3.2.ceil() / 3.8.floor()', '${3.2.ceil()} / ${3.8.floor()}');
  show('7.toDouble()', 7.toDouble());
  show("int.parse('42')", int.parse('42'));
  show("int.tryParse('abc')  // null, no throw", int.tryParse('abc'));
  show("double.tryParse('3.14')", double.tryParse('3.14'));
  show('3.14159.toStringAsFixed(2)', 3.14159.toStringAsFixed(2));
  show('0.1 + 0.2 == 0.3  // IEEE-754 floats', 0.1 + 0.2 == 0.3);
  show('0.1 + 0.2', 0.1 + 0.2);

  topic('int specifics');
  show('255.toRadixString(16)', 255.toRadixString(16));
  show('int.parse("ff", radix: 16)', int.parse('ff', radix: 16));
  show('5.isEven / 5.isOdd', '${5.isEven} / ${5.isOdd}');
  show('(-5).abs()', (-5).abs());
  show('1_000_000 (digit separators)', 1000000);

  topic('String is IMMUTABLE');
  var greeting = 'Hello';
  final upper = greeting.toUpperCase(); // returns a NEW string
  show('original (unchanged)', greeting);
  show('toUpperCase() result', upper);
  greeting = '$greeting, world'; // rebinding, not mutating
  show('after rebinding', greeting);

  topic('StringBuffer — the right way to build strings in a loop');
  final buffer = StringBuffer();
  for (var i = 1; i <= 5; i++) {
    buffer.write('item$i');
    if (i < 5) buffer.write(', ');
  }
  show('StringBuffer result', buffer.toString());
  show('buffer.length', buffer.length);

  topic('String features');
  final user = 'Aditya';
  final items = [1, 2, 3];
  show('interpolation', 'Hi $user, you have ${items.length} items');
  show('expression interpolation', '2 + 3 = ${2 + 3}');
  show(r'raw string  r"C:\path\new"', r'C:\path\new');
  print('  multi-line:\n${'''    line one
    line two'''}');
  show("'dart'.padLeft(8, '*')", 'dart'.padLeft(8, '*'));
  show("' trim me '.trim()", "'${' trim me '.trim()}'");
  show("'a,b,c'.split(',')", 'a,b,c'.split(','));
  show("'dart'.contains('ar')", 'dart'.contains('ar'));
  show("'dart'.replaceAll('a', '4')", 'dart'.replaceAll('a', '4'));
  show("'dart'[0] and .codeUnitAt(0)", '${'dart'[0]} / ${'dart'.codeUnitAt(0)}');

  topic('bool — no truthy/falsy in Dart');
  final isReady = true;
  final hasItems = items.isNotEmpty; // must be an explicit bool
  show('isReady && hasItems', isReady && hasItems);
  // if (items) {}          // COMPILE ERROR: a List is not a bool.
  // if (name != null) {}   // this is how you express "truthiness".
  print('  Conditions MUST be `bool` — write the comparison explicitly.');

  topic('dynamic vs Object? — the critical difference');
  dynamic loose = 'I am a string';
  show('dynamic value', loose);
  try {
    // Compiles fine (no static checking), explodes at runtime.
    print('  calling a bogus method on dynamic...');
    loose.thisMethodDoesNotExist();
  } on NoSuchMethodError catch (_) {
    show('dynamic crashed with', 'NoSuchMethodError');
  }

  Object? safe = 'I am a string';
  // safe.toUpperCase();  // COMPILE ERROR: Object? has no toUpperCase.
  if (safe is String) {
    // Type promotion makes this safe.
    show('Object? after `is` promotion', safe.toUpperCase());
  }
  safe = null;
  show('Object? can hold null', safe);
  print('  dynamic = opt out of the type system (avoid).');
  print('  Object? = keep the type system, check before use (prefer).');

  topic('Type checks and casts');
  final Object value = 3.14;
  show('value is double', value is double);
  show('value is! String', value is! String);
  show('(value as double) + 1', (value as double) + 1);
  final maybeInt = value as dynamic;
  show('safe cast pattern', maybeInt is int ? 'int' : 'not an int');

  topic('Web int caveat & money handling');
  print('  On the web, `int` is a JS double -> 2^53 precision limit.');
  print('  Never store currency as double. Store paise/cents as int:');
  final priceInPaise = 129999; // Rs. 1,299.99
  show('formatted from int paise',
      'Rs. ${(priceInPaise / 100).toStringAsFixed(2)}');
}

// =============================================================================
// SECTION 3 — OPERATORS  (arithmetic, logical, null-aware, cascade, spread)
// =============================================================================
// Points covered:
//   * `a + b` is really `a.+(b)` -> operators are overridable methods
//   * operator overloading + `==`/`hashCode` overridden TOGETHER
//   * arithmetic, compound assignment, increment (pre vs post)
//   * relational, equality, `is` / `is!` / `as`
//   * logical &&, ||, ! and SHORT-CIRCUITING
//   * bitwise & | ^ ~ << >>
//   * every meaning of `?` : T? · ?. · ?[] · ?.. · ?? · ??= · ? :
//   * every meaning of `!` : !x · x! · is!
//   * cascade `..` returns the RECEIVER; `?..` null-safe cascade
//   * spread `...` and `...?`; collection-if / collection-for
// =============================================================================

void section3Operators() {
  section('SECTION 3 · OPERATORS');

  topic('Arithmetic & compound assignment');
  var n = 10;
  show('n + 3', n + 3);
  show('n - 3', n - 3);
  show('n * 3', n * 3);
  show('n / 3  -> double', n / 3);
  show('n ~/ 3 -> int', n ~/ 3);
  show('n % 3', n % 3);
  show('-n (unary minus)', -n);
  n += 5;
  show('n += 5', n);
  n -= 2;
  n *= 2;
  n ~/= 3;
  show('after -= 2, *= 2, ~/= 3', n);

  topic('Increment: pre vs post');
  var i = 5;
  show('i++ returns old value', i++);
  show('i is now', i);
  show('++i returns new value', ++i);

  topic('`a + b` is a method call: a.+(b)');
  show('2 + 3', 2 + 3);
  show('(2).operator+ equivalent', 2.toDouble() + 3);
  print('  So any class can define +, -, *, [], ==, <, etc.');

  topic('Operator overloading on a value type');
  const a = Vector(2, 3);
  const b = Vector(4, 1);
  show('a + b', a + b);
  show('a - b', a - b);
  show('a * 3', a * 3);
  show('-a (unary)', -a);
  show('a[0], a[1] (index operator)', '${a[0]}, ${a[1]}');
  show('a < b (by magnitude)', a < b);

  topic('== and hashCode MUST be overridden together');
  final v1 = Vector(1, 2);
  final v2 = Vector(1, 2);
  show('v1 == v2  (value equality)', v1 == v2);
  show('identical(v1, v2)', identical(v1, v2));
  show('hashCodes match', v1.hashCode == v2.hashCode);
  final vectorSet = {v1, v2}; // dedupes correctly BECAUSE of hashCode
  show('Set{v1, v2}.length', vectorSet.length);
  final vectorMap = {v1: 'first'};
  show('map lookup with an equal-but-different instance', vectorMap[v2]);

  topic('Relational, equality, type-test operators');
  show('3 < 5 / 3 <= 3 / 5 > 3 / 5 >= 6', '${3 < 5} ${3 <= 3} ${5 > 3} ${5 >= 6}');
  show("'a' == 'a'  (String uses value equality)", 'a' == 'a');
  Object obj = 'text';
  show('obj is String', obj is String);
  show('obj is! int', obj is! int);
  show('obj as String -> length', (obj as String).length);
  try {
    // `as` THROWS on a bad cast; `is` just returns false.
    obj = 42;
    print('  bad cast: ${obj as String}');
  } on TypeError catch (_) {
    show('bad `as` cast threw', 'TypeError');
  }

  topic('Logical operators & short-circuiting');
  final yes = opaqueBool(true);
  final no = opaqueBool(false);
  show('true && false', yes && no);
  show('true || false', yes || no);
  show('!true', !yes);
  var sideEffectRan = false;
  bool expensiveCheck() {
    sideEffectRan = true;
    return true;
  }

  // `false && ...` never evaluates the right side.
  final shortCircuited = no && expensiveCheck();
  show('false && expensiveCheck()', shortCircuited);
  show('did the right side run?', sideEffectRan);
  final orShort = yes || expensiveCheck();
  show('true || expensiveCheck() (also skipped)', orShort);
  show('side effect still not run', sideEffectRan);

  topic('Bitwise & shift operators');
  show('12 & 10 (AND)', 12 & 10);
  show('12 | 10 (OR)', 12 | 10);
  show('12 ^ 10 (XOR)', 12 ^ 10);
  show('~12 (NOT)', ~12);
  show('1 << 4 (left shift)', 1 << 4);
  show('32 >> 2 (right shift)', 32 >> 2);
  show('flags check: 0b0110 & 0b0100 != 0', (0x6 & 0x4) != 0);

  topic('Every meaning of `?` — decided by POSITION');
  // 1) `T?` — nullable TYPE marker (a declaration, not an operator).
  String? nullableName = opaque<String>(null);
  show('1. T?   nullable type', nullableName);

  // 2) `?.` `?[]` `?..` — null-SHORTING member access.
  show('2. ?.   null-shorting call', nullableName?.toUpperCase());
  final nullableList = opaque<List<int>>(null);
  show('2. ?[]  null-shorting index', nullableList?[0]);

  // 3) `??` and `??=` — fallback / assign-if-null.
  show('3. ??   fallback value', nullableName ?? 'GUEST');
  nullableName ??= 'assigned because null';
  nullableName = opaque(nullableName); // hide it from flow analysis again
  nullableName ??= 'IGNORED — already non-null';
  show('3. ??=  assigned once, second ??= was a no-op', nullableName);

  // 4) `? :` — the conditional (ternary) expression.
  // `??=` above guaranteed a value, so flow analysis promoted it to `String`.
  final len = nullableName.length;
  show('4. ? :  ternary', len > 10 ? 'long' : 'short');

  topic('Every meaning of `!` — also decided by POSITION');
  final flag = opaqueBool(false);
  show('1. !x   boolean NOT', !flag);

  var maybe = opaque('present');
  show('2. x!   null assertion (non-null result)', maybe!.length);
  maybe = opaque<String>(null);
  try {
    print('  x! on null -> ${maybe!.length}');
  } on TypeError catch (_) {
    show('2. x!   on null THROWS', 'TypeError (null check operator)');
  }

  Object thing = 'str';
  show('3. is!  negated type test', thing is! int);

  topic('?. vs !. — the difference that matters');
  final nothing = opaque<String>(null);
  show('nothing?.length  -> null, no crash', nothing?.length);
  print('  nothing!.length  -> CRASH (throws immediately)');
  print('  Prefer promotion or `late` over sprinkling `!`.');

  topic('Chained null-shorting');
  final Company? company = Company(ceo: Person(name: 'Ada'));
  final Company? empty = Company(ceo: null);
  show('company?.ceo?.name', company?.ceo?.name);
  show('empty?.ceo?.name  (short-circuits)', empty?.ceo?.name);
  show('with a fallback', empty?.ceo?.name ?? 'no CEO');

  topic('Cascade `..` — returns the RECEIVER, not the method result');
  // Without cascade you need a temp variable.
  final withTemp = StringBuffer();
  withTemp.write('a');
  withTemp.write('b');
  // With cascade it is one expression.
  final withCascade = StringBuffer()
    ..write('a')
    ..write('b')
    ..write('c');
  show('temp-variable style', withTemp.toString());
  show('cascade style', withCascade.toString());

  final cart = ShoppingCart()
    ..addItem('Book', 499)
    ..addItem('Pen', 20)
    ..applyDiscount(10);
  show('cascade-built cart', cart);

  // A cascade evaluates to the receiver, so `..add()` does NOT give you
  // add()'s bool/void return value.
  final built = <int>[]
    ..add(1)
    ..add(2);
  show('list built with cascade', built);

  topic('Null-safe cascade `?..`');
  var maybeCart = opaque<ShoppingCart>(null);
  maybeCart?..addItem('never added', 1); // whole cascade is skipped
  show('cascade on null was skipped', maybeCart);
  maybeCart = opaque(ShoppingCart());
  maybeCart?..addItem('Notebook', 150);
  show('cascade on non-null ran', maybeCart);

  topic('Spread `...` and null-aware spread `...?`');
  final base = [1, 2, 3];
  final extra = [4, 5];
  final List<int>? missing = null;
  final combined = [0, ...base, ...extra, ...?missing, 6];
  show('spread combined', combined);
  final mapA = {'a': 1};
  final mapB = {'b': 2};
  show('spread maps', {...mapA, ...mapB});
  show('spread sets', {...base, ...extra, 1});
  print('  `...null` is a runtime error — use `...?` for nullable lists.');

  topic('Collection-if and collection-for');
  final isPremium = opaqueBool(true);
  final isAdmin = opaqueBool(false);
  final menu = [
    'Home',
    if (isPremium) 'Premium Reports',
    if (isAdmin) 'Admin Panel' else 'Feedback',
    for (final n in [1, 2, 3]) 'Item $n',
    for (var k = 0; k < 2; k++) 'Slot $k',
  ];
  show('built declaratively', menu);
  final squares = {for (final n in [1, 2, 3, 4]) n: n * n};
  show('map comprehension', squares);

  topic('Precedence — parenthesize when in doubt');
  show('2 + 3 * 4', 2 + 3 * 4);
  show('(2 + 3) * 4', (2 + 3) * 4);
  show('true || false && false  (&& binds tighter)', yes || no && no);
  show('a ?? b == c pitfall -> parenthesize', (opaque<int>(null) ?? 5) == 5);
}

/// Value type showing arithmetic/index/comparison operator overloading plus
/// correct `==`/`hashCode`.
class Vector {
  final double x;
  final double y;
  const Vector(this.x, this.y);

  Vector operator +(Vector other) => Vector(x + other.x, y + other.y);
  Vector operator -(Vector other) => Vector(x - other.x, y - other.y);
  Vector operator *(num scale) => Vector(x * scale, y * scale);
  Vector operator -() => Vector(-x, -y); // unary minus
  double operator [](int index) => index == 0 ? x : y;
  bool operator <(Vector other) => magnitude < other.magnitude;

  double get magnitude => (x * x + y * y);

  @override
  bool operator ==(Object other) =>
      other is Vector && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Vector($x, $y)';
}

class Person {
  final String name;
  Person({required this.name});
}

class Company {
  final Person? ceo;
  Company({required this.ceo});
}

/// Cascade-friendly mutable builder.
class ShoppingCart {
  final Map<String, int> _items = {};
  int _discountPercent = 0;

  void addItem(String name, int price) => _items[name] = price;
  void applyDiscount(int percent) => _discountPercent = percent;

  int get total {
    final sum = _items.values.fold(0, (acc, price) => acc + price);
    return sum - (sum * _discountPercent ~/ 100);
  }

  @override
  String toString() => 'Cart(${_items.keys.join("+")}, total=$total)';
}

// =============================================================================
// SECTION 4 — CONTROL FLOW  (if, for, while, switch, collection-if/for)
// =============================================================================
// Points covered:
//   * No truthy/falsy — conditions must be `bool`
//   * if / else if / else, ternary, if-case (pattern condition)
//   * classic for, for-in, forEach, while, do-while
//   * break, continue, labeled break for nested loops
//   * for-in gives a FRESH binding per iteration -> closure-safe
//     (classic `for (var i...)` shares one variable)
//   * switch statement: fall-through-free, multi-case labels, default
//   * switch EXPRESSION: returns a value, exhaustive, no `_` needed on enums
//   * jump table optimisation for dense int/enum switches
//   * collection-if / collection-for inside [] and {}
// =============================================================================

void section4ControlFlow() {
  section('SECTION 4 · CONTROL FLOW');

  topic('Conditions must be bool (no truthy/falsy)');
  final items = <int>[];
  final name = '';
  // if (items) ...    // ERROR
  // if (name) ...     // ERROR
  if (items.isEmpty) print('  items.isEmpty -> true');
  if (name.isEmpty) print('  name.isEmpty  -> true (empty String is NOT false)');

  topic('if / else if / else and the ternary');
  final score = 82;
  if (score >= 90) {
    print('  grade: A');
  } else if (score >= 80) {
    print('  grade: B');
  } else {
    print('  grade: C');
  }
  show('ternary', score >= 50 ? 'pass' : 'fail');
  show('nested ternary (use sparingly)',
      score >= 90 ? 'A' : score >= 80 ? 'B' : 'C');

  topic('Loops: classic for, for-in, forEach');
  final buffer = StringBuffer();
  for (var i = 1; i <= 5; i++) {
    buffer.write('$i ');
  }
  show('classic for', buffer.toString().trim());

  final fruits = ['apple', 'banana', 'cherry'];
  final upper = <String>[];
  for (final fruit in fruits) {
    upper.add(fruit.toUpperCase());
  }
  show('for-in', upper);

  final indexed = <String>[];
  for (final (index, fruit) in fruits.indexed) {
    indexed.add('$index:$fruit');
  }
  show('.indexed with a record pattern', indexed);

  final collected = <int>[];
  fruits.asMap().forEach((i, f) => collected.add(f.length));
  show('forEach over asMap()', collected);

  topic('while and do-while');
  var countdown = 3;
  final whileOut = <int>[];
  while (countdown > 0) {
    whileOut.add(countdown);
    countdown--;
  }
  show('while', whileOut);

  var attempts = 0;
  final doOut = <String>[];
  do {
    attempts++;
    doOut.add('attempt $attempts');
  } while (attempts < 2);
  show('do-while (body runs at least once)', doOut);

  topic('break, continue, labeled break');
  final evens = <int>[];
  for (var i = 1; i <= 10; i++) {
    if (i.isOdd) continue; // skip this iteration
    if (i > 8) break; // exit the loop
    evens.add(i);
  }
  show('continue + break', evens);

  String? found;
  outer:
  for (final row in ['ab', 'cd', 'ef']) {
    for (final ch in row.split('')) {
      if (ch == 'd') {
        found = 'found "$ch" in "$row"';
        break outer; // breaks BOTH loops
      }
    }
  }
  show('labeled break', found);

  topic('Closure capture: for-in is safe, classic `for` needs care');
  final forInClosures = <int Function()>[];
  for (final n in [1, 2, 3]) {
    forInClosures.add(() => n); // fresh `n` per iteration
  }
  show('for-in captures', forInClosures.map((f) => f()).toList());

  final classicClosures = <int Function()>[];
  for (var k = 1; k <= 3; k++) {
    final captured = k; // copy to a fresh local -> safe
    classicClosures.add(() => captured);
  }
  show('classic for + local copy', classicClosures.map((f) => f()).toList());

  topic('switch STATEMENT — no implicit fall-through');
  for (final code in ['GET', 'POST', 'PATCH', 'TRACE']) {
    switch (code) {
      case 'GET':
        print('  $code -> read');
      case 'POST':
      case 'PATCH': // multiple labels share one body
        print('  $code -> write');
      default:
        print('  $code -> unsupported');
    }
  }

  topic('switch EXPRESSION — returns a value, is exhaustive');
  for (final status in OrderStatus.values) {
    // No `default`/`_` needed: the compiler knows all enum values are covered.
    // Add a new enum value and this STOPS COMPILING until you handle it.
    final label = switch (status) {
      OrderStatus.pending => 'Waiting for payment',
      OrderStatus.shipped => 'On the way',
      OrderStatus.delivered => 'Delivered',
      OrderStatus.cancelled => 'Cancelled',
    };
    print('  ${status.name.padRight(10)} -> $label');
  }

  topic('switch expression with guards and relational patterns');
  for (final temp in [-5, 12, 24, 39]) {
    final advice = switch (temp) {
      < 0 => 'freezing',
      < 15 => 'cold',
      < 30 => 'pleasant',
      _ => 'hot',
    };
    print('  ${temp.toString().padLeft(3)}C -> $advice');
  }

  topic('if-case — pattern matching in an if');
  final Object payload = {'type': 'user', 'id': 7};
  if (payload case {'type': 'user', 'id': int id}) {
    show('destructured id', id);
  }

  topic('Dense int/enum switches compile to a jump table');
  print('  O(1) dispatch instead of a chain of comparisons.');
  print('  Prefer switch over long if/else-if chains on enums.');

  topic('Collection-if / collection-for (control flow inside literals)');
  const isLoggedIn = true;
  final permissions = ['read'];
  final navigation = [
    'Dashboard',
    if (isLoggedIn) 'Profile',
    if (permissions.contains('write')) 'Editor',
    for (final p in permissions) 'perm:$p',
  ];
  show('literal built with control flow', navigation);
  final config = {
    'theme': 'dark',
    if (isLoggedIn) 'session': 'active',
    for (final p in permissions) 'can_$p': true,
  };
  show('map built with control flow', config);
}

// =============================================================================
// SECTION 5 — FUNCTIONS  (params, arrow, closures, higher-order, typedef)
// =============================================================================
// Points covered:
//   * required positional, optional positional [], named {} with defaults
//   * `required` named params; you CANNOT mix [] and {} in one signature
//   * arrow `=>` is one EXPRESSION; block bodies need `return`
//   * functions are first-class: store, pass, return
//   * closures capture and remember outer-scope variables
//   * higher-order functions and generic functions
//   * typedef for function types and type aliases
//   * `myFn` vs `myFn()` — the classic onPressed bug
//   * recursion; closures in hot paths cause GC pressure -> hoist them
// =============================================================================

void section5Functions() {
  section('SECTION 5 · FUNCTIONS');

  topic('Parameter kinds');
  show('required positional  add(2, 3)', add(2, 3));
  show('optional positional  greet("Ada")', greet('Ada'));
  show('optional positional  greet("Ada", "Hi")', greet('Ada', 'Hi'));
  show('named with defaults  createUser(name:)', createUser(name: 'Bob'));
  show('named all supplied',
      createUser(name: 'Bob', age: 30, isActive: false));
  print('  A signature may use [] OR {} for optionals — never both.');

  topic('Arrow vs block bodies');
  show('arrow (single expression)', double3(4));
  show('block (needs return)', doubleBlock(4));
  print('  `=>` is sugar for `{ return <expr>; }` — statements need `{}`.');

  topic('Functions are first-class values');
  final operation = add; // stored in a variable (no parentheses!)
  show('stored then called', operation(10, 5));
  final ops = <String, int Function(int, int)>{
    'add': add,
    'mul': (a, b) => a * b, // anonymous function
  };
  show('functions in a Map', '${ops['add']!(3, 4)} / ${ops['mul']!(3, 4)}');

  topic('`myFn` vs `myFn()` — the onPressed bug');
  // Passing `sayHi()` calls it NOW and passes the RESULT (void/null).
  // Passing `sayHi` passes the FUNCTION for later invocation.
  final callback = sayHi; // reference — correct
  print('  reference stored, nothing printed yet');
  callback(); // now it runs
  print('  In Flutter: onPressed: _submit   (not _submit())');
  print('  With args:  onPressed: () => _submit(id)');

  topic('Closures — a function + its captured scope');
  final counter = makeCounter();
  show('counter()', counter());
  show('counter()', counter());
  show('counter()', counter());
  final independent = makeCounter(); // separate captured state
  show('a fresh counter starts over', independent());

  final add10 = makeAdder(10);
  final add100 = makeAdder(100);
  show('makeAdder(10)(5)', add10(5));
  show('makeAdder(100)(5)', add100(5));

  topic('Higher-order functions');
  show('applyTwice(add10, 1)', applyTwice(add10, 1));
  show('List.map with a function argument',
      [1, 2, 3].map((n) => n * n).toList());
  show('List.where', [1, 2, 3, 4, 5, 6].where((n) => n.isEven).toList());
  show('fold as a HOF', [1, 2, 3, 4].fold<int>(0, (acc, n) => acc + n));

  topic('Generic functions');
  show('firstOrNull<int>', firstOrNull<int>([7, 8]));
  show('firstOrNull on empty', firstOrNull<String>([]));
  show('swapPair<String, int>', swapPair(('a', 1)));

  topic('typedef — names for function types and type aliases');
  const Validator<String> notEmpty = _notEmpty;
  show('Validator typedef', notEmpty('') ?? 'valid');
  show('Validator typedef', notEmpty('ok') ?? 'valid');
  final Json payload = {'id': 1, 'name': 'Ada'};
  show('Json type alias', payload);
  final Transform<int> triple = (v) => v * 3;
  show('Transform<int>', triple(7));

  topic('Recursion');
  show('factorial(6)', factorial(6));
  show('fib(10)', fib(10));

  topic('Functional toolkit built from closures');
  final slugify = pipe<String>([
    (s) => s.trim(),
    (s) => s.toLowerCase(),
    (s) => s.replaceAll(' ', '-'),
  ]);
  show('pipe', slugify('  Hello Dart World  '));

  var rawCalls = 0;
  int slowSquare(int n) {
    rawCalls++;
    return n * n;
  }

  final memoSquare = memoize<int, int>(slowSquare);
  show('memoize first  call', memoSquare(9));
  show('memoize second call', memoSquare(9));
  show('underlying invocations', rawCalls);

  var initCount = 0;
  final initOnce = once(() => initCount++);
  initOnce();
  initOnce();
  initOnce();
  show('once() ran exactly', '$initCount time(s)');

  topic('Performance note');
  print('  Every closure literal allocates. In hot paths (build methods,');
  print('  tight loops) hoist the closure to a field or a top-level function');
  print('  instead of recreating it per call — less GC pressure.');
}

// --- Section 5 supporting declarations ---------------------------------------

typedef Json = Map<String, dynamic>; // type alias
typedef Transform<T> = T Function(T value); // function type alias
typedef Validator<T> = String? Function(T value); // returns null when valid

int add(int a, int b) => a + b;

/// Optional POSITIONAL parameter with a default.
String greet(String name, [String salutation = 'Hello']) =>
    '$salutation, $name!';

/// NAMED parameters: optional by default; `required` makes one mandatory.
String createUser({required String name, int age = 18, bool isActive = true}) =>
    '$name (age $age, active=$isActive)';

int double3(int n) => n * 2; // arrow body
int doubleBlock(int n) {
  // block body
  final result = n * 2;
  return result;
}

void sayHi() => print('  ...sayHi() executed');

/// Returns a closure that keeps its own private counter.
int Function() makeCounter() {
  var count = 0; // captured by the returned closure
  return () => ++count;
}

int Function(int) makeAdder(int addend) => (int value) => value + addend;

int applyTwice(int Function(int) fn, int value) => fn(fn(value));

T? firstOrNull<T>(List<T> items) => items.isEmpty ? null : items.first;

(B, A) swapPair<A, B>((A, B) pair) => (pair.$2, pair.$1);

String? _notEmpty(String value) => value.isEmpty ? 'Must not be empty' : null;

int factorial(int n) => n <= 1 ? 1 : n * factorial(n - 1);

int fib(int n) => n < 2 ? n : fib(n - 1) + fib(n - 2);

/// Composes a list of same-type transforms left-to-right.
T Function(T) pipe<T>(List<Transform<T>> stages) => (T input) {
      var value = input;
      for (final stage in stages) {
        value = stage(value);
      }
      return value;
    };

/// Caches results in a `Map` captured by the closure.
R Function(A) memoize<A, R>(R Function(A) fn) {
  final cache = <A, R>{};
  return (A arg) => cache.putIfAbsent(arg, () => fn(arg));
}

/// Runs the wrapped action at most once.
void Function() once(void Function() action) {
  var done = false;
  return () {
    if (done) return;
    done = true;
    action();
  };
}

// =============================================================================
// SECTION 6 — COLLECTIONS  (List, Set, Map, Iterable, Queue) & LAZY OPS
// =============================================================================
// Points covered:
//   * List = ordered + duplicates; Set = unique + fast contains;
//     Map = key lookup; Queue = FIFO/deque
//   * growable vs fixed-length vs unmodifiable lists
//   * `{}` is a MAP; `<T>{}` (or a typed variable) is a SET
//   * LAZY: map / where / expand / take / skip  (nothing runs until iterated)
//     EAGER: toList / toSet / fold / reduce / forEach / join / any / every
//   * `reduce` throws on empty; `fold` is empty-safe and can change the type
//   * custom objects as Set members / Map keys need `==` + `hashCode`
//   * dedupe with toSet().toList(); grouping with fold; sorting with compare
// =============================================================================

void section6Collections() {
  section('SECTION 6 · COLLECTIONS');

  topic('List — ordered, allows duplicates');
  final numbers = <int>[3, 1, 4, 1, 5];
  numbers.add(9);
  numbers.insert(0, 0);
  numbers.remove(1); // removes the FIRST matching value
  show('list', numbers);
  show('first / last / length',
      '${numbers.first} / ${numbers.last} / ${numbers.length}');
  show('indexOf(4) / contains(5)',
      '${numbers.indexOf(4)} / ${numbers.contains(5)}');
  show('sublist(1, 3)', numbers.sublist(1, 3));
  show('reversed', numbers.reversed.toList());
  final sorted = [...numbers]..sort();
  show('sorted (copy, not in place)', sorted);
  final byDescending = [...numbers]..sort((a, b) => b.compareTo(a));
  show('custom comparator (desc)', byDescending);

  topic('List flavours');
  final growable = <int>[]; // default
  growable.add(1);
  final filled = List<int>.filled(3, 0); // fixed length
  final generated = List<int>.generate(4, (i) => i * i);
  final frozen = List<int>.unmodifiable([1, 2, 3]);
  show('growable', growable);
  show('List.filled(3, 0)', filled);
  show('List.generate', generated);
  try {
    frozen.add(4);
  } on UnsupportedError catch (_) {
    show('unmodifiable list .add', 'UnsupportedError');
  }

  topic('Set — unique members, O(1) contains');
  // Built from a List so the duplicate is real data, not a literal typo.
  final tags = ['dart', 'flutter', 'dart'].toSet(); // duplicate dropped
  tags.add('mobile');
  show('set (dupes collapsed)', tags);
  final other = {'flutter', 'web'};
  show('union', tags.union(other));
  show('intersection', tags.intersection(other));
  show('difference', tags.difference(other));
  show('contains("dart")', tags.contains('dart'));

  topic('`{}` is a Map — `<T>{}` is a Set');
  final emptyMap = {}; // Map<dynamic, dynamic>
  final emptySet = <String>{}; // Set<String>
  show('{} runtimeType', emptyMap.runtimeType);
  show('<String>{} runtimeType', emptySet.runtimeType);

  topic('Map — key/value lookup');
  final scores = <String, int>{'ada': 92, 'bob': 78};
  scores['cleo'] = 85;
  scores.putIfAbsent('dan', () => 60); // only inserts when missing
  scores.update('bob', (v) => v + 5);
  scores.remove('ada');
  show('map', scores);
  show('keys / values', '${scores.keys.toList()} / ${scores.values.toList()}');
  show('containsKey("bob")', scores.containsKey('bob'));
  show('lookup missing key -> null', scores['nobody']);
  show('lookup with fallback', scores['nobody'] ?? 0);
  final entriesDesc = scores.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  show('sorted entries', entriesDesc.map((e) => '${e.key}=${e.value}').toList());
  show('map -> transformed map',
      scores.map((k, v) => MapEntry(k.toUpperCase(), v >= 80)));

  topic('Queue — FIFO / double-ended (dart:collection)');
  final queue = Queue<String>();
  queue.addLast('job1');
  queue.addLast('job2');
  queue.addFirst('urgent');
  show('queue', queue.toList());
  show('removeFirst()', queue.removeFirst());
  show('removeLast()', queue.removeLast());
  show('remaining', queue.toList());

  topic('LAZY vs EAGER — this is the exam question');
  var lazyWorkDone = 0;
  final lazyPipeline = [1, 2, 3, 4, 5]
      .map((n) {
        lazyWorkDone++; // side effect proves when work happens
        return n * 2;
      })
      .where((n) => n > 4);
  show('after building the pipeline, work done', lazyWorkDone);
  final materialized = lazyPipeline.toList(); // NOW it runs
  show('after toList(), work done', lazyWorkDone);
  show('result', materialized);
  print('  Lazy: map, where, expand, take, skip, takeWhile, skipWhile, cast');
  print('  Eager: toList, toSet, fold, reduce, forEach, join, any, every, length');
  print('  Iterating a lazy chain twice re-runs the work — materialize once.');

  topic('Iterable transformations');
  final source = [1, 2, 3, 4, 5, 6, 7, 8];
  show('map', source.map((n) => n * n).take(4).toList());
  show('where', source.where((n) => n.isOdd).toList());
  show('expand (flatMap)', [[1, 2], [3, 4]].expand((l) => l).toList());
  show('take(3) / skip(5)', '${source.take(3).toList()} / ${source.skip(5).toList()}');
  show('takeWhile(<4)', source.takeWhile((n) => n < 4).toList());
  show('skipWhile(<6)', source.skipWhile((n) => n < 6).toList());
  show('any / every', '${source.any((n) => n > 7)} / ${source.every((n) => n > 0)}');
  show('firstWhere with orElse', source.firstWhere((n) => n > 100, orElse: () => -1));
  show('join', source.take(3).join(' -> '));
  show('followedBy', [1, 2].followedBy([3]).toList());
  show('whereType<int>', <Object>[1, 'a', 2].whereType<int>().toList());

  topic('fold vs reduce');
  show('reduce (sum)', source.reduce((a, b) => a + b));
  show('fold (sum, seeded)', source.fold<int>(0, (acc, n) => acc + n));
  show('fold can CHANGE the result type',
      source.take(3).fold<String>('', (acc, n) => '$acc[$n]'));
  try {
    <int>[].reduce((a, b) => a + b); // no seed -> nothing to return
  } on StateError catch (_) {
    show('[].reduce()', 'StateError — reduce is NOT empty-safe');
  }
  show('[].fold(0, ...)', <int>[].fold<int>(0, (a, b) => a + b));

  topic('Dedupe and group');
  final withDupes = ['a', 'b', 'a', 'c', 'b'];
  show('toSet().toList()', withDupes.toSet().toList());
  final words = ['apple', 'avocado', 'banana', 'blueberry', 'cherry'];
  final grouped = words.fold<Map<String, List<String>>>({}, (acc, w) {
    acc.putIfAbsent(w[0], () => []).add(w);
    return acc;
  });
  show('grouped by first letter', grouped);

  topic('Custom objects in Sets / as Map keys need == + hashCode');
  // Same three inputs, two different classes.
  final withEquality =
      [const Sku('A1'), const Sku('A1'), const Sku('B2')].toSet();
  show('3 Skus (has ==/hashCode) -> Set size', withEquality.length);
  final noEquality = [RawSku('A1'), RawSku('A1'), RawSku('B2')].toSet();
  show('3 RawSkus (has neither)  -> Set size', noEquality.length);
  print('  Without ==/hashCode, equal-looking objects stay distinct.');
  final priceTable = {const Sku('A1'): 100};
  show('Map lookup by an equal Sku instance', priceTable[const Sku('A1')]);

  topic('Complexity cheat sheet');
  print('  List: index O(1) · contains O(n) · insert/remove middle O(n)');
  print('  Set/Map: add/contains/lookup O(1) average');
  print('  Queue: addFirst/addLast/removeFirst/removeLast O(1)');
  print('  Searching a big List repeatedly? Build a Set/Map first.');
}

/// Has value equality — safe as a Set member and Map key.
class Sku {
  final String code;
  const Sku(this.code);

  @override
  bool operator ==(Object other) => other is Sku && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'Sku($code)';
}

/// No `==`/`hashCode` -> identity equality -> duplicates in Sets.
class RawSku {
  final String code;
  RawSku(this.code);
}

// =============================================================================
// SECTION 7 — NULL SAFETY  (?, !, ??, ??=, late, flow analysis)
// =============================================================================
// Points covered:
//   * `?` declares a nullable type; non-nullable is the default
//   * `!` asserts non-null and MAY THROW — a claim, not a conversion
//   * `??` fallback expression; `??=` assign-if-null
//   * `?.` `?[]` null-shorting
//   * FLOW ANALYSIS / promotion: works on locals and final fields,
//     NOT on non-final instance fields -> copy to a local first
//   * null is a valid value -> `?.` / `??`; null means a bug -> `!` (fail fast)
//   * `late`: deferred non-null init OR lazy final;
//     read-before-set -> LateInitializationError
//   * required named params, nullable generics, safe collection access
// =============================================================================

void section7NullSafety() {
  section('SECTION 7 · NULL SAFETY');

  topic('Non-nullable by default');
  String definitely = 'never null';
  var possibly = opaque<String>(null); // String?, implicitly null
  // definitely = null;   // COMPILE ERROR
  show('non-nullable', definitely);
  show('nullable (unassigned)', possibly);

  topic('?? and ??=');
  show('possibly ?? "fallback"', possibly ?? 'fallback');
  possibly ??= 'assigned by ??=';
  show('after ??=', possibly);
  possibly = opaque(possibly); // hide the value from flow analysis again
  possibly ??= 'not assigned — already non-null';
  show('??= is a no-op when non-null', possibly);
  final chain = opaque<String>(null) ?? opaque<String>(null) ?? 'third wins';
  show('?? chains left-to-right', chain);

  topic('?. and ?[] null-shorting');
  var maybeText = opaque<String>(null);
  show('maybeText?.length', maybeText?.length);
  show('maybeText?.length ?? 0', maybeText?.length ?? 0);
  maybeText = opaque('dart');
  show('now maybeText?.toUpperCase()', maybeText?.toUpperCase());
  final maybeMap = opaque<Map<String, int>>({'a': 1});
  show('maybeMap?["a"]', maybeMap?['a']);
  show('maybeMap?["zz"] (key missing)', maybeMap?['zz']);

  topic('`!` — assertion, not conversion');
  var present = opaque('here');
  show('present! is fine', present!.length);
  present = opaque<String>(null);
  try {
    print('  present!.length -> ${present!.length}');
  } on TypeError catch (_) {
    show('present! on null', 'threw TypeError — this is the point of `!`');
  }
  print('  Use `!` only where null would be a BUG you want to hear about.');

  topic('Flow analysis / type promotion');
  final input = opaque('promote me');
  if (input != null) {
    // Promoted to non-nullable String inside this block — no `!` needed.
    show('promoted local', input.toUpperCase());
  }
  final unwrapped = describeLength(null);
  show('early-return promotion (null)', unwrapped);
  show('early-return promotion (value)', describeLength('hello'));

  topic('Promotion does NOT work on non-final instance fields');
  final holder = MessageHolder();
  holder.message = 'set now';
  show('field via local copy', holder.describeCorrectly());
  show('field via ?. + ??', holder.describeWithNullAware());
  print('  Why: another thread/callback could null the field between the');
  print('  check and the use, so the compiler refuses to promote it.');
  print('  Fix: `final local = field;` then check `local`.');

  topic('late — deferred non-null initialization');
  final service = ApiService();
  try {
    service.ping();
  } on Error catch (e) {
    show('use before init', e.toString().split('\n').first);
  }
  service.configure('https://api.example.com');
  show('after configure()', service.ping());

  topic('late final — lazy singleton-ish initialization');
  final cfg = LazyConfig();
  show('first access', cfg.parsedLimit);
  show('second access (cached)', cfg.parsedLimit);
  show('parse invocations', LazyConfig.parseCount);

  topic('required named params replace "hope they passed it"');
  show('buildUrl', buildUrl(host: 'example.com', path: '/v1/users'));
  show('buildUrl with optional port',
      buildUrl(host: 'example.com', path: '/v1', port: 8080));

  topic('Safe collection access');
  final list = <int>[10, 20];
  show('firstOrNull on non-empty', list.isEmpty ? null : list.first);
  show('elementAtOrNull-style guard', list.length > 5 ? list[5] : null);
  try {
    print('  list[5] -> ${list[5]}');
  } on RangeError catch (_) {
    show('list[5]', 'RangeError — index access is NOT null-safe');
  }
  final Map<String, int> m = {'a': 1};
  show('map lookup returns V? by design', m['missing']);

  topic('Nullable generics');
  final results = <String?>['a', null, 'b'];
  show('List<String?>', results);
  show('filtered to non-null (whereType)', results.whereType<String>().toList());
  show('.nonNulls', results.nonNulls.toList());

  topic('Decision table');
  print('  Value legitimately absent   -> `T?` + `?.` / `??`');
  print('  Absent means a programming bug -> `!` (fail loudly)');
  print('  Set later but always before use -> `late`');
  print('  Expensive and maybe unused  -> `late final x = compute();`');
}

String describeLength(String? text) {
  if (text == null) return 'no text';
  // `text` is promoted to String from here on.
  return 'length=${text.length}';
}

class MessageHolder {
  String? message; // non-final field -> NOT promotable

  String describeCorrectly() {
    final local = message; // copy to a local...
    if (local == null) return 'empty';
    return local.toUpperCase(); // ...local IS promotable
  }

  String describeWithNullAware() => message?.toUpperCase() ?? 'empty';
}

class ApiService {
  late String _baseUrl; // set in configure(), never null afterwards

  void configure(String url) => _baseUrl = url;

  String ping() => 'GET $_baseUrl/ping';
}

class LazyConfig {
  static int parseCount = 0;

  /// Computed on first read only.
  late final int parsedLimit = _parse('250');

  int _parse(String raw) {
    parseCount++;
    return int.parse(raw);
  }
}

String buildUrl({required String host, required String path, int? port}) {
  final portPart = port == null ? '' : ':$port';
  return 'https://$host$portPart$path';
}

// =============================================================================
// SECTION 8 — ENUMS  (basic & enhanced)
// =============================================================================
// Points covered:
//   * enum = a fixed set of named singletons; canonical + cheap equality
//   * `.name`, `.index`, `.values`, comparison, use in Sets/Maps
//   * safe parsing: `values.byName` (throws) vs `firstWhere(orElse:)` (safe)
//   * ENHANCED enum: fields + const constructor + methods + getters +
//     `implements` an interface
//   * exhaustive `switch` over enum values (compiler-checked)
//   * PERSIST `.name`, never `.index` (reordering silently corrupts data)
//   * enums cannot carry per-instance payload -> use a sealed class
// =============================================================================

void section8Enums() {
  section('SECTION 8 · ENUMS');

  topic('Basic enum essentials');
  const status = OrderStatus.shipped;
  show('value', status);
  show('.name', status.name);
  show('.index', status.index);
  show('OrderStatus.values', OrderStatus.values.map((e) => e.name).toList());
  show('values.length', OrderStatus.values.length);
  show('== is cheap identity', status == OrderStatus.shipped);
  show('identical()', identical(status, OrderStatus.shipped));

  topic('Enums in collections');
  final terminal = {OrderStatus.delivered, OrderStatus.cancelled};
  show('is shipped terminal?', terminal.contains(OrderStatus.shipped));
  final counts = <OrderStatus, int>{
    OrderStatus.pending: 4,
    OrderStatus.shipped: 2,
  };
  show('enum-keyed map', counts.map((k, v) => MapEntry(k.name, v)));

  topic('Safe parsing from a string');
  show("byName('pending')", OrderStatus.values.byName('pending'));
  try {
    OrderStatus.values.byName('bogus');
  } on ArgumentError catch (_) {
    show("byName('bogus')", 'ArgumentError — byName THROWS');
  }
  show('safe parse (valid)', parseStatus('delivered'));
  show('safe parse (invalid -> null)', parseStatus('nope'));

  topic('Exhaustive switch over an enum');
  for (final s in OrderStatus.values) {
    // Omit `_`/`default` deliberately: adding a value breaks compilation.
    final canCancel = switch (s) {
      OrderStatus.pending || OrderStatus.shipped => true,
      OrderStatus.delivered || OrderStatus.cancelled => false,
    };
    print('  ${s.name.padRight(10)} cancellable=$canCancel');
  }

  topic('ENHANCED enum — fields, const ctor, methods, interface');
  for (final role in Role.values) {
    print('  ${role.name.padRight(9)} '
        'level=${role.level} '
        'label="${role.label}" '
        'isStaff=${role.isStaff} '
        'describe="${role.describe()}"');
  }
  show('Role.admin.canAccess(Role.editor)', Role.admin.canAccess(Role.editor));
  show('Role.viewer.canAccess(Role.editor)', Role.viewer.canAccess(Role.editor));
  show('highest role', Role.values.reduce((a, b) => a.level >= b.level ? a : b));
  show('sorted by level',
      ([...Role.values]..sort((a, b) => a.level.compareTo(b.level)))
          .map((r) => r.name)
          .toList());

  topic('Serialization: persist `.name`, NOT `.index`');
  const stored = Role.editor;
  final json = {'role': stored.name}; // stable across reordering
  show('serialized', json);
  final restored = Role.values.byName(json['role'] as String);
  show('deserialized', restored);
  print('  If you stored `.index` and later reordered the enum, every');
  print('  persisted record would silently mean a different role.');

  topic('When an enum is NOT enough — payload per variant');
  print('  Enum values are compile-time singletons: they cannot carry');
  print('  per-instance data like an error message or a loaded list.');
  print('  For that use a sealed class hierarchy (see Section 9).');
}

/// Basic enum used across Sections 4 and 8.
enum OrderStatus { pending, shipped, delivered, cancelled }

OrderStatus? parseStatus(String raw) => OrderStatus.values
    .where((s) => s.name == raw.toLowerCase())
    .firstOrNull;

/// Interface an enhanced enum can implement.
abstract interface class Describable {
  String describe();
}

/// ENHANCED enum: fields, a `const` constructor, getters, methods, interface.
enum Role implements Describable {
  viewer(level: 1, label: 'Read only'),
  editor(level: 5, label: 'Can edit'),
  admin(level: 9, label: 'Full control');

  const Role({required this.level, required this.label});

  final int level;
  final String label;

  bool get isStaff => level >= 5;

  bool canAccess(Role required) => level >= required.level;

  @override
  String describe() => '${name.toUpperCase()} ($label)';
}

// =============================================================================
// SECTION 9 — RECORDS & PATTERNS  (Dart 3)
// =============================================================================
// Points covered:
//   * records: positional `(1, 'a')` and named `(id: 1)`; fields `$1` / `.id`
//   * records are immutable and have STRUCTURAL equality
//   * multiple return values without a throwaway class
//   * destructuring declarations, swap, list/map/object/record patterns
//   * `switch` with patterns, `if-case`, guards via `when`
//   * `if (json case {'k': int v})` = validate + bind in one step
//   * rest patterns, null-check/null-assert patterns, wildcard `_`
//   * sealed class + patterns = exhaustive, ADT-style state modelling
// =============================================================================

void section9RecordsAndPatterns() {
  section('SECTION 9 · RECORDS & PATTERNS');

  topic('Positional and named records');
  final point = (3, 4);
  final user = (id: 7, name: 'Ada', active: true);
  show('positional record', point);
  show('fields via \$1 / \$2', '${point.$1}, ${point.$2}');
  show('named record', user);
  show('fields by name', '${user.id} / ${user.name}');
  final mixed = (1, 'two', flag: true);
  show('mixed record', '${mixed.$1} ${mixed.$2} ${mixed.flag}');
  show('record type annotation', typedRecord());

  topic('Records are immutable with STRUCTURAL equality');
  show('(1, 2) == (1, 2)', (1, 2) == (1, 2));
  show('(a: 1) == (a: 1)', (a: 1) == (a: 1));
  show('(1, 2) == (2, 1)', (1, 2) == (2, 1));
  show('equal records share a hashCode', (1, 2).hashCode == (1, 2).hashCode);
  show('records work as Map keys', {(1, 2): 'origin-ish'}[(1, 2)]);
  // point.$1 = 5;   // COMPILE ERROR: record fields are final.

  topic('Multiple return values — no throwaway class');
  final stats = minMaxAverage([4, 8, 15, 16, 23, 42]);
  show('record result', stats);
  show('accessed by name', 'min=${stats.min} max=${stats.max}');
  // Destructure straight out of the call.
  final (min: lo, max: hi, average: avg) = minMaxAverage([1, 2, 3]);
  show('destructured', 'lo=$lo hi=$hi avg=${avg.toStringAsFixed(2)}');

  topic('Destructuring declarations & swap');
  final (x, y) = (10, 20);
  show('(x, y) = (10, 20)', 'x=$x y=$y');
  var first = 'A';
  var second = 'B';
  (first, second) = (second, first); // swap, no temp variable
  show('after swap', '$first$second');
  final [a, b, c] = [1, 2, 3]; // list pattern
  show('list destructuring', '$a $b $c');
  final {'host': host, 'port': port} = {'host': 'localhost', 'port': 8080};
  show('map destructuring', '$host:$port');

  topic('List patterns, rest patterns, wildcards');
  for (final input in [<int>[], [1], [1, 2], [1, 2, 3, 4, 5]]) {
    final description = switch (input) {
      [] => 'empty',
      [final only] => 'single: $only',
      [final f, final s] => 'pair: $f & $s',
      [final f, ..., final l] => 'many: starts $f ends $l',
    };
    print('  ${input.toString().padRight(15)} -> $description');
  }
  final [_, second2, ...rest] = [10, 20, 30, 40];
  show('wildcard + rest', 'second=$second2 rest=$rest');

  topic('Map patterns — validate + bind in ONE step');
  final payloads = <Map<String, dynamic>>[
    {'type': 'circle', 'r': 2.0},
    {'type': 'rect', 'w': 3.0, 'h': 4.0},
    {'type': 'circle', 'r': 'not a number'},
    {'type': 'hexagon'},
  ];
  for (final json in payloads) {
    final area = switch (json) {
      {'type': 'circle', 'r': final num r} => '${(3.14159 * r * r).toStringAsFixed(2)}',
      {'type': 'rect', 'w': final num w, 'h': final num h} => '${w * h}',
      {'type': final String t} => 'unsupported type "$t"',
      _ => 'malformed',
    };
    print('  ${json.toString().padRight(38)} -> $area');
  }
  print('  No containsKey chains, no manual casts, no null checks.');

  topic('if-case with a guard (`when`)');
  final Object response = {'status': 200, 'body': 'ok'};
  if (response case {'status': final int code, 'body': final String body}
      when code >= 200 && code < 300) {
    show('success branch', '$code / $body');
  }
  final Object badResponse = {'status': 500, 'body': 'boom'};
  if (badResponse case {'status': final int code} when code >= 500) {
    show('server error branch', code);
  }

  topic('Relational, logical and constant patterns');
  for (final value in [0, 7, 42, 99, 'text']) {
    final label = switch (value) {
      0 => 'zero (constant pattern)',
      42 => 'the answer',
      int n when n.isOdd => 'odd int $n (guard)',
      int() => 'even int',
      String s => 'string of length ${s.length}',
      _ => 'something else',
    };
    print('  ${value.toString().padRight(6)} -> $label');
  }

  topic('Object patterns — destructure class instances');
  final shapes = <Shape>[
    Circle(2),
    Rectangle(3, 4),
    Triangle(base: 6, height: 5),
  ];
  for (final shape in shapes) {
    // Exhaustive over a SEALED hierarchy: no `_` arm needed.
    final info = switch (shape) {
      Circle(radius: final r) => 'circle r=$r area=${shape.area.toStringAsFixed(2)}',
      Rectangle(width: final w, height: final h) when w == h => 'square $w',
      Rectangle(width: final w, height: final h) => 'rect ${w}x$h',
      Triangle(base: final base) => 'triangle base=$base area=${shape.area}',
    };
    print('  $info');
  }

  topic('Sealed class + patterns = exhaustive state modelling');
  final states = <ScreenState>[
    const Loading(),
    const Empty(),
    Loaded(['a', 'b', 'c']),
    const Failure('network down'),
  ];
  for (final state in states) {
    print('  ${render(state)}');
  }
  print('  Add a new subclass and every `switch` over ScreenState fails to');
  print('  compile until it is handled — that is the whole point.');

  topic('Null-check and null-assert patterns');
  final values = <int?>[1, null, 3];
  final onlyNonNull = <int>[];
  for (final v in values) {
    if (v case final int n) onlyNonNull.add(n); // null-check pattern
  }
  show('collected non-null', onlyNonNull);

  topic('Records vs classes — how to choose');
  print('  Record: anonymous, local, structural, zero ceremony (return pairs).');
  print('  Class : named type, invariants, methods, part of your public API.');
}

({int min, int max, double average}) minMaxAverage(List<int> values) {
  final sorted = [...values]..sort();
  final total = values.fold<int>(0, (acc, v) => acc + v);
  return (min: sorted.first, max: sorted.last, average: total / values.length);
}

(String label, int count) typedRecord() => ('items', 3);

/// Sealed hierarchy -> `switch` over it is exhaustively checked.
sealed class Shape {
  double get area;
}

class Circle extends Shape {
  final double radius;
  Circle(this.radius);
  @override
  double get area => 3.14159 * radius * radius;
}

class Rectangle extends Shape {
  final double width;
  final double height;
  Rectangle(this.width, this.height);
  @override
  double get area => width * height;
}

class Triangle extends Shape {
  final double base;
  final double height;
  Triangle({required this.base, required this.height});
  @override
  double get area => 0.5 * base * height;
}

/// The classic UI state ADT — what an enum cannot express.
sealed class ScreenState {
  const ScreenState();
}

class Loading extends ScreenState {
  const Loading();
}

class Empty extends ScreenState {
  const Empty();
}

class Loaded extends ScreenState {
  final List<String> items;
  const Loaded(this.items);
}

class Failure extends ScreenState {
  final String message;
  const Failure(this.message);
}

String render(ScreenState state) => switch (state) {
      Loading() => 'spinner',
      Empty() => 'nothing here yet',
      Loaded(items: final items) => 'list of ${items.length}: ${items.join(",")}',
      Failure(message: final m) => 'error banner: $m',
    };

// =============================================================================
// SECTION 10 — EXCEPTION HANDLING
// =============================================================================
// Points covered:
//   * `throw` sends an OBJECT (any object); message comes from `toString()`
//   * try / on T / catch (e, st) / finally; specific -> general ordering
//   * `finally` ALWAYS runs (even on rethrow / early return)
//   * `rethrow` preserves the original stack trace (`throw e` loses it)
//   * custom exception types with a meaningful `toString()`
//   * Error = programming bug (don't recover) vs Exception = expected, handle
//   * Dart has NO checked exceptions — nothing forces you to catch
//   * built-ins: FormatException, ArgumentError, StateError, RangeError,
//     UnsupportedError, AssertionError
//   * hot paths: prefer a `Result<T, E>` type over throw/catch
// =============================================================================

void section10ExceptionHandling() {
  section('SECTION 10 · EXCEPTION HANDLING');

  topic('throw sends an object; the message is its toString()');
  try {
    throw ValidationException('email', 'must contain @');
  } catch (e) {
    show('caught', e); // interpolation calls toString()
    show('runtimeType', e.runtimeType);
  }
  try {
    throw 'a bare String is throwable (but do not do this)';
  } catch (e) {
    show('caught a String', e);
  }

  topic('on / catch / finally, ordered specific -> general');
  for (final input in ['42', 'abc', '-1']) {
    try {
      final parsed = parsePositiveInt(input);
      print('  "$input" -> $parsed');
    } on FormatException catch (e) {
      print('  "$input" -> FormatException: ${e.message}');
    } on ArgumentError catch (e) {
      print('  "$input" -> ArgumentError: ${e.message}');
    } catch (e) {
      print('  "$input" -> unexpected: $e');
    } finally {
      // Always runs — success or failure.
    }
  }

  topic('catch (e, stackTrace)');
  try {
    throw StateError('something went wrong');
  } on StateError catch (e, stackTrace) {
    show('error', e.message);
    show('stack trace captured', stackTrace.toString().isNotEmpty);
    show('top frame', stackTrace.toString().split('\n').first.trim());
  }

  topic('finally always runs');
  show('finally on success', runWithFinally(shouldThrow: false));
  show('finally on failure', runWithFinally(shouldThrow: true));
  print('  Use it for cleanup: close files/sockets, stop timers, unlock.');

  topic('rethrow preserves the original stack trace');
  try {
    logThenRethrow();
  } catch (e) {
    show('outer handler received', e);
    print('  `rethrow` keeps the ORIGINAL throw site.');
    print('  `throw e;` would reset the stack trace to the catch block.');
  }

  topic('Custom exception hierarchy');
  final failures = <Object>[
    ValidationException('age', 'must be >= 0'),
    NotFoundException('User', 42),
    RowParseException(rowNumber: 3, reason: 'expected 4 columns, got 2'),
  ];
  for (final f in failures) {
    try {
      throw f;
    } on AppException catch (e) {
      print('  AppException -> $e  (code=${e.code})');
    } catch (e) {
      print('  other -> $e');
    }
  }

  topic('Error vs Exception');
  print('  Exception = expected, recoverable  -> catch and handle');
  print('              (FormatException, IOException, your AppExceptions)');
  print('  Error     = programming bug        -> let it crash, then FIX it');
  print('              (StateError, TypeError, RangeError, AssertionError)');
  try {
    final list = [1, 2, 3];
    print('  list[10] -> ${list[10]}');
  } on RangeError catch (e) {
    show('RangeError (a bug, not a user error)', e.message);
  }

  topic('Built-in exceptions you will actually hit');
  _tryPrint('int.parse("x")', () => int.parse('x'));
  _tryPrint('[].first', () => <int>[].first);
  _tryPrint('ArgumentError.value', () => throw ArgumentError.value(-1, 'age'));
  _tryPrint('UnsupportedError',
      () => const <int>[1].add(2));
  _tryPrint('checkNotNull', () => ArgumentError.checkNotNull(null, 'token'));

  topic('No checked exceptions — nothing forces a catch');
  print('  Dart will not warn you that a function can throw.');
  print('  Therefore: document throws, and catch at the boundary you can');
  print('  actually act on (never swallow with an empty `catch (_) {}`).');

  topic('Result<T, E> — errors as VALUES (hot paths, no stack unwinding)');
  for (final raw in ['10', 'oops']) {
    final result = tryParseInt(raw);
    final message = switch (result) {
      Ok(value: final v) => 'parsed $v',
      Err(error: final e) => 'failed: $e',
    };
    print('  "$raw" -> $message');
  }
  final chained = tryParseInt('21').map((v) => v * 2);
  show('Result.map', switch (chained) {
    Ok(value: final v) => v,
    Err(error: final e) => e,
  });
  show('getOrElse on an Err', tryParseInt('bad').getOrElse(0));
  print('  Throwing is expensive (stack capture). In tight loops and in');
  print('  domain layers, returning a Result is faster and self-documenting.');

  topic('Anti-patterns');
  print('  X  catch (_) {}                 // silent failure');
  print('  X  catch (e) { throw e; }        // stack trace destroyed');
  print('  X  catch (e) for control flow    // use if/else');
  print('  V  on SpecificType catch (e, st) { log(e, st); rethrow; }');
}

int parsePositiveInt(String raw) {
  final value = int.parse(raw); // throws FormatException on bad input
  if (value < 0) {
    throw ArgumentError.value(value, 'raw', 'must be positive');
  }
  return value;
}

String runWithFinally({required bool shouldThrow}) {
  final log = <String>[];
  try {
    log.add('try');
    if (shouldThrow) throw Exception('boom');
    log.add('no throw');
  } catch (_) {
    log.add('catch');
  } finally {
    log.add('finally');
  }
  return log.join(' -> ');
}

void logThenRethrow() {
  try {
    throw NotFoundException('Order', 99);
  } catch (e) {
    print('  inner: logging "$e" then rethrowing');
    rethrow; // keeps the original stack trace
  }
}

void _tryPrint(String label, void Function() action) {
  try {
    action();
    print('  ${label.padRight(22)} -> no throw');
  } catch (e) {
    print('  ${label.padRight(22)} -> ${e.runtimeType}');
  }
}

/// Base class so callers can catch the whole family with `on AppException`.
abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);

  String get code;

  @override
  String toString() => '$runtimeType($code): $message';
}

class ValidationException extends AppException {
  final String field;
  ValidationException(this.field, String reason) : super(reason);

  @override
  String get code => 'validation.$field';
}

class NotFoundException extends AppException {
  final String entity;
  final Object id;
  NotFoundException(this.entity, this.id) : super('$entity $id not found');

  @override
  String get code => 'not_found';
}

class RowParseException extends AppException {
  final int rowNumber;
  RowParseException({required this.rowNumber, required String reason})
      : super(reason);

  @override
  String get code => 'row.$rowNumber';

  @override
  String toString() => 'RowParseException(row $rowNumber): $message';
}

// --- Result<T, E>: errors as values ------------------------------------------

sealed class Result<T, E> {
  const Result();

  /// Transforms the success value, passing errors through untouched.
  Result<R, E> map<R>(R Function(T value) transform) => switch (this) {
        Ok<T, E>(value: final v) => Ok(transform(v)),
        Err<T, E>(error: final e) => Err(e),
      };

  T getOrElse(T fallback) => switch (this) {
        Ok<T, E>(value: final v) => v,
        Err<T, E>() => fallback,
      };
}

class Ok<T, E> extends Result<T, E> {
  final T value;
  const Ok(this.value);
}

class Err<T, E> extends Result<T, E> {
  final E error;
  const Err(this.error);
}

Result<int, String> tryParseInt(String raw) {
  final parsed = int.tryParse(raw);
  if (parsed == null) return Err('"$raw" is not an integer');
  return Ok(parsed);
}

// =============================================================================
// SECTION 11 — MINI PROJECTS (one condensed build per notes file)
// =============================================================================

void section11MiniProjects() {
  section('SECTION 11 · MINI PROJECTS (one per notes file)');

  topic('01 · Config loader (const defaults + late final lazy overrides)');
  final config = AppConfig();
  show('default (no load yet)', config.resolve('theme'));
  show('override source loaded?', AppConfig.loadCount > 0);
  show('override value (triggers load)', config.resolve('apiUrl'));
  show('override source loaded?', AppConfig.loadCount > 0);
  show('load ran exactly', '${AppConfig.loadCount} time(s)');

  topic('02 · Typed JSON firewall (no dynamic escapes the class)');
  final goodJson = <String, dynamic>{
    'id': 1,
    'name': 'Ada',
    'email': 'ada@example.com',
    'age': 36,
  };
  show('valid', User.fromJson(goodJson));
  for (final bad in <Json>[
    {'id': 'x', 'name': 'A', 'email': 'a@b.c'},
    {'id': 2, 'name': '', 'email': 'a@b.c'},
    {'id': 3, 'name': 'A', 'email': 'nope'},
  ]) {
    try {
      User.fromJson(bad);
    } on FormatException catch (e) {
      print('  rejected -> ${e.message}');
    }
  }

  topic('03 · Immutable geometry (operators + value equality)');
  const r1 = Rect(origin: Vector(0, 0), size: Vector(4, 3));
  final moved = r1.translate(const Vector(2, 2));
  show('rect', r1);
  show('area / perimeter', '${r1.area} / ${r1.perimeter}');
  show('translated', moved);
  show('value equality', r1 == const Rect(origin: Vector(0, 0), size: Vector(4, 3)));
  final rectSet =
      [r1, const Rect(origin: Vector(0, 0), size: Vector(4, 3))].toSet();
  show('two equal Rects collapse into one Set entry', rectSet.length);

  topic('04 · State-to-view mapper (exhaustive switch, no `_`)');
  for (final s in <ScreenState>[
    const Loading(),
    const Empty(),
    Loaded(['x', 'y']),
    const Failure('timeout'),
  ]) {
    print('  ${s.runtimeType.toString().padRight(9)} -> ${render(s)}');
  }

  topic('05 · Functional toolkit (pipe / compose / memoize / once)');
  final normalize = pipe<String>([
    (s) => s.trim(),
    (s) => s.replaceAll(RegExp(r'\s+'), ' '),
    (s) => s.toLowerCase(),
  ]);
  show('pipe', normalize('   Dart   IS   Fun  '));
  final fibMemo = memoize<int, int>(fib);
  show('memoize(fib)(20)', fibMemo(20));
  show('cached second call', fibMemo(20));

  topic('06 · Order analytics (Set / Map / fold / lazy pipeline)');
  final orders = <Order>[
    Order('o1', 'ada', 1200, OrderStatus.delivered),
    Order('o2', 'bob', 450, OrderStatus.pending),
    Order('o3', 'ada', 3000, OrderStatus.delivered),
    Order('o4', 'cleo', 800, OrderStatus.cancelled),
    Order('o5', 'bob', 2500, OrderStatus.shipped),
  ];
  final uniqueCustomers = orders.map((o) => o.customer).toSet();
  show('unique customers', uniqueCustomers);
  final revenueByStatus = orders.fold<Map<OrderStatus, int>>({}, (acc, o) {
    acc[o.status] = (acc[o.status] ?? 0) + o.amount;
    return acc;
  });
  show('revenue by status',
      revenueByStatus.map((k, v) => MapEntry(k.name, v)));
  final spendByCustomer = orders.fold<Map<String, int>>({}, (acc, o) {
    acc[o.customer] = (acc[o.customer] ?? 0) + o.amount;
    return acc;
  });
  final top = spendByCustomer.entries.reduce((a, b) => a.value >= b.value ? a : b);
  show('top customer', '${top.key} (${top.value})');
  // Lazy: nothing is filtered until we call toList() once.
  final largeOrders = orders.where((o) => o.amount >= 1000).map((o) => o.id);
  show('large orders (materialized once)', largeOrders.toList());

  topic('07 · Null-safe settings resolver (no `!` anywhere)');
  final settings = Settings(
    userOverrides: {'fontSize': '18'},
    remoteDefaults: {'theme': 'dark', 'fontSize': '14'},
  );
  show('fontSize (user override wins)', settings.fontSize);
  show('theme (remote default)', settings.theme);
  show('locale (hardcoded fallback)', settings.locale);
  show('expensive computed (lazy)', settings.computedCacheKey);
  show('same value, cached', settings.computedCacheKey);

  topic('08 · Permissions engine (enhanced enum, no magic strings)');
  for (final role in Role.values) {
    final allowed = Feature.values.where((f) => role.canAccess(f.minimumRole));
    print('  ${role.name.padRight(7)} -> ${allowed.map((f) => f.name).toList()}');
  }
  show('home label for admin', homeLabel(Role.admin));
  show('home label for viewer', homeLabel(Role.viewer));
  show('parse "editor"', Role.values.byName('editor'));

  topic('09 · JSON shape validator (map + constant patterns)');
  for (final raw in <Json>[
    {'shape': 'circle', 'r': 3},
    {'shape': 'rectangle', 'w': 4, 'h': 5},
    {'shape': 'triangle', 'b': 6, 'h': 2},
    {'shape': 'circle'},
    {'shape': 'dodecahedron'},
  ]) {
    final (ok, message, area) = validateShape(raw);
    print('  ${raw.toString().padRight(36)} ok=$ok '
        'area=${area?.toStringAsFixed(2) ?? "-"}  $message');
  }

  topic('10 · Robust CSV importer (per-row errors, finally, custom exception)');
  const csv = '''
id,name,amount
1,Coffee,250
2,Tea
3,Snack,abc
4,Juice,180
''';
  final (imported, errors) = importTransactions(csv);
  show('imported rows', imported);
  for (final e in errors) {
    print('  error -> $e');
  }
  print('\nAll 10 topics demonstrated. Read each notes file for the theory.');
}

// --- Mini project 01: config loader ------------------------------------------

class AppConfig {
  static int loadCount = 0;

  static const Map<String, String> _defaults = {
    'theme': 'light',
    'apiUrl': 'https://default.example.com',
    'locale': 'en',
  };

  /// Simulates an expensive load — runs only if `overrides` is ever read.
  late final Map<String, String> overrides = _loadOverrides();

  Map<String, String> _loadOverrides() {
    loadCount++;
    return {'apiUrl': 'https://prod.example.com'};
  }

  /// `theme` is a default, so this never touches `overrides`.
  String resolve(String key) {
    if (!_defaults.containsKey(key)) return 'unknown key';
    if (key == 'theme') return '${_defaults[key]} (default)';
    final override = overrides[key];
    return override == null
        ? '${_defaults[key]} (default)'
        : '$override (override)';
  }
}

// --- Mini project 02: typed JSON firewall ------------------------------------

class User {
  final int id;
  final String name;
  final String email;
  final int? age;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.age,
  });

  /// Every field is validated; no `dynamic` leaves this constructor.
  factory User.fromJson(Json json) {
    final rawId = json['id'];
    if (rawId is! int) {
      throw FormatException('id must be an int, got ${rawId.runtimeType}');
    }
    final rawName = json['name'];
    if (rawName is! String || rawName.isEmpty) {
      throw const FormatException('name must be a non-empty String');
    }
    final rawEmail = json['email'];
    if (rawEmail is! String || !rawEmail.contains('@')) {
      throw FormatException('email is invalid: "$rawEmail"');
    }
    final rawAge = json['age'];
    if (rawAge != null && rawAge is! int) {
      throw const FormatException('age must be an int when present');
    }
    return User(
      id: rawId,
      name: rawName,
      email: rawEmail,
      age: rawAge as int?,
    );
  }

  @override
  String toString() => 'User($id, $name, $email, age=${age ?? "-"})';
}

// --- Mini project 03: immutable geometry -------------------------------------

class Rect {
  final Vector origin;
  final Vector size;
  const Rect({required this.origin, required this.size});

  double get area => size.x * size.y;
  double get perimeter => 2 * (size.x + size.y);

  Rect translate(Vector delta) => Rect(origin: origin + delta, size: size);

  @override
  bool operator ==(Object other) =>
      other is Rect && other.origin == origin && other.size == size;

  @override
  int get hashCode => Object.hash(origin, size);

  @override
  String toString() => 'Rect(origin=$origin, size=$size)';
}

// --- Mini project 06: order analytics ---------------------------------------

class Order {
  final String id;
  final String customer;
  final int amount;
  final OrderStatus status;
  const Order(this.id, this.customer, this.amount, this.status);
}

// --- Mini project 07: null-safe settings ------------------------------------

class Settings {
  final Map<String, String> userOverrides;
  final Map<String, String> remoteDefaults;

  Settings({required this.userOverrides, required this.remoteDefaults});

  // user override -> remote default -> hardcoded default. No `!` used.
  String get theme =>
      userOverrides['theme'] ?? remoteDefaults['theme'] ?? 'light';

  int get fontSize =>
      int.tryParse(userOverrides['fontSize'] ?? '') ??
      int.tryParse(remoteDefaults['fontSize'] ?? '') ??
      12;

  String get locale =>
      userOverrides['locale'] ?? remoteDefaults['locale'] ?? 'en';

  /// Expensive, computed at most once.
  late final String computedCacheKey = '$theme-$fontSize-$locale'.hashCode
      .toRadixString(16);
}

// --- Mini project 08: permissions engine ------------------------------------

enum Feature {
  dashboard(Role.viewer),
  editArticle(Role.editor),
  manageUsers(Role.admin);

  const Feature(this.minimumRole);
  final Role minimumRole;
}

String homeLabel(Role role) => switch (role) {
      Role.viewer => 'Your feed',
      Role.editor => 'Editor desk',
      Role.admin => 'Control centre',
    };

// --- Mini project 09: JSON shape validator ----------------------------------

(bool ok, String message, double? area) validateShape(Json raw) =>
    switch (raw) {
      {'shape': 'circle', 'r': final num r} =>
        (true, 'circle ok', 3.14159 * r * r),
      {'shape': 'rectangle', 'w': final num w, 'h': final num h} =>
        (true, 'rectangle ok', (w * h).toDouble()),
      {'shape': 'triangle', 'b': final num b, 'h': final num h} =>
        (true, 'triangle ok', 0.5 * b * h),
      {'shape': final String s} => (false, 'invalid or incomplete "$s"', null),
      _ => (false, 'not a shape payload', null),
    };

// --- Mini project 10: robust CSV importer -----------------------------------

/// Parses a CSV, collecting per-row errors instead of aborting the import.
(int imported, List<RowParseException> errors) importTransactions(String csv) {
  final errors = <RowParseException>[];
  var imported = 0;
  final reader = FakeReader(csv);

  try {
    final rows = reader.readLines();
    for (var i = 1; i < rows.length; i++) {
      // skip the header
      final line = rows[i];
      if (line.trim().isEmpty) continue;
      try {
        final cells = line.split(',');
        if (cells.length != 3) {
          throw RowParseException(
            rowNumber: i + 1,
            reason: 'expected 3 columns, got ${cells.length}',
          );
        }
        final amount = int.tryParse(cells[2]);
        if (amount == null) {
          throw RowParseException(
            rowNumber: i + 1,
            reason: 'amount "${cells[2]}" is not an integer',
          );
        }
        imported++;
      } on RowParseException catch (e) {
        errors.add(e); // collect and keep importing valid rows
      }
    }
  } finally {
    reader.close(); // always released
  }

  return (imported, errors);
}

/// Stands in for a file/stream handle so `finally` has something to close.
class FakeReader {
  final String _content;
  bool isClosed = false;
  FakeReader(this._content);

  List<String> readLines() {
    if (isClosed) throw StateError('reader already closed');
    return _content.split('\n');
  }

  void close() => isClosed = true;
}
