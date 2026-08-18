// =============================================================================
// 04 · SOLID PRINCIPLES — ALL-IN-ONE PRACTICAL FILE
// =============================================================================
// Runnable companion to the 5 notes files in this folder. Every principle is
// shown the way the notes present it:
//
//     SMELLS  ->  X VIOLATION (running, and demonstrably broken)
//             ->  V REFACTOR  (running, and demonstrably better)
//             ->  Flutter example  ->  Enterprise example
//
// The violations are not strawmen: each one is executed and the resulting bug,
// crash, or untestability is printed.
//
//   Run:      fvm dart run --enable-asserts "06_practicals_all_in_one.dart"
//   Analyze:  fvm dart analyze "06_practicals_all_in_one.dart"
//
// Map of sections -> source notes file:
//   1  S · Single Responsibility ....... 01_srp_single_responsibility.md
//   2  O · Open/Closed ................. 02_ocp_open_closed.md
//   3  L · Liskov Substitution ......... 03_lsp_liskov_substitution.md
//   4  I · Interface Segregation ....... 04_isp_interface_segregation.md
//   5  D · Dependency Inversion ........ 05_dip_dependency_inversion.md
//   6  Mini projects 1-4
//   7  CAPSTONE — the order-service refactor satisfying all five
// =============================================================================

void main() {
  section1Srp();
  section2Ocp();
  section3Lsp();
  section4Isp();
  section5Dip();
  section6MiniProjects();
  section7Capstone();
}

// -----------------------------------------------------------------------------
// Output helpers.
// -----------------------------------------------------------------------------
void section(String title) => print('\n${'=' * 76}\n$title\n${'=' * 76}');

void topic(String title) {
  final pad = 62 - title.length;
  print('\n-- $title ${'-' * (pad < 3 ? 3 : pad)}');
}

void show(String label, Object? value) => print('  $label: $value');
void note(String text) => print('  $text');
void smells(List<String> items) {
  print('  SMELLS that signal this violation:');
  for (final item in items) {
    print('    * $item');
  }
}

/// Records side effects that a "real" infrastructure class would perform, so
/// the untestability of the violating designs is visible rather than asserted.
final List<String> sideEffects = [];

// =============================================================================
// A tiny Result type used by several sections (a contract that never throws).
// =============================================================================

sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;

  R fold<R>({required R Function(T value) ok, required R Function(String error) err}) =>
      switch (this) {
        Ok<T>(value: final v) => ok(v),
        Err<T>(message: final m) => err(m),
      };

  @override
  String toString() => fold(ok: (v) => 'Ok($v)', err: (e) => 'Err($e)');
}

class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}

class Err<T> extends Result<T> {
  final String message;
  const Err(this.message);
}

// =============================================================================
// SECTION 1 — S · SINGLE RESPONSIBILITY PRINCIPLE
// =============================================================================
// "A class should have ONE reason to change" — one actor, one concern.
//
// Points covered:
//   * a God class with three reasons to change, and why that hurts
//   * the refactor: split by concern, then compose/inject
//   * the payoff proved at runtime: rules testable with NO database,
//     formatting testable with NO persistence
//   * Flutter mapping: widget = UI, repository = data, viewmodel = logic
//   * enterprise mapping: one service per bounded concern
// =============================================================================

void section1Srp() {
  section('SECTION 1 · S — SINGLE RESPONSIBILITY PRINCIPLE');

  note('Intent: a class should have ONE reason to change.');
  note('"Reason to change" = an ACTOR who can demand a change: the accountant');
  note('(tax rules), the designer (receipt layout), the DBA (storage).');

  topic('SMELLS');
  smells([
    'a class named Manager / Helper / Util / Service that does everything',
    'you describe it with "and": "it validates AND saves AND emails"',
    'HTTP + SQL + formatting + business rules in one file',
    'a test for the rules needs a database, a clock, and a mail server',
    'two unrelated bug fixes keep colliding in the same file',
  ]);

  topic('X VIOLATION — one class, three reasons to change');
  sideEffects.clear();
  final god = InvoiceEverything(client: 'Acme', amountPaise: 100000);
  show('it does work', god.processAndSave());
  show('side effects it performed', sideEffects);
  note('');
  note('InvoiceEverything changes when ANY of these people change their mind:');
  note('  1. the accountant  -> tax calculation');
  note('  2. the designer    -> receipt text/layout');
  note('  3. the DBA         -> storage format');
  note('Three actors, one file: every change risks breaking the other two, and');
  note('you cannot test the tax rule without touching persistence.');
  show('can I test the tax rule alone?', 'no — processAndSave() always writes');

  topic('V REFACTOR — one responsibility each');
  sideEffects.clear();
  const invoice = Invoice(client: 'Acme', amountPaise: 100000);
  show('1. Invoice — the RULES only', invoice.totalPaise);
  show('   tax portion', invoice.taxPaise);
  show('   side effects so far', sideEffects.isEmpty ? 'none' : sideEffects);
  note('   ^ the accountant\'s concern, testable as pure arithmetic.');

  const plain = PlainTextInvoiceFormatter();
  const html = HtmlInvoiceFormatter();
  show('2. formatter (text)', plain.format(invoice));
  show('   formatter (html)', html.format(invoice));
  show('   side effects so far', sideEffects.isEmpty ? 'none' : sideEffects);
  note('   ^ the designer\'s concern; a second format is a NEW class, not an');
  note('     edit to Invoice.');

  final memoryRepo = InMemoryInvoiceRepository();
  final useCase = IssueInvoice(repository: memoryRepo, formatter: plain);
  show('3. use case composes the three', useCase.call(invoice));
  show('   stored in the fake repo', memoryRepo.saved.length);
  show('   side effects (no real DB touched)',
      sideEffects.isEmpty ? 'none' : sideEffects);

  topic('The payoff, proved');
  show('rules tested with NO database', Invoice(client: 'T', amountPaise: 200).totalPaise);
  show('formatting tested with NO persistence', plain.format(invoice).length);
  show('persistence tested with NO tax rules', memoryRepo.saved.first.client);
  note('Each concern is independently testable, which is the operational');
  note('definition of "one responsibility".');

  topic('SRP is about COHESION, not line count');
  note('A 300-line class with one reason to change is fine.');
  note('A 30-line class that both parses JSON and writes to SQLite is not.');
  note('Do not split until you can name the SECOND actor — otherwise you get');
  note('a maze of one-method classes, which is its own maintenance problem.');

  topic('Flutter example');
  note('X  A StatefulWidget that builds UI, calls http.get, parses JSON,');
  note('   caches to SharedPreferences and holds business rules.');
  note('V  Widget      -> layout + user intent only');
  note('   ViewModel   -> state + orchestration (Bloc/Cubit/Notifier)');
  note('   Repository  -> data access, caching, DTO<->entity mapping');
  note('   Model       -> the rules');
  note('Symptom you have it wrong: your widget test needs a mock HTTP client.');

  topic('Enterprise example');
  note('X  OrderManager: pricing + inventory + payment + shipping + email.');
  note('V  PricingService · InventoryService · PaymentService ·');
  note('   ShippingService · NotificationService — each owned by ONE team,');
  note('   each deployable and testable on its own.');
  note('Team boundary is the real test: if two teams must edit one class to');
  note('ship independent features, SRP is being violated.');
}

// --- X the God class ---------------------------------------------------------

class InvoiceEverything {
  final String client;
  final int amountPaise;

