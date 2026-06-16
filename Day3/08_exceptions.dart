// =============================================================================
// Day 3 · Part 8 — Exception Handling
// Run: dart run Day3/08_exceptions.dart
// =============================================================================
//
// try / catch / on / finally + custom exceptions + rethrow.
//   Exception = anticipated, recoverable (bad input, network) -> catch it.
//   Error     = a bug (RangeError, type error) -> fix the code, don't catch.
// =============================================================================

void main() {
  // 1. Basic try/catch.
  try {
    final result = 10 ~/ 0; // integer divide-by-zero throws
    print(result);
  } catch (e) {
    print('1. caught: $e');
  }

  // 2. `on Type` for a specific exception; `catch (e, st)` to get the trace.
  try {
    int.parse('abc'); // throws FormatException
  } on FormatException catch (e) {
    print('2. format error: ${e.message}');
  } catch (e, st) {
    print('2. other: $e\n${st.toString().split('\n').first}');
  }

  // 3. finally ALWAYS runs — cleanup goes here.
  try {
    print('3. working...');
    throw 'boom';
  } catch (e) {
    print('3. caught $e');
  } finally {
    print('3. finally always runs');
  }

  // 4. Custom exception + multiple `on` clauses (most specific first).
  for (final age in [25, -5]) {
    try {
      print('4. valid age ${validateAge(age)}');
    } on InvalidAgeException catch (e) {
      print('4. ${e.message}');
    }
  }

  // 5. rethrow — log then propagate unchanged (keeps original stack trace).
  try {
    outer();
  } catch (e) {
    print('5. top-level saw: $e');
  }
}

class InvalidAgeException implements Exception {
  final String message;
  InvalidAgeException(this.message);
  @override
  String toString() => 'InvalidAgeException: $message';
}

int validateAge(int age) {
  if (age < 0) throw InvalidAgeException('age cannot be negative ($age)');
  return age;
}

void outer() {
  try {
    throw StateError('inner failure');
  } catch (e) {
    print('5. logging then rethrowing: $e');
    rethrow; // preserves the original error + stack trace
  }
}
