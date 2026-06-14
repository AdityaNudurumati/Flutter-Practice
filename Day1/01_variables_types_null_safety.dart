// =============================================================================
// Day 1 · Part 1 — Variables, Types, and Null Safety
// Run: dart run Day1/01_variables_types_null_safety.dart
// =============================================================================
//
// Interview framing:
//   Dart is statically typed with type inference and SOUND null safety.
//   "Sound" means: if the type system says a value is non-null, it is GUARANTEED
//   non-null at runtime — the compiler enforces it, no NPEs sneak through.
// =============================================================================

void main() {
  variablesAndInference();
  finalVsConst();
  allDataTypes();
  nullableVsNonNullable();
  nullAwareOperators();
  lateKeyword();
}

// -----------------------------------------------------------------------------
// 1. var, final, const, and type inference
// -----------------------------------------------------------------------------
void variablesAndInference() {
  print('\n--- variables & inference ---');

  // `var` infers the type at compile time. Once inferred, it is FIXED.
  var count = 10; // inferred as int
  count = 20; // ok
  // count = 'hello'; // COMPILE ERROR — count is int, not dynamic.

  // Explicit type — same effect, clearer at API boundaries.
  int age = 30;

  // `dynamic` opts OUT of static checking. Avoid unless you truly need it
  // (JSON parsing, reflection-like code). It defers errors to runtime.
  dynamic anything = 5;
  anything = 'now a string'; // allowed — no compile-time safety
  anything = [1, 2, 3]; // also allowed

  // `Object?` is the safe alternative to dynamic: holds anything, but you must
  // check/cast before using type-specific members.
  Object? safeAny = 'text';

  print('count=$count age=$age anything=$anything safeAny=$safeAny');
}

// -----------------------------------------------------------------------------
// 2. final vs const  — a classic interview question
// -----------------------------------------------------------------------------
void finalVsConst() {
  print('\n--- final vs const ---');

  // final  : set ONCE, value computed at RUNTIME. Variable is immutable.
  final now = DateTime.now(); // runtime value — fine for final
  final String name = 'Aditya';

  // const  : COMPILE-TIME constant. Value must be known when you compile.
  const pi = 3.14159;
  // const t = DateTime.now(); // ERROR — not known at compile time.

  // const also makes the OBJECT deeply immutable and canonicalized:
  const a = [1, 2, 3];
  const b = [1, 2, 3];
  print('identical(const a, const b) = ${identical(a, b)}'); // true — same instance!

  final c = [1, 2, 3];
  final d = [1, 2, 3];
  print('identical(final c, final d) = ${identical(c, d)}'); // false — distinct

  print('now=$now name=$name pi=$pi');
}

// -----------------------------------------------------------------------------
// 3. All the core built-in data types
// -----------------------------------------------------------------------------
void allDataTypes() {
  print('\n--- all data types ---');

  // Numbers
  int whole = 42;
  double decimal = 3.14;
  num eitherOne = 7; // num is the supertype of int and double
  eitherOne = 7.5;

  // String — single or double quotes, supports interpolation and multiline.
  String greeting = 'Hello';
  String interpolated = '$greeting, world! 1+1 = ${1 + 1}';
  String multiline = '''
line one
line two''';

  // bool
  bool isReady = true;

  // Collections (covered in depth in file 03)
  List<int> list = [1, 2, 3];
  Set<String> set = {'a', 'b', ...['a']}; // duplicates dropped -> {'a','b'}
  Map<String, int> map = {'one': 1, 'two': 2};

  // Runes / symbols exist too but are rarely asked. Mention if pushed:
  //   Runes = Unicode code points in a string; Symbol = a name reference.

  print('int=$whole double=$decimal num=$eitherOne');
  print('string="$interpolated"');
  print('multiline=$multiline');
  print('bool=$isReady list=$list set=$set map=$map');
}

// -----------------------------------------------------------------------------
// 4. Nullable vs non-nullable types
// -----------------------------------------------------------------------------
void nullableVsNonNullable() {
  print('\n--- nullable vs non-nullable ---');

  // Non-nullable (default): MUST be assigned, can never hold null.
  int x = 5;
  // int y; print(y); // ERROR — must be initialized before use.

  // Nullable: add `?`. Can hold a value OR null.
  int? maybe;
  print('maybe starts as: $maybe'); // null
  maybe = 10;
  print('maybe now: $maybe');

  // You CANNOT call methods on a nullable without handling the null case:
  String? nick = _maybeName(); // String?, happens to be null at runtime
  // print(nick.length); // ERROR — nick might be null.
  print('nick length (null-aware): ${nick?.length}'); // null, no crash

  print('x=$x');
}

// -----------------------------------------------------------------------------
// 5. Null-aware operators:  ?.   ??   ??=   !
// -----------------------------------------------------------------------------
void nullAwareOperators() {
  print('\n--- null-aware operators ---');

  // _maybeName() returns String? so the analyzer can't "promote" it away —
  // that keeps these operator demos realistic (mirrors real nullable sources
  // like JSON fields or API responses).
  String? name = _maybeName();

  // ?.  — call member only if not null, else the whole expression is null.
  print('name?.length = ${name?.length}'); // null

  // ??  — provide a fallback when the left side is null.
  String display = name ?? 'Guest';
  print('display = $display'); // Guest

  // ??= — assign only if currently null.
  name ??= 'Default';
  print('name after ??= : $name'); // Default

  // !  — the "bang" / null assertion. Tells the compiler "trust me, not null."
  //      If you're WRONG at runtime, it throws. Use sparingly.
  String? definitelySet = _knownValue(); // type is String?, value is non-null
  String forced = definitelySet!; // safe here — we know it's set
  print('forced = $forced');

  // Demonstrate the throw (caught so the program continues):
  String? oops;
  try {
    print(oops!); // throws — oops is null
  } catch (e) {
    print('oops! threw: ${e.runtimeType}'); // _TypeError / Null check error
  }
}

// -----------------------------------------------------------------------------
// 6. The `late` keyword
// -----------------------------------------------------------------------------
//   Two uses:
//   (a) Non-nullable variable initialized AFTER declaration (you promise it
//       will be set before first read). Throws if you read it too early.
//   (b) LAZY initialization — the initializer runs only on first access.
// -----------------------------------------------------------------------------
void lateKeyword() {
  print('\n--- late ---');

  // (a) Deferred initialization of a non-nullable.
  late String description;
  // print(description); // would throw LateInitializationError if read here
  description = 'set later';
  print('description = $description');

  // (b) Lazy: expensiveSetup() runs only when `config` is first used.
  late final String config = _expensiveSetup();
  print('before first access to config');
  print('config = $config'); // _expensiveSetup() runs HERE
  print('config = $config'); // cached — does not run again
}

String _expensiveSetup() {
  print('  >> _expensiveSetup() actually ran');
  return 'computed-value';
}

// Returns null here, but its return TYPE is String? — so the analyzer treats
// callers as genuinely nullable (no flow promotion). Flip it to return a value
// to see the operators behave differently.
String? _maybeName() => null;

// Return TYPE is String? (so no flow promotion), but it always returns a value.
// That's the realistic case where `!` is justified: you know more than the type.
String? _knownValue() => 'value';
