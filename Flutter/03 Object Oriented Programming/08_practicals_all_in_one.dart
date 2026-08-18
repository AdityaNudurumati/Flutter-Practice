// =============================================================================
// 03 · OBJECT ORIENTED PROGRAMMING — ALL-IN-ONE PRACTICAL FILE
// =============================================================================
// Runnable companion to the 7 notes files in this folder. Every "Revision
// Notes" bullet from each file has a live, printable demonstration here.
//
//   Run:      fvm dart run     "08_practicals_all_in_one.dart"
//   Analyze:  fvm dart analyze "08_practicals_all_in_one.dart"
//
//   Asserts are OFF under a plain `dart run`. Two demos below rely on them,
//   so prefer:  fvm dart run --enable-asserts "08_practicals_all_in_one.dart"
//
// Map of sections -> source notes file:
//   1  Classes & Objects ............... 01_classes_and_objects.md
//   2  Encapsulation ................... 02_encapsulation.md
//   3  Inheritance ..................... 03_inheritance.md
//   4  Polymorphism .................... 04_polymorphism.md
//   5  Abstraction & Interfaces ........ 05_abstraction_and_interfaces.md
//   6  Composition & Relationships ..... 06_composition_and_relationships.md
//   7  Equality & Copying .............. 07_equality_and_copying.md
//   8  Mini Projects (one per notes file)
//
// This module is about DESIGN JUDGEMENT, so several demos deliberately show a
// BAD design next to the GOOD one and prove the difference at runtime.
// =============================================================================

void main() {
  section1ClassesAndObjects();
  section2Encapsulation();
  section3Inheritance();
  section4Polymorphism();
  section5AbstractionAndInterfaces();
  section6CompositionAndRelationships();
  section7EqualityAndCopying();
  section8MiniProjects();
}

// -----------------------------------------------------------------------------
// Output helpers.
// -----------------------------------------------------------------------------
void section(String title) => print('\n${'=' * 74}\n$title\n${'=' * 74}');

void topic(String title) {
  final pad = 60 - title.length;
  print('\n-- $title ${'-' * (pad < 3 ? 3 : pad)}');
}

void show(String label, Object? value) => print('  $label: $value');
void note(String text) => print('  $text');

/// Shared trace buffer for the construction-order demos.
final List<String> _trace = [];
String _traceStep(String label) {
  _trace.add(label);
  return label;
}

// =============================================================================
// SECTION 1 — CLASSES & OBJECTS
// =============================================================================
// Points covered:
//   * class = blueprint/type; object = an instance on the HEAP
//   * a variable holds a REFERENCE, never the object itself
//   * instance fields (one set per object) vs `static` (one per CLASS)
//   * `this` — disambiguation, and returning the instance for chaining
//   * getters/setters give fields and computed values one uniform syntax
//   * method vs getter: verb-with-work vs cheap noun-like access
//   * an object is collectible once UNREACHABLE
//   * always override `toString()` for debuggable output
// =============================================================================

void section1ClassesAndObjects() {
  section('SECTION 1 · CLASSES & OBJECTS');

  topic('Class vs object');
  final a = Track(title: 'Blue Train', seconds: 634);
  final b = Track(title: 'Giant Steps', seconds: 285);
  show('object a', a);
  show('object b', b);
  show('same class, different objects', a.runtimeType == b.runtimeType);
  note('`Track` is the TYPE. `a` and `b` are two separate heap objects.');

  topic('Variables hold REFERENCES (reference semantics)');
  final original = Playlist('Jazz');
  final alias = original; // copies the REFERENCE, not the object
  alias.add(a);
  show('added through `alias`, visible through `original`', original.length);
  show('identical(original, alias)', identical(original, alias));
  final separate = Playlist('Jazz');
  show('identical(original, separate)', identical(original, separate));
  note('Assignment never copies an object. Two names, one object.');
  note('This is why passing an object to a function lets that function mutate it.');

  topic('Instance fields vs static members');
  show('a.seconds (per object)', a.seconds);
  show('b.seconds (per object)', b.seconds);
  show('Playlist.instanceCount (per CLASS)', Playlist.instanceCount);
  Playlist('Rock');
  show('after creating one more', Playlist.instanceCount);
  show('static constant', Playlist.maxTracks);
  show('static method', Playlist.formatDuration(3725));
  note('Static members belong to the class: `Playlist.instanceCount`, never');
  note('`myPlaylist.instanceCount`. They cannot see `this`.');

  topic('`this` — disambiguation and chaining');
  final chained = Playlist('Chained')
      .addAndReturn(a)
      .addAndReturn(b)
      .rename('Chained (renamed)');
  show('fluent chain via `return this`', chained);
  note('`this.title = title` disambiguates a parameter that shadows a field.');
  note('Dart also lets you skip it entirely with `Track({required this.title})`.');

  topic('Getters vs methods');
  final playlist = Playlist('Coltrane')
    ..add(a)
    ..add(b);
  show('length (getter — cheap, noun)', playlist.length);
  show('totalSeconds (getter — computed)', playlist.totalSeconds);
  show('formattedDuration (getter — derived)', playlist.formattedDuration);
  show('isEmpty (getter)', playlist.isEmpty);
  show('longestTrack() (method — does work)', playlist.longestTrack());
  note('Getter: cheap, no side effects, reads like a property.');
  note('Method: does work, may fail, takes arguments, reads like a verb.');

  topic('Computed getter stays in sync automatically');
  show('before adding', playlist.totalSeconds);
  playlist.add(Track(title: 'Naima', seconds: 265));
  show('after adding (nothing to recompute manually)', playlist.totalSeconds);
  note('Storing `totalSeconds` as a field would let it go STALE. Derive it.');

  topic('Object lifecycle');
  note('1. `Playlist(...)` allocates on the heap and runs the constructor.');
  note('2. The object lives while ANY reference chain reaches it from a root');
  note('   (a local on the stack, a static field, a live closure).');
  note('3. When the last reference disappears, it becomes garbage. The GC');
  note('   reclaims it at some later, unspecified time.');
  note('There is no destructor and no `delete` — see 02 Advanced Dart / GC.');
  var temporary = Playlist('Short lived');
  show('reachable', temporary.title);
  temporary = Playlist('Replacement'); // the first object is now unreachable
  show('previous object is now garbage; current is', temporary.title);

  topic('toString()');
  show('with an override', a);
  show('without an override', NoToString());
  note('Default `toString` prints "Instance of \'ClassName\'" — useless in a');
  note('log or a test failure. Override it on every domain class.');
}

class Track {
  final String title;
  final int seconds;

  Track({required this.title, required this.seconds});

  @override
  String toString() => 'Track($title, ${Playlist.formatDuration(seconds)})';
}

class Playlist {
  // Static: ONE copy for the whole class.
  static int instanceCount = 0;
  static const int maxTracks = 500;

  String title;
  final List<Track> _items = [];

  Playlist(this.title) {
    instanceCount++;
  }

  // --- getters: cheap, derived, noun-like ---
  int get length => _items.length;
  bool get isEmpty => _items.isEmpty;
  int get totalSeconds => _items.fold(0, (sum, t) => sum + t.seconds);
  String get formattedDuration => formatDuration(totalSeconds);
  List<Track> get items => List.unmodifiable(_items);

  // --- methods: do work, may take arguments ---
  void add(Track track) {
    if (_items.length >= maxTracks) {
      throw StateError('playlist is full');
    }
    _items.add(track);
  }

  /// `return this` enables fluent chaining.
  Playlist addAndReturn(Track track) {
    add(track);
    return this;
  }

  Playlist rename(String newTitle) {
    // `this.title` disambiguates the field from the parameter name below.
    title = newTitle;
    return this;
  }

  Track? longestTrack() {
    if (_items.isEmpty) return null;
    var longest = _items.first;
    for (final track in _items.skip(1)) {
      if (track.seconds > longest.seconds) longest = track;
    }
    return longest;
  }

  static String formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  String toString() => 'Playlist("$title", $length tracks, $formattedDuration)';
}

class NoToString {}

// =============================================================================
// SECTION 2 — ENCAPSULATION
// =============================================================================
// Points covered:
//   * `_member` is LIBRARY-private (per file / `part`), not class-private
//   * getter-only field = read-only from outside
//   * a validating setter, or no setter at all
//   * invariants protected by constructor validation + method-only mutation
//   * return `List.unmodifiable` so callers cannot reach in
//   * keep the public surface minimal
//   * avoid the anemic model: put behaviour WITH the data
// =============================================================================

