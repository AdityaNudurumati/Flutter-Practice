// =============================================================================
// Day 2 · Part 6 — Exception Handling
// Run: dart run Day2/06_exception_handling.dart
// =============================================================================
//
// try / catch / on / finally, throwing, custom exceptions, and `rethrow`.
//
// Exception vs Error:
//   Exception = a condition you can reasonably ANTICIPATE & recover from
//               (bad input, network failure). Catch these.
//   Error     = a programming BUG (RangeError, null check on null, type error).
//               You should FIX the code, not catch it.
// =============================================================================

void main() {
  // 1. Basic try/catch. `catch (e)` catches anything thrown.
  try {
    final result = 10 ~/ 0; // integer divide by zero -> throws
    print(result);
  } catch (e) {
    print('1. caught: $e');
  }

  // 2. `on Type` catches a SPECIFIC type; `catch (e, stack)` gives the trace.
  try {
    parseAge('abc');
  } on FormatException catch (e) {
    print('2. format problem: ${e.message}');
  } catch (e, stack) {
    print('2. other error: $e');
    print(stack.toString().split('\n').first); // first stack frame
  }

  // 3. Multiple `on` clauses — most specific first.
  for (final input in ['25', '-5', 'oops']) {
    try {
      print('3. valid age: ${parseAge(input)}');
    } on FormatException {
      print('3. "$input" is not a number');
    } on InvalidAgeException catch (e) {
      print('3. ${e.message}');
    }
  }

  // 4. finally ALWAYS runs (success, caught, or even uncaught) — cleanup goes here.
  try {
    print('4. doing work');
    throw 'boom';
  } catch (e) {
    print('4. caught $e');
  } finally {
    print('4. finally: always runs (close files, sockets, etc.)');
  }

  // 5. rethrow: handle partially (log) then let it propagate up unchanged.
  try {
    riskyOuter();
  } catch (e) {
    print('5. top-level saw: $e');
  }
}

// 3 & 5. A CUSTOM exception = any class implementing Exception. Carry context.
class InvalidAgeException implements Exception {
  final String message;
  InvalidAgeException(this.message);
  @override
  String toString() => 'InvalidAgeException: $message';
}

int parseAge(String input) {
  final n = int.parse(input); // throws FormatException on non-numbers
  if (n < 0) throw InvalidAgeException('age cannot be negative ($n)');
  return n;
}

void riskyOuter() {
  try {
    throw StateError('inner failure');
  } catch (e) {
    print('5. logging then rethrowing: $e');
    rethrow; // preserves the original error + stack trace
  }
}
