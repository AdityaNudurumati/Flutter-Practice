// =============================================================================
// Day 3 · Part 2 — Encapsulation (private fields, getters, setters)
// Run: dart run Day3/02_encapsulation.dart
// =============================================================================
//
// Encapsulation = hide internal state behind a controlled interface so callers
// can't put the object in an invalid state.
//   _field   -> library-private (leading underscore). No public/private keyword.
//   get x    -> read access (often computed/derived).
//   set x    -> write access WITH validation.
// =============================================================================

void main() {
  final account = BankAccount();
  account.deposit(100);
  account.deposit(50);
  print('1. balance = ${account.balance}'); // 150  (read via getter)

  // account._balance = 999;  // NOT allowed from another library/file — private.

  account.withdraw(40);
  print('2. balance = ${account.balance}'); // 110

  // Setter with validation: rejects bad input instead of corrupting state.
  account.owner = 'Aditya';
  print('3. owner = ${account.owner}');
  try {
    account.owner = ''; // setter throws
  } catch (e) {
    print('4. rejected: $e');
  }

  // Computed getter — derived, read-only, no backing field.
  print('5. isOverdrawn? ${account.isOverdrawn}'); // false
}

class BankAccount {
  // Private state — the leading underscore makes these inaccessible outside
  // this library (file). Callers must go through the public API below.
  double _balance = 0;
  String _owner = 'Unknown';

  // GETTER: read-only public view of private state.
  double get balance => _balance;

  // GETTER + SETTER pair: controlled read/write of _owner with validation.
  String get owner => _owner;
  set owner(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError('owner name cannot be empty');
    }
    _owner = value;
  }

  // COMPUTED getter: no backing field, derived from other state.
  bool get isOverdrawn => _balance < 0;

  // METHODS expose safe operations rather than raw field access.
  void deposit(double amount) {
    if (amount <= 0) throw ArgumentError('deposit must be positive');
    _balance += amount;
  }

  void withdraw(double amount) {
    if (amount > _balance) throw StateError('insufficient funds');
    _balance -= amount;
  }
}