void section2Encapsulation() {
  section('SECTION 2 · ENCAPSULATION');

  topic('`_` privacy is per-LIBRARY (per file), not per class');
  final account = BankAccount(owner: 'Ada', openingBalance: 1000);
  show('public getter', account.balance);
  show('another class in the SAME file reads _balance',
      AccountInspector().rawBalance(account));
  note('`_balance` is private to this FILE. Move AccountInspector to another');
  note('file and it stops compiling. Dart has no `private`/`protected` keyword.');

  topic('Read-only exposure: getter, no setter');
  show('account.balance', account.balance);
  note('`account.balance = 999999;` does NOT compile — there is no setter.');
  note('State changes only through deposit()/withdraw(), which validate.');

  topic('Invariants enforced at construction');
  for (final (owner, opening) in const [('Bob', 500), ('', 500), ('Cleo', -50)]) {
    try {
      final created = BankAccount(owner: owner, openingBalance: opening);
      print('  created  -> $created');
    } on DomainException catch (e) {
      print('  rejected -> $e');
    }
  }
  note('An object can never exist in an invalid state — not even briefly.');

  topic('Invariants enforced on every mutation');
  show('start', account.balance);
  account.deposit(500);
  show('after deposit(500)', account.balance);
  for (final (label, action) in <(String, void Function())>[
    ('withdraw(200)', () => account.withdraw(200)),
    ('withdraw(999999)', () => account.withdraw(999999)),
    ('withdraw(-5)', () => account.withdraw(-5)),
    ('deposit(0)', () => account.deposit(0)),
  ]) {
    try {
      action();
      print('  ${label.padRight(18)} -> ok, balance=${account.balance}');
    } on DomainException catch (e) {
      print('  ${label.padRight(18)} -> ${e.message}');
    }
  }
  show('final balance', account.balance);
  show('immutable audit trail', account.history);

  topic('Validating setter vs no setter');
  final profile = UserProfile(email: 'ada@example.com');
  profile.email = 'grace@navy.mil'; // goes through the validating setter
  show('after a valid set', profile.email);
  try {
    profile.email = 'not-an-email';
  } on DomainException catch (e) {
    show('invalid set rejected', e.message);
  }
  show('email unchanged', profile.email);
  note('If a setter cannot validate meaningfully, do not write one — expose an');
  note('intention-revealing method like `changeEmail(newEmail, confirmation)`.');

  topic('Never hand out your internal collection');
  final leaky = LeakyCart(['apple']);
  leaky.items.add('free stuff'); // compiles: caller mutates private state
  show('leaky cart after outside mutation', leaky.items);
  final safe = SafeCart(['apple']);
  try {
    safe.items.add('free stuff');
  } on UnsupportedError catch (_) {
    show('safe cart rejects outside mutation', 'UnsupportedError');
  }
  safe.addItem('pear'); // the sanctioned path
  show('safe cart via its own API', safe.items);
  note('Copy on the way IN (`List.of`), freeze on the way OUT');
  note('(`List.unmodifiable`). A `final List` field is still mutable.');

  topic('Anemic model vs rich model');
  final anemic = AnemicOrder(items: [30, 20], discountPercent: 10);
  show('anemic: caller must know the rules',
      AnemicOrderService.total(anemic));
  note('An anemic class is a bag of public fields; the RULES live elsewhere, so');
  note('every caller can compute the total differently (or wrongly).');
  final rich = RichOrder(items: [30, 20])..applyDiscount(10);
  show('rich: the object owns its rules', rich.total);
  show('rich: rejects an impossible discount', rich.tryApplyDiscount(150));
  note('Rule of thumb: if a class has only getters and setters, its behaviour');
  note('has leaked somewhere it cannot be protected.');

  topic('Keep the public surface minimal');
  note('Every public member is a promise you must keep. Start private and');
  note('promote deliberately — widening an API is easy, narrowing breaks callers.');
}

class DomainException implements Exception {
  final String message;
  const DomainException(this.message);
  @override
  String toString() => 'DomainException: $message';
}

class BankAccount {
  final String owner;
  int _balance; // private: the invariant lives here
  final List<String> _history = [];

  BankAccount({required this.owner, required int openingBalance})
      : _balance = openingBalance {
    if (owner.trim().isEmpty) {
      throw const DomainException('owner must not be empty');
    }
    if (openingBalance < 0) {
      throw const DomainException('opening balance cannot be negative');
    }
    _history.add('opened with $openingBalance');
  }

  /// Read-only to the outside world.
  int get balance => _balance;
  List<String> get history => List.unmodifiable(_history);

  void deposit(int amount) {
    if (amount <= 0) {
      throw const DomainException('deposit must be positive');
    }
    _balance += amount;
    _history.add('deposit $amount');
  }

  /// `protected`-by-convention hook so subclasses can tighten the rule.
  /// Dart has no `protected`, so this is documented, not enforced.
  void assertCanWithdraw(int amount) {
    if (amount <= 0) {
      throw const DomainException('withdrawal must be positive');
    }
    if (amount > _balance) {
      throw DomainException('insufficient funds: balance $_balance, asked $amount');
    }
  }

  void withdraw(int amount) {
    assertCanWithdraw(amount);
    _balance -= amount;
    _history.add('withdraw $amount');
  }

  /// Subclasses adjust the balance through this, never by touching `_balance`
  /// arithmetic scattered across the hierarchy.
  void creditInternal(int amount, String reason) {
    _balance += amount;
    _history.add(reason);
  }

  @override
  String toString() => '$runtimeType($owner, balance=$_balance)';
}

/// Same library -> `_balance` is visible. This is the point of the demo.
class AccountInspector {
  int rawBalance(BankAccount account) => account._balance;
}

class UserProfile {
  String _email;

  UserProfile({required String email}) : _email = email {
    _validate(email);
  }

  String get email => _email;

  /// Validating setter: the object refuses to become invalid.
  set email(String value) {
    _validate(value);
    _email = value;
  }

  static void _validate(String value) {
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
      throw DomainException('"$value" is not a valid email');
    }
  }
}

class LeakyCart {
  final List<String> items; // public + mutable = no encapsulation
  LeakyCart(this.items);
}

class SafeCart {
  final List<String> _items;
  SafeCart(List<String> items) : _items = List.of(items); // copy IN

  List<String> get items => List.unmodifiable(_items); // freeze OUT
  void addItem(String item) => _items.add(item);
}

/// Anemic: data with no behaviour. The rules live in a service.
class AnemicOrder {
  List<int> items;
  int discountPercent;
  AnemicOrder({required this.items, required this.discountPercent});
}

class AnemicOrderService {
  static int total(AnemicOrder order) {
    final sum = order.items.fold(0, (a, b) => a + b);
    return sum - (sum * order.discountPercent ~/ 100);
  }
}

/// Rich: the object owns its data AND the rules that guard it.
class RichOrder {
  final List<int> _items;
  int _discountPercent = 0;

  RichOrder({required List<int> items}) : _items = List.of(items);

  int get subtotal => _items.fold(0, (a, b) => a + b);
  int get total => subtotal - (subtotal * _discountPercent ~/ 100);

  void applyDiscount(int percent) {
    if (percent < 0 || percent > 100) {
      throw DomainException('discount must be 0-100, got $percent');
    }
    _discountPercent = percent;
  }

  String tryApplyDiscount(int percent) {
    try {
      applyDiscount(percent);
      return 'applied $percent%';
    } on DomainException catch (e) {
      return e.message;
    }
  }
}

// =============================================================================
// SECTION 3 — INHERITANCE
// =============================================================================
// Points covered:
//   * `extends` gives single inheritance plus `super`
//   * constructor chaining: `super(...)` and the `super.field` shorthand
//   * initialization ORDER: subclass initializers -> super constructor ->
//     subclass body
//   * `@override` to specialize; `super.method()` to EXTEND base behaviour
//   * abstract base class = shared implementation + required holes
//   * subclasses must keep the base contract (LSP — Section 4)
//   * the fragile base class problem; prefer composition; class modifiers
// =============================================================================