  InvoiceEverything({required this.client, required this.amountPaise});

  // Reason to change #1: the accountant.
  int _tax() => (amountPaise * 0.18).round();

  // Reason to change #2: the designer.
  String _receipt() =>
      'INVOICE for $client\nsubtotal ${amountPaise}p\ntax ${_tax()}p\n'
      'total ${amountPaise + _tax()}p';

  // Reason to change #3: the DBA.
  void _save(String receipt) {
    sideEffects.add('REAL DB WRITE (${receipt.length} bytes)');
  }

  void _log(String message) => sideEffects.add('LOG: $message');

  /// Every call does all three. You cannot exercise one without the others.
  String processAndSave() {
    final receipt = _receipt();
    _save(receipt);
    _log('invoice issued for $client');
    return 'issued: total ${amountPaise + _tax()}p';
  }
}

// --- V one responsibility each -----------------------------------------------

/// RULES only. No IO, no formatting. Pure and instantly testable.
class Invoice {
  final String client;
  final int amountPaise;
  static const double taxRate = 0.18;

  const Invoice({required this.client, required this.amountPaise});

  int get taxPaise => (amountPaise * taxRate).round();
  int get totalPaise => amountPaise + taxPaise;
}

/// FORMATTING only. A new output format is a new class.
abstract interface class InvoiceFormatter {
  String format(Invoice invoice);
}

class PlainTextInvoiceFormatter implements InvoiceFormatter {
  const PlainTextInvoiceFormatter();
  @override
  String format(Invoice invoice) =>
      '${invoice.client}: ${invoice.amountPaise}p + ${invoice.taxPaise}p tax '
      '= ${invoice.totalPaise}p';
}

class HtmlInvoiceFormatter implements InvoiceFormatter {
  const HtmlInvoiceFormatter();
  @override
  String format(Invoice invoice) =>
      '<b>${invoice.client}</b> total <i>${invoice.totalPaise}p</i>';
}

/// PERSISTENCE only, behind an interface so tests need no database.
abstract interface class InvoiceRepository {
  void save(Invoice invoice, String rendered);
}

class InMemoryInvoiceRepository implements InvoiceRepository {
  final List<Invoice> saved = [];
  final List<String> renderings = [];

  @override
  void save(Invoice invoice, String rendered) {
    saved.add(invoice);
    renderings.add(rendered);
  }
}

class SqlInvoiceRepository implements InvoiceRepository {
  @override
  void save(Invoice invoice, String rendered) {
    sideEffects.add('REAL DB WRITE for ${invoice.client}');
  }
}

/// ORCHESTRATION only — it composes the other three and owns no rules.
class IssueInvoice {
  final InvoiceRepository repository;
  final InvoiceFormatter formatter;

  const IssueInvoice({required this.repository, required this.formatter});

  String call(Invoice invoice) {
    final rendered = formatter.format(invoice);
    repository.save(invoice, rendered);
    return 'issued -> $rendered';
  }
}

// =============================================================================
// SECTION 2 — O · OPEN/CLOSED PRINCIPLE
// =============================================================================
// "Open for EXTENSION, closed for MODIFICATION."
//
// Points covered:
//   * the growing switch/if-on-type smell, and the bug it causes
//   * the refactor: interface + implementations + a registry (Strategy/Factory)
//   * proof: a brand-new variant works without editing the consumer
//   * `sealed` + exhaustive switch = CLOSED-set OCP (compiler-enforced);
//     an open interface = OPEN-set OCP (runtime-pluggable)
//   * apply on the 2nd-3rd variant — not speculatively
// =============================================================================

void section2Ocp() {
  section('SECTION 2 · O — OPEN/CLOSED PRINCIPLE');

  note('Intent: add behaviour by ADDING code, not by editing working code.');
  note('Every edit to a tested file risks a regression; a new file cannot.');

  topic('SMELLS');
  smells([
    'a switch or if/else-if chain over a type/enum that grows every sprint',
    'the same switch duplicated in several places (pricing, labels, icons)',
    'a merge conflict in one method every time two people add a variant',
    'a `default:` arm that silently does the wrong thing for new cases',
  ]);

  topic('X VIOLATION — edit the method for every new tier');
  for (final tier in ['regular', 'silver', 'gold']) {
    print('  ${tier.padRight(9)} -> ${legacyDiscount(tier, 100000)}p');
  }
  note('Now the business adds "platinum". The function is not updated yet:');
  show('platinum  -> falls into `default`', '${legacyDiscount('platinum', 100000)}p');
  note('SILENT BUG: a platinum customer gets 0% off and nobody throws. The');
  note('compiler cannot help — `default` swallowed the new case. And this same');
  note('switch is duplicated in the label, the badge icon, and the report.');

  topic('V REFACTOR — interface + implementations + registry');
  final registry = DiscountRegistry()
    ..register(const RegularDiscount())
    ..register(const SilverDiscount())
    ..register(const GoldDiscount());
  final priceService = PriceService(registry: registry);
  for (final tier in ['regular', 'silver', 'gold']) {
    print('  ${tier.padRight(9)} -> ${priceService.finalPrice(tier, 100000)}p');
  }
  show('unknown tier is explicit, not silent',
      priceService.describe('platinum'));

  topic('Extension WITHOUT modification — the proof');
  note('PlatinumDiscount is a NEW class. Registering it changes no existing');
  note('class: not PriceService, not DiscountRegistry, not the other tiers.');
  registry.register(const PlatinumDiscount());
  show('platinum now works', '${priceService.finalPrice('platinum', 100000)}p');
  show('PriceService source edits required', 0);
  show('existing strategy edits required', 0);
  note('Compare with the violation, where "platinum" needed a new switch arm in');
  note('every place the switch appeared.');

  topic('Two flavours of OCP');
  note('OPEN set (interface + registry, above):');
  note('  * new variants can arrive from anywhere, even another package');
  note('  * resolution happens at RUNTIME');
  note('  * risk: forgetting to register -> handle the miss explicitly');
  note('CLOSED set (`sealed` + exhaustive switch):');
  for (final method in <ShipMethod>[Standard(), Express(), Freight(weightKg: 120)]) {
    print('    ${shippingLabel(method)}');
  }
  note('  * the variants are finite and known (a domain enumeration)');
  note('  * adding one BREAKS COMPILATION until every switch handles it —');
  note('    which is exactly what you want for exhaustive domain logic');
  note('Choose sealed for closed domains (results, states); choose an');
  note('interface for genuinely open extension points (plugins, gateways).');

  topic('Do NOT apply OCP speculatively');
  note('One variant  -> write the concrete code. No interface.');
  note('Two variants -> notice the shape, maybe extract.');
  note('Three, or a variant from outside your module -> extract the abstraction.');
  note('Premature abstraction ("speculative generality") costs indirection,');
  note('files, and cognitive load for flexibility you never use. YAGNI applies');
  note('to design as much as to features.');

  topic('Flutter example');
  note('X  `Widget buildIcon(String type) { switch (type) { ... } }` growing');
  note('   an arm per feature, edited by every team.');
  note('V  a registry `Map<String, WidgetBuilder>` populated by each feature');
  note('   module — the shell widget never changes.');
  note('Same pattern powers `onGenerateRoute`, theme extensions, and the');
  note('form-field validator lists you compose rather than switch over.');

  topic('Enterprise example');
  note('X  PaymentProcessor with `if (gateway == "stripe") ... else if ...`.');
  note('V  a PaymentGateway interface; each gateway is a separate class (often');
  note('   a separate package), wired at the composition root. Adding');
  note('   "razorpay" ships without touching the checkout service or its tests.');
}

