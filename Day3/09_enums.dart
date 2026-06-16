// =============================================================================
// Day 3 · Part 9 — Enums (basic + enhanced)
// Run: dart run Day3/09_enums.dart
// =============================================================================
//
// An ENUM is a fixed set of named constant values. Great for representing
// state (loading/success/error), categories, modes — Flutter uses them for
// state management, MainAxisAlignment, TextAlign, etc.
// =============================================================================

void main() {
  // 1. Basic enum usage.
  Status status = Status.loading;
  print('1. $status'); // Status.loading
  print('1. name = ${status.name}  index = ${status.index}'); // loading  0

  // 2. Iterate all values & switch (exhaustive — compiler warns if you miss one).
  for (final s in Status.values) {
    describe(s);
  }

  // 3. Parse from a string (e.g. from JSON).
  final parsed = Status.values.byName('success');
  print('3. parsed = $parsed');

  // 4. ENHANCED enum (Dart 2.17+): fields, a const constructor, and methods.
  print('4. ${Planet.earth.label} has gravity ${Planet.earth.gravity}');
  for (final p in Planet.values) {
    print('   ${p.label}: ${p.weightOf(70).toStringAsFixed(1)} N for a 70kg body');
  }
}

// 1–3. Plain enum.
enum Status { loading, success, error }

void describe(Status s) {
  // switch as a statement; switch expressions also work for enums.
  final text = switch (s) {
    Status.loading => 'Please wait...',
    Status.success => 'Done!',
    Status.error => 'Something went wrong',
  };
  print('2. ${s.name} -> $text');
}

// 4. Enhanced enum: each value carries data and the enum has behavior.
enum Planet {
  mercury('Mercury', 3.7),
  earth('Earth', 9.8),
  jupiter('Jupiter', 24.8);

  final String label;
  final double gravity; // m/s^2
  const Planet(this.label, this.gravity);

  // A method available on every enum value.
  double weightOf(double massKg) => massKg * gravity;
}