void section3Inheritance() {
  section('SECTION 3 · INHERITANCE');

  topic('Constructor chaining and initialization ORDER');
  _trace.clear();
  TraceDerived();
  for (final step in _trace) {
    note('  $step');
  }
  note('');
  note('So the real order is:');
  note('  1. the SUBCLASS initializer list, in SOURCE order (which is why the');
  note('     super() ARGUMENTS are evaluated at their written position)');
  note('  2. the SUPERCLASS field initializers');
  note('  3. the SUPERCLASS constructor body');
  note('  4. the SUBCLASS constructor body');
  note('The base is fully built before the subclass body runs — and `this` is');
  note('illegal in an initializer list because the object does not exist yet.');

  final savings = SavingsAccount(
    owner: 'Ada',
    openingBalance: 1000,
    minimumBalance: 100,
  );
  show('constructed', savings);

  topic('`super.field` shorthand');
  final checking = CheckingAccount(
    owner: 'Bob',
    openingBalance: 500,
    overdraftLimit: 200,
  );
  show('built with super.owner / super.openingBalance', checking);
  note('`CheckingAccount({required super.owner, ...})` forwards straight to the');
  note('base constructor — no `super(owner: owner)` boilerplate.');

  topic('Inherited behaviour comes for free');
  savings.deposit(500);
  show('deposit() inherited from BankAccount', savings.balance);
  show('toString() uses runtimeType, so it adapts', '$savings');

  topic('@override to SPECIALIZE, super.method() to EXTEND');
  show('savings balance', savings.balance);
  try {
    savings.withdraw(1450); // would drop below the minimum balance
  } on DomainException catch (e) {
    show('SavingsAccount tightened the rule', e.message);
  }
  savings.withdraw(400);
  show('withdraw(400) allowed', savings.balance);
  note('SavingsAccount.assertCanWithdraw calls super first (reusing the base');
  note('validation), THEN adds its own minimum-balance rule.');

  show('CheckingAccount allows overdraft', checking.balance);
  checking.withdraw(600); // 500 balance + 200 overdraft
  show('after withdraw(600)', checking.balance);
  try {
    checking.withdraw(500);
  } on DomainException catch (e) {
    show('but not beyond the limit', e.message);
  }

  topic('Abstract base class: shared code + required holes');
  final accounts = <BankAccount>[savings, checking];
  for (final acct in accounts) {
    print('  ${acct.runtimeType.toString().padRight(16)} '
        'balance=${acct.balance.toString().padLeft(5)} '
        'interest=${describeInterest(acct)}');
  }
  note('`InterestBearing` declares WHAT (applyInterest) without saying HOW.');

  topic('Interest applied polymorphically');
  final before = savings.balance;
  savings.applyInterest();
  show('savings after applyInterest()', '$before -> ${savings.balance}');

  topic('The fragile base class problem');
  final fragile = FragileCounter();
  fragile.addAll([1, 2, 3]);
  show('base counts each add: expected 3, got', fragile.count);
  note('DoubleCountingCounter overrides add() AND addAll(); the base addAll()');
  note('already calls add() per element, so the count is double-counted:');
  final broken = DoubleCountingCounter();
  broken.addAll([1, 2, 3]);
  show('subclass double-counts: expected 3, got', broken.count);
  note('Nothing in the subclass is "wrong" — the BASE changed the rules by');
  note('implementing addAll in terms of add. That is the fragile base class:');
  note('a subclass depends on the base\'s internal call graph, which is not');
  note('part of its published contract.');
  note('Fixes: document self-calls, make them final/private, or use COMPOSITION');
  note('(Section 6) so there is no inherited call graph to depend on.');

  topic('Deep hierarchies rot');
  note('A > B > C > D: a change in A can break D in a way nobody predicts, and');
  note('you must read four files to understand one object. Keep chains at 1-2');
  note('levels; reach for composition or an interface instead.');
  note('Rule of thumb: inherit only for a true IS-A with a stable contract.');

  topic('Class modifiers control who may extend you');
  note('abstract   : cannot be instantiated; may hold abstract members');
  note('base       : may be extended, NEVER implemented (protects your impl)');
  note('final      : may not be extended OR implemented — fully closed');
  note('interface  : may be implemented, NEVER extended (contract only)');
  note('sealed     : implicitly abstract + final; subtypes must live in THIS');
  note('             library, which is what makes `switch` exhaustive');
  note('Default (no modifier): anyone can extend AND implement your class.');
  show('sealed subtype handled exhaustively', describeShape(const Circle(2)));
}

/// Takes `Object`, not `BankAccount`, on purpose: Dart only promotes when the
/// tested type is a SUBTYPE of the variable's declared type. `InterestBearing`
/// is unrelated to `BankAccount`, so `account is InterestBearing` would not
/// promote and `account.annualRatePercent` would not compile. Widening the
/// parameter to `Object` makes the promotion legal.
String describeInterest(Object account) =>
    account is InterestBearing ? '${account.annualRatePercent}%' : 'none';

/// Exists purely to trace construction order. Every step appends to [_trace].
class TraceBase {
  final String forwarded;

  /// A field initializer belonging to the BASE class.
  final String baseField = _traceStep('base field initializer');

  TraceBase(this.forwarded) {
    _trace.add('base constructor BODY');
  }
}

class TraceDerived extends TraceBase {
  /// A field initializer belonging to the SUBCLASS.
  final String derivedField;

  TraceDerived()
      // Initializer-list entries are evaluated in SOURCE order, so this line
      // runs before the super() arguments below it.
      : derivedField = _traceStep('subclass initializer list entry'),
        super(_traceStep('super() ARGUMENTS evaluated')) {
    _trace.add('subclass constructor BODY');
  }
}

/// Contract for accounts that grow — implemented by SavingsAccount only.
abstract interface class InterestBearing {
  double get annualRatePercent;
  void applyInterest();
}

class SavingsAccount extends BankAccount implements InterestBearing {
  final int minimumBalance;

  @override
  final double annualRatePercent;

  SavingsAccount({
    required super.owner,
    required int openingBalance,
    required this.minimumBalance,
    this.annualRatePercent = 4.5,
  })  : assert(minimumBalance >= 0, 'minimum balance cannot be negative'),
        super(openingBalance: openingBalance);

  /// Specialize: reuse the base rule, then add our own.
  @override
  void assertCanWithdraw(int amount) {
    super.assertCanWithdraw(amount); // base validation first
    if (balance - amount < minimumBalance) {
      throw DomainException(
        'withdrawal would drop balance below the $minimumBalance minimum',
      );
    }
  }

  @override
  void applyInterest() {
    final interest = (balance * annualRatePercent / 100).round();
    creditInternal(interest, 'interest $interest');
  }
}

class CheckingAccount extends BankAccount {
  final int overdraftLimit;

  CheckingAccount({
    required super.owner,
    required super.openingBalance,
    required this.overdraftLimit,
  });

  /// Loosen the base rule — allowed here because the base contract is
  /// "reject withdrawals you cannot cover", and an overdraft IS cover.
  @override
  void assertCanWithdraw(int amount) {
    if (amount <= 0) {
      throw const DomainException('withdrawal must be positive');
    }
    if (amount > balance + overdraftLimit) {
      throw DomainException(
        'exceeds overdraft: balance $balance + limit $overdraftLimit',
      );
    }
  }
}

/// The base implements addAll IN TERMS OF add — an internal detail subclasses
/// end up depending on.
class FragileCounter {
  int count = 0;
  void add(int value) => count++;
  void addAll(List<int> values) {
    for (final value in values) {
      add(value); // self-call: invisible from the outside
    }
  }
}

class DoubleCountingCounter extends FragileCounter {
  @override
  void add(int value) {
    super.add(value);
  }

  @override
  void addAll(List<int> values) {
    count += values.length; // reasonable-looking optimisation...
    super.addAll(values); // ...but super.addAll calls add() again
  }
}

// =============================================================================
// SECTION 4 — POLYMORPHISM
// =============================================================================
// Points covered:
//   * dynamic dispatch: the RUNTIME type picks the method body
//   * the compiler checks against the STATIC type
//   * program to the abstraction, not the concrete class
//   * Liskov Substitution: no stronger preconditions, no weaker
//     postconditions, no surprise throws
//   * a live LSP violation, and the redesign that fixes it
//   * replace `is`/`as` chains with a polymorphic method or Strategy
// =============================================================================