/// X the growing switch. Note `default` silently returning 0 for new tiers.
int legacyDiscount(String tier, int pricePaise) {
  switch (tier) {
    case 'regular':
      return pricePaise;
    case 'silver':
      return pricePaise - pricePaise * 5 ~/ 100;
    case 'gold':
      return pricePaise - pricePaise * 10 ~/ 100;
    default:
      return pricePaise; // new tiers land here and are silently ignored
  }
}

/// V the abstraction each variant implements.
abstract interface class DiscountStrategy {
  String get tier;
  int apply(int pricePaise);
}

class RegularDiscount implements DiscountStrategy {
  const RegularDiscount();
  @override
  String get tier => 'regular';
  @override
  int apply(int pricePaise) => pricePaise;
}

class SilverDiscount implements DiscountStrategy {
  const SilverDiscount();
  @override
  String get tier => 'silver';
  @override
  int apply(int pricePaise) => pricePaise - pricePaise * 5 ~/ 100;
}

class GoldDiscount implements DiscountStrategy {
  const GoldDiscount();
  @override
  String get tier => 'gold';
  @override
  int apply(int pricePaise) => pricePaise - pricePaise * 10 ~/ 100;
}

/// Added LAST. No existing class was modified to support it.
class PlatinumDiscount implements DiscountStrategy {
  const PlatinumDiscount();
  @override
  String get tier => 'platinum';
  @override
  int apply(int pricePaise) => pricePaise - pricePaise * 20 ~/ 100;
}

class DiscountRegistry {
  final Map<String, DiscountStrategy> _byTier = {};

  void register(DiscountStrategy strategy) => _byTier[strategy.tier] = strategy;
  DiscountStrategy? resolve(String tier) => _byTier[tier];
  List<String> get knownTiers => _byTier.keys.toList();
}

/// Closed for modification: no switch, no `is`, no knowledge of any tier.
class PriceService {
  final DiscountRegistry registry;
  const PriceService({required this.registry});

  int finalPrice(String tier, int pricePaise) {
    final strategy = registry.resolve(tier);
    if (strategy == null) {
      throw ArgumentError.value(tier, 'tier', 'no discount strategy registered');
    }
    return strategy.apply(pricePaise);
  }

  String describe(String tier) => registry.resolve(tier) == null
      ? 'unknown tier "$tier" (known: ${registry.knownTiers.join(", ")})'
      : 'tier "$tier" is registered';
}

/// CLOSED-set OCP: a finite domain the compiler can check exhaustively.
sealed class ShipMethod {
  const ShipMethod();
}

class Standard extends ShipMethod {
  const Standard();
}

class Express extends ShipMethod {
  const Express();
}

class Freight extends ShipMethod {
  final double weightKg;
  const Freight({required this.weightKg});
}

/// No `default`: add a 4th ShipMethod and this stops compiling.
String shippingLabel(ShipMethod method) => switch (method) {
      Standard() => 'standard — 5-7 days',
      Express() => 'express — next day',
      Freight(weightKg: final kg) => 'freight — ${kg}kg, quote required',
    };

// =============================================================================
// SECTION 3 — L · LISKOV SUBSTITUTION PRINCIPLE
// =============================================================================
// "A subtype must be usable ANYWHERE its base is expected, without the caller
//  knowing or caring."
//
// Points covered:
//   * no stronger preconditions, no weaker postconditions
//   * no broken invariants, no surprise exceptions
//   * the classic Square/Rectangle setter trap, and the fix
//   * an `UnsupportedError` override is a red flag
//   * `is`-special-casing in a caller is the symptom
//   * the ADAPTER fix: wrap a throwing legacy API so it honours the contract
//   * the compiler cannot enforce LSP — only tests and review can
// =============================================================================

void section3Lsp() {
  section('SECTION 3 · L — LISKOV SUBSTITUTION PRINCIPLE');

  note('Intent: subtypes must honour the BEHAVIOURAL contract of the base, not');
  note('just its method signatures. Dart checks signatures; only you can check');
  note('behaviour.');

  topic('SMELLS');
  smells([
    'an override that throws UnsupportedError / "not supported here"',
    'a caller doing `if (x is SpecificSubtype)` before it can proceed',
    'an override that tightens validation the base accepted',
    'documentation saying "do not pass a X here"',
    'a subclass that leaves inherited fields meaningless (unused salary, etc.)',
  ]);

  topic('X VIOLATION 1 — a broken POSTCONDITION (Square/Rectangle)');
  note('Contract of Rectangle: setting width does not change height.');
  final rectangle = MutableRectangle(width: 2, height: 3);
  final square = MutableSquare(side: 2);
  show('stretchToFiveByFour(rectangle) area', stretchToFiveByFour(rectangle));
  show('stretchToFiveByFour(square)    area', stretchToFiveByFour(square));
  note('The caller is correct and unchanged; the SUBTYPE broke the promise.');
  note('20 vs 16 — a silent numeric bug, the worst kind.');

  topic('X VIOLATION 2 — a stronger PRECONDITION');
  final validators = <BaseAmountValidator>[
    BaseAmountValidator(),
    StrictAmountValidator(),
  ];
  for (final validator in validators) {
    final outcome = validator.validate(50);
    print('  ${validator.runtimeType.toString().padRight(22)} validate(50) -> $outcome');
  }
  note('The base accepts any positive amount. The subtype demands >= 100, so');
  note('code written against the base starts failing when handed the subtype.');
  note('Subtypes may WEAKEN preconditions (accept more), never strengthen them.');

  topic('X VIOLATION 3 — a surprise EXCEPTION');
  final stores = <KeyValueStore>[MemoryStore(), ReadOnlyStore()];
  for (final store in stores) {
    try {
      store.put('k', 'v');
      print('  ${store.runtimeType.toString().padRight(15)} put -> ok');
    } on UnsupportedError catch (_) {
      print('  ${store.runtimeType.toString().padRight(15)} put -> UnsupportedError <-- LSP break');
    }
  }
  note('Every caller of `KeyValueStore.put` must now wrap it in try/catch or');
  note('type-check first. The abstraction has stopped abstracting.');
  note('Fix: split the interface (ISP!) so a read-only store has no `put`.');

  topic('V REFACTOR — model the real contract');
  final shapes = <Shape>[const Rect(width: 2, height: 4), const Sq(side: 4)];
  for (final shape in shapes) {
    print('  ${shape.runtimeType.toString().padRight(6)} area=${shape.area} '
        'widened-to-5 -> ${shape.withPrimary(5).area}');
  }
  note('Square and Rect are SIBLINGS, both immutable. There is no inherited');
  note('setter to lie about, so substitution is safe by construction.');

  topic('V REFACTOR — an ADAPTER makes a badly-behaved API substitutable');
  note('The contract: charge() returns a Result and NEVER throws for validated');
  note('input. LegacyGateway is a third-party class that throws — we cannot');
  note('change it, so we WRAP it.');
  final gateways = <PaymentGateway>[
    CardGateway(),
    UpiGateway(),
    LegacyGatewayAdapter(legacy: LegacyPaymentApi()),
  ];
  for (final gateway in gateways) {
    // Identical treatment for all three: no try/catch, no `is` check.
    final result = gateway.charge(50000);
    print('  ${gateway.runtimeType.toString().padRight(22)} -> $result');
  }
  note('And the amount that the legacy API rejects:');
  for (final gateway in gateways) {
    final result = gateway.charge(-1);
    print('  ${gateway.runtimeType.toString().padRight(22)} -> $result');
  }
  show('did any gateway throw?', 'no — the adapter converted the throw to Err');
  note('The caller loop is written ONCE against the interface. That is what');
  note('substitutability buys you.');

  topic('The rules, stated precisely');
  note('Preconditions  : a subtype may accept MORE, never less');
  note('Postconditions : a subtype may guarantee MORE, never less');
  note('Invariants     : must be preserved');
  note('Exceptions     : only those the base contract already allows');
  note('Return types   : may narrow (covariant) — Dart allows this');
  note('Parameters     : may widen (contravariant); narrowing needs `covariant`');
  note('               and moves the check to runtime, which is a smell');

  topic('The compiler cannot save you');
  show('MutableSquare compiles fine', true);
  show('ReadOnlyStore compiles fine', true);
  note('Both type-check perfectly and both break callers. LSP is enforced by');
  note('CONTRACT TESTS: write one test suite against the interface and run it');
  note('against every implementation. If a subtype fails it, it is not a subtype.');
  show('contract test over all 3 gateways', runGatewayContractTest(gateways));

  topic('Flutter example');
  note('X  a custom ScrollController subclass that throws in jumpTo(), so');
  note('   every widget expecting a ScrollController can crash.');
  note('X  a Widget subclass whose build() returns null-ish/empty in cases the');
  note('   parent assumed were renderable.');
  note('V  honour the framework contract exactly; if you cannot, compose a new');
  note('   type instead of subclassing one you cannot fully implement.');

  topic('Enterprise example');
  note('X  a `S3Storage` and a `LocalStorage` behind one `Storage` interface,');
  note('   where LocalStorage throws on `presignedUrl()`. Every caller');
  note('   type-checks, and the abstraction is worthless.');
  note('V  split into `Storage` (get/put) and `PresignableStorage` (adds urls).');
  note('   Callers that need URLs depend on the narrower role. ISP fixes LSP.');
}

