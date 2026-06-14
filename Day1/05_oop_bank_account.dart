// =============================================================================
// Day 1 · Part 5 — OOP in Dart: BankAccount -> SavingsAccount
// Run: dart run Day1/05_oop_bank_account.dart
// =============================================================================
//
// Concepts demonstrated (all common interview topics):
//   - Private fields with `_` (library-level privacy in Dart, not class-level)
//   - Named constructor + initializer list + assertions
//   - Getters (computed, read-only public API over a private field)
//   - Encapsulation: balance can only change through deposit/withdraw
//   - Inheritance with `extends`, `super(...)`, and method `@override`
//   - Polymorphism: a List<BankAccount> holding subclass instances
//   - Custom exception type for domain errors
// =============================================================================

void main() {
  print('--- BankAccount ---');
  final acc = BankAccount(owner: 'Aditya', openingBalance: 1000);
  acc.deposit(500);
  acc.withdraw(200);
  print(acc); // BankAccount(Aditya): balance=1300.00

  // Demonstrate validation via a caught exception.
  try {
    acc.withdraw(99999);
  } on InsufficientFundsException catch (e) {
    print('Caught: $e');
  }

  print('\n--- SavingsAccount ---');
  final savings = SavingsAccount(
    owner: 'Aditya',
    openingBalance: 1000,
    annualInterestRate: 0.06, // 6%
  );
  savings.deposit(500); // balance 1500
  savings.applyMonthlyInterest(); // +1500 * 0.06/12 = +7.50
  print(savings); // SavingsAccount(Aditya): balance=1507.50 @6.0% APR

  // Withdrawal rule overridden: savings enforces a minimum balance.
  try {
    savings.withdraw(1500); // would drop below the 100 minimum
  } on InsufficientFundsException catch (e) {
    print('Caught: $e');
  }

  print('\n--- Polymorphism ---');
  // Both types are BankAccounts; we can treat them uniformly.
  final List<BankAccount> portfolio = [acc, savings];
  final total = portfolio.fold<double>(0, (sum, a) => sum + a.balance);
  print('Total across ${portfolio.length} accounts: ${total.toStringAsFixed(2)}');
}

// -----------------------------------------------------------------------------
// Base class
// -----------------------------------------------------------------------------
class BankAccount {
  final String owner;

  // Private: only this library can touch `_balance` directly. The leading `_`
  // is what makes it private in Dart (privacy is per-FILE/library, not class).
  double _balance;

  // Named-parameter constructor with an initializer list + assertion guard.
  BankAccount({required this.owner, double openingBalance = 0})
      : assert(openingBalance >= 0, 'Opening balance cannot be negative'),
        _balance = openingBalance;

  // Getter: exposes balance read-only. No setter => callers can't assign it.
  double get balance => _balance;

  void deposit(double amount) {
    if (amount <= 0) {
      throw ArgumentError('Deposit must be positive, got $amount');
    }
    _balance += amount;
  }

  // `void withdraw` is overridable; subclasses can tighten the rules.
  void withdraw(double amount) {
    if (amount <= 0) {
      throw ArgumentError('Withdrawal must be positive, got $amount');
    }
    if (amount > _balance) {
      throw InsufficientFundsException(requested: amount, available: _balance);
    }
    _balance -= amount;
  }

  // toString override for friendly printing/debugging.
  @override
  String toString() => 'BankAccount($owner): balance=${_balance.toStringAsFixed(2)}';
}

// -----------------------------------------------------------------------------
// Subclass — adds interest behavior and a minimum-balance rule
// -----------------------------------------------------------------------------
class SavingsAccount extends BankAccount {
  final double annualInterestRate; // e.g. 0.06 == 6%
  static const double minimumBalance = 100;

  SavingsAccount({
    required super.owner, // forwards to BankAccount's `owner`
    super.openingBalance,
    required this.annualInterestRate,
  });

  // New behavior unique to savings.
  void applyMonthlyInterest() {
    final monthly = balance * (annualInterestRate / 12);
    deposit(monthly); // reuse parent logic
  }

  // Override withdraw to enforce the minimum balance rule, then defer to super.
  @override
  void withdraw(double amount) {
    if (balance - amount < minimumBalance) {
      throw InsufficientFundsException(
        requested: amount,
        available: balance - minimumBalance,
        reason: 'must keep minimum balance of $minimumBalance',
      );
    }
    super.withdraw(amount); // run the base validation + actual debit
  }

  @override
  String toString() =>
      'SavingsAccount($owner): balance=${balance.toStringAsFixed(2)} '
      '@${(annualInterestRate * 100).toStringAsFixed(1)}% APR';
}

// -----------------------------------------------------------------------------
// Custom exception — domain-specific, implements Exception
// -----------------------------------------------------------------------------
class InsufficientFundsException implements Exception {
  final double requested;
  final double available;
  final String? reason;

  InsufficientFundsException({
    required this.requested,
    required this.available,
    this.reason,
  });

  @override
  String toString() {
    final base = 'InsufficientFunds: requested ${requested.toStringAsFixed(2)}, '
        'available ${available.toStringAsFixed(2)}';
    return reason == null ? base : '$base ($reason)';
  }
}