void section4Polymorphism() {
  section('SECTION 4 · POLYMORPHISM');

  topic('Dynamic dispatch — one call site, many behaviours');
  final methods = <PaymentMethod>[
    const CardPayment(last4: '4242', network: 'Visa'),
    const UpiPayment(vpa: 'ada@upi'),
    WalletPayment(balancePaise: 150000),
  ];
  for (final method in methods) {
    // `method` is statically a PaymentMethod; the body that runs is chosen by
    // the RUNTIME type. No `if`, no `switch`, no casts.
    print('  ${method.label.padRight(18)} -> ${method.charge(50000)}');
  }

  topic('Static type checks, runtime type dispatches');
  final PaymentMethod any = const CardPayment(last4: '1111', network: 'Amex');
  show('static type', 'PaymentMethod');
  show('runtime type', any.runtimeType);
  show('dispatched to', any.charge(1000));
  note('`any.network` would NOT compile: the STATIC type is PaymentMethod.');
  note('The compiler guarantees the member exists; the VM picks the body.');

  topic('Program to the abstraction: Checkout knows nothing concrete');
  final checkout = Checkout();
  show('total fees across mixed methods', checkout.chargeAll(methods, 50000));
  note('Checkout has no `is`, no `as`, and no switch over payment types.');

  topic('Open/Closed: add a type, change zero existing code');
  final extended = <PaymentMethod>[...methods, const NetBankingPayment(bank: 'HDFC')];
  show('same Checkout, new payment type', checkout.chargeAll(extended, 50000));
  note('NetBankingPayment was added AFTER Checkout was written. Checkout did');
  note('not change — that is polymorphism buying you extensibility.');

  topic('LSP VIOLATION — the classic mutable Square/Rectangle');
  note('Contract of MutableRectangle: setting width leaves height alone.');
  final rect = MutableRectangle(width: 2, height: 3);
  show('stretch(rectangle) -> area', stretch(rect));
  final square = MutableSquare(side: 2); // IS-A MutableRectangle... supposedly
  show('stretch(square)    -> area', stretch(square));
  note('`stretch` sets width=5 and height=4 and expects 20. The square gives');
  note('16 because its width setter secretly changes height too. The subtype');
  note('is NOT substitutable: it broke a postcondition the base promised.');

  topic('The fix: model the real relationship');
  final shapes = <ImmutableShape>[
    const Rect(width: 2, height: 4),
    const Square(side: 4),
  ];
  for (final shape in shapes) {
    print('  ${shape.runtimeType.toString().padRight(8)} area=${shape.area} '
        'resized-to-5 area=${shape.scaledTo(5).area}');
  }
  note('A square is not a mutable rectangle. Make them siblings under a shared');
  note('abstraction, and make them immutable so no setter can lie.');

  topic('LSP VIOLATION — a surprise throw');
  final lists = <Appendable>[GrowableBox(), FixedBox()];
  for (final box in lists) {
    try {
      box.append(1);
      print('  ${box.runtimeType.toString().padRight(12)} -> appended');
    } on UnsupportedError catch (_) {
      print('  ${box.runtimeType.toString().padRight(12)} -> UnsupportedError (LSP violation)');
    }
  }
  note('If the base says "append adds an element", a subtype that throws is not');
  note('substitutable. Either split the interface (ReadOnlyBox has no append),');
  note('or make throwing part of the documented base contract.');

  topic('Replace `is`/`as` chains with polymorphism');
  note('BAD — every new type means editing this function:');
  for (final method in extended) {
    print('    ${describeWithTypeChecks(method)}');
  }
  note('GOOD — the type answers for itself:');
  for (final method in extended) {
    print('    ${method.label} (fee ${method.feePaise(50000)}p)');
  }
  note('A long `is` chain is a design smell: the knowledge belongs IN the type,');
  note('or in a Strategy object you can swap.');

  topic('Strategy — polymorphism you can change at runtime');
  final cart = PricedCart(items: [50000, 30000]);
  for (final strategy in <PricingStrategy>[
    const NoDiscount(),
    const PercentOff(10),
    const FlatOff(15000),
  ]) {
    print('  ${strategy.name.padRight(14)} -> ${strategy.apply(cart.subtotal)}');
  }
  note('Inheritance picks the behaviour at COMPILE time (which subclass you');
  note('instantiated). Strategy picks it at RUNTIME (which object you injected).');

  topic('Cost');
  note('A virtual call is one extra indirection through the class\'s method');
  note('table. The AOT compiler devirtualizes/inlines monomorphic call sites,');
  note('so in practice this is not a thing you optimise away. Clarity wins.');
}

abstract class PaymentMethod {
  const PaymentMethod();

  String get label;
  int feePaise(int amountPaise);

  /// Shared template: subclasses supply the fee, the base does the arithmetic.
  String charge(int amountPaise) {
    final fee = feePaise(amountPaise);
    final total = amountPaise + fee;
    return 'charged ${_rupees(total)} (fee ${_rupees(fee)})';
  }

  static String _rupees(int paise) => 'Rs.${(paise / 100).toStringAsFixed(2)}';
}

class CardPayment extends PaymentMethod {
  final String last4;
  final String network;
  const CardPayment({required this.last4, required this.network});

  @override
  String get label => '$network ****$last4';

  @override
  int feePaise(int amountPaise) => (amountPaise * 0.02).round();
}

class UpiPayment extends PaymentMethod {
  final String vpa;
  const UpiPayment({required this.vpa});

  @override
  String get label => 'UPI $vpa';

  @override
  int feePaise(int amountPaise) => 0; // UPI is free
}

class WalletPayment extends PaymentMethod {
  int balancePaise;
  WalletPayment({required this.balancePaise});

  @override
  String get label => 'Wallet';

  @override
  int feePaise(int amountPaise) => 100; // flat Re.1
}

/// Added later — Checkout needed no changes.
class NetBankingPayment extends PaymentMethod {
  final String bank;
  const NetBankingPayment({required this.bank});

  @override
  String get label => 'NetBanking $bank';

  @override
  int feePaise(int amountPaise) => 1500;
}

/// Depends only on the abstraction: no `is`, no `as`, no switch.
class Checkout {
  String chargeAll(List<PaymentMethod> methods, int amountPaise) {
    var fees = 0;
    for (final method in methods) {
      fees += method.feePaise(amountPaise);
    }
    return 'Rs.${(fees / 100).toStringAsFixed(2)} in fees across '
        '${methods.length} methods';
  }
}

/// The type-check chain this design avoids. Shown only to compare.
String describeWithTypeChecks(PaymentMethod method) {
  if (method is CardPayment) return 'Card ${method.network}';
  if (method is UpiPayment) return 'UPI ${method.vpa}';
  if (method is WalletPayment) return 'Wallet';
  if (method is NetBankingPayment) return 'NetBanking ${method.bank}';
  return 'unknown method'; // easy to forget to update -> silent bug
}

// --- LSP violation: mutable Square extends mutable Rectangle -----------------

class MutableRectangle {
  double _width;
  double _height;
  MutableRectangle({required double width, required double height})
      : _width = width,
        _height = height;

  double get width => _width;
  set width(double value) => _width = value;

  double get height => _height;
  set height(double value) => _height = value;

  double get area => _width * _height;
}

class MutableSquare extends MutableRectangle {
  MutableSquare({required double side}) : super(width: side, height: side);

  // Keeping the square invariant means BREAKING the rectangle contract.
  @override
  set width(double value) {
    _width = value;
    _height = value;
  }

  @override
  set height(double value) {
    _width = value;
    _height = value;
  }
}

/// Written against MutableRectangle's contract: expects 5 * 4 == 20.
double stretch(MutableRectangle rectangle) {
  rectangle.width = 5;
  rectangle.height = 4;
  return rectangle.area;
}

// --- the fix: immutable siblings under one abstraction -----------------------

abstract class ImmutableShape {
  const ImmutableShape();
  double get area;

  /// Returns a NEW shape; nothing can be mutated out from under a caller.
  ImmutableShape scaledTo(double primaryDimension);
}

class Rect extends ImmutableShape {
  final double width;
  final double height;
  const Rect({required this.width, required this.height});

  @override
  double get area => width * height;

  @override
  Rect scaledTo(double primaryDimension) =>
      Rect(width: primaryDimension, height: height);
}

class Square extends ImmutableShape {
  final double side;
  const Square({required this.side});

  @override
  double get area => side * side;

  @override
  Square scaledTo(double primaryDimension) => Square(side: primaryDimension);
}

// --- LSP violation: a surprise throw ----------------------------------------

abstract class Appendable {
  void append(int value);
}

class GrowableBox implements Appendable {
  final List<int> _values = [];
  @override
  void append(int value) => _values.add(value);
}

class FixedBox implements Appendable {
  @override
  void append(int value) =>
      throw UnsupportedError('FixedBox cannot grow'); // breaks the contract
}

// --- Strategy ---------------------------------------------------------------

abstract class PricingStrategy {
  const PricingStrategy();
  String get name;
  int apply(int subtotalPaise);
}