// --- X postcondition violation ----------------------------------------------

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

  @override
  set width(double value) {
    _width = value;
    _height = value; // breaks the base postcondition
  }

  @override
  set height(double value) {
    _width = value;
    _height = value;
  }
}

/// Written against MutableRectangle's contract: 5 * 4 must be 20.
double stretchToFiveByFour(MutableRectangle rectangle) {
  rectangle.width = 5;
  rectangle.height = 4;
  return rectangle.area;
}

// --- X precondition violation ------------------------------------------------

class BaseAmountValidator {
  /// Contract: accepts any positive amount.
  String validate(int amount) =>
      amount > 0 ? 'accepted' : 'rejected: must be positive';
}

class StrictAmountValidator extends BaseAmountValidator {
  @override
  String validate(int amount) => amount >= 100
      ? 'accepted'
      : 'rejected: minimum is 100 <-- STRONGER precondition';
}

// --- X surprise exception ----------------------------------------------------

abstract interface class KeyValueStore {
  String? get(String key);
  void put(String key, String value);
}

class MemoryStore implements KeyValueStore {
  final Map<String, String> _data = {};
  @override
  String? get(String key) => _data[key];
  @override
  void put(String key, String value) => _data[key] = value;
}

class ReadOnlyStore implements KeyValueStore {
  @override
  String? get(String key) => 'frozen';
  @override
  void put(String key, String value) =>
      throw UnsupportedError('this store is read-only');
}

// --- V immutable siblings ----------------------------------------------------

abstract class Shape {
  const Shape();
  double get area;

  /// Returns a NEW shape — no setter can lie.
  Shape withPrimary(double value);
}

class Rect extends Shape {
  final double width;
  final double height;
  const Rect({required this.width, required this.height});
  @override
  double get area => width * height;
  @override
  Rect withPrimary(double value) => Rect(width: value, height: height);
}

class Sq extends Shape {
  final double side;
  const Sq({required this.side});
  @override
  double get area => side * side;
  @override
  Sq withPrimary(double value) => Sq(side: value);
}

// --- V the adapter that restores substitutability ----------------------------

/// The contract: never throws for validated input; failures come back as Err.
abstract interface class PaymentGateway {
  Result<String> charge(int amountPaise);
}

class CardGateway implements PaymentGateway {
  @override
  Result<String> charge(int amountPaise) => amountPaise > 0
      ? Ok('card charged ${amountPaise}p')
      : const Err('amount must be positive');
}

class UpiGateway implements PaymentGateway {
  @override
  Result<String> charge(int amountPaise) => amountPaise > 0
      ? Ok('upi charged ${amountPaise}p')
      : const Err('amount must be positive');
}

/// A third-party class we do NOT control. It throws.
class LegacyPaymentApi {
  String doCharge(int paise) {
    if (paise <= 0) throw ArgumentError('legacy: bad amount $paise');
    return 'legacy charged ${paise}p';
  }
}

/// Adapter: absorbs the throw so the CONTRACT holds.
class LegacyGatewayAdapter implements PaymentGateway {
  final LegacyPaymentApi legacy;
  LegacyGatewayAdapter({required this.legacy});

  @override
  Result<String> charge(int amountPaise) {
    try {
      return Ok(legacy.doCharge(amountPaise));
    } on ArgumentError catch (e) {
      return Err('adapted: ${e.message}');
    }
  }
}

/// One suite, run against every implementation. This is how LSP is enforced.
String runGatewayContractTest(List<PaymentGateway> gateways) {
  for (final gateway in gateways) {
    try {
      final good = gateway.charge(100);
      if (!good.isOk) return 'FAIL: ${gateway.runtimeType} rejected a valid amount';
      final bad = gateway.charge(-5);
      if (bad.isOk) return 'FAIL: ${gateway.runtimeType} accepted an invalid amount';
    } catch (e) {
      return 'FAIL: ${gateway.runtimeType} threw instead of returning Err';
    }
  }
  return 'PASS — all ${gateways.length} implementations honour the contract';
}

// =============================================================================
// SECTION 4 — I · INTERFACE SEGREGATION PRINCIPLE
// =============================================================================
// "No client should be forced to depend on members it does not use."
//
// Points covered:
//   * the fat interface, and the UnsupportedError stubs it forces
//   * the refactor: small ROLE interfaces, combined via multiple `implements`
//   * define interfaces on the CLIENT side (the consumer names what it needs)
//   * ISP supports LSP (no stub throws) and testability (tiny fakes)
// =============================================================================

void section4Isp() {
  section('SECTION 4 · I — INTERFACE SEGREGATION PRINCIPLE');

  note('Intent: an interface should be as small as its CLIENT needs, not as');
  note('large as its biggest implementer happens to be.');

  topic('SMELLS');
  smells([
    'implementations full of empty methods or UnsupportedError stubs',
    'an interface named after a THING (Machine) rather than a ROLE (Printer)',
    'a mock in your tests needs 12 method stubs to test one call',
    'adding a method to an interface breaks classes that will never use it',
    '"optional" members documented as "only call this on some subtypes"',
  ]);

  topic('X VIOLATION — one fat interface');
  final devices = <AllInOneMachine>[FatBasicPrinter(), FatOfficeMachine()];
  for (final device in devices) {
    final results = <String>[];
    for (final (name, action) in <(String, String Function())>[
      ('print', () => device.printDocument('report')),
      ('scan', () => device.scanDocument()),
      ('fax', () => device.faxDocument('555')),
    ]) {
      try {
        action();
        results.add('$name:ok');
      } on UnsupportedError catch (_) {
        results.add('$name:THROWS');
      }
    }
    print('  ${device.runtimeType.toString().padRight(18)} $results');
  }
  note('FatBasicPrinter had to implement scan and fax it cannot do, so it');
  note('throws — which also breaks LSP. And a client that only prints still');
  note('depends on scan/fax, so changing the fax signature recompiles it.');

  topic('V REFACTOR — role interfaces');
  final basic = BasicPrinter();
  final office = OfficeMachine();
  show('BasicPrinter fills the roles', rolesOf(basic));
  show('OfficeMachine fills the roles', rolesOf(office));
  note('No stubs, no throws: a class implements exactly the roles it fills.');

  topic('Each client depends on ONE role');
  show('printReport (needs Printer only) + BasicPrinter', printReport(basic));
  show('printReport (needs Printer only) + OfficeMachine', printReport(office));
  show('archiveDocument (needs Scanner only)', archiveDocument(office));
  show('sendFax (needs Fax only)', sendFax(office, '555-0100'));
  note('`printReport` cannot even be CALLED with something that only scans —');
  note('the mismatch is a compile error instead of a runtime throw.');

  topic('Tiny fakes — the testability payoff');
  final fakePrinter = FakePrinter();
  show('test printReport with a 1-method fake', printReport(fakePrinter));
  show('fake recorded', fakePrinter.printed);
  note('The fake implements ONE method. Under the fat interface it would need');
  note('scan() and fax() stubs too — noise in every test file.');

  topic('Define interfaces CLIENT-side');
  note('Wrong instinct: "what can my Device class do?" -> one fat interface');
  note('named after the implementation.');
  note('Right instinct: "what does this consumer NEED?" -> a narrow interface');
  note('named after the role, owned by the consumer\'s module.');
  note('Consequence: the same OfficeMachine satisfies three interfaces defined');
  note('in three different modules, none of which know about each other.');

  topic('ISP vs LSP vs DIP');
  note('ISP removes the need for stub-throws  -> makes LSP achievable.');
  note('ISP gives DIP something small to depend on -> cheap fakes.');
  note('All three push the same way: depend on the minimum you actually use.');

  topic('Do not over-segregate');
  note('One interface per method is as bad as one giant interface: you get');
  note('dozens of names and constructors with eight collaborators. Group');
  note('members that are ALWAYS used together — cohesion is the test.');

  topic('Flutter example');
  note('X  one `AppRepository` with 40 methods; every screen depends on all 40,');
  note('   and every widget test mocks all 40.');
  note('V  `AuthRepository`, `ProfileRepository`, `FeedRepository` — a screen');
  note('   takes only what it uses, and its test fakes only that.');
  note('This is also why Flutter has `Listenable`, `ValueListenable`, and');
  note('`ChangeNotifier` rather than one big observable type.');

  topic('Enterprise example');
  note('X  `UserService` exposing read, write, admin-delete and billing to all');
  note('   callers — a reporting job holds a handle that can delete users.');
  note('V  `UserReader` / `UserWriter` / `UserAdmin`. The reporting job takes');
  note('   `UserReader`, so "can it delete?" is answered by the TYPE, and');
  note('   least-privilege is enforced at compile time.');
}

// --- X the fat interface -----------------------------------------------------

abstract interface class AllInOneMachine {
  String printDocument(String doc);
  String scanDocument();
  String faxDocument(String number);
}

class FatBasicPrinter implements AllInOneMachine {
  @override
  String printDocument(String doc) => 'printed $doc';

  @override
  String scanDocument() => throw UnsupportedError('no scanner on this device');

  @override
  String faxDocument(String number) => throw UnsupportedError('no fax on this device');
}

class FatOfficeMachine implements AllInOneMachine {
  @override
  String printDocument(String doc) => 'printed $doc';
  @override
  String scanDocument() => 'scanned';
  @override
  String faxDocument(String number) => 'faxed to $number';
}

// --- V role interfaces -------------------------------------------------------

abstract interface class Printer {
  String printDocument(String doc);
}

abstract interface class Scanner {
  String scanDocument();
}

abstract interface class Fax {
  String faxDocument(String number);
}

class BasicPrinter implements Printer {
  @override
  String printDocument(String doc) => 'printed $doc';
}

class OfficeMachine implements Printer, Scanner, Fax {
  @override
  String printDocument(String doc) => 'printed $doc';
  @override
  String scanDocument() => 'scanned';
  @override
  String faxDocument(String number) => 'faxed to $number';
}

/// A 1-method fake — only possible because the interface is narrow.
class FakePrinter implements Printer {
  final List<String> printed = [];
  @override
  String printDocument(String doc) {
    printed.add(doc);
    return 'fake printed $doc';
  }
}

/// Reports which roles a device actually fills. Takes `Object` so each check is
/// a genuine runtime test.
List<String> rolesOf(Object device) {
  final roles = <String>[];
  if (device is Printer) roles.add('Printer');
  if (device is Scanner) roles.add('Scanner');
  if (device is Fax) roles.add('Fax');
  return roles;
}

// Each client asks for exactly one role.
String printReport(Printer printer) => printer.printDocument('monthly-report');
String archiveDocument(Scanner scanner) => scanner.scanDocument();
String sendFax(Fax fax, String number) => fax.faxDocument(number);

// =============================================================================
// SECTION 5 — D · DEPENDENCY INVERSION PRINCIPLE
// =============================================================================
// "High-level policy must not depend on low-level detail. Both should depend on
//  an abstraction — and the abstraction belongs to the high level."
//
// Points covered:
//   * high-level module `new`ing its own concretes = untestable + rigid
//   * the refactor: constructor-inject abstractions
//   * the CONSUMER owns the interface, and it must be detail-free
//   * wiring happens once, at the COMPOSITION ROOT
//   * DIP is the principle; DI is the technique
//   * invert the VOLATILE dependencies (network, db, clock, random), not
//     stable ones (String, List, math)
// =============================================================================