class NoDiscount extends PricingStrategy {
  const NoDiscount();
  @override
  String get name => 'no discount';
  @override
  int apply(int subtotalPaise) => subtotalPaise;
}

class PercentOff extends PricingStrategy {
  final int percent;
  const PercentOff(this.percent);
  @override
  String get name => '$percent% off';
  @override
  int apply(int subtotalPaise) => subtotalPaise - subtotalPaise * percent ~/ 100;
}

class FlatOff extends PricingStrategy {
  final int amountPaise;
  const FlatOff(this.amountPaise);
  @override
  String get name => 'flat off';
  @override
  int apply(int subtotalPaise) =>
      (subtotalPaise - amountPaise).clamp(0, subtotalPaise);
}

class PricedCart {
  final List<int> items;
  const PricedCart({required this.items});
  int get subtotal => items.fold(0, (a, b) => a + b);
}

// =============================================================================
// SECTION 5 — ABSTRACTION & INTERFACES
// =============================================================================
// Points covered:
//   * EVERY class has an implicit interface
//   * `implements` = contract only (reimplement everything), many allowed
//   * `extends` = inherit implementation, exactly one allowed
//   * abstract class = cannot be instantiated; mixes concrete + abstract members
//   * `sealed` = closed hierarchy + exhaustive `switch` with no `default`
//   * modifiers: abstract / base / final / interface / sealed
//   * depend on abstractions, not concretions (DIP)
// =============================================================================

void section5AbstractionAndInterfaces() {
  section('SECTION 5 · ABSTRACTION & INTERFACES');

  topic('Every class has an implicit interface');
  final stub = StubClock(); // implements Clock's interface without extending it
  // Typed as Object so the check is a real runtime test the analyzer cannot
  // fold to a constant.
  final Object asObject = stub;
  show('StubClock implements Clock', asObject is Clock);
  show('stub.now()', stub.now().toIso8601String());
  note('`class StubClock implements Clock` works even though Clock is a plain');
  note('concrete class — Dart derives an interface from every class.');

  topic('implements vs extends');
  show('extends: inherits the code', ConsoleLogger().format('hi'));
  show('implements: had to rewrite everything', SilentLogger().format('hi'));
  note('extends    -> reuse the base implementation, ONE parent, `super` works');
  note('implements -> take the contract only, MANY allowed, no `super`, you');
  note('              must supply every member yourself');

  topic('Implementing several interfaces at once');
  final repo = FileRepository();
  final Object erasedRepo = repo; // again, force a real runtime check
  show('is Readable', erasedRepo is Readable);
  show('is Writable', erasedRepo is Writable);
  show('is Disposable', erasedRepo is Disposable);
  show('read', repo.read('config'));
  repo.write('config', 'dark-mode');
  show('read after write', repo.read('config'));
  repo.dispose();
  show('after dispose', repo.isDisposed);
  note('Small, focused interfaces compose. One fat interface forces every');
  note('implementer to stub out members it does not need.');

  topic('Abstract class: concrete code + required holes');
  final exporters = <ReportExporter>[CsvExporter(), JsonLinesExporter()];
  for (final exporter in exporters) {
    print('  ${exporter.runtimeType.toString().padRight(18)} '
        '-> ${exporter.export(const [
              ['id', 'name'],
              ['1', 'Ada'],
            ])}');
  }
  note('`export()` is a TEMPLATE METHOD: the base fixes the algorithm and the');
  note('subclass fills in `formatRow`/`separator`. Shared code without');
  note('duplicating the workflow.');
  note('`ReportExporter()` does NOT compile — abstract classes have no instances.');

  topic('`sealed` — a closed set the compiler can check');
  final results = <AuthResult>[
    const Authenticated(userId: 'u1', token: 'abc'),
    const Failed(reason: 'wrong password'),
    Locked(until: DateTime(2026, 8, 18)),
  ];
  for (final result in results) {
    print('  ${describeAuth(result)}');
  }
  note('No `default` arm: the switch lists every subtype and the compiler');
  note('PROVES it is exhaustive. Add a 4th subtype and this stops compiling');
  note('until you handle it — the opposite of the `is`-chain in Section 4.');

  topic('sealed vs abstract');
  note('abstract : open — anyone anywhere can add a subtype, so a switch over');
  note('           it can never be proven exhaustive (you need a default).');
  note('sealed   : closed — subtypes must be in THIS library, so exhaustive');
  note('           switches work. Use it for finite domain states (results,');
  note('           UI states, events) and abstract for open extension points');
  note('           (plugins, strategies, repositories).');

  topic('Sealed hierarchies nest');
  for (final shape in <Shape>[const Circle(2), const Rectangle(3, 4), const Triangle(6, 5)]) {
    print('  ${describeShape(shape)}');
  }

  topic('Dependency Inversion: depend on the abstraction');
  final withFake = LoginUseCase(repository: FakeAuthRepository());
  final withHttp = LoginUseCase(repository: HttpAuthRepository());
  show('same use case, fake repo', describeAuth(withFake.call('ada', 'correct')));
  show('same use case, fake repo (bad pw)', describeAuth(withFake.call('ada', 'wrong')));
  show('same use case, "http" repo', describeAuth(withHttp.call('ada', 'correct')));
  note('LoginUseCase never names a concrete repository, so it is testable');
  note('without a network and swappable without edits. High-level policy does');
  note('not depend on low-level detail — both depend on the interface.');

  topic('Class modifiers in practice');
  note('abstract class X          : no instances; may have abstract members');
  note('abstract interface class X: pure contract — cannot be extended');
  note('base class X              : extend yes, implement NO (your impl is');
  note('                            guaranteed to run in every subtype)');
  note('final class X             : neither extend nor implement — fully closed');
  note('sealed class X            : abstract + final + exhaustive switching');
  note('Pick the MOST restrictive one that still allows what you intend.');
}

class Clock {
  DateTime now() => DateTime.now();
}

/// Implements Clock's implicit interface without extending it.
class StubClock implements Clock {
  @override
  DateTime now() => DateTime(2026, 1, 1);
}

class BaseLogger {
  String format(String message) => '[LOG] $message';
}

class ConsoleLogger extends BaseLogger {} // inherits format()

class SilentLogger implements BaseLogger {
  @override
  String format(String message) => '(silenced)'; // had to write it all
}

abstract interface class Readable {
  String? read(String key);
}

abstract interface class Writable {
  void write(String key, String value);
}

abstract interface class Disposable {
  void dispose();
  bool get isDisposed;
}

class FileRepository implements Readable, Writable, Disposable {
  final Map<String, String> _store = {'config': 'light-mode'};
  bool _disposed = false;

  @override
  String? read(String key) => _disposed ? null : _store[key];

  @override
  void write(String key, String value) {
    if (_disposed) throw StateError('disposed');
    _store[key] = value;
  }

  @override
  void dispose() {
    _store.clear();
    _disposed = true;
  }

  @override
  bool get isDisposed => _disposed;
}

/// Template Method: the base owns the algorithm, subclasses own the details.
abstract class ReportExporter {
  String get separator;
  String formatRow(List<String> cells);

  String export(List<List<String>> rows) =>
      rows.map(formatRow).join(separator);
}

class CsvExporter extends ReportExporter {
  @override
  String get separator => ' | ';

  @override
  String formatRow(List<String> cells) => cells.join(',');
}

class JsonLinesExporter extends ReportExporter {
  @override
  String get separator => ' ';

  @override
  String formatRow(List<String> cells) =>
      '{${cells.map((c) => '"$c"').join(':')}}';
}

/// Closed set of outcomes -> exhaustive switching.
sealed class AuthResult {
  const AuthResult();
}

class Authenticated extends AuthResult {
  final String userId;
  final String token;
  const Authenticated({required this.userId, required this.token});
}

class Failed extends AuthResult {
  final String reason;
  const Failed({required this.reason});
}

class Locked extends AuthResult {
  final DateTime until;
  const Locked({required this.until});
}

/// No `default` — the compiler verifies every subtype is covered.
String describeAuth(AuthResult result) => switch (result) {
      Authenticated(userId: final id) => 'welcome $id',
      Failed(reason: final reason) => 'denied: $reason',
      Locked(until: final until) => 'locked until ${until.toIso8601String()}',
    };

sealed class Shape {
  const Shape();
  double get area;
}

class Circle extends Shape {
  final double radius;
  const Circle(this.radius);
  @override
  double get area => 3.14159 * radius * radius;
}