void section5Dip() {
  section('SECTION 5 · D — DEPENDENCY INVERSION PRINCIPLE');

  note('Intent: point the arrows inward. Business rules should not know about');
  note('SQLite, HTTP, or SMTP — those should conform to the rules\' interfaces.');

  topic('SMELLS');
  smells([
    '`new`/constructor calls to infrastructure inside a business class',
    'a business file importing a database, http, or platform package',
    'a test that needs a real network, clock, filesystem or random source',
    'a class you cannot construct without booting half the app',
    'static singletons reached from anywhere (a hidden dependency)',
  ]);

  topic('X VIOLATION — high-level policy depends on concretes');
  sideEffects.clear();
  final rigid = RigidSignupService();
  show('it works, but look at the cost', rigid.signUp('ada@example.com'));
  show('side effects performed', sideEffects);
  note('RigidSignupService constructs a real database and a real mail client');
  note('inside itself. Therefore:');
  note('  * you cannot unit-test it without a DB and an SMTP server');
  note('  * you cannot swap Postgres for Mongo without editing the policy');
  note('  * you cannot verify "an email was sent" — it just happens');
  note('  * the arrow points DOWN: policy -> detail. That is the inversion');
  note('    that has not happened yet.');

  topic('V REFACTOR — inject abstractions');
  sideEffects.clear();
  final fakeUsers = InMemoryUserStore();
  final fakeMail = RecordingMailer();
  final fakeClock = FixedClock(DateTime(2026, 8, 17));
  final testable = SignupService(
    users: fakeUsers,
    mailer: fakeMail,
    clock: fakeClock,
  );
  show('same behaviour', testable.signUp('ada@example.com'));
  show('side effects (nothing real was touched)',
      sideEffects.isEmpty ? 'none' : sideEffects);
  show('ASSERTED: user persisted', fakeUsers.saved);
  show('ASSERTED: welcome email sent', fakeMail.sent);
  show('ASSERTED: deterministic timestamp', fakeUsers.timestamps.first);
  note('The test can now assert on OUTCOMES, not just "it did not crash".');

  topic('Same policy, production wiring');
  sideEffects.clear();
  final production = CompositionRoot.buildSignupService();
  show('production run', production.signUp('grace@navy.mil'));
  show('real infrastructure was used', sideEffects);
  note('SignupService did not change. Only the WIRING changed.');

  topic('The consumer owns the interface — and it must be detail-free');
  note('V  `abstract interface class UserStore { void save(User, DateTime); }`');
  note('   lives next to SignupService, in the DOMAIN layer.');
  note('X  `abstract class UserStore { Future<PostgresResult> upsertRow(...); }`');
  note('   is a leaky abstraction: `PostgresResult` drags the detail back in,');
  note('   so swapping the database still edits the domain.');
  note('Test for leakage: could a totally different technology implement this');
  note('interface without contortions? If not, it is not an abstraction.');

  topic('Direction of the dependency arrows');
  note('BEFORE:  SignupService  ---->  PostgresUserStore   (policy -> detail)');
  note('AFTER:   SignupService  ---->  UserStore  <----  PostgresUserStore');
  note('                              (abstraction)');
  note('The detail now depends on the abstraction the POLICY declared. The');
  note('arrow from infrastructure points UP into the domain. That is the');
  note('"inversion", and it is the whole basis of Clean Architecture.');

  topic('DIP vs DI vs a DI container');
  note('DIP       : the PRINCIPLE — depend on abstractions.');
  note('DI        : the TECHNIQUE — pass dependencies in. Constructor');
  note('            injection is the default: it makes them explicit and');
  note('            makes an incompletely-wired object impossible to build.');
  note('Container : the TOOL (get_it, riverpod, injectable). Optional. Using a');
  note('            container while every class still `new`s its own deps buys');
  note('            you nothing — you can have DI with no container, and a');
  note('            container with no DIP.');
  note('Service locator caveat: `GetIt.I<Foo>()` inside a class hides the');
  note('dependency again. Prefer constructor injection; use the locator only');
  note('at the composition root.');

  topic('What to invert — and what NOT to');
  note('INVERT (volatile / external / non-deterministic):');
  note('  network, database, filesystem, DateTime.now(), Random, device APIs,');
  note('  push notifications, analytics, payment gateways');
  note('DO NOT INVERT (stable, pure, deterministic):');
  note('  String, List, Map, math, your own value objects and pure functions');
  note('Wrapping `int.parse` behind an interface is ceremony with no payoff.');
  show('why invert the clock? deterministic tests', fakeClock.now().year);

  topic('Flutter example');
  note('X  a Widget calling `http.get(...)` or `FirebaseAuth.instance` directly.');
  note('V  Widget -> ViewModel -> AuthRepository (interface)');
  note('              ^ injected via Provider/Riverpod/get_it at app start');
  note('   Tests pump the widget with a FakeAuthRepository — no Firebase, no');
  note('   network, instant and deterministic.');

  topic('Enterprise example');
  note('X  domain/OrderService.dart imports package:postgres and package:aws.');
  note('V  domain declares OrderRepository + PaymentGateway + EventPublisher;');
  note('   infrastructure implements them; main() wires it. The domain package');
  note('   has ZERO infrastructure dependencies in its pubspec — a rule you can');
  note('   enforce in CI, which is how architecture stops eroding.');
}

// --- X the rigid version ----------------------------------------------------

class PostgresDatabase {
  void insertUser(String email) => sideEffects.add('REAL DB INSERT $email');
}

class SmtpMailClient {
  void send(String to, String body) => sideEffects.add('REAL SMTP -> $to');
}

/// High-level policy welded to low-level detail.
class RigidSignupService {
  String signUp(String email) {
    final db = PostgresDatabase(); // <-- hard-wired detail
    final mail = SmtpMailClient(); // <-- hard-wired detail
    final now = DateTime.now(); // <-- hidden, non-deterministic dependency

    if (!email.contains('@')) return 'invalid email';
    db.insertUser(email);
    mail.send(email, 'welcome!');
    return 'signed up $email at ${now.year} (untestable)';
  }
}

// --- V abstractions owned by the consumer -----------------------------------

class User {
  final String email;
  const User(this.email);
  @override
  String toString() => 'User($email)';
}

abstract interface class UserStore {
  void save(User user, DateTime at);
}

abstract interface class Mailer {
  void sendWelcome(String to);
}

abstract interface class AppClock {
  DateTime now();
}

// Test doubles.
class InMemoryUserStore implements UserStore {
  final List<User> saved = [];
  final List<DateTime> timestamps = [];
  @override
  void save(User user, DateTime at) {
    saved.add(user);
    timestamps.add(at);
  }
}

class RecordingMailer implements Mailer {
  final List<String> sent = [];
  @override
  void sendWelcome(String to) => sent.add(to);
}

class FixedClock implements AppClock {
  final DateTime fixed;
  FixedClock(this.fixed);
  @override
  DateTime now() => fixed;
}

// Production implementations — they depend on the abstraction, not vice versa.
class PostgresUserStore implements UserStore {
  final PostgresDatabase db;
  PostgresUserStore({required this.db});
  @override
  void save(User user, DateTime at) => db.insertUser(user.email);
}

class SmtpMailer implements Mailer {
  final SmtpMailClient client;
  SmtpMailer({required this.client});
  @override
  void sendWelcome(String to) => client.send(to, 'welcome!');
}

class SystemClock implements AppClock {
  const SystemClock();
  @override
  DateTime now() => DateTime.now();
}

/// High-level policy. Knows THREE interfaces and zero technologies.
class SignupService {
  final UserStore users;
  final Mailer mailer;
  final AppClock clock;

  const SignupService({
    required this.users,
    required this.mailer,
    required this.clock,
  });

  String signUp(String email) {
    if (!email.contains('@')) return 'invalid email';
    users.save(User(email), clock.now());
    mailer.sendWelcome(email);
    return 'signed up $email';
  }
}

/// The ONE place that knows about concrete technologies.
class CompositionRoot {
  static SignupService buildSignupService() => SignupService(
        users: PostgresUserStore(db: PostgresDatabase()),
        mailer: SmtpMailer(client: SmtpMailClient()),
        clock: const SystemClock(),
      );
}

// =============================================================================
// SECTION 6 — MINI PROJECTS 1-4
// =============================================================================

void section6MiniProjects() {
  section('SECTION 6 · MINI PROJECTS 1-4');

  topic('01 · Invoice module refactor (SRP)');
  sideEffects.clear();
  const invoice = Invoice(client: 'Globex', amountPaise: 250000);
  final repo = InMemoryInvoiceRepository();
  note('Each class tested in ISOLATION:');
  show('  rules only (no repo, no formatter)', invoice.totalPaise);
  show('  formatting only (no repo)', const PlainTextInvoiceFormatter().format(invoice));
  show('  formatting, other format', const HtmlInvoiceFormatter().format(invoice));
  show('  persistence only (fake repo)', () {
    repo.save(invoice, 'precomputed');
    return repo.saved.length;
  }());
  show('  orchestration', IssueInvoice(
    repository: repo,
    formatter: const HtmlInvoiceFormatter(),
  ).call(invoice));
  show('real infrastructure touched', sideEffects.isEmpty ? 'none' : sideEffects);
  note('Acceptance met: one responsibility each; no test needed an unrelated');
  note('dependency.');

  topic('02 · Pluggable discount engine (OCP)');
  final registry = DiscountRegistry()
    ..register(const RegularDiscount())
    ..register(const SilverDiscount())
    ..register(const GoldDiscount());
  final prices = PriceService(registry: registry);
  show('known tiers', registry.knownTiers);
  for (final tier in registry.knownTiers) {
    print('  ${tier.padRight(9)} 100000p -> ${prices.finalPrice(tier, 100000)}p');
  }
  note('Now add a brand-new tier. Files edited: ZERO.');
  registry.register(const PlatinumDiscount());
  show('platinum', '${prices.finalPrice('platinum', 100000)}p');
  show('PriceService still has no type-switch', true);
  show('unregistered tier is explicit', prices.describe('diamond'));

  topic('03 · Contract-safe gateway (LSP)');
  final gateways = <PaymentGateway>[
    CardGateway(),
    UpiGateway(),
    LegacyGatewayAdapter(legacy: LegacyPaymentApi()),
  ];
  show('contract test across all implementations', runGatewayContractTest(gateways));
  note('Substituted through the interface with identical calling code:');
  for (final gateway in gateways) {
    print('  ${gateway.runtimeType.toString().padRight(22)} '
        'valid=${gateway.charge(1000)} invalid=${gateway.charge(0)}');
  }
  note('Acceptance met: no caller special-cases a subtype; the throwing legacy');
  note('API was wrapped, not exposed.');

  topic('04 · Device driver roles (ISP)');
  final basic = BasicPrinter();
  final allInOne = OfficeMachine();
  show('printReport(BasicPrinter)', printReport(basic));
  show('printReport(OfficeMachine)', printReport(allInOne));
  show('archiveDocument(OfficeMachine)', archiveDocument(allInOne));
  show('sendFax(OfficeMachine)', sendFax(allInOne, '555-0199'));
  final fake = FakePrinter();
  show('tiny fake satisfies the client', printReport(fake));
  show('UnsupportedError stubs anywhere?', 'none');
  note('`printReport(scannerOnlyDevice)` would not COMPILE — the mismatch is');
  note('caught by the type system instead of at runtime.');
}

// =============================================================================
// SECTION 7 — CAPSTONE: THE ORDER-SERVICE REFACTOR (all five principles)
// =============================================================================
// Before: `OrderEverything` parses, validates, prices with if/else on type,
// saves to a DB, sends email, formats a receipt and logs — with every
// dependency constructed inside itself.
//
// After: seven collaborators behind narrow interfaces, pricing as pluggable
// strategies, contracts that return Result instead of throwing, and all wiring
// at a composition root.
// =============================================================================

void section7Capstone() {
  section('SECTION 7 · CAPSTONE — ORDER SERVICE REFACTOR');

  topic('X BEFORE — OrderEverything');
  sideEffects.clear();
  final bad = OrderEverything();
  show('happy path', bad.process('gold|1500'));
  show('bad input', bad.process('nonsense'));
  show('unknown tier (silently full price)', bad.process('platinum|1000'));
  show('side effects, unavoidable', sideEffects);
  note('');
  note('Violations, one per principle:');
  note('  SRP: parses + validates + prices + saves + emails + formats + logs');
  note('  OCP: `if (tier == ...)` — every new tier edits this method');
  note('  LSP: one String return channel carries BOTH receipts and errors, so');
  note('       success and failure are told apart by string-matching "ERROR:".');
  note('       Worse, an unknown tier returns a perfectly valid-looking');
  note('       receipt at full price — the postcondition "the total reflects');
  note('       the tier" is silently broken.');
  note('  ISP: nothing is behind an interface, so a client depends on all of it');
  note('  DIP: it constructs its own Database and mail client inside the policy');
  note('Consequence: it cannot be unit-tested at all, and the "platinum" bug');
  note('above is silent.');

  topic('V AFTER — composed from single-purpose parts');
  final pricing = PricingEngine()
    ..register(const RegularTier())
    ..register(const GoldTier());
  final orders = FakeOrderRepository();
  final notifier = FakeNotifier();
  final log = ListLogger();
  final service = OrderService(
    parser: const OrderParser(),
    validator: const OrderValidator(),
    pricing: pricing,
    repository: orders,
    notifier: notifier,
    logger: log,
    formatter: const ReceiptFormatter(),
  );

  sideEffects.clear();
  for (final input in ['gold|1500', 'regular|500', 'nonsense', 'gold|-5', 'platinum|1000']) {
    final result = service.place(input);
    print('  ${input.padRight(14)} -> $result');
  }
  show('real infrastructure touched', sideEffects.isEmpty ? 'none' : sideEffects);
  show('orders persisted', orders.saved.length);
  show('notifications sent', notifier.sent);
  show('log lines', log.lines.length);
  note('Every failure came back as an Err — nothing threw, so the caller loop');
  note('needed no try/catch.');

  topic('Proof: adding a tier edits NO existing class');
  pricing.register(const PlatinumTier());
  show('platinum now priced correctly', service.place('platinum|1000'));
  show('OrderService edited?', 'no');
  show('existing tiers edited?', 'no');

  topic('Proof: adding a notification channel edits NO existing class');
  final multi = FanOutNotifier(channels: [FakeNotifier(), SmsChannel(), PushChannel()]);
  final serviceWithSms = OrderService(
    parser: const OrderParser(),
    validator: const OrderValidator(),
    pricing: pricing,
    repository: orders,
    notifier: multi, // a Notifier that happens to hold three Notifiers
    logger: log,
    formatter: const ReceiptFormatter(),
  );
  show('order with 3 channels', serviceWithSms.place('gold|2000'));
  show('channels notified', multi.log);
  note('FanOutNotifier is itself a Notifier (Composite pattern), so');
  note('OrderService cannot tell the difference — and did not change.');

  topic('Proof: production wiring, same service');
  sideEffects.clear();
  final live = OrderCompositionRoot.build(pricing);
  show('production run', live.place('gold|999'));
  show('real infrastructure used', sideEffects);
  note('One class knows about concrete technologies. Everything else is policy.');

  topic('Scorecard');
  for (final (letter, how) in const [
    ('S', 'parser / validator / pricing / repo / notifier / logger / formatter'),
    ('O', 'PricingEngine registry — new tier = new class, zero edits'),
    ('L', 'every collaborator returns Result; no surprise throws'),
    ('I', 'OrderRepository, Notifier, Logger are 1-2 method roles'),
    ('D', 'OrderService holds only interfaces; concretes injected at the root'),
  ]) {
    print('  $letter -> $how');
  }
  note('');
  note('Acceptance from the notes, verified above:');
  note('  * OrderService contains no `new` and no type-switch');
  note('  * the whole suite ran on fakes — no DB, no SMTP');
  note('  * a new tier and a new channel each edited zero existing classes');

  print('\nAll 5 principles demonstrated (violation + refactor). '
      'Read each notes file for the theory.');
}