class Rectangle extends Shape {
  final double width;
  final double height;
  const Rectangle(this.width, this.height);
  @override
  double get area => width * height;
}

class Triangle extends Shape {
  final double base;
  final double height;
  const Triangle(this.base, this.height);
  @override
  double get area => 0.5 * base * height;
}

String describeShape(Shape shape) => switch (shape) {
      Circle(radius: final r) => 'circle r=$r area=${shape.area.toStringAsFixed(2)}',
      Rectangle(width: final w, height: final h) when w == h => 'square $w',
      Rectangle(width: final w, height: final h) => 'rect ${w}x$h area=${shape.area}',
      Triangle(base: final b) => 'triangle base=$b area=${shape.area}',
    };

/// The contract the use case depends on.
abstract interface class AuthRepository {
  AuthResult signIn(String username, String password);
}

class FakeAuthRepository implements AuthRepository {
  @override
  AuthResult signIn(String username, String password) => password == 'correct'
      ? Authenticated(userId: username, token: 'fake-token')
      : const Failed(reason: 'wrong password');
}

class HttpAuthRepository implements AuthRepository {
  @override
  AuthResult signIn(String username, String password) =>
      // A real one would hit the network; shape is what matters here.
      Authenticated(userId: username, token: 'jwt-from-server');
}

/// Depends on the INTERFACE only — no network, no concrete class.
class LoginUseCase {
  final AuthRepository repository;
  const LoginUseCase({required this.repository});

  AuthResult call(String username, String password) {
    if (username.isEmpty || password.isEmpty) {
      return const Failed(reason: 'username and password are required');
    }
    return repository.signIn(username, password);
  }
}

// =============================================================================
// SECTION 6 — COMPOSITION & RELATIONSHIPS
// =============================================================================
// Points covered:
//   * COMPOSITION: owns the part, creates it, DISPOSES it (car -> engine)
//   * AGGREGATION: references a shared part, must NOT dispose it
//     (playlist -> song)
//   * ASSOCIATION: merely uses another object, often transiently (driver -> car)
//   * favour composition over inheritance; delegate + inject collaborators
//   * mixin = compile-time behaviour, fixed; composition = runtime, swappable
//   * Flutter composes widgets instead of subclassing them
// =============================================================================

void section6CompositionAndRelationships() {
  section('SECTION 6 · COMPOSITION & RELATIONSHIPS');

  topic('COMPOSITION — owns the part and its lifetime');
  final car = Car(model: 'Nexon'); // Car CREATES its own Engine
  show('car', car);
  show('start (delegated to the engine)', car.start());
  car.dispose(); // disposing the car disposes the engine
  show('engine disposed with the car', car.isEngineDisposed);
  note('"HAS-A, and owns it": the Engine cannot outlive the Car, and nobody');
  note('else has a reference to it. The owner disposes the part.');

  topic('AGGREGATION — shares a part it must NOT dispose');
  final shared = Song(title: 'So What');
  final morning = SongList('Morning')..addSong(shared);
  final evening = SongList('Evening')..addSong(shared);
  show('same Song object in both lists',
      identical(morning.songs.first, evening.songs.first));
  morning.dispose();
  show('after morning.dispose(), evening still works', evening.songs.first.title);
  note('"HAS-A, but shares it": the Song was created OUTSIDE and outlives any');
  note('one list. Disposing a list must never dispose the songs.');

  topic('ASSOCIATION — just uses it');
  final driver = Driver(name: 'Ada');
  show('driver uses a car passed in', driver.drive(Car(model: 'Punch')));
  note('No ownership at all: the Car arrives as a parameter, is used, and the');
  note('Driver holds no reference afterwards. Weakest coupling of the three.');

  topic('Composition over inheritance — the refactor');
  note('BAD: inherit to get behaviour you happen to want.');
  final badRobot = InheritedRobot();
  show('InheritedRobot extends Employee', badRobot.describe());
  note('It inherited salary, leave balance and a tax id it must not have, and');
  note('it IS-A Employee everywhere in the type system. Wrong model.');
  note('GOOD: compose the piece you actually need.');
  final goodRobot = ComposedRobot(scheduler: WorkScheduler());
  show('ComposedRobot has-a WorkScheduler', goodRobot.describe());
  note('Reuse without inheriting an identity or an API you cannot honour.');

  topic('Delegation');
  final list = CountingList<int>(inner: []);
  list.add(1);
  list.add(2);
  list.remove(1);
  show('delegating wrapper', list);
  show('operations counted', list.operationCount);
  note('CountingList does not EXTEND List (which would force it to reimplement');
  note('~40 members and inherit their call graph). It HOLDS a List and');
  note('forwards the few methods it needs. Composition, not inheritance.');

  topic('Injected collaborators = testable seams');
  final production = CheckoutService(
    gateway: RealGateway(),
    logger: ConsoleAuditLogger(),
    inventory: RealInventory(),
  );
  final underTest = CheckoutService(
    gateway: FakeGateway(shouldSucceed: false),
    logger: RecordingLogger(),
    inventory: FakeInventory(stock: {'sku-1': 0}),
  );
  show('production run', production.checkout('sku-1', 50000));
  show('test run (gateway fails, no stock)', underTest.checkout('sku-1', 50000));
  final recorded = underTest.logger;
  if (recorded is RecordingLogger) {
    show('logger captured for assertions', recorded.lines);
  }
  note('Every collaborator is behind an interface and passed in, so the test');
  note('needs no network, no clock, no database — and can ASSERT on the log.');

  topic('Mixin vs composition');
  show('mixin: behaviour fixed at compile time', MixedInService().describe());
  final swappable = ComposedService(formatter: UpperFormatter());
  show('composition: swappable at runtime', swappable.describe());
  show('same object, different collaborator',
      ComposedService(formatter: ReverseFormatter()).describe());
  note('Mixin      : zero indirection, shares the host\'s `this`, but you');
  note('             cannot swap it or configure it per instance.');
  note('Composition: one extra reference, fully swappable and stateful, and it');
  note('             cannot accidentally collide with the host\'s members.');
  note('Choose a mixin for stateless cross-cutting behaviour; choose');
  note('composition whenever the collaborator has state or needs to vary.');

  topic('How Flutter does it');
  note('You do not subclass Container to make a PaddedRedBox — you NEST:');
  note('  Padding(child: DecoratedBox(child: Text(...)))');
  note('The entire widget tree is composition. The only inheritance you write');
  note('is `extends StatelessWidget/StatefulWidget` — one level, to plug into');
  note('the framework, never to reuse another widget\'s code.');

  topic('Ownership checklist');
  note('Did I CREATE it? -> I own it -> I dispose it (composition).');
  note('Was it GIVEN to me? -> someone else owns it -> hands off (aggregation).');
  note('Do I only touch it inside one method? -> association; hold no field.');
}

class Engine {
  bool disposed = false;
  String ignite() => 'vroom';
  void dispose() => disposed = true;
}

/// COMPOSITION: creates and owns its Engine.
class Car {
  final String model;
  final Engine _engine; // created here, never handed in

  Car({required this.model}) : _engine = Engine();

  String start() => '$model: ${_engine.ignite()}';
  bool get isEngineDisposed => _engine.disposed;

  void dispose() => _engine.dispose(); // owner disposes the part

  @override
  String toString() => 'Car($model, engine owned)';
}

class Song {
  final String title;
  Song({required this.title});
}

/// AGGREGATION: holds songs it did not create and must not dispose.
class SongList {
  final String name;
  final List<Song> _songs = [];

  SongList(this.name);

  void addSong(Song song) => _songs.add(song); // passed IN from outside
  List<Song> get songs => List.unmodifiable(_songs);

  /// Drops references only. Deliberately does NOT touch the songs.
  void dispose() => _songs.clear();
}

/// ASSOCIATION: uses a Car without owning or storing it.
class Driver {
  final String name;
  Driver({required this.name});

  String drive(Car car) => '$name drives ${car.start()}';
}

class Employee {
  int salary = 50000;
  int leaveBalance = 20;
  String taxId = 'TAX-123';
  String schedule() => 'works 9-5';
  String describe() => 'Employee: ${schedule()}, salary=$salary';
}

/// BAD: inherits an identity and an API it should not have.
class InheritedRobot extends Employee {
  @override
  String describe() => 'Robot: ${schedule()} — but also has salary=$salary, '
      'leave=$leaveBalance, taxId=$taxId (nonsense)';
}

class WorkScheduler {
  String schedule() => 'works 24/7';
}

/// GOOD: composes just the capability it needs.
class ComposedRobot {
  final WorkScheduler scheduler;
  ComposedRobot({required this.scheduler});

  String describe() => 'Robot: ${scheduler.schedule()} — no salary, no leave';
}

/// Delegation: wraps a List instead of extending it.
class CountingList<T> {
  final List<T> _inner;
  int operationCount = 0;

  CountingList({required List<T> inner}) : _inner = inner;

  void add(T value) {
    operationCount++;
    _inner.add(value);
  }

  bool remove(T value) {
    operationCount++;
    return _inner.remove(value);
  }

  int get length => _inner.length;

  @override
  String toString() => 'CountingList($_inner)';
}

// --- injected collaborators -------------------------------------------------

abstract interface class PaymentGateway {
  bool charge(int amountPaise);
}

abstract interface class AuditLogger {
  void log(String line);
}

abstract interface class InventoryClient {
  int stockFor(String sku);
  void reserve(String sku);
}

class RealGateway implements PaymentGateway {
  @override
  bool charge(int amountPaise) => true;
}

class FakeGateway implements PaymentGateway {
  final bool shouldSucceed;
  FakeGateway({required this.shouldSucceed});
  @override
  bool charge(int amountPaise) => shouldSucceed;
}

class ConsoleAuditLogger implements AuditLogger {
  @override
  void log(String line) {} // quiet in this demo
}

class RecordingLogger implements AuditLogger {
  final List<String> lines = [];
  @override
  void log(String line) => lines.add(line);
}

class RealInventory implements InventoryClient {
  @override
  int stockFor(String sku) => 10;
  @override
  void reserve(String sku) {}
}

class FakeInventory implements InventoryClient {
  final Map<String, int> stock;
  FakeInventory({required this.stock});
  @override
  int stockFor(String sku) => stock[sku] ?? 0;
  @override
  void reserve(String sku) => stock[sku] = (stock[sku] ?? 1) - 1;
}

/// Composed of three injected collaborators, each behind an interface.
class CheckoutService {
  final PaymentGateway gateway;
  final AuditLogger logger;
  final InventoryClient inventory;

  CheckoutService({
    required this.gateway,
    required this.logger,
    required this.inventory,
  });

  String checkout(String sku, int amountPaise) {
    logger.log('checkout started for $sku');
    if (inventory.stockFor(sku) <= 0) {
      logger.log('out of stock: $sku');
      return 'failed: out of stock';
    }
    if (!gateway.charge(amountPaise)) {
      logger.log('payment declined');
      return 'failed: payment declined';
    }
    inventory.reserve(sku);
    logger.log('checkout complete');
    return 'ok: reserved $sku';
  }
}

// --- mixin vs composition ---------------------------------------------------

mixin ShoutMixin {
  String decorate(String text) => '${text.toUpperCase()}!!!';
}

class MixedInService with ShoutMixin {
  String describe() => decorate('fixed behaviour');
}

abstract interface class Formatter {
  String format(String text);
}

class UpperFormatter implements Formatter {
  @override
  String format(String text) => text.toUpperCase();
}

class ReverseFormatter implements Formatter {
  @override
  String format(String text) => text.split('').reversed.join();
}

class ComposedService {
  final Formatter formatter;
  ComposedService({required this.formatter});

  String describe() => formatter.format('swappable behaviour');
}

// =============================================================================
// SECTION 7 — EQUALITY & COPYING
// =============================================================================
// Points covered:
//   * default `==` is IDENTITY; override it for value semantics
//   * `identical(a, b)` asks "same instance", never overridable
//   * override `==` and `hashCode` TOGETHER, over the SAME fields
//   * the contract: a == b IMPLIES a.hashCode == b.hashCode
//   * hash keys must be IMMUTABLE — mutating a key loses the entry
//   * shallow copy shares nested objects; deep copy clones them
//   * prefer immutability + equatable/freezed/records
// =============================================================================

void section7EqualityAndCopying() {
  section('SECTION 7 · EQUALITY & COPYING');

  topic('Default `==` is identity');
  final a = IdentityPoint(1, 2);
  final b = IdentityPoint(1, 2);
  show('a == b (no override)', a == b);
  show('identical(a, b)', identical(a, b));
  note('Two objects with identical field values are NOT equal by default.');

  topic('Value equality via an override');
  const p1 = ValuePoint(1, 2);
  const p2 = ValuePoint(1, 2);
  const p3 = ValuePoint(9, 9);
  show('p1 == p2', p1 == p2);
  show('p1 == p3', p1 == p3);
  show('identical(p1, p2) — const canonicalized', identical(p1, p2));
  show('identical(ValuePoint(1,2), ValuePoint(1,2))',
      identical(ValuePoint(1, 2), ValuePoint(1, 2)));
  note('`==` is about VALUE; `identical` is about the object\'s address.');

  topic('The hashCode contract');
  show('equal objects share a hashCode', p1.hashCode == p2.hashCode);
  final valueSet = [p1, p2, p3].toSet();
  show('Set dedupes correctly', valueSet.length);
  show('Map lookup with a different-but-equal key', {p1: 'stored'}[p2]);

  topic('What breaks when you override only `==`');
  final broken1 = BrokenEquality(1);
  final broken2 = BrokenEquality(1);
  show('broken1 == broken2', broken1 == broken2);
  show('but hashCodes differ', broken1.hashCode != broken2.hashCode);
  show('Set does NOT dedupe', [broken1, broken2].toSet().length);
  show('Map lookup FAILS', {broken1: 'stored'}[broken2]);
  note('Hash containers bucket by hashCode FIRST, then compare with ==. Unequal');
  note('hashes send equal objects to different buckets, so `==` is never even');
  note('called. Override both, over the same fields, or neither.');

  topic('Mutable hash keys lose their entries');
  final key = MutableKey('original');
  final map = {key: 'value'};
  show('lookup before mutation', map[key]);
  key.name = 'changed'; // hashCode now differs from the stored bucket
  show('lookup after mutating the key', map[key]);
  show('but the entry is still in there', map.length);
  show('containsKey', map.containsKey(key));
  note('The entry is stranded in the old bucket: unreachable, undeletable, and');
  note('it still holds memory. NEVER use a mutable object as a Map/Set key —');
  note('this is the single strongest argument for immutable value objects.');

  topic('SHALLOW copy shares nested objects');
  final doc = Document(
    title: 'Draft',
    paragraphs: [Paragraph('intro'), Paragraph('body')],
  );
  final shallow = doc.shallowCopy();
  shallow.title = 'Shallow copy';
  shallow.paragraphs[0].text = 'MUTATED VIA THE COPY';
  show('original title (independent)', doc.title);
  show('original paragraph (SHARED!)', doc.paragraphs[0].text);
  show('same Paragraph instance', identical(doc.paragraphs[0], shallow.paragraphs[0]));
  note('The top level was copied; everything one level down is the SAME object.');
  note('`List.of(other)` and a plain `copyWith` are both shallow.');

  topic('DEEP copy clones the whole graph');
  final fresh = Document(
    title: 'Draft',
    paragraphs: [Paragraph('intro'), Paragraph('body')],
  );
  final deep = fresh.deepCopy();
  deep.paragraphs[0].text = 'MUTATED VIA THE DEEP COPY';
  show('original paragraph (untouched)', fresh.paragraphs[0].text);
  show('copy paragraph', deep.paragraphs[0].text);
  show('different instances', !identical(fresh.paragraphs[0], deep.paragraphs[0]));
  note('Deep copy costs an allocation per node and must handle cycles. Which');
  note('is why the real fix is usually IMMUTABILITY — if nothing can be');
  note('mutated, sharing is free and copying is unnecessary.');

  topic('The immutable alternative: copyWith');
  const money = Money(amountPaise: 129999, currency: 'INR');
  final discounted = money.copyWith(amountPaise: 99999);
  show('original (never changed)', money);
  show('derived value', discounted);
  show('equality still by value', money == const Money(amountPaise: 129999, currency: 'INR'));
  note('No shallow/deep question arises: there is nothing to mutate, so sharing');
  note('a reference is always safe.');

  topic('Records give you equality for free');
  const r1 = (x: 1, y: 2);
  const r2 = (x: 1, y: 2);
  show('(x:1, y:2) == (x:1, y:2)', r1 == r2);
  show('hashCodes match', r1.hashCode == r2.hashCode);
  show('usable as a Map key', {r1: 'origin'}[r2]);
  note('Records have STRUCTURAL equality built in — ideal for short-lived');
  note('local values and multi-value returns. For a named domain type with');
  note('methods and invariants, still write a class.');

  topic('Tooling');
  note('equatable : extend Equatable, list `props` — == and hashCode derived');
  note('freezed   : codegen for immutability + copyWith + == + unions + JSON');
  note('records   : zero-boilerplate structural equality, no name/methods');
  note('By hand: `Object.hash(a, b, c)` for fields, `Object.hashAll(list)` for');
  note('collections. Never write `a.hashCode + b.hashCode` (collisions).');
}