// --- X the God class --------------------------------------------------------

class Database {
  void insert(String row) => sideEffects.add('REAL DB INSERT: $row');
}

class Mailer2 {
  void send(String body) => sideEffects.add('REAL EMAIL: $body');
}

class OrderEverything {
  String process(String raw) {
    // 1. parse
    final parts = raw.split('|');
    if (parts.length != 2) {
      return 'ERROR: could not parse "$raw"'; // ad-hoc error channel
    }
    final tier = parts[0];
    final amount = int.tryParse(parts[1]);
    // 2. validate
    if (amount == null || amount <= 0) {
      return 'ERROR: bad amount';
    }
    // 3. price — a switch that grows forever
    int total;
    if (tier == 'regular') {
      total = amount;
    } else if (tier == 'gold') {
      total = amount - amount * 10 ~/ 100;
    } else {
      total = amount; // platinum silently pays full price
    }
    // 4. persist — hard-wired detail
    Database().insert('$tier:$total');
    // 5. notify — hard-wired detail
    Mailer2().send('your order total is $total');
    // 6. format
    final receipt = 'RECEIPT tier=$tier total=$total';
    // 7. log
    sideEffects.add('LOG: processed $raw');
    return receipt;
  }
}

// --- V the refactor ---------------------------------------------------------

class OrderRequest {
  final String tier;
  final int amountPaise;
  const OrderRequest({required this.tier, required this.amountPaise});
}

class Receipt {
  final String tier;
  final int totalPaise;
  const Receipt({required this.tier, required this.totalPaise});
}

/// SRP: parsing only.
class OrderParser {
  const OrderParser();

  Result<OrderRequest> parse(String raw) {
    final parts = raw.split('|');
    if (parts.length != 2) return Err('cannot parse "$raw"');
    final amount = int.tryParse(parts[1]);
    if (amount == null) return Err('amount "${parts[1]}" is not a number');
    return Ok(OrderRequest(tier: parts[0], amountPaise: amount));
  }
}

/// SRP: validation only.
class OrderValidator {
  const OrderValidator();

  Result<OrderRequest> validate(OrderRequest request) =>
      request.amountPaise <= 0
          ? Err('amount must be positive, got ${request.amountPaise}')
          : Ok(request);
}

/// OCP: pricing tiers are pluggable strategies.
abstract interface class PricingTier {
  String get tier;
  int priceFor(int amountPaise);
}

class RegularTier implements PricingTier {
  const RegularTier();
  @override
  String get tier => 'regular';
  @override
  int priceFor(int amountPaise) => amountPaise;
}

class GoldTier implements PricingTier {
  const GoldTier();
  @override
  String get tier => 'gold';
  @override
  int priceFor(int amountPaise) => amountPaise - amountPaise * 10 ~/ 100;
}

/// Added last — no existing class was edited.
class PlatinumTier implements PricingTier {
  const PlatinumTier();
  @override
  String get tier => 'platinum';
  @override
  int priceFor(int amountPaise) => amountPaise - amountPaise * 25 ~/ 100;
}

class PricingEngine {
  final Map<String, PricingTier> _tiers = {};

  void register(PricingTier tier) => _tiers[tier.tier] = tier;

  /// LSP: returns Err instead of throwing, so callers need no try/catch.
  Result<int> price(OrderRequest request) {
    final tier = _tiers[request.tier];
    if (tier == null) {
      return Err('unknown tier "${request.tier}" '
          '(known: ${_tiers.keys.join(", ")})');
    }
    return Ok(tier.priceFor(request.amountPaise));
  }
}

/// ISP: one method each.
abstract interface class OrderRepository {
  Result<void> save(Receipt receipt);
}

abstract interface class Notifier {
  Result<void> notify(String message);
}

abstract interface class Logger {
  void log(String line);
}

class FakeOrderRepository implements OrderRepository {
  final List<Receipt> saved = [];
  @override
  Result<void> save(Receipt receipt) {
    saved.add(receipt);
    return const Ok(null);
  }
}

class FakeNotifier implements Notifier {
  final List<String> sent = [];
  @override
  Result<void> notify(String message) {
    sent.add(message);
    return const Ok(null);
  }
}

class SmsChannel implements Notifier {
  final List<String> sent = [];
  @override
  Result<void> notify(String message) {
    sent.add('sms: $message');
    return const Ok(null);
  }
}

class PushChannel implements Notifier {
  final List<String> sent = [];
  @override
  Result<void> notify(String message) {
    sent.add('push: $message');
    return const Ok(null);
  }
}

/// Composite: a Notifier made of Notifiers. OrderService cannot tell.
class FanOutNotifier implements Notifier {
  final List<Notifier> channels;
  final List<String> log = [];

  FanOutNotifier({required this.channels});

  @override
  Result<void> notify(String message) {
    for (final channel in channels) {
      channel.notify(message);
      log.add(channel.runtimeType.toString());
    }
    return const Ok(null);
  }
}

class ListLogger implements Logger {
  final List<String> lines = [];
  @override
  void log(String line) => lines.add(line);
}

/// SRP: formatting only.
class ReceiptFormatter {
  const ReceiptFormatter();
  String format(Receipt receipt) =>
      'RECEIPT tier=${receipt.tier} total=${receipt.totalPaise}p';
}

/// DIP: depends on seven ABSTRACTIONS. No `new`, no type-switch, no throw.
class OrderService {
  final OrderParser parser;
  final OrderValidator validator;
  final PricingEngine pricing;
  final OrderRepository repository;
  final Notifier notifier;
  final Logger logger;
  final ReceiptFormatter formatter;

  const OrderService({
    required this.parser,
    required this.validator,
    required this.pricing,
    required this.repository,
    required this.notifier,
    required this.logger,
    required this.formatter,
  });

  String place(String raw) {
    logger.log('placing order from "$raw"');

    final parsed = parser.parse(raw);
    return parsed.fold(
      err: (e) => 'Err($e)',
      ok: (request) => validator.validate(request).fold(
        err: (e) => 'Err($e)',
        ok: (valid) => pricing.price(valid).fold(
          err: (e) => 'Err($e)',
          ok: (total) {
            final receipt = Receipt(tier: valid.tier, totalPaise: total);
            return repository.save(receipt).fold(
              err: (e) => 'Err(save failed: $e)',
              ok: (_) {
                final rendered = formatter.format(receipt);
                notifier.notify(rendered);
                logger.log('order placed: $rendered');
                return 'Ok($rendered)';
              },
            );
          },
        ),
      ),
    );
  }
}

/// Production wiring — the only class that names concrete technologies.
class LiveOrderRepository implements OrderRepository {
  @override
  Result<void> save(Receipt receipt) {
    Database().insert('${receipt.tier}:${receipt.totalPaise}');
    return const Ok(null);
  }
}

class EmailNotifier implements Notifier {
  @override
  Result<void> notify(String message) {
    Mailer2().send(message);
    return const Ok(null);
  }
}

class PrintLogger implements Logger {
  @override
  void log(String line) => sideEffects.add('LOG: $line');
}

class OrderCompositionRoot {
  static OrderService build(PricingEngine pricing) => OrderService(
        parser: const OrderParser(),
        validator: const OrderValidator(),
        pricing: pricing,
        repository: LiveOrderRepository(),
        notifier: EmailNotifier(),
        logger: PrintLogger(),
        formatter: const ReceiptFormatter(),
      );
}