class IdentityPoint {
  final int x;
  final int y;
  IdentityPoint(this.x, this.y);
}

class ValuePoint {
  final int x;
  final int y;
  const ValuePoint(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      other is ValuePoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'ValuePoint($x, $y)';
}

/// Overrides `==` but not `hashCode` — the classic bug.
class BrokenEquality {
  final int id;
  BrokenEquality(this.id);

  @override
  bool operator ==(Object other) => other is BrokenEquality && other.id == id;
  // ignore: hash_and_equals
}

/// Mutable + used as a key = stranded entries.
class MutableKey {
  String name;
  MutableKey(this.name);

  @override
  bool operator ==(Object other) => other is MutableKey && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

class Paragraph {
  String text;
  Paragraph(this.text);

  Paragraph clone() => Paragraph(text);

  @override
  String toString() => 'Paragraph("$text")';
}

class Document {
  String title;
  List<Paragraph> paragraphs;

  Document({required this.title, required this.paragraphs});

  /// New Document, new list — but the SAME Paragraph objects.
  Document shallowCopy() =>
      Document(title: title, paragraphs: List.of(paragraphs));

  /// New Document, new list, and a clone of every Paragraph.
  Document deepCopy() => Document(
        title: title,
        paragraphs: paragraphs.map((p) => p.clone()).toList(),
      );
}

class Money {
  final int amountPaise;
  final String currency;

  const Money({required this.amountPaise, required this.currency});

  Money copyWith({int? amountPaise, String? currency}) => Money(
        amountPaise: amountPaise ?? this.amountPaise,
        currency: currency ?? this.currency,
      );

  Money operator +(Money other) {
    if (other.currency != currency) {
      throw DomainException('cannot add ${other.currency} to $currency');
    }
    return copyWith(amountPaise: amountPaise + other.amountPaise);
  }

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.amountPaise == amountPaise &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(amountPaise, currency);

  @override
  String toString() => '$currency ${(amountPaise / 100).toStringAsFixed(2)}';
}

// =============================================================================
// SECTION 8 — MINI PROJECTS (one per notes file)
// =============================================================================

void section8MiniProjects() {
  section('SECTION 8 · MINI PROJECTS (one per notes file)');

  topic('01 · Domain object toolkit (Playlist)');
  final countBefore = Playlist.instanceCount;
  final playlist = Playlist('Coltrane Essentials')
    ..add(Track(title: 'Blue Train', seconds: 634))
    ..add(Track(title: 'Naima', seconds: 265))
    ..add(Track(title: 'Giant Steps', seconds: 285));
  show('playlist', playlist);
  show('computed duration getter', playlist.formattedDuration);
  show('longest track', playlist.longestTrack());
  show('static counter moved by', Playlist.instanceCount - countBefore);
  try {
    playlist.items.add(Track(title: 'Pirate', seconds: 1));
  } on UnsupportedError catch (_) {
    show('tracks cannot be mutated externally', 'UnsupportedError');
  }
  show('reference semantics: alias sees the same object',
      identical(playlist, playlist));

  topic('02 · Guarded account domain');
  final guarded = BankAccount(owner: 'Ada', openingBalance: 1000);
  final savings = SavingsAccount(
    owner: 'Ada',
    openingBalance: 5000,
    minimumBalance: 1000,
  );
  for (final (label, action) in <(String, void Function())>[
    ('open with -1', () => BankAccount(owner: 'X', openingBalance: -1)),
    ('open with no owner', () => BankAccount(owner: '  ', openingBalance: 10)),
    ('over-withdraw', () => guarded.withdraw(99999)),
    ('savings below minimum', () => savings.withdraw(4500)),
    ('negative deposit', () => guarded.deposit(-1)),
  ]) {
    try {
      action();
      print('  ${label.padRight(22)} -> ALLOWED (invariant broken!)');
    } on DomainException catch (e) {
      print('  ${label.padRight(22)} -> blocked: ${e.message}');
    }
  }
  note('Direct field access is impossible: `_balance` has no public setter.');

  topic('03 · Account hierarchy');
  final hierarchy = <BankAccount>[
    BankAccount(owner: 'Plain', openingBalance: 1000),
    SavingsAccount(owner: 'Saver', openingBalance: 5000, minimumBalance: 1000),
    CheckingAccount(owner: 'Spender', openingBalance: 500, overdraftLimit: 300),
  ];
  for (final account in hierarchy) {
    final attempt = 700;
    String outcome;
    try {
      account.withdraw(attempt);
      outcome = 'withdrew $attempt -> ${account.balance}';
    } on DomainException catch (e) {
      outcome = 'refused: ${e.message}';
    }
    print('  ${account.runtimeType.toString().padRight(16)} $outcome');
  }
  note('Same call, three rules — each subclass reused the base validation via');
  note('`super` and toString() adapted through `runtimeType`.');

  topic('04 · Payment processor (Open/Closed)');
  final checkout = Checkout();
  final v1 = <PaymentMethod>[
    const CardPayment(last4: '4242', network: 'Visa'),
    const UpiPayment(vpa: 'ada@upi'),
  ];
  show('v1 methods', checkout.chargeAll(v1, 100000));
  final v2 = <PaymentMethod>[...v1, const NetBankingPayment(bank: 'HDFC')];
  show('v2 after adding a type', checkout.chargeAll(v2, 100000));
  note('Zero edits to Checkout — no `is`, no `as`, no switch over types.');

  topic('05 · Auth + result contracts');
  final useCase = LoginUseCase(repository: FakeAuthRepository());
  for (final (user, pass) in const [('ada', 'correct'), ('ada', 'wrong'), ('', '')]) {
    print('  ("$user","$pass") -> ${describeAuth(useCase.call(user, pass))}');
  }
  show('locked branch', describeAuth(Locked(until: DateTime(2026, 12, 25))));
  note('Exhaustive switch, no default. Repository swapped without touching the');
  note('use case; a new AuthResult subtype would break compilation until handled.');

  topic('06 · Composable service layer');
  final logger = RecordingLogger();
  final service = CheckoutService(
    gateway: FakeGateway(shouldSucceed: true),
    logger: logger,
    inventory: FakeInventory(stock: {'sku-1': 2}),
  );
  show('first checkout', service.checkout('sku-1', 50000));
  show('second checkout', service.checkout('sku-1', 50000));
  show('third (stock exhausted)', service.checkout('sku-1', 50000));
  show('audit log captured', logger.lines.length);
  for (final line in logger.lines) {
    note('    $line');
  }
  note('Ownership: CheckoutService does NOT dispose its collaborators — they');
  note('were injected, so whoever created them owns them (aggregation).');

  topic('07 · Equality & copy lab');
  const priceA = Money(amountPaise: 129999, currency: 'INR');
  const priceB = Money(amountPaise: 129999, currency: 'INR');
  show('value equality', priceA == priceB);
  show('dedupes in a Set', [priceA, priceB].toSet().length);
  show('works as a Map key', {priceA: 'listed'}[priceB]);
  show('operator +', priceA + const Money(amountPaise: 1, currency: 'INR'));
  try {
    priceA + const Money(amountPaise: 100, currency: 'USD');
  } on DomainException catch (e) {
    show('currency invariant', e.message);
  }

  final doc = Document(
    title: 'Spec',
    paragraphs: [Paragraph('alpha'), Paragraph('beta')],
  );
  final shallow = doc.shallowCopy();
  final deep = doc.deepCopy();
  shallow.paragraphs[0].text = 'changed by shallow';
  show('shallow SHARES nested -> original now', doc.paragraphs[0].text);
  deep.paragraphs[1].text = 'changed by deep';
  show('deep is INDEPENDENT -> original still', doc.paragraphs[1].text);
  show('shallow shares instance', identical(doc.paragraphs[0], shallow.paragraphs[0]));
  show('deep clones instance', !identical(doc.paragraphs[0], deep.paragraphs[0]));

  print('\nAll 7 topics demonstrated. Read each notes file for the theory.');
}
