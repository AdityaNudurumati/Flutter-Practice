// =============================================================================
// 05 · DESIGN PATTERNS — ALL-IN-ONE PRACTICAL FILE
// =============================================================================
// Runnable companion to the 21 notes files in this folder. Each section follows
// the structure the notes use:
//
//     INTENT  ->  the PROBLEM/smell it solves  ->  Dart implementation
//             ->  Flutter / real-world usage   ->  when NOT to use it
//
// Each section's implementation IS that file's Mini Project, so all 21 mini
// projects are built here rather than repeated in a separate block.
//
//   Run:      fvm dart run --enable-asserts "22_practicals_all_in_one.dart"
//   Analyze:  fvm dart analyze "22_practicals_all_in_one.dart"
//
// Map of sections -> source notes file:
//   CREATIONAL
//     1  Factory ....................... 01_factory.md
//     2  Builder ....................... 02_builder.md
//     3  Singleton ..................... 03_singleton.md
//     4  Prototype ..................... 04_prototype.md
//   STRUCTURAL
//     5  Adapter ....................... 05_adapter.md
//     6  Decorator ..................... 06_decorator.md
//     7  Facade ........................ 07_facade.md
//     8  Bridge ........................ 08_bridge.md
//     9  Composite ..................... 09_composite.md
//     10 Proxy ......................... 10_proxy.md
//   BEHAVIOURAL
//     11 Strategy ...................... 11_strategy.md
//     12 Observer ...................... 12_observer.md
//     13 Command ....................... 13_command.md
//     14 State ......................... 14_state.md
//     15 Template Method ............... 15_template_method.md
//     16 Chain of Responsibility ....... 16_chain_of_responsibility.md
//     17 Mediator ...................... 17_mediator.md
//     18 Visitor ....................... 18_visitor.md
//     19 Iterator ...................... 19_iterator.md
//   APPLICATION
//     20 Repository .................... 20_repository.md
//     21 Dependency Injection .......... 21_dependency_injection.md
//     22 Choosing a pattern (and the confusable pairs)
// =============================================================================

import 'dart:async';
import 'dart:collection';

Future<void> main() async {
  // Creational
  section1Factory();
  section2Builder();
  section3Singleton();
  section4Prototype();
  // Structural
  section5Adapter();
  section6Decorator();
  section7Facade();
  section8Bridge();
  section9Composite();
  section10Proxy();
  // Behavioural
  section11Strategy();
  await section12Observer();
  section13Command();
  section14State();
  section15TemplateMethod();
  section16ChainOfResponsibility();
  section17Mediator();
  section18Visitor();
  section19Iterator();
  // Application
  section20Repository();
  section21DependencyInjection();
  section22ChoosingAPattern();
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

void intent(String text) => print('  INTENT: $text');
void problem(String text) => print('  PROBLEM IT SOLVES: $text');

void flutterUse(List<String> lines) {
  print('  FLUTTER / REAL WORLD:');
  for (final line in lines) {
    print('    * $line');
  }
}

void avoidWhen(List<String> lines) {
  print('  WHEN NOT TO USE:');
  for (final line in lines) {
    print('    x $line');
  }
}

/// Records side effects a "real" dependency would perform.
final List<String> effects = [];

// =============================================================================
// Shared Result type — several patterns return outcomes instead of throwing.
// =============================================================================

sealed class Result<T> {
  const Result();

  R fold<R>({
    required R Function(T value) ok,
    required R Function(String error) err,
  }) =>
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
// SECTION 1 — FACTORY (Simple / Factory Method / Abstract Factory)
// =============================================================================

void section1Factory() {
  section('1 · FACTORY  [creational]');
  intent('Create objects without naming their concrete classes.');
  problem('`new ConcreteThing()` scattered everywhere couples every caller to '
      'every implementation, so swapping one means editing all of them.');

  topic('a) SIMPLE factory — a function/ctor returning the ABSTRACTION');
  for (final km in [2, 40, 4000]) {
    final transport = Transport.forDistance(km);
    print('  ${km.toString().padLeft(5)}km -> ${transport.runtimeType} '
        '(${transport.describe()})');
  }
  note('Callers get a `Transport`; the decision lives in ONE place.');
  note('Dart supports this natively with a `factory` constructor, so you do not');
  note('need a separate `TransportFactory` class at all.');

  topic('b) FACTORY METHOD — the SUBCLASS decides which product');
  for (final dialog in <DialogCreator>[InfoDialogCreator(), ErrorDialogCreator()]) {
    // The base algorithm is fixed; the subclass supplies the product.
    print('  ${dialog.runtimeType.toString().padRight(20)} -> ${dialog.render()}');
  }
  note('`DialogCreator.render()` never names a concrete dialog. Subclasses');
  note('override `createDialog()` — the "factory METHOD".');

  topic('c) ABSTRACT FACTORY — a whole FAMILY of matching products');
  note('Mini project: a UI kit where the family must stay internally consistent');
  note('(never a Material button next to a Cupertino switch).');
  for (final platform in UiPlatform.values) {
    final factory = uiFactoryFor(platform);
    print('  ${platform.name.padRight(10)} ${renderSettingsForm(factory)}');
  }
  show('did renderSettingsForm name any concrete class?', 'no — only UiFactory');

  topic('Registry > switch (the OCP upgrade)');
  final registry = TransportRegistry()
    ..register('bike', () => const Bike())
    ..register('car', () => const Car());
  show('resolve("bike")', registry.create('bike')?.describe());
  registry.register('rocket', () => const Rocket()); // NEW, nothing edited
  show('resolve("rocket") after late registration', registry.create('rocket')?.describe());
  show('unknown key is explicit', registry.create('teleporter') ?? 'not registered');
  note('A `switch` inside the factory still needs editing per product; a');
  note('registry map does not. Same pattern, one step more open.');

  flutterUse([
    'adaptive widgets: a Material family vs a Cupertino family per platform',
    '`Theme.of(context)` handing you a consistent family of styles',
    '`Icon`/`Icons` and `MaterialPageRoute` vs `CupertinoPageRoute`',
    'json `fromJson` factory constructors',
  ]);
  avoidWhen([
    'there is exactly ONE implementation — just call the constructor',
    'construction is trivial and unlikely to vary (speculative generality)',
    'you only need to pick an ALGORITHM, not create an object -> Strategy',
  ]);
}

// --- simple factory ---
abstract class Transport {
  const Transport();

  /// Dart's own `factory` constructor IS the simple-factory pattern.
  factory Transport.forDistance(int km) {
    if (km < 5) return const Bike();
    if (km < 500) return const Car();
    return const Plane();
  }

  String describe();
}

class Bike extends Transport {
  const Bike();
  @override
  String describe() => 'pedal, 15km/h';
}

class Car extends Transport {
  const Car();
  @override
  String describe() => 'drive, 60km/h';
}

class Plane extends Transport {
  const Plane();
  @override
  String describe() => 'fly, 800km/h';
}

class Rocket extends Transport {
  const Rocket();
  @override
  String describe() => 'launch, 28000km/h';
}

class TransportRegistry {
  final Map<String, Transport Function()> _builders = {};
  void register(String key, Transport Function() build) => _builders[key] = build;
  Transport? create(String key) => _builders[key]?.call();
}

// --- factory method ---
abstract class AppDialog {
  String get body;
}

class InfoDialog implements AppDialog {
  @override
  String get body => 'info';
}

class ErrorDialog implements AppDialog {
  @override
  String get body => 'error';
}

abstract class DialogCreator {
  /// THE factory method — subclasses decide the product.
  AppDialog createDialog();

  /// Fixed algorithm that works for every product.
  String render() {
    final dialog = createDialog();
    return '[${dialog.body.toUpperCase()}] rendered with a border';
  }
}

class InfoDialogCreator extends DialogCreator {
  @override
  AppDialog createDialog() => InfoDialog();
}

class ErrorDialogCreator extends DialogCreator {
  @override
  AppDialog createDialog() => ErrorDialog();
}

// --- abstract factory (mini project: UI kit) ---
enum UiPlatform { material, cupertino, fluent }

abstract interface class UiButton {
  String render(String label);
}

abstract interface class UiCheckbox {
  String render(bool checked);
}

abstract interface class UiSwitch {
  String render(bool on);
}

/// The family contract. One implementation per design language.
abstract interface class UiFactory {
  UiButton button();
  UiCheckbox checkbox();
  UiSwitch toggle();
}

class MaterialUiFactory implements UiFactory {
  const MaterialUiFactory();
  @override
  UiButton button() => const _MaterialButton();
  @override
  UiCheckbox checkbox() => const _MaterialCheckbox();
  @override
  UiSwitch toggle() => const _MaterialSwitch();
}

class CupertinoUiFactory implements UiFactory {
  const CupertinoUiFactory();
  @override
  UiButton button() => const _CupertinoButton();
  @override
  UiCheckbox checkbox() => const _CupertinoCheckbox();
  @override
  UiSwitch toggle() => const _CupertinoSwitch();
}

/// Added LAST — no client code changed.
class FluentUiFactory implements UiFactory {
  const FluentUiFactory();
  @override
  UiButton button() => const _FluentButton();
  @override
  UiCheckbox checkbox() => const _FluentCheckbox();
  @override
  UiSwitch toggle() => const _FluentSwitch();
}

class _MaterialButton implements UiButton {
  const _MaterialButton();
  @override
  String render(String label) => '[$label]';
}

class _MaterialCheckbox implements UiCheckbox {
  const _MaterialCheckbox();
  @override
  String render(bool checked) => checked ? '[x]' : '[ ]';
}

class _MaterialSwitch implements UiSwitch {
  const _MaterialSwitch();
  @override
  String render(bool on) => on ? '(=o)' : '(o=)';
}

class _CupertinoButton implements UiButton {
  const _CupertinoButton();
  @override
  String render(String label) => '($label)';
}

class _CupertinoCheckbox implements UiCheckbox {
  const _CupertinoCheckbox();
  @override
  String render(bool checked) => checked ? '(v)' : '( )';
}

class _CupertinoSwitch implements UiSwitch {
  const _CupertinoSwitch();
  @override
  String render(bool on) => on ? '<ON >' : '<OFF>';
}

class _FluentButton implements UiButton {
  const _FluentButton();
  @override
  String render(String label) => '{$label}';
}

class _FluentCheckbox implements UiCheckbox {
  const _FluentCheckbox();
  @override
  String render(bool checked) => checked ? '{*}' : '{-}';
}

class _FluentSwitch implements UiSwitch {
  const _FluentSwitch();
  @override
  String render(bool on) => on ? '|ON|' : '|--|';
}

UiFactory uiFactoryFor(UiPlatform platform) => switch (platform) {
      UiPlatform.material => const MaterialUiFactory(),
      UiPlatform.cupertino => const CupertinoUiFactory(),
      UiPlatform.fluent => const FluentUiFactory(),
    };

/// The client: depends ONLY on the abstract family.
String renderSettingsForm(UiFactory ui) =>
    '${ui.button().render("Save")} ${ui.checkbox().render(true)} '
    '${ui.toggle().render(false)}';

// =============================================================================
// SECTION 2 — BUILDER
// =============================================================================

void section2Builder() {
  section('2 · BUILDER  [creational]');
  intent('Construct a complex object step by step, then produce it immutably.');
  problem('A constructor with 9 optional parameters, half of which are only '
      'valid in certain combinations, and no place to validate the whole.');

  topic('Mini project: a fluent HTTP request builder');
  final request = RequestBuilder('https://api.example.com/users')
      .method(HttpMethod.post)
      .header('Accept', 'application/json')
      .header('X-Trace', 'abc123')
      .query('page', '1')
      .body('{"name":"Ada"}')
      .timeout(const Duration(seconds: 5))
      .build();
  show('built', request);
  show('product is immutable', 'headers/query exposed unmodifiable');
  try {
    request.headers['hacked'] = 'yes';
  } on UnsupportedError catch (_) {
    show('mutating the product', 'UnsupportedError');
  }

  topic('Validation belongs in build(), not in each setter');
  final invalid = RequestBuilder('https://api.example.com/users')
      .method(HttpMethod.get)
      .body('{"illegal":"on a GET"}');
  try {
    invalid.build();
  } on StateError catch (e) {
    show('GET + body rejected', e.message);
  }
  note('A setter cannot know the final shape — only build() sees everything.');
  note('This is why the invariant is checked once, at the end.');

  topic('Defensive copies');
  final headers = {'A': '1'};
  final built = (RequestBuilder('https://x.test')..headers(headers)).build();
  headers['B'] = '2'; // mutate the source AFTER building
  show('caller mutated their map afterwards', headers.keys.toList());
  show('the product is unaffected', built.headers.keys.toList());
  note('Copy on the way IN and freeze on the way OUT, or your "immutable"');
  note('product has a live wire back to the caller.');

  topic('The idiomatic Dart alternative');
  const simple = SimpleRequest(url: 'https://x.test');
  final derived = simple.copyWith(method: HttpMethod.put, body: '{}');
  show('named params + copyWith', derived);
  note('For most objects, named parameters + `copyWith` + cascades beat a');
  note('builder class: less code, no half-built state, immutable throughout.');
  note('Reach for a real Builder when construction is a MULTI-STEP PROCESS');
  note('with cross-field validation, or the steps arrive at different times.');

  flutterUse([
    '`WidgetBuilder` / `ListView.builder` / `LayoutBuilder` (lazy construction)',
    '`ThemeData` and `TextStyle` — copyWith-style incremental building',
    '`StringBuffer` — the standard-library builder for strings',
    'query builders in Drift / SQL packages',
  ]);
  avoidWhen([
    '2-3 parameters — a plain constructor is clearer',
    'no cross-field validation — use named params + copyWith',
    'you need to pick WHICH class to create -> Factory, not Builder',
  ]);
}

enum HttpMethod { get, post, put, delete }

class HttpRequest {
  final String url;
  final HttpMethod method;
  final Map<String, String> headers;
  final Map<String, String> query;
  final String? body;
  final Duration timeout;

  HttpRequest._({
    required this.url,
    required this.method,
    required Map<String, String> headers,
    required Map<String, String> query,
    required this.body,
    required this.timeout,
  })  : headers = Map.unmodifiable(headers),
        query = Map.unmodifiable(query);

  @override
  String toString() => '${method.name.toUpperCase()} $url'
      '${query.isEmpty ? '' : '?${query.entries.map((e) => '${e.key}=${e.value}').join('&')}'}'
      ' headers=${headers.length} body=${body ?? '-'} timeout=${timeout.inSeconds}s';
}

class RequestBuilder {
  final String _url;
  HttpMethod _method = HttpMethod.get;
  final Map<String, String> _headers = {};
  final Map<String, String> _query = {};
  String? _body;
  Duration _timeout = const Duration(seconds: 30);

  RequestBuilder(this._url);

  // Each step returns `this` so calls can be chained.
  RequestBuilder method(HttpMethod value) {
    _method = value;
    return this;
  }

  RequestBuilder header(String key, String value) {
    _headers[key] = value;
    return this;
  }

  /// Defensive copy: we take the caller's entries, not their map.
  RequestBuilder headers(Map<String, String> values) {
    _headers.addAll(values);
    return this;
  }

  RequestBuilder query(String key, String value) {
    _query[key] = value;
    return this;
  }

  RequestBuilder body(String value) {
    _body = value;
    return this;
  }

  RequestBuilder timeout(Duration value) {
    _timeout = value;
    return this;
  }

  /// The ONE place that sees the whole object, so the ONE place that validates.
  HttpRequest build() {
    if (!_url.startsWith('http')) {
      throw StateError('url must be absolute, got "$_url"');
    }
    if (_method == HttpMethod.get && _body != null) {
      throw StateError('a GET request must not carry a body');
    }
    if (_timeout <= Duration.zero) {
      throw StateError('timeout must be positive');
    }
    return HttpRequest._(
      url: _url,
      method: _method,
      headers: _headers,
      query: _query,
      body: _body,
      timeout: _timeout,
    );
  }
}

/// The Dart-idiomatic alternative to a builder class.
class SimpleRequest {
  final String url;
  final HttpMethod method;
  final String? body;

  const SimpleRequest({required this.url, this.method = HttpMethod.get, this.body});

  SimpleRequest copyWith({String? url, HttpMethod? method, String? body}) =>
      SimpleRequest(
        url: url ?? this.url,
        method: method ?? this.method,
        body: body ?? this.body,
      );

  @override
  String toString() =>
      '${method.name.toUpperCase()} $url body=${body ?? '-'}';
}

// =============================================================================
// SECTION 3 — SINGLETON
// =============================================================================

void section3Singleton() {
  section('3 · SINGLETON  [creational]');
  intent('Guarantee exactly one instance and give it a global access point.');
  problem('Genuinely-single resources (a config, a connection pool) being '
      'constructed repeatedly, or drifting out of sync.');

  topic('The two Dart idioms');
  final a = RawAppConfig.instance;
  final b = RawAppConfig.instance;
  show('static final + private ctor -> identical', identical(a, b));
  show('lazily created (only on first access)', RawAppConfig.constructions);
  final c = RawLogger();
  final d = RawLogger();
  show('factory ctor returning a cached instance', identical(c, d));
  note('`static final x = Foo._()` is LAZY in Dart — no double-checked locking,');
  note('no `synchronized`, nothing to get wrong.');

  topic('Per ISOLATE, not per process');
  note('Each isolate has its OWN heap, so each isolate gets its OWN "singleton".');
  note('A spawned isolate cannot see the main isolate\'s instance — which makes');
  note('a mutable singleton a poor choice for anything shared across isolates.');

  topic('Why it is often an ANTI-PATTERN');
  RawLogger().log('from module A');
  RawLogger().log('from module B');
  show('global mutable state accumulated', RawLogger().lines.length);
  note('x  hidden dependency: a class using RawLogger() does not declare it, so');
  note('   its constructor lies about what it needs');
  note('x  test pollution: state survives between tests, and order matters');
  note('x  cannot substitute a fake without a global setter');
  note('x  a retained singleton holding a context/subscription leaks forever');
  show('test isolation problem: lines carried over', RawLogger().lines);

  topic('V The fix: ONE instance, but INJECTED (mini project)');
  final container = TinyContainer()
    ..registerSingleton<ConfigPort>(() => AppConfigImpl(env: 'prod'))
    ..registerSingleton<LoggerPort>(() => RealLogger());
  final service = ReportService(
    config: container.resolve<ConfigPort>(),
    logger: container.resolve<LoggerPort>(),
  );
  show('production run', service.run());
  show('still exactly one instance',
      identical(container.resolve<LoggerPort>(), container.resolve<LoggerPort>()));

  final testContainer = TinyContainer()
    ..registerSingleton<ConfigPort>(() => AppConfigImpl(env: 'test'))
    ..registerSingleton<LoggerPort>(() => FakeLogger());
  final underTest = ReportService(
    config: testContainer.resolve<ConfigPort>(),
    logger: testContainer.resolve<LoggerPort>(),
  );
  show('test run', underTest.run());
  final fake = testContainer.resolve<LoggerPort>();
  show('fake captured for assertions', fake is FakeLogger ? fake.captured : []);
  note('Single-instance LIFETIME is a wiring concern; it does not require');
  note('global ACCESS. That distinction is the whole lesson of this pattern.');

  flutterUse([
    'get_it / Riverpod registering one instance of a repository or client',
    '`WidgetsBinding.instance`, `ServicesBinding.instance` (framework-owned)',
    'a single Dio/http client, a single database handle',
  ]);
  avoidWhen([
    'the object holds mutable app state -> use a state-management solution',
    'you want it for convenience — that is a global variable with extra steps',
    'you need per-test substitution -> register a single instance in a container',
    'it would retain a BuildContext, subscription or timer (leak)',
  ]);
}

class RawAppConfig {
  static int constructions = 0;
  static final RawAppConfig instance = RawAppConfig._();
  RawAppConfig._() {
    constructions++;
  }
  final String env = 'prod';
}

class RawLogger {
  static final RawLogger _instance = RawLogger._();
  final List<String> lines = [];

  RawLogger._();

  /// The `factory` idiom: `RawLogger()` always returns the same object.
  factory RawLogger() => _instance;

  void log(String line) => lines.add(line);
}

abstract interface class ConfigPort {
  String get env;
}

abstract interface class LoggerPort {
  void log(String line);
}

class AppConfigImpl implements ConfigPort {
  @override
  final String env;
  AppConfigImpl({required this.env});
}

class RealLogger implements LoggerPort {
  @override
  void log(String line) => effects.add('REAL LOG: $line');
}

class FakeLogger implements LoggerPort {
  final List<String> captured = [];
  @override
  void log(String line) => captured.add(line);
}

/// A container that guarantees single instances WITHOUT global access.
class TinyContainer {
  final Map<Type, Object Function()> _factories = {};
  final Map<Type, Object> _singletons = {};

  void registerSingleton<T extends Object>(T Function() create) =>
      _factories[T] = create;

  T resolve<T extends Object>() {
    final existing = _singletons[T];
    if (existing != null) return existing as T;
    final create = _factories[T];
    if (create == null) throw StateError('nothing registered for $T');
    final created = create();
    _singletons[T] = created;
    return created as T;
  }
}

class ReportService {
  final ConfigPort config;
  final LoggerPort logger;
  const ReportService({required this.config, required this.logger});

  String run() {
    logger.log('report generated in ${config.env}');
    return 'report for ${config.env}';
  }
}

// =============================================================================
// SECTION 4 — PROTOTYPE
// =============================================================================

void section4Prototype() {
  section('4 · PROTOTYPE  [creational]');
  intent('Create new objects by CLONING an existing one, not by constructing '
      'from scratch.');
  problem('Building an object is expensive or requires knowledge the caller '
      'does not have — but a good example already exists.');

  topic('Mini project: a document template registry');
  final invoice = DocumentTemplates.get('invoice');
  show('prototype fetched', invoice);
  final custom = invoice!.copyWith(
    title: 'Invoice #42',
    sections: [const DocSection('Total', '118000p')],
  );
  show('cloned + customised', custom);
  show('prototype untouched', DocumentTemplates.get('invoice'));
  note('The registry holds immutable prototypes; `copyWith` IS the clone.');

  topic('Dart idiom: copyWith on an immutable class');
  note('The classic pattern needs a `clone()` method because the objects are');
  note('mutable. In Dart, an immutable class with `copyWith` gives you the same');
  note('capability, with no aliasing hazard at all.');
  show('two clones from one prototype are independent', () {
    final a = invoice.copyWith(title: 'A');
    final b = invoice.copyWith(title: 'B');
    return '${a.title} / ${b.title}';
  }());

  topic('SHALLOW vs DEEP clone — the part everyone gets wrong');
  final original = MutableReport(
    name: 'Q3',
    rows: [MutableRow('north', 100), MutableRow('south', 200)],
  );
  final shallow = original.shallowClone();
  shallow.rows[0].amount = 999; // reaches into the ORIGINAL
  show('after mutating the shallow clone, original row', original.rows[0]);
  show('same row instance', identical(original.rows[0], shallow.rows[0]));

  final fresh = MutableReport(
    name: 'Q3',
    rows: [MutableRow('north', 100), MutableRow('south', 200)],
  );
  final deep = fresh.deepClone();
  deep.rows[0].amount = 999;
  show('after mutating the deep clone, original row', fresh.rows[0]);
  show('different row instances', !identical(fresh.rows[0], deep.rows[0]));
  note('Shallow copies the top level and SHARES everything below. Deep clones');
  note('the whole graph (and must handle cycles). Keep prototypes IMMUTABLE and');
  note('the question disappears.');

  flutterUse([
    '`ThemeData.copyWith` / `TextStyle.copyWith` — the canonical Flutter use',
    '`BoxDecoration`, `InputDecoration` derived from a base',
    'state classes in Bloc/Riverpod deriving the next state via copyWith',
  ]);
  avoidWhen([
    'construction is cheap and simple — just build a new one',
    'the object is mutable and deeply nested (deep clone becomes a liability)',
    'you need a DIFFERENT type, not a variant -> Factory',
  ]);
}

class DocSection {
  final String heading;
  final String content;
  const DocSection(this.heading, this.content);
  @override
  String toString() => '$heading="$content"';
}

class TemplateDocument {
  final String title;
  final String footer;
  final List<DocSection> sections;

  const TemplateDocument({
    required this.title,
    required this.footer,
    this.sections = const [],
  });

  /// The clone operation, Dart style.
  TemplateDocument copyWith({
    String? title,
    String? footer,
    List<DocSection>? sections,
  }) =>
      TemplateDocument(
        title: title ?? this.title,
        footer: footer ?? this.footer,
        sections: sections ?? this.sections,
      );

  @override
  String toString() =>
      'Doc("$title", ${sections.length} sections, footer="$footer")';
}

class DocumentTemplates {
  static const Map<String, TemplateDocument> _prototypes = {
    'invoice': TemplateDocument(title: 'Invoice', footer: 'Thank you'),
    'report': TemplateDocument(title: 'Report', footer: 'Confidential'),
  };

  static TemplateDocument? get(String key) => _prototypes[key];
  static List<String> get available => _prototypes.keys.toList();
}

class MutableRow {
  final String region;
  int amount;
  MutableRow(this.region, this.amount);
  MutableRow clone() => MutableRow(region, amount);
  @override
  String toString() => '$region=$amount';
}

class MutableReport {
  String name;
  List<MutableRow> rows;
  MutableReport({required this.name, required this.rows});

  /// New report, new list — but the SAME row objects.
  MutableReport shallowClone() => MutableReport(name: name, rows: List.of(rows));

  /// New report, new list, cloned rows.
  MutableReport deepClone() =>
      MutableReport(name: name, rows: rows.map((r) => r.clone()).toList());
}

// =============================================================================
// SECTION 5 — ADAPTER
// =============================================================================

void section5Adapter() {
  section('5 · ADAPTER  [structural]');
  intent('Convert one interface into another so incompatible code can work '
      'together.');
  problem('Two vendor SDKs with different method names, different money units '
      'and different failure styles — and a checkout that should not care.');

  topic('Mini project: payment gateway adapters over mismatched SDKs');
  note('StripeSdk wants CENTS and returns a status string.');
  note('RazorpaySdk wants RUPEES as a double and THROWS on failure.');
  note('Our domain speaks paise and returns a Result.');

  final gateways = <PaymentGateway>[
    StripeAdapter(sdk: StripeSdk()),
    RazorpayAdapter(sdk: RazorpaySdk()),
  ];
  final checkout = AdapterCheckout();
  for (final gateway in gateways) {
    print('  ${gateway.runtimeType.toString().padRight(18)} '
        'ok=${checkout.pay(gateway, 129900)}');
  }
  note('And the failure path, normalised to the SAME shape:');
  for (final gateway in gateways) {
    print('  ${gateway.runtimeType.toString().padRight(18)} '
        'bad=${checkout.pay(gateway, -1)}');
  }
  show('does AdapterCheckout mention Stripe or Razorpay?', 'no');
  show('did any SDK exception escape?', 'no — adapters translate them');

  topic('What belongs in an adapter');
  note('V  renaming/reshaping calls           (doCharge -> charge)');
  note('V  unit conversion                    (paise -> cents / rupees)');
  note('V  error translation                  (throw -> Err, code -> message)');
  note('V  type mapping                       (SDK model -> domain entity)');
  note('x  business rules, pricing, retries, logging — those are NOT adapting.');
  note('An adapter with an `if (customer.isVip)` in it has stopped being one.');

  topic('Adapter vs Facade vs Bridge');
  note('Adapter : CONVERTS an existing, mismatched interface (retrofit)');
  note('Facade  : SIMPLIFIES a complex subsystem behind one easy call');
  note('Bridge  : DESIGNED up-front so two hierarchies can vary independently');

  flutterUse([
    'wrapping a platform-channel/native SDK into a clean Dart interface',
    'mapping API DTOs onto domain entities (an adapter in spirit)',
    'making a third-party analytics/crash SDK satisfy your own interface',
    '`SliverChildListDelegate` adapting a list to the sliver protocol',
  ]);
  avoidWhen([
    'you own both sides — just fix the interface',
    'the mismatch is trivial (one rename) and used once',
    'you would be hiding a semantic difference, not just a syntactic one',
  ]);
}

/// The interface OUR code wants (defined by us, the client).
abstract interface class PaymentGateway {
  Result<String> charge(int amountPaise);
}

/// Vendor SDK #1 — cents, status strings, no exceptions.
class StripeSdk {
  String createCharge(int amountCents) =>
      amountCents > 0 ? 'succeeded:$amountCents' : 'failed:invalid_amount';
}

/// Vendor SDK #2 — rupees as double, throws on failure.
class RazorpaySdk {
  String pay(double rupees) {
    if (rupees <= 0) throw ArgumentError('razorpay: amount must be > 0');
    return 'PAID ${rupees.toStringAsFixed(2)}';
  }
}

class StripeAdapter implements PaymentGateway {
  final StripeSdk sdk;
  StripeAdapter({required this.sdk});

  @override
  Result<String> charge(int amountPaise) {
    final cents = amountPaise; // unit conversion lives HERE
    final raw = sdk.createCharge(cents);
    if (raw.startsWith('succeeded')) return Ok('stripe: $raw');
    return Err('stripe declined: ${raw.split(':').last}'); // error translation
  }
}

class RazorpayAdapter implements PaymentGateway {
  final RazorpaySdk sdk;
  RazorpayAdapter({required this.sdk});

  @override
  Result<String> charge(int amountPaise) {
    try {
      final rupees = amountPaise / 100; // unit conversion
      return Ok('razorpay: ${sdk.pay(rupees)}');
    } on ArgumentError catch (e) {
      return Err('razorpay declined: ${e.message}'); // throw -> Result
    }
  }
}

/// Depends only on the target interface.
class AdapterCheckout {
  String pay(PaymentGateway gateway, int amountPaise) =>
      gateway.charge(amountPaise).toString();
}

// =============================================================================
// SECTION 6 — DECORATOR
// =============================================================================

void section6Decorator() {
  section('6 · DECORATOR  [structural]');
  intent('Add behaviour by WRAPPING an object in something with the same '
      'interface.');
  problem('You need logging, caching and retry in every combination. Subclassing'
      ' gives you 2^3 classes (LoggingCachingRetryingRepo...).');

  topic('Mini project: a resilient repository stack');
  effects.clear();
  final flaky = HttpArticleSource(failuresBeforeSuccess: 2);
  final stack = LoggingArticles(
    inner: CachingArticles(
      inner: RetryingArticles(inner: flaky, maxAttempts: 4),
    ),
  );
  show('first call (retries, then caches)', stack.fetch('flutter'));
  show('http attempts so far', flaky.attempts);
  show('second call (served from cache)', stack.fetch('flutter'));
  show('http attempts after the 2nd call', flaky.attempts);
  note('The cache prevented a second network call entirely.');
  note('Log produced by the outermost decorator:');
  for (final line in effects) {
    note('    $line');
  }

  topic('Each decorator does ONE thing');
  final loggingOnly = LoggingArticles(inner: HttpArticleSource());
  final cachingOnly = CachingArticles(inner: HttpArticleSource());
  show('logging only', loggingOnly.fetch('dart'));
  show('caching only, twice', '${cachingOnly.fetch("dart")} / ${cachingOnly.fetch("dart")}');
  note('Because each is independent, each is testable in isolation and any');
  note('combination composes without a new class.');

  topic('ORDER MATTERS — and the difference is observable');
  // logging OUTSIDE cache: the log sees every CALL, cache hits included.
  effects.clear();
  final logOutside = LoggingArticles(inner: CachingArticles(inner: HttpArticleSource()));
  logOutside.fetch('x');
  logOutside.fetch('x');
  logOutside.fetch('x');
  final logOutsideLines = effects.where((e) => e.startsWith('->')).length;

  // logging INSIDE cache: the log sees only calls that reached the network.
  effects.clear();
  final logInside = CachingArticles(inner: LoggingArticles(inner: HttpArticleSource()));
  logInside.fetch('x');
  logInside.fetch('x');
  logInside.fetch('x');
  final logInsideLines = effects.where((e) => e.startsWith('->')).length;

  show('3 calls, logging(caching(http)) -> logged', logOutsideLines);
  show('3 calls, caching(logging(http)) -> logged', logInsideLines);
  note('Same two decorators, same three calls, different answers to "how many');
  note('requests did we serve?" vs "how many did we fetch?". Neither is wrong —');
  note('but only one matches what you meant.');
  note('For retry + cache, cache(retry(http)) is normally right: retry the');
  note('network, then cache the SUCCESS. Putting retry outside re-enters the');
  note('cache layer on every attempt, wasting work and risking a cached failure.');
  note('Document your intended order — a wrong stack still compiles.');

  topic('Composed by environment (a factory of stacks)');
  show('dev stack', describeStack(buildArticleStack(production: false)));
  show('prod stack', describeStack(buildArticleStack(production: true)));

  topic('Decorator vs Proxy — same shape, different intent');
  note('Decorator: ADDS behaviour, the wrapped call always happens.');
  note('Proxy    : CONTROLS access — it may delay, deny, cache or remote the');
  note('           call, and may never forward it at all.');

  flutterUse([
    'widgets: Padding/Center/Opacity/DecoratedBox wrapping a child',
    '`Stream` transformations (`map`, `where`) wrapping a source stream',
    'an http Client wrapper adding auth headers, logging and retries',
    '`ChangeNotifierProxyProvider`-style layering',
  ]);
  avoidWhen([
    'only ONE combination will ever exist — just write the behaviour inline',
    'the added behaviour changes the CONTRACT (then it is not a decorator)',
    'the stack gets so deep that debugging a call means unwrapping 6 layers',
  ]);
}

abstract interface class ArticleSource {
  String fetch(String topic);
}

class HttpArticleSource implements ArticleSource {
  final int failuresBeforeSuccess;
  int attempts = 0;

  HttpArticleSource({this.failuresBeforeSuccess = 0});

  @override
  String fetch(String topic) {
    attempts++;
    if (attempts <= failuresBeforeSuccess) {
      throw StateError('network error (attempt $attempts)');
    }
    return 'articles about "$topic"';
  }
}

/// Adds logging. Nothing else.
class LoggingArticles implements ArticleSource {
  final ArticleSource inner;
  LoggingArticles({required this.inner});

  @override
  String fetch(String topic) {
    effects.add('-> fetch("$topic")');
    final result = inner.fetch(topic);
    effects.add('<- ${result.length} bytes');
    return result;
  }
}

/// Adds caching. Nothing else.
class CachingArticles implements ArticleSource {
  final ArticleSource inner;
  final Map<String, String> _cache = {};
  CachingArticles({required this.inner});

  @override
  String fetch(String topic) => _cache.putIfAbsent(topic, () => inner.fetch(topic));
}

/// Adds retries. Nothing else.
class RetryingArticles implements ArticleSource {
  final ArticleSource inner;
  final int maxAttempts;
  RetryingArticles({required this.inner, required this.maxAttempts});

  @override
  String fetch(String topic) {
    Object? last;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return inner.fetch(topic);
      } catch (e) {
        last = e;
      }
    }
    throw StateError('all $maxAttempts attempts failed: $last');
  }
}

ArticleSource buildArticleStack({required bool production}) {
  final base = HttpArticleSource();
  if (!production) return LoggingArticles(inner: base);
  return CachingArticles(inner: RetryingArticles(inner: base, maxAttempts: 3));
}

String describeStack(ArticleSource source) {
  final parts = <String>[];
  ArticleSource current = source;
  while (true) {
    parts.add(current.runtimeType.toString());
    final next = switch (current) {
      LoggingArticles(inner: final i) => i,
      CachingArticles(inner: final i) => i,
      RetryingArticles(inner: final i) => i,
      _ => null,
    };
    if (next == null) break;
    current = next;
  }
  return parts.join(' -> ');
}

// =============================================================================
// SECTION 7 — FACADE
// =============================================================================

void section7Facade() {
  section('7 · FACADE  [structural]');
  intent('Provide one simple entry point to a complicated subsystem.');
  problem('Placing an order means calling four services in the right order '
      'with the right rollback — and every caller re-implements that dance.');

  topic('Mini project: an order-placement facade');
  final stock = FakeStock(available: {'sku-1': 3});
  final billing = FakeBilling(shouldSucceed: true);
  final store = FakeOrderStore();
  final notifier = FakeCustomerNotifier();
  final facade = OrderFacade(
    stock: stock,
    billing: billing,
    store: store,
    notifier: notifier,
  );

  show('one call for the caller', facade.placeOrder('sku-1', 2, 50000));
  show('stock reserved', stock.available);
  show('order stored', store.orders);
  show('customer notified', notifier.messages);

  topic('Failure paths are handled ONCE, inside the facade');
  show('out of stock', facade.placeOrder('sku-1', 99, 50000));
  final declining = OrderFacade(
    stock: FakeStock(available: {'sku-1': 5}),
    billing: FakeBilling(shouldSucceed: false),
    store: FakeOrderStore(),
    notifier: FakeCustomerNotifier(),
  );
  show('payment declined (stock released)', declining.placeOrder('sku-1', 1, 50000));
  note('Every caller would otherwise have to remember to release the');
  note('reservation when billing fails. The facade owns that knowledge.');

  topic('A facade ORCHESTRATES; it does not compute');
  note('V  call subsystems in the right order, handle their failures, roll back');
  note('x  pricing rules, tax maths, validation logic — those belong to the');
  note('   subsystems or the domain. A facade with business rules is a God');
  note('   object wearing a pattern name.');
  note('Keep it thin, depend on INTERFACES, and inject them — the facade above');
  note('was tested with four fakes and zero infrastructure.');

  topic('Split by area, not one mega-facade');
  note('OrderFacade, CatalogFacade, AccountFacade — each one screen/use case.');
  note('A single `AppFacade` with 60 methods is exactly the complexity you were');
  note('trying to hide, just relocated.');

  topic('Facade vs Adapter vs Mediator');
  note('Facade  : SIMPLIFIES many components behind one call (one direction)');
  note('Adapter : CONVERTS one interface to another (same capability)');
  note('Mediator: COORDINATES peers that talk back and forth (bidirectional)');

  flutterUse([
    'a use-case / interactor class in Clean Architecture — a facade over repos',
    '`Navigator.of(context).push(...)` hiding the routing machinery',
    '`SharedPreferences` hiding platform-specific storage',
    'a `FirebaseService` wrapping auth + firestore + storage calls',
  ]);
  avoidWhen([
    'the subsystem is already simple — a facade just adds a hop',
    'callers legitimately need the fine-grained API (do not hide it, add to it)',
    'it would accumulate rules from every layer -> split it',
  ]);
}

abstract interface class StockService {
  int quantityOf(String sku);
  void reserve(String sku, int qty);
  void release(String sku, int qty);
}

abstract interface class BillingService {
  bool charge(int amountPaise);
}

abstract interface class OrderStore {
  void save(String sku, int qty, int amountPaise);
}

abstract interface class CustomerNotifier {
  void send(String message);
}

class FakeStock implements StockService {
  final Map<String, int> available;
  FakeStock({required this.available});
  @override
  int quantityOf(String sku) => available[sku] ?? 0;
  @override
  void reserve(String sku, int qty) => available[sku] = quantityOf(sku) - qty;
  @override
  void release(String sku, int qty) => available[sku] = quantityOf(sku) + qty;
}

class FakeBilling implements BillingService {
  final bool shouldSucceed;
  FakeBilling({required this.shouldSucceed});
  @override
  bool charge(int amountPaise) => shouldSucceed;
}

class FakeOrderStore implements OrderStore {
  final List<String> orders = [];
  @override
  void save(String sku, int qty, int amountPaise) =>
      orders.add('$sku x$qty @${amountPaise}p');
}

class FakeCustomerNotifier implements CustomerNotifier {
  final List<String> messages = [];
  @override
  void send(String message) => messages.add(message);
}

/// Orchestration only — four subsystems, one call, correct rollback.
class OrderFacade {
  final StockService stock;
  final BillingService billing;
  final OrderStore store;
  final CustomerNotifier notifier;

  const OrderFacade({
    required this.stock,
    required this.billing,
    required this.store,
    required this.notifier,
  });

  String placeOrder(String sku, int qty, int amountPaise) {
    if (stock.quantityOf(sku) < qty) {
      return 'failed: only ${stock.quantityOf(sku)} of $sku left';
    }
    stock.reserve(sku, qty);
    if (!billing.charge(amountPaise)) {
      stock.release(sku, qty); // the rollback callers keep forgetting
      return 'failed: payment declined (reservation released)';
    }
    store.save(sku, qty, amountPaise);
    notifier.send('your order for $qty x $sku is confirmed');
    return 'ok: $qty x $sku placed';
  }
}

// =============================================================================
// SECTION 8 — BRIDGE
// =============================================================================

void section8Bridge() {
  section('8 · BRIDGE  [structural]');
  intent('Split an abstraction from its implementation so both can vary '
      'independently.');
  problem('Two independent axes (notification KIND x delivery CHANNEL) '
      'multiplied into a class per combination: M x N explosion.');

  topic('The problem, sized');
  note('Kinds: Alert, Reminder, Receipt        (M = 3)');
  note('Channels: Email, Sms, Push             (N = 3)');
  note('Inheritance: AlertEmail, AlertSms, AlertPush, ReminderEmail, ...');
  show('classes needed with inheritance (M x N)', 3 * 3);
  show('classes needed with a bridge (M + N)', 3 + 3);
  note('Add one channel: inheritance needs 3 more classes, the bridge needs 1.');

  topic('Mini project: notification x channel bridge');
  final channels = <Channel>[EmailChannel(), SmsChannel(), PushChannel()];
  for (final channel in channels) {
    final alert = Alert(channel: channel, severity: 'high');
    final reminder = Reminder(channel: channel, dueIn: 'tomorrow');
    print('  ${channel.name.padRight(6)} | ${alert.send()}');
    print('  ${''.padRight(6)} | ${reminder.send()}');
  }

  topic('Both axes extend independently — the proof');
  note('NEW CHANNEL (WhatsApp): no notification class was edited.');
  final whatsapp = WhatsAppChannel();
  show('alert over a brand-new channel', Alert(channel: whatsapp, severity: 'low').send());
  show('reminder over the same new channel',
      Reminder(channel: whatsapp, dueIn: 'in 1h').send());
  note('NEW KIND (Receipt): no channel class was edited.');
  show('brand-new kind over an existing channel',
      Receipt(channel: EmailChannel(), totalPaise: 129900).send());

  topic('Bridge vs Strategy vs Adapter');
  note('Bridge  : DESIGNED up front; two hierarchies, both expected to grow.');
  note('          The abstraction OWNS an implementor for its whole life.');
  note('Strategy: swap ONE algorithm at runtime; usually a single axis.');
  note('Adapter : retrofit an interface you did not design and cannot change.');
  note('Structurally Bridge and Strategy look identical — the difference is');
  note('intent and lifetime, which is why they are so often confused.');

  flutterUse([
    'a `Notification` abstraction over local/FCM/APNs delivery',
    'a rendering abstraction over Canvas / SVG / PDF backends',
    'Flutter itself: Widget (abstraction) vs RenderObject (implementation)',
    '`dart:io` vs `dart:html` implementations behind one Dart API',
  ]);
  avoidWhen([
    'only ONE axis actually varies — you get indirection for nothing',
    'the second axis has exactly one implementation and always will',
    'the two axes are not truly independent (then they are one concept)',
  ]);
}

/// The IMPLEMENTOR axis.
abstract interface class Channel {
  String get name;
  String deliver(String payload);
}

class EmailChannel implements Channel {
  @override
  String get name => 'email';
  @override
  String deliver(String payload) => 'emailed "$payload"';
}

class SmsChannel implements Channel {
  @override
  String get name => 'sms';
  @override
  String deliver(String payload) => 'texted "$payload"';
}

class PushChannel implements Channel {
  @override
  String get name => 'push';
  @override
  String deliver(String payload) => 'pushed "$payload"';
}

/// Added later. Zero notification classes touched.
class WhatsAppChannel implements Channel {
  @override
  String get name => 'whatsapp';
  @override
  String deliver(String payload) => 'whatsapp "$payload"';
}

/// The ABSTRACTION axis — holds a Channel rather than inheriting from one.
abstract class AppNotification {
  final Channel channel;
  const AppNotification({required this.channel});

  String buildPayload();

  String send() => channel.deliver(buildPayload());
}

class Alert extends AppNotification {
  final String severity;
  const Alert({required super.channel, required this.severity});
  @override
  String buildPayload() => 'ALERT($severity)';
}

class Reminder extends AppNotification {
  final String dueIn;
  const Reminder({required super.channel, required this.dueIn});
  @override
  String buildPayload() => 'REMINDER due $dueIn';
}

/// Added later. Zero channel classes touched.
class Receipt extends AppNotification {
  final int totalPaise;
  const Receipt({required super.channel, required this.totalPaise});
  @override
  String buildPayload() => 'RECEIPT ${totalPaise}p';
}

// =============================================================================
// SECTION 9 — COMPOSITE
// =============================================================================

void section9Composite() {
  section('9 · COMPOSITE  [structural]');
  intent('Let clients treat a single object and a TREE of objects the same way.');
  problem('Code littered with `if (node is Directory) { recurse } else { ... }` '
      'every time it walks a hierarchy.');

  topic('Mini project: a file-system model');
  final tree = FsDirectory('root', [
    FsFile('README.md', 1200),
    FsDirectory('lib', [
      FsFile('main.dart', 800),
      FsDirectory('src', [
        FsFile('util.dart', 450),
        FsFile('model.dart', 950),
      ]),
    ]),
    FsDirectory('empty', []),
  ]);

  print(tree.render());
  show('total size (recursive)', tree.size());
  show('file count (recursive)', tree.count());
  show('a LEAF answers the same questions', FsFile('solo.txt', 42).size());
  note('`size()` and `count()` are called identically on a file and on a');
  note('directory. That uniformity IS the pattern.');

  topic('find() — one recursive call, no type checks in the caller');
  for (final name in ['util.dart', 'src', 'missing.dart']) {
    show('find("$name")', tree.find(name)?.name ?? 'not found');
  }

  topic('Child operations belong on the COMPOSITE only (ISP + LSP)');
  note('The classic GoF version puts add()/remove() on the shared interface, so');
  note('a File must implement them — and throws. That breaks LSP.');
  note('Here `add` exists only on FsDirectory, so `file.add(...)` does not');
  note('COMPILE. The type system enforces the tree\'s shape.');
  final lib = tree.find('lib');
  if (lib is FsDirectory) {
    lib.add(FsFile('extra.dart', 100));
    show('added a child to a directory', lib.children.length);
  }
  show('total size after the add', tree.size());

  topic('Guard the recursion');
  final cyclic = FsDirectory('a', []);
  cyclic.add(cyclic); // deliberately create a cycle
  show('size() with a cycle, guarded', cyclic.size());
  note('Without a visited-set this would recurse until a StackOverflowError.');
  note('Also watch DEPTH: a 10k-deep tree can blow the stack even acyclic.');

  flutterUse([
    'the widget tree itself — every Widget composes children uniformly',
    '`Column`/`Row`/`Stack` taking `List<Widget>`; a leaf `Text` taking none',
    'a JSON tree, a menu tree, an org chart, a folder browser',
    'pairs naturally with Visitor (Section 18) to add operations',
  ]);
  avoidWhen([
    'the data is flat — a List is not a tree',
    'leaves and branches genuinely need different APIs (do not force it)',
    'the tree is deep enough that recursion is unsafe -> iterate with a stack',
  ]);
}

abstract class FsNode {
  final String name;
  const FsNode(this.name);

  int size([Set<FsNode>? visited]);
  int count([Set<FsNode>? visited]);
  FsNode? find(String target, [Set<FsNode>? visited]);
  String render([String indent]);
}

class FsFile extends FsNode {
  final int bytes;
  FsFile(super.name, this.bytes);

  @override
  int size([Set<FsNode>? visited]) => bytes;

  @override
  int count([Set<FsNode>? visited]) => 1;

  @override
  FsNode? find(String target, [Set<FsNode>? visited]) =>
      name == target ? this : null;

  @override
  String render([String indent = '  ']) => '$indent$name (${bytes}b)';
}

class FsDirectory extends FsNode {
  final List<FsNode> _children;
  FsDirectory(super.name, List<FsNode> children) : _children = List.of(children);

  List<FsNode> get children => List.unmodifiable(_children);

  /// Child management exists ONLY here — a file cannot be asked to add.
  void add(FsNode node) => _children.add(node);
  bool remove(FsNode node) => _children.remove(node);

  @override
  int size([Set<FsNode>? visited]) {
    final seen = visited ?? <FsNode>{};
    if (!seen.add(this)) return 0; // cycle guard
    return _children.fold(0, (sum, child) => sum + child.size(seen));
  }

  @override
  int count([Set<FsNode>? visited]) {
    final seen = visited ?? <FsNode>{};
    if (!seen.add(this)) return 0;
    return _children.fold(0, (sum, child) => sum + child.count(seen));
  }

  @override
  FsNode? find(String target, [Set<FsNode>? visited]) {
    final seen = visited ?? <FsNode>{};
    if (!seen.add(this)) return null;
    if (name == target) return this;
    for (final child in _children) {
      final hit = child.find(target, seen);
      if (hit != null) return hit;
    }
    return null;
  }

  @override
  String render([String indent = '  ']) {
    final lines = <String>['$indent$name/'];
    for (final child in _children) {
      lines.add(child.render('$indent  '));
    }
    return lines.join('\n');
  }
}

// =============================================================================
// SECTION 10 — PROXY
// =============================================================================

void section10Proxy() {
  section('10 · PROXY  [structural]');
  intent('Stand in for another object to CONTROL access to it.');
  problem('An object is expensive to create, remote, or must be permission '
      'checked — but callers should not have to know or care.');

  topic('Mini project: virtual (lazy) + caching image proxy');
  HighResImage.loadCount = 0;
  final lazy = LazyImageProxy(path: 'hero.png');
  show('proxy constructed — was the image loaded?', HighResImage.loadCount);
  show('metadata without loading', lazy.path);
  show('first render (loads now)', lazy.render());
  show('load count', HighResImage.loadCount);
  show('second render (cached)', lazy.render());
  show('load count still', HighResImage.loadCount);
  note('The expensive work was DEFERRED to first use and then done ONCE.');
  note('That is the "virtual proxy" plus a cache, the pattern behind every');
  note('lazy list and image cache you have used.');

  topic('Protection proxy — an auth gate');
  final guarded = ProtectedImage(
    inner: LazyImageProxy(path: 'payslip.png'),
    auth: AuthContext(role: 'guest'),
  );
  show('guest access', guarded.render());
  final asAdmin = ProtectedImage(
    inner: LazyImageProxy(path: 'payslip.png'),
    auth: AuthContext(role: 'admin'),
  );
  show('admin access', asAdmin.render());
  note('The caller code is identical; the proxy decided whether to forward.');

  topic('Proxies COMPOSE (they share the interface)');
  HighResImage.loadCount = 0;
  final stacked = ProtectedImage(
    inner: LazyImageProxy(path: 'chart.png'),
    auth: AuthContext(role: 'admin'),
  );
  show('protected + lazy, first', stacked.render());
  show('protected + lazy, second', stacked.render());
  show('expensive loads performed', HighResImage.loadCount);

  topic('The four classic kinds');
  note('VIRTUAL    : defer expensive creation until first use (above)');
  note('CACHING    : remember results (above)');
  note('PROTECTION : allow/deny by permission (above)');
  note('REMOTE     : make a network call look like a local one (gRPC/REST stub)');

  topic('Proxy vs Decorator — identical structure, opposite intent');
  note('Decorator: "and also do X" — the inner call ALWAYS happens.');
  note('Proxy    : "should this call happen at all, and when?" — it may deny,');
  note('           delay, or answer from a cache without forwarding.');
  note('If you find yourself asking "is this a decorator or a proxy?", ask');
  note('whether the wrapped object might never be called. If yes: proxy.');

  flutterUse([
    'Flutter\'s `ImageCache` — a caching proxy in front of decoding',
    '`ListView.builder` — a virtual proxy for off-screen items',
    'a generated API client stub standing in for a remote service',
    'a feature-flag or permission wrapper around a repository',
  ]);
  avoidWhen([
    'the object is cheap — laziness adds a branch and a nullable field',
    'you are ADDING behaviour, not controlling access -> Decorator',
    'the indirection hides latency in a way callers must know about',
  ]);
}

abstract interface class ImageResource {
  String get path;
  String render();
}

/// The expensive real subject.
class HighResImage implements ImageResource {
  static int loadCount = 0;

  @override
  final String path;
  final int bytes;

  HighResImage(this.path) : bytes = path.length * 1000 {
    loadCount++; // pretend this decoded 8MB
  }

  @override
  String render() => 'rendered $path (${bytes}b)';
}

/// Virtual + caching proxy: nothing loads until render() is first called.
class LazyImageProxy implements ImageResource {
  @override
  final String path;
  HighResImage? _real;

  LazyImageProxy({required this.path});

  @override
  String render() {
    _real ??= HighResImage(path); // load once, on demand
    return _real!.render();
  }
}

class AuthContext {
  final String role;
  AuthContext({required this.role});
  bool get canViewSensitive => role == 'admin';
}

/// Protection proxy: may refuse to forward at all.
class ProtectedImage implements ImageResource {
  final ImageResource inner;
  final AuthContext auth;

  ProtectedImage({required this.inner, required this.auth});

  @override
  String get path => inner.path;

  @override
  String render() => auth.canViewSensitive
      ? inner.render()
      : 'ACCESS DENIED for role "${auth.role}" (inner never called)';
}

// =============================================================================
// SECTION 11 — STRATEGY
// =============================================================================

void section11Strategy() {
  section('11 · STRATEGY  [behavioural]');
  intent('Make an algorithm swappable behind an interface.');
  problem('A `switch` inside the class that picks HOW to do something, edited '
      'every time a new variant appears.');

  topic('Mini project: a pricing engine, as CLASS strategies');
  final checkout = PriceCheckout(rule: const RegularRule());
  show('regular', checkout.total(100000));
  checkout.rule = const MemberRule(); // swapped at RUNTIME
  show('member (swapped in place)', checkout.total(100000));
  checkout.rule = const SeasonalRule(percentOff: 25);
  show('seasonal 25%', checkout.total(100000));
  checkout.rule = const CouponRule(code: 'SAVE50', flatOffPaise: 50000);
  show('coupon', checkout.total(100000));
  show('PriceCheckout contains a behaviour switch?', 'no');

  topic('The same thing as FUNCTION strategies (very Dart)');
  final fnCheckout = FnCheckout(price: regularPrice);
  show('function strategy: regular', fnCheckout.total(100000));
  fnCheckout.price = (paise) => paise - paise * 10 ~/ 100; // an inline lambda
  show('function strategy: inline 10% off', fnCheckout.total(100000));
  fnCheckout.price = memberPrice;
  show('function strategy: named top-level fn', fnCheckout.total(100000));
  note('A `typedef Fn = int Function(int)` plus a closure IS a Strategy. When');
  note('the algorithm is one method with no state, prefer the function — you');
  note('skip an interface and N classes.');
  note('Use classes when the strategy needs a NAME, configuration, or several');
  note('related methods.');

  topic('A factory selects the strategy from config');
  for (final config in ['regular', 'member', 'seasonal', 'unknown']) {
    final rule = priceRuleFor(config);
    print('  ${config.padRight(9)} -> ${rule.label.padRight(16)} '
        '${PriceCheckout(rule: rule).total(100000)}');
  }
  note('Selection is isolated in the factory; the context stays closed.');

  topic('Keep strategies STATELESS');
  note('All the rules above are `const` — one instance can be shared by every');
  note('caller with no risk. A stateful strategy is a shared-mutable-state bug');
  note('waiting to happen; put the state in the context or the parameters.');

  topic('Strategy vs State vs Template Method');
  note('Strategy : the CLIENT picks the algorithm; variants are peers.');
  note('State    : the OBJECT picks, based on its own state, and the states');
  note('           transition between themselves (Section 14).');
  note('Template : the skeleton is fixed by INHERITANCE and only the steps');
  note('           vary; chosen at compile time (Section 15).');

  flutterUse([
    '`ScrollPhysics` — Bouncing vs Clamping, injected into a scroll view',
    '`List.sort(comparator)` — the comparator is a function strategy',
    '`Curve` in animations; `TextInputFormatter`s; validator functions',
    'a `PageTransitionsTheme` swapping route animation algorithms',
  ]);
  avoidWhen([
    'there is one algorithm and no sign of a second',
    'the variants differ by a single constant -> pass a parameter',
    'the behaviour depends on internal state transitions -> State',
  ]);
}

abstract interface class PriceRule {
  String get label;
  int apply(int pricePaise);
}

class RegularRule implements PriceRule {
  const RegularRule();
  @override
  String get label => 'regular';
  @override
  int apply(int pricePaise) => pricePaise;
}

class MemberRule implements PriceRule {
  const MemberRule();
  @override
  String get label => 'member';
  @override
  int apply(int pricePaise) => pricePaise - pricePaise * 15 ~/ 100;
}

class SeasonalRule implements PriceRule {
  final int percentOff;
  const SeasonalRule({required this.percentOff});
  @override
  String get label => 'seasonal $percentOff%';
  @override
  int apply(int pricePaise) => pricePaise - pricePaise * percentOff ~/ 100;
}

class CouponRule implements PriceRule {
  final String code;
  final int flatOffPaise;
  const CouponRule({required this.code, required this.flatOffPaise});
  @override
  String get label => 'coupon $code';
  @override
  int apply(int pricePaise) =>
      (pricePaise - flatOffPaise).clamp(0, pricePaise);
}

/// The context: holds a strategy, never a switch.
class PriceCheckout {
  PriceRule rule;
  PriceCheckout({required this.rule});
  int total(int pricePaise) => rule.apply(pricePaise);
}

PriceRule priceRuleFor(String config) => switch (config) {
      'member' => const MemberRule(),
      'seasonal' => const SeasonalRule(percentOff: 20),
      'regular' => const RegularRule(),
      _ => const RegularRule(), // safe default, chosen deliberately
    };

// Function strategies.
typedef PriceFn = int Function(int pricePaise);

int regularPrice(int pricePaise) => pricePaise;
int memberPrice(int pricePaise) => pricePaise - pricePaise * 15 ~/ 100;

class FnCheckout {
  PriceFn price;
  FnCheckout({required this.price});
  int total(int pricePaise) => price(pricePaise);
}

// =============================================================================
// SECTION 12 — OBSERVER
// =============================================================================

Future<void> section12Observer() async {
  section('12 · OBSERVER  [behavioural]');
  intent('Notify many dependents automatically when one object changes.');
  problem('The subject would otherwise have to know every interested party, '
      'and polling wastes work.');

  topic('Mini project: a stock ticker, hand-rolled');
  final ticker = PriceObservable(1000.0);
  final logger = LoggingObserver();
  final alerts = AlertObserver(threshold: 1100);

  final unsubscribeLogger = ticker.subscribe(logger);
  ticker.subscribe(alerts);
  show('observer count', ticker.observerCount);

  ticker.value = 1050;
  ticker.value = 1150;
  show('logger saw', logger.seen);
  show('alerts fired', alerts.fired);

  topic('Unsubscribing must actually stop delivery');
  unsubscribeLogger();
  show('observer count after unsubscribe', ticker.observerCount);
  ticker.value = 1200;
  show('logger saw (unchanged)', logger.seen);
  show('alerts still receiving', alerts.fired);
  note('The subscribe() call returned a CANCEL function — much harder to forget');
  note('than a matching `removeObserver` call somewhere else in the file.');

  topic('Notify over a COPY of the list');
  final reentrant = PriceObservable(1.0);
  reentrant.subscribe(SelfRemovingObserver(subject: reentrant));
  reentrant.subscribe(LoggingObserver());
  reentrant.value = 2.0; // an observer unsubscribes DURING the notify
  show('survived an unsubscribe mid-notify', 'yes');
  note('Iterating the live list while an observer removes itself would throw');
  note('ConcurrentModificationError. Always iterate `List.of(_observers)`.');

  topic('The same thing with a broadcast Stream (idiomatic Dart)');
  final controller = StreamController<double>.broadcast();
  final streamSeen = <double>[];
  final alertsFromStream = <String>[];
  final sub1 = controller.stream.listen(streamSeen.add);
  final sub2 = controller.stream
      .where((price) => price > 1100)
      .listen((price) => alertsFromStream.add('ALERT $price'));

  controller.add(1050);
  controller.add(1150);
  await Future<void>.delayed(Duration.zero);
  show('stream observers saw', streamSeen);
  show('filtered observer', alertsFromStream);

  await sub1.cancel();
  await sub2.cancel();
  controller.add(9999); // nobody is listening
  await Future<void>.delayed(Duration.zero);
  show('after cancel, nothing delivered', streamSeen);
  await controller.close();
  note('`Stream.broadcast` gives you filtering, mapping, async delivery and');
  note('backpressure for free. Prefer it (or ChangeNotifier/ValueNotifier)');
  note('over hand-rolling the pattern.');

  topic('LEAKS are the #1 Observer bug');
  note('A live subscription keeps the callback alive, which keeps the observer');
  note('alive, which in Flutter keeps State -> context -> the whole subtree');
  note('alive. Cancel every subscription in dispose(); close every controller');
  note('you created. See 02 Advanced Dart / 13_memory_and_gc.md.');

  flutterUse([
    '`ChangeNotifier` / `ValueNotifier` + `AnimatedBuilder` / `ListenableBuilder`',
    '`Stream` + `StreamBuilder`; Bloc/Riverpod are Observer at their core',
    '`Listenable.merge`, `ScrollController` listeners, `TextEditingController`',
    'anything reactive: the pattern IS state management',
  ]);
  avoidWhen([
    'there is exactly one dependent that you can just call directly',
    'notification order matters between observers (that is fragile by design)',
    'you cannot guarantee unsubscription -> you are building a leak',
  ]);
}

abstract interface class PriceObserver {
  void onPriceChanged(double price);
}

class LoggingObserver implements PriceObserver {
  final List<double> seen = [];
  @override
  void onPriceChanged(double price) => seen.add(price);
}

class AlertObserver implements PriceObserver {
  final double threshold;
  final List<String> fired = [];
  AlertObserver({required this.threshold});
  @override
  void onPriceChanged(double price) {
    if (price > threshold) fired.add('ALERT $price');
  }
}

/// Removes itself while being notified — the classic reentrancy hazard.
class SelfRemovingObserver implements PriceObserver {
  final PriceObservable subject;
  SelfRemovingObserver({required this.subject});
  @override
  void onPriceChanged(double price) => subject.unsubscribe(this);
}

class PriceObservable {
  final List<PriceObserver> _observers = [];
  double _value;

  PriceObservable(this._value);

  int get observerCount => _observers.length;

  double get value => _value;
  set value(double next) {
    if (next == _value) return; // do not notify for a no-op
    _value = next;
    _notify();
  }

  /// Returns the CANCEL function — the caller cannot lose the handle.
  void Function() subscribe(PriceObserver observer) {
    _observers.add(observer);
    return () => unsubscribe(observer);
  }

  void unsubscribe(PriceObserver observer) => _observers.remove(observer);

  void _notify() {
    // Iterate a COPY: an observer may unsubscribe during delivery.
    for (final observer in List.of(_observers)) {
      observer.onPriceChanged(_value);
    }
  }
}

// =============================================================================
// SECTION 13 — COMMAND
// =============================================================================

void section13Command() {
  section('13 · COMMAND  [behavioural]');
  intent('Turn a request into an object, so it can be stored, queued, logged, '
      'and UNDONE.');
  problem('"Add undo" is impossible when actions are just method calls — there '
      'is nothing to keep and nothing that knows its own inverse.');

  topic('Mini project: an undoable text editor');
  final editor = TextEditor(historyLimit: 5);
  editor.run(AppendCommand(' world'));
  editor.run(AppendCommand('!'));
  show('after two appends', '"${editor.text}"');
  editor.run(ReplaceCommand(from: 'hello', to: 'goodbye'));
  show('after replace', '"${editor.text}"');
  editor.run(DeleteCommand(count: 1));
  show('after delete', '"${editor.text}"');

  topic('Undo / redo');
  editor.undo();
  show('undo delete', '"${editor.text}"');
  editor.undo();
  show('undo replace', '"${editor.text}"');
  editor.redo();
  show('redo replace', '"${editor.text}"');
  show('undo stack / redo stack', '${editor.undoDepth} / ${editor.redoDepth}');

  topic('execute and undo must be exact inverses');
  final probe = TextEditor(historyLimit: 5);
  const original = 'hello';
  final command = ReplaceCommand(from: 'l', to: 'L');
  probe.run(command);
  final changed = probe.text;
  probe.undo();
  show('original -> changed -> undone', '"$original" -> "$changed" -> "${probe.text}"');
  show('round trip is exact', probe.text == original);
  note('ReplaceCommand stores the PREVIOUS text, not a reverse-replace. Trying');
  note('to compute the inverse ("replace L with l") breaks the moment the text');
  note('already contained an L. Capture the prior state instead.');

  topic('A MACRO command is just a Command containing Commands');
  final macro = MacroCommand([
    AppendCommand(' AAA'),
    AppendCommand(' BBB'),
    ReplaceCommand(from: 'AAA', to: 'XXX'),
  ]);
  final macroEditor = TextEditor(historyLimit: 5);
  macroEditor.run(macro);
  show('after macro', '"${macroEditor.text}"');
  macroEditor.undo();
  show('ONE undo reverses the whole macro', '"${macroEditor.text}"');
  note('The macro undoes its children in REVERSE order — that ordering is the');
  note('only subtle part of the whole pattern.');

  topic('History must be BOUNDED');
  final bounded = TextEditor(historyLimit: 3);
  for (var i = 0; i < 10; i++) {
    bounded.run(AppendCommand('$i'));
  }
  show('10 commands, limit 3 -> undo depth', bounded.undoDepth);
  note('Each command retains a snapshot. Unbounded history = a memory leak that');
  note('grows with usage, which is exactly the bug users report as "it gets');
  note('slower the longer I work".');

  topic('Dart shortcut: a pair of closures');
  final closureCommand = ClosureCommand(
    doIt: () => effects.add('did the thing'),
    undoIt: () => effects.add('undid the thing'),
  );
  effects.clear();
  closureCommand.execute();
  closureCommand.undo();
  show('closure-pair command', effects);
  note('When a command has no fields worth naming, two closures are enough.');

  flutterUse([
    '`Actions` / `Intent` / `Shortcuts` — Flutter\'s own Command implementation',
    'undo/redo in editors; `UndoHistory` and `TextEditingController` history',
    'a queue of offline mutations to replay when connectivity returns',
    'analytics/audit: log the command objects, not scattered call sites',
  ]);
  avoidWhen([
    'you do not need undo, queuing, logging or macros — just call the method',
    'capturing the inverse state is prohibitively large (whole-document copies)',
    'the "command" has no receiver and no state -> a plain function is fine',
  ]);
}

abstract interface class EditorCommand {
  void execute(TextEditorState state);
  void undo(TextEditorState state);
}

/// The receiver's mutable state, kept separate so commands stay small.
class TextEditorState {
  String text;
  TextEditorState(this.text);
}

class AppendCommand implements EditorCommand {
  final String suffix;
  AppendCommand(this.suffix);

  @override
  void execute(TextEditorState state) => state.text = state.text + suffix;

  @override
  void undo(TextEditorState state) =>
      state.text = state.text.substring(0, state.text.length - suffix.length);
}

class DeleteCommand implements EditorCommand {
  final int count;
  String _removed = '';
  DeleteCommand({required this.count});

  @override
  void execute(TextEditorState state) {
    _removed = state.text.substring(state.text.length - count);
    state.text = state.text.substring(0, state.text.length - count);
  }

  @override
  void undo(TextEditorState state) => state.text = state.text + _removed;
}

class ReplaceCommand implements EditorCommand {
  final String from;
  final String to;
  String _previous = '';

  ReplaceCommand({required this.from, required this.to});

  @override
  void execute(TextEditorState state) {
    _previous = state.text; // capture the PRIOR state, not a reverse operation
    state.text = state.text.replaceAll(from, to);
  }

  @override
  void undo(TextEditorState state) => state.text = _previous;
}

/// A Command made of Commands (Composite + Command).
class MacroCommand implements EditorCommand {
  final List<EditorCommand> commands;
  MacroCommand(this.commands);

  @override
  void execute(TextEditorState state) {
    for (final command in commands) {
      command.execute(state);
    }
  }

  @override
  void undo(TextEditorState state) {
    // REVERSE order, or the inverses do not line up.
    for (final command in commands.reversed) {
      command.undo(state);
    }
  }
}

class ClosureCommand {
  final void Function() doIt;
  final void Function() undoIt;
  ClosureCommand({required this.doIt, required this.undoIt});
  void execute() => doIt();
  void undo() => undoIt();
}

/// The invoker: owns history, knows nothing about what any command does.
class TextEditor {
  final int historyLimit;
  final TextEditorState _state = TextEditorState('hello');
  final Queue<EditorCommand> _undoStack = Queue();
  final List<EditorCommand> _redoStack = [];

  TextEditor({required this.historyLimit});

  String get text => _state.text;
  int get undoDepth => _undoStack.length;
  int get redoDepth => _redoStack.length;

  void run(EditorCommand command) {
    command.execute(_state);
    _undoStack.addLast(command);
    if (_undoStack.length > historyLimit) {
      _undoStack.removeFirst(); // bounded
    }
    _redoStack.clear(); // a new action invalidates the redo branch
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    final command = _undoStack.removeLast();
    command.undo(_state);
    _redoStack.add(command);
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final command = _redoStack.removeLast();
    command.execute(_state);
    _undoStack.addLast(command);
  }
}

// =============================================================================
// SECTION 14 — STATE
// =============================================================================

void section14State() {
  section('14 · STATE  [behavioural]');
  intent('Let an object change its BEHAVIOUR when its internal state changes.');
  problem('`if (status == "draft") ... else if (status == "shipped") ...` '
      'repeated in ship(), cancel(), deliver() and refund().');

  topic('Mini project: an order lifecycle, as State classes');
  final order = OrderContext();
  show('start', order.describe());
  for (final action in ['place', 'ship', 'deliver', 'cancel']) {
    final outcome = order.dispatch(action);
    print('  ${action.padRight(8)} -> ${outcome.padRight(34)} now: ${order.stateName}');
  }

  topic('Illegal transitions are DENIED by the state itself');
  final fresh = OrderContext();
  show('ship before placing', fresh.dispatch('ship'));
  show('deliver before shipping', fresh.dispatch('deliver'));
  show('state unchanged', fresh.stateName);
  final cancellable = OrderContext()..dispatch('place');
  show('cancel after placing', cancellable.dispatch('cancel'));
  show('ship after cancelling', cancellable.dispatch('ship'));
  note('Each state knows only its OWN legal moves. No central switch, and no');
  note('way for one state\'s rules to leak into another\'s.');

  topic('States are `const` and stateless');
  show('two references to the same state are identical',
      identical(const DraftState(), const DraftState()));
  note('All data lives in the CONTEXT; the states are pure behaviour, so one');
  note('instance can serve every order in the system.');

  topic('The Dart 3 alternative: sealed states + exhaustive switch');
  var phase = const DraftPhase() as OrderPhase;
  final log = <String>[];
  for (final event in ['place', 'ship', 'deliver']) {
    final next = advance(phase, event);
    log.add('${phaseName(phase)} --$event--> ${phaseName(next)}');
    phase = next;
  }
  for (final line in log) {
    note('  $line');
  }
  show('illegal move returns the same phase',
      phaseName(advance(const DeliveredPhase(), 'ship')));
  note('One `switch` per operation, exhaustively CHECKED: add a phase and every');
  note('transition function stops compiling until handled. Less boilerplate than');
  note('a class per state, and the compiler enforces coverage.');
  note('Trade-off: the classic form keeps each state\'s rules in one class;');
  note('the sealed form keeps each OPERATION in one place. Pick by which axis');
  note('changes more often.');

  topic('State vs Strategy');
  note('Identical structure. The difference:');
  note('  Strategy: the CLIENT chooses, variants are unaware of each other.');
  note('  State   : the OBJECT chooses, and states TRANSITION to one another.');
  note('If your "strategies" reference each other, you have a State machine.');

  flutterUse([
    'Bloc/Cubit states as sealed classes + exhaustive switch in the builder',
    'connection state, form state, checkout flow, media player state',
    '`AnimationStatus` (forward/reverse/completed/dismissed)',
    'Navigator flows where each step allows different actions',
  ]);
  avoidWhen([
    'two states and one boolean would do',
    'the states never transition — that is Strategy',
    'the machine is big enough to deserve a real FSM/statechart library',
  ]);
}

// --- classic State pattern ---
abstract class OrderState {
  const OrderState();
  String get name;

  /// Returns the outcome; may ask the context to transition.
  String handle(OrderContext context, String action);
}

class DraftState extends OrderState {
  const DraftState();
  @override
  String get name => 'draft';
  @override
  String handle(OrderContext context, String action) {
    if (action == 'place') {
      context.transitionTo(const PlacedState());
      return 'order placed';
    }
    return 'cannot "$action" a draft';
  }
}

class PlacedState extends OrderState {
  const PlacedState();
  @override
  String get name => 'placed';
  @override
  String handle(OrderContext context, String action) {
    switch (action) {
      case 'ship':
        context.transitionTo(const ShippedState());
        return 'order shipped';
      case 'cancel':
        context.transitionTo(const CancelledState());
        return 'order cancelled';
      default:
        return 'cannot "$action" a placed order';
    }
  }
}

class ShippedState extends OrderState {
  const ShippedState();
  @override
  String get name => 'shipped';
  @override
  String handle(OrderContext context, String action) {
    if (action == 'deliver') {
      context.transitionTo(const DeliveredState());
      return 'order delivered';
    }
    return 'cannot "$action" a shipped order';
  }
}

class DeliveredState extends OrderState {
  const DeliveredState();
  @override
  String get name => 'delivered';
  @override
  String handle(OrderContext context, String action) =>
      'delivered orders are final; "$action" refused';
}

class CancelledState extends OrderState {
  const CancelledState();
  @override
  String get name => 'cancelled';
  @override
  String handle(OrderContext context, String action) =>
      'cancelled orders are final; "$action" refused';
}

class OrderContext {
  OrderState _state = const DraftState();
  final List<String> history = ['draft'];

  String get stateName => _state.name;

  void transitionTo(OrderState next) {
    _state = next;
    history.add(next.name);
  }

  /// The context delegates — it holds NO conditional logic.
  String dispatch(String action) => _state.handle(this, action);

  String describe() => 'order is ${_state.name}';
}

// --- Dart 3 sealed alternative ---
sealed class OrderPhase {
  const OrderPhase();
}

class DraftPhase extends OrderPhase {
  const DraftPhase();
}

class PlacedPhase extends OrderPhase {
  const PlacedPhase();
}

class ShippedPhase extends OrderPhase {
  const ShippedPhase();
}

class DeliveredPhase extends OrderPhase {
  const DeliveredPhase();
}

class CancelledPhase extends OrderPhase {
  const CancelledPhase();
}

String phaseName(OrderPhase phase) => switch (phase) {
      DraftPhase() => 'draft',
      PlacedPhase() => 'placed',
      ShippedPhase() => 'shipped',
      DeliveredPhase() => 'delivered',
      CancelledPhase() => 'cancelled',
    };

/// One exhaustive switch per OPERATION. Add a phase -> this stops compiling.
OrderPhase advance(OrderPhase phase, String event) => switch (phase) {
      DraftPhase() when event == 'place' => const PlacedPhase(),
      PlacedPhase() when event == 'ship' => const ShippedPhase(),
      PlacedPhase() when event == 'cancel' => const CancelledPhase(),
      ShippedPhase() when event == 'deliver' => const DeliveredPhase(),
      _ => phase, // illegal move: no change
    };

// =============================================================================
// SECTION 15 — TEMPLATE METHOD
// =============================================================================

void section15TemplateMethod() {
  section('15 · TEMPLATE METHOD  [behavioural]');
  intent('Fix the SKELETON of an algorithm in a base class; let subclasses fill '
      'in the variable steps.');
  problem('Two importers share the same 6-step workflow but differ in two '
      'steps — and the workflow gets copy-pasted (then they drift apart).');

  topic('Mini project: an import pipeline');
  final csv = CsvImporter();
  final json = JsonImporter();

  final csvReport = csv.importAll('id,name\n1,Ada\nBROKEN\n2,Grace');
  show('CSV import', csvReport);
  show('CSV skipped rows (default hook)', csv.skipped);

  final jsonReport = json.importAll('{"id":1}\nNOT JSON\n{"id":2}');
  show('JSON import', jsonReport);
  show('JSON skipped rows (overridden hook)', json.skipped);
  note('`importAll` — open, parse, validate, collect, report, close — is');
  note('written ONCE. Each importer supplies only parseRow and validateRow.');

  topic('The skeleton must NOT be overridable');
  note('Dart has no `final` method modifier, so the convention is:');
  note('  * document the template method as "do not override"');
  note('  * keep the varying steps `@protected`-by-convention (or private-ish)');
  note('  * or seal the base with a `base class` modifier so subclasses cannot');
  note('    be implemented (only extended), which keeps super calls reliable');
  show('base class modifier used here', 'base class DataImporter');

  topic('Hooks: optional steps with a default');
  note('`onSkippedRow` has a working default (record it). CsvImporter accepts');
  note('the default; JsonImporter overrides it to add a prefix. A hook is how');
  note('you offer an extension point WITHOUT forcing every subclass to care.');

  topic('The Strategy-based alternative, side by side');
  final strategyImport = StrategyImporter(
    parse: (row) => row.contains(',') ? row.split(',') : null,
    validate: (cells) => cells.length == 2,
  );
  show('same job via composition', strategyImport.importAll('a,1\nbad\nb,2'));
  note('Template Method : inheritance, chosen at COMPILE time, one subclass per');
  note('                  variant, easy access to shared protected helpers.');
  note('Strategy        : composition, swappable at RUNTIME, mixable, testable');
  note('                  in isolation, no fragile-base-class risk.');
  note('Prefer Strategy when the steps vary independently or must change at');
  note('runtime; prefer Template Method when the workflow is genuinely a family');
  note('of near-identical subclasses.');

  flutterUse([
    '`State` lifecycle: initState -> didChangeDependencies -> build -> dispose',
    '  (the framework calls the skeleton, you override the steps)',
    '`RenderObject.performLayout`, `CustomPainter.paint`',
    '`StatelessWidget.build` — the one step you must supply',
  ]);
  avoidWhen([
    'the steps need to change at runtime -> Strategy',
    'you would need multiple inheritance to combine variants -> Strategy/mixins',
    'the base keeps calling itself in ways subclasses depend on (fragile base)',
  ]);
}

/// `base` = may be extended, never implemented, so `super` calls stay reliable.
base class DataImporter {
  final List<String> skipped = [];

  /// THE TEMPLATE METHOD. Do not override — override the steps instead.
  String importAll(String raw) {
    final rows = _open(raw);
    final imported = <List<String>>[];
    for (final row in rows) {
      final parsed = parseRow(row);
      if (parsed == null || !validateRow(parsed)) {
        onSkippedRow(row); // hook with a default
        continue;
      }
      imported.add(parsed);
    }
    final report = _report(imported.length, skipped.length);
    _close();
    return report;
  }

  // --- fixed steps (private = not overridable) ---
  List<String> _open(String raw) => raw.split('\n');
  String _report(int ok, int bad) => 'imported $ok, skipped $bad';
  void _close() {}

  // --- variable steps ---
  List<String>? parseRow(String row) => row.isEmpty ? null : [row];
  bool validateRow(List<String> cells) => true;

  // --- hook with a working default ---
  void onSkippedRow(String row) => skipped.add(row);
}

final class CsvImporter extends DataImporter {
  @override
  List<String>? parseRow(String row) =>
      row.contains(',') ? row.split(',') : null;

  @override
  bool validateRow(List<String> cells) =>
      cells.length == 2 && cells[0] != 'id'; // drop the header
}

final class JsonImporter extends DataImporter {
  @override
  List<String>? parseRow(String row) {
    final trimmed = row.trim();
    if (!trimmed.startsWith('{') || !trimmed.endsWith('}')) return null;
    return [trimmed];
  }

  /// Overriding the HOOK, not the skeleton.
  @override
  void onSkippedRow(String row) => skipped.add('malformed-json: "$row"');
}

/// The composition-based equivalent.
class StrategyImporter {
  final List<String>? Function(String row) parse;
  final bool Function(List<String> cells) validate;

  StrategyImporter({required this.parse, required this.validate});

  String importAll(String raw) {
    var ok = 0;
    var bad = 0;
    for (final row in raw.split('\n')) {
      final parsed = parse(row);
      if (parsed == null || !validate(parsed)) {
        bad++;
        continue;
      }
      ok++;
    }
    return 'imported $ok, skipped $bad';
  }
}

// =============================================================================
// SECTION 16 — CHAIN OF RESPONSIBILITY
// =============================================================================

void section16ChainOfResponsibility() {
  section('16 · CHAIN OF RESPONSIBILITY  [behavioural]');
  intent('Pass a request along a chain of handlers until one handles it.');
  problem('One method doing auth, then rate limiting, then routing, in a nest '
      'of ifs — where the order is implicit and nothing is reusable.');

  topic('Mini project: a request pipeline as linked handlers');
  final chain = LoggingHandler()
    ..setNext(AuthHandler()
      ..setNext(RateLimitHandler(limit: 2)..setNext(RouteHandler()..setNext(NotFoundHandler()))));

  for (final request in [
    RequestContext(path: '/public', token: null),
    RequestContext(path: '/private', token: null),
    RequestContext(path: '/private', token: 'valid'),
    RequestContext(path: '/private', token: 'valid'),
    RequestContext(path: '/private', token: 'valid'),
    RequestContext(path: '/nope', token: 'valid'),
  ]) {
    final response = chain.handle(request);
    print('  ${request.path.padRight(9)} token=${(request.token ?? '-').padRight(6)} '
        '-> $response');
  }
  note('AuthHandler SHORT-CIRCUITS unauthenticated private requests: the rest');
  note('of the chain never runs. RateLimitHandler short-circuits the 3rd call.');

  topic('A TERMINAL handler is mandatory');
  show('unmatched path reached the terminal handler', '404, not null');
  note('Without a terminal handler a request can fall off the end and return');
  note('null, which becomes a NoSuchMethodError three layers up. Always end the');
  note('chain with something that answers.');

  topic('Same pipeline as composed FUNCTIONS (very Dart)');
  final pipeline = composeMiddleware([
    loggingMiddleware,
    authMiddleware,
    routeMiddleware,
  ]);
  for (final request in [
    RequestContext(path: '/public', token: null),
    RequestContext(path: '/private', token: null),
    RequestContext(path: '/private', token: 'valid'),
  ]) {
    print('  ${request.path.padRight(9)} token=${(request.token ?? '-').padRight(6)} '
        '-> ${pipeline(request)}');
  }
  note('`typedef Middleware = Response Function(Request, Next)` is the same');
  note('pattern with no classes — this is exactly how shelf, Express and most');
  note('HTTP frameworks are built.');

  topic('ORDER is configuration, not code');
  final authFirst = composeMiddleware([authMiddleware, loggingMiddleware, routeMiddleware]);
  effects.clear();
  authFirst(RequestContext(path: '/private', token: null));
  show('auth before logging -> nothing logged', effects.isEmpty ? 'no log' : effects);
  effects.clear();
  pipeline(RequestContext(path: '/private', token: null));
  show('logging before auth -> request logged', effects);
  note('Reordering a list changes behaviour without touching a handler. That is');
  note('the OCP payoff — and the hazard, so make the order explicit and tested.');

  topic('CoR vs Decorator');
  note('CoR      : handlers may STOP the request; typically ONE handles it.');
  note('Decorator: every layer runs and augments; nobody short-circuits.');
  note('If a layer can answer on its own, it is a chain.');

  flutterUse([
    'Flutter gesture/notification bubbling up the tree (`Notification.dispatch`)',
    '`NavigatorObserver`s, route guards, Dio/http interceptors',
    'form validation running validators until one fails',
    'error handling: try local -> remote -> default',
  ]);
  avoidWhen([
    'exactly one handler will ever apply — call it',
    'every handler must run -> Decorator or a simple loop',
    'debugging matters more than flexibility (chains hide the actual path)',
  ]);
}

class RequestContext {
  final String path;
  final String? token;
  RequestContext({required this.path, required this.token});
}

abstract class Handler {
  Handler? _next;

  Handler setNext(Handler next) {
    _next = next;
    return next;
  }

  /// Default: pass along. Subclasses override to handle or short-circuit.
  String handle(RequestContext request) =>
      _next?.handle(request) ?? 'ERROR: fell off the end of the chain';
}

class LoggingHandler extends Handler {
  @override
  String handle(RequestContext request) {
    effects.add('log ${request.path}');
    return super.handle(request); // always passes along
  }
}

class AuthHandler extends Handler {
  @override
  String handle(RequestContext request) {
    final needsAuth = request.path.startsWith('/private');
    if (needsAuth && request.token == null) {
      return '401 unauthorised'; // SHORT-CIRCUIT
    }
    return super.handle(request);
  }
}

class RateLimitHandler extends Handler {
  final int limit;
  int _seen = 0;
  RateLimitHandler({required this.limit});

  @override
  String handle(RequestContext request) {
    _seen++;
    if (_seen > limit) return '429 too many requests'; // SHORT-CIRCUIT
    return super.handle(request);
  }
}

class RouteHandler extends Handler {
  static const _routes = {'/public': '200 public page', '/private': '200 secret page'};

  @override
  String handle(RequestContext request) {
    final page = _routes[request.path];
    if (page != null) return page;
    return super.handle(request);
  }
}

/// The TERMINAL handler — the chain always has an answer.
class NotFoundHandler extends Handler {
  @override
  String handle(RequestContext request) => '404 not found';
}

// --- functional middleware ---
typedef Next = String Function(RequestContext request);
typedef Middleware = String Function(RequestContext request, Next next);

String loggingMiddleware(RequestContext request, Next next) {
  effects.add('log ${request.path}');
  return next(request);
}

String authMiddleware(RequestContext request, Next next) {
  if (request.path.startsWith('/private') && request.token == null) {
    return '401 unauthorised';
  }
  return next(request);
}

String routeMiddleware(RequestContext request, Next next) =>
    switch (request.path) {
      '/public' => '200 public page',
      '/private' => '200 secret page',
      _ => next(request),
    };

Next composeMiddleware(List<Middleware> middleware) {
  // The terminal handler.
  Next chain = (request) => '404 not found';
  for (final layer in middleware.reversed) {
    final downstream = chain;
    chain = (request) => layer(request, downstream);
  }
  return chain;
}

// =============================================================================
// SECTION 17 — MEDIATOR
// =============================================================================

void section17Mediator() {
  section('17 · MEDIATOR  [behavioural]');
  intent('Put the interaction logic for a group of objects in ONE place.');
  problem('N components each holding references to the others: N x N coupling, '
      'and rules like "enable submit when..." smeared across all of them.');

  topic('Mini project: a login form mediator');
  final form = LoginMediator();
  show('initial submit enabled?', form.submitEnabled);

  // Each step mutates a COLLEAGUE and lets it report to the mediator — the
  // real direction of the pattern, rather than calling the mediator directly.
  final steps = <(String, void Function())>[
    ('type username', () => form.username.type('ada')),
    ('type short password', () => form.password.type('123')),
    ('type good password', () => form.password.type('hunter2!')),
    ('accept terms', () => form.terms.toggle(true)),
    ('clear username', () => form.username.type('')),
    ('retype username', () => form.username.type('ada')),
    ('untick terms', () => form.terms.toggle(false)),
  ];
  for (final (label, action) in steps) {
    action();
    print('  ${label.padRight(20)} submit=${form.submitEnabled.toString().padRight(5)} '
        'hint="${form.hint}"');
  }

  topic('Colleagues never reference each other');
  show('username field knows about the password field?', 'no');
  show('it knows about', 'its mediator only');
  note('Each field reports "I changed" to the mediator. The mediator re-applies');
  note('ALL the rules and pushes results back. Adding a 5th field changes one');
  note('method (`_recompute`), not four classes.');

  topic('The N x N problem it removes');
  note('Without a mediator, "enable submit" logic lives in username AND');
  note('password AND terms, each needing a reference to the other two:');
  show('references needed for 4 peers (n*(n-1))', 4 * 3);
  show('references needed with a mediator (n)', 4);

  topic('Risk: the mediator becomes a God object');
  note('SCOPE IT. One mediator per form/screen/feature, not per app. If your');
  note('mediator has 40 methods and 12 colleagues, split it by area — the');
  note('pattern was meant to reduce coupling, not centralise everything.');

  topic('Mediator vs Observer vs Facade');
  note('Mediator: BIDIRECTIONAL coordination between known peers; it holds the');
  note('          rules and pushes results back.');
  note('Observer: ONE-WAY broadcast; the subject does not know or care what');
  note('          observers do, and holds no rules about them.');
  note('Facade  : simplifies a SUBSYSTEM for outside callers; the components');
  note('          do not talk back through it.');

  flutterUse([
    'a ViewModel / Bloc / Cubit coordinating the widgets of one screen',
    '`Form` + `FormState` coordinating its `FormField`s',
    'a controller that owns several `TextEditingController`s and derived state',
    'an app-shell coordinating tabs, routing and a bottom nav',
  ]);
  avoidWhen([
    'two components interacting — let them talk directly',
    'the interaction is one-way notification -> Observer',
    'it would grow into an app-wide God object',
  ]);
}

/// Colleagues talk ONLY to this.
class LoginMediator {
  final UsernameField username = UsernameField();
  final PasswordField password = PasswordField();
  final TermsCheckbox terms = TermsCheckbox();
  final SubmitButton submit = SubmitButton();

  String hint = 'enter your username';

  LoginMediator() {
    username._mediator = this;
    password._mediator = this;
    terms._mediator = this;
  }

  bool get submitEnabled => submit.enabled;

  // Colleagues report changes; they never inspect one another.
  void usernameChanged(String value) {
    username.value = value;
    _recompute();
  }

  void passwordChanged(String value) {
    password.value = value;
    _recompute();
  }

  void termsChanged(bool value) {
    terms.checked = value;
    _recompute();
  }

  /// ALL the interaction rules, in one readable place.
  void _recompute() {
    final hasUsername = username.value.trim().isNotEmpty;
    final strongPassword = password.value.length >= 8;
    final accepted = terms.checked;

    submit.enabled = hasUsername && strongPassword && accepted;

    hint = switch ((hasUsername, strongPassword, accepted)) {
      (false, _, _) => 'enter your username',
      (_, false, _) => 'password needs 8+ characters',
      (_, _, false) => 'please accept the terms',
      _ => 'ready to sign in',
    };
  }
}

class UsernameField {
  LoginMediator? _mediator;
  String value = '';

  /// The user types; the field reports UP to the mediator and nowhere else.
  /// Note what is NOT here: any reference to the password field or the terms.
  void type(String next) {
    value = next;
    _mediator?.usernameChanged(next);
  }
}

class PasswordField {
  LoginMediator? _mediator;
  String value = '';

  void type(String next) {
    value = next;
    _mediator?.passwordChanged(next);
  }
}

class TermsCheckbox {
  LoginMediator? _mediator;
  bool checked = false;

  void toggle(bool next) {
    checked = next;
    _mediator?.termsChanged(next);
  }
}

class SubmitButton {
  bool enabled = false;
}

// =============================================================================
// SECTION 18 — VISITOR
// =============================================================================

void section18Visitor() {
  section('18 · VISITOR  [behavioural]');
  intent('Add new OPERATIONS to a stable set of types without editing them.');
  problem('An AST with 20 node types and a new operation every month — each '
      'one otherwise means editing all 20 classes.');

  topic('Mini project: an expression evaluator');
  // (2 + 3) * 4
  final ast = MulExpr(AddExpr(NumExpr(2), NumExpr(3)), NumExpr(4));

  show('EvalVisitor', ast.accept(EvalVisitor()));
  show('PrintVisitor', ast.accept(PrintVisitor()));
  show('DepthVisitor (added later, zero node edits)', ast.accept(DepthVisitor()));
  note('Three operations, and NumExpr/AddExpr/MulExpr were never touched after');
  note('they were written. That is the pattern\'s whole promise.');

  topic('Double dispatch — the mechanism');
  note('1. you call `node.accept(visitor)`');
  note('2. the NODE knows its own type, so it calls `visitor.visitMul(this)`');
  note('3. the VISITOR knows its own type, so the right method body runs');
  note('Two virtual calls select one behaviour from (nodes x operations).');
  note('Without step 2 you would need `if (node is MulExpr)` in every visitor.');

  topic('Visitor INVERTS the usual OCP trade-off');
  note('Normal polymorphism: easy to add TYPES, hard to add OPERATIONS.');
  note('Visitor            : easy to add OPERATIONS, hard to add TYPES.');
  note('Adding a 4th node type here means editing ExprVisitor and every');
  note('implementation of it. So use Visitor only when the TYPE set is stable');
  note('and the OPERATION set keeps growing (compilers, ASTs, document trees).');

  topic('The Dart 3 alternative: sealed classes + exhaustive switch');
  // The same expression, built from the SEALED `Node` hierarchy.
  const sealedAst = MulNode(AddNode(NumNode(2), NumNode(3)), NumNode(4));
  show('evaluate via switch', evaluate(sealedAst));
  show('print via switch', prettyPrint(sealedAst));
  show('depth via switch (3rd operation, no node edits)', depth(sealedAst));
  note('No accept(), no visitor interface, no double dispatch — and because');
  note('`Node` is SEALED, those switches carry no `_` arm at all: the compiler');
  note('verifies every subtype is handled. Add a 4th node type and all three');
  note('functions stop compiling until you handle it — a compile error instead');
  note('of a silently-missing visitX method.');
  note('(The Expr hierarchy above is not sealed, so a switch over IT would');
  note('still need a default — that contrast is the whole point.)');
  note('In modern Dart, prefer sealed + switch. Reach for classic Visitor when');
  note('operations must be pluggable at runtime or come from other packages');
  note('(a switch cannot be extended from outside; a visitor can).');

  flutterUse([
    '`RenderObject` tree walks; `Element.visitChildren`',
    '`InheritedWidget` dependency traversal',
    'analyzer/linter AST visitors (`package:analyzer` RecursiveAstVisitor)',
    'JSON/XML tree transformation; serialization over a node tree',
  ]);
  avoidWhen([
    'the type set changes often — every change breaks every visitor',
    'there is one operation — write a method on the type',
    'a sealed hierarchy + switch would be clearer (usually true in Dart 3)',
  ]);
}

abstract class Expr {
  const Expr();
  R accept<R>(ExprVisitor<R> visitor);
}

class NumExpr extends Expr {
  final double value;
  const NumExpr(this.value);
  @override
  R accept<R>(ExprVisitor<R> visitor) => visitor.visitNum(this);
}

class AddExpr extends Expr {
  final Expr left;
  final Expr right;
  const AddExpr(this.left, this.right);
  @override
  R accept<R>(ExprVisitor<R> visitor) => visitor.visitAdd(this);
}

class MulExpr extends Expr {
  final Expr left;
  final Expr right;
  const MulExpr(this.left, this.right);
  @override
  R accept<R>(ExprVisitor<R> visitor) => visitor.visitMul(this);
}

abstract interface class ExprVisitor<R> {
  R visitNum(NumExpr node);
  R visitAdd(AddExpr node);
  R visitMul(MulExpr node);
}

class EvalVisitor implements ExprVisitor<double> {
  @override
  double visitNum(NumExpr node) => node.value;
  @override
  double visitAdd(AddExpr node) =>
      node.left.accept(this) + node.right.accept(this);
  @override
  double visitMul(MulExpr node) =>
      node.left.accept(this) * node.right.accept(this);
}

class PrintVisitor implements ExprVisitor<String> {
  @override
  String visitNum(NumExpr node) => node.value.toStringAsFixed(0);
  @override
  String visitAdd(AddExpr node) =>
      '(${node.left.accept(this)} + ${node.right.accept(this)})';
  @override
  String visitMul(MulExpr node) =>
      '${node.left.accept(this)} * ${node.right.accept(this)}';
}

/// Added after the nodes were written — no node class changed.
class DepthVisitor implements ExprVisitor<int> {
  @override
  int visitNum(NumExpr node) => 1;
  @override
  int visitAdd(AddExpr node) =>
      1 + (node.left.accept(this) > node.right.accept(this)
          ? node.left.accept(this)
          : node.right.accept(this));
  @override
  int visitMul(MulExpr node) =>
      1 + (node.left.accept(this) > node.right.accept(this)
          ? node.left.accept(this)
          : node.right.accept(this));
}

// --- the Dart 3 way: sealed + exhaustive switch, no visitor at all ---
sealed class Node {
  const Node();
}

class NumNode extends Node {
  final double value;
  const NumNode(this.value);
}

class AddNode extends Node {
  final Node left;
  final Node right;
  const AddNode(this.left, this.right);
}

class MulNode extends Node {
  final Node left;
  final Node right;
  const MulNode(this.left, this.right);
}

// NOTE the absence of a `_` arm below. These compile ONLY because `Node` is
// `sealed`: the compiler can see the complete subtype list and verify coverage.
// The `Expr` hierarchy above is NOT sealed, so a switch over it would still
// need a default — which is exactly the difference this section is about.

double evaluate(Node node) => switch (node) {
      NumNode(value: final v) => v,
      AddNode(left: final l, right: final r) => evaluate(l) + evaluate(r),
      MulNode(left: final l, right: final r) => evaluate(l) * evaluate(r),
    };

String prettyPrint(Node node) => switch (node) {
      NumNode(value: final v) => v.toStringAsFixed(0),
      AddNode(left: final l, right: final r) =>
        '(${prettyPrint(l)} + ${prettyPrint(r)})',
      MulNode(left: final l, right: final r) =>
        '${prettyPrint(l)} * ${prettyPrint(r)}',
    };

/// A third operation, added with no edits to any node class — the same win the
/// Visitor gives, without the accept()/visitX ceremony.
int depth(Node node) => switch (node) {
      NumNode() => 1,
      AddNode(left: final l, right: final r) =>
        1 + (depth(l) > depth(r) ? depth(l) : depth(r)),
      MulNode(left: final l, right: final r) =>
        1 + (depth(l) > depth(r) ? depth(l) : depth(r)),
    };

// =============================================================================
// SECTION 19 — ITERATOR
// =============================================================================

void section19Iterator() {
  section('19 · ITERATOR  [behavioural]');
  intent('Traverse a collection sequentially without exposing how it stores '
      'its elements.');
  problem('Callers reaching into `list._nodes` or needing to know it is a '
      'linked list, a tree, or a ring buffer.');

  topic('Mini project: a LinkedList that IS an Iterable');
  final list = SinglyLinkedList<String>()
    ..add('alpha')
    ..add('beta')
    ..add('gamma');

  show('length', list.length);
  print('  for-in:');
  for (final item in list) {
    print('    $item');
  }
  note('`extends Iterable<T>` + a `sync*` generator gives you `for-in` and the');
  note('ENTIRE Iterable API for free — the caller never sees a _Node.');

  topic('The whole Iterable API comes along');
  show('map', list.map((s) => s.toUpperCase()).toList());
  show('where', list.where((s) => s.contains('a')).toList());
  show('first / last', '${list.first} / ${list.last}');
  show('contains', list.contains('beta'));
  show('join', list.join(' -> '));
  show('fold (total chars)', list.fold<int>(0, (sum, s) => sum + s.length));
  show('take(2)', list.take(2).toList());
  show('isEmpty on a fresh list', SinglyLinkedList<int>().isEmpty);

  topic('A FRESH iterator per traversal');
  final a = list.iterator;
  a.moveNext();
  final b = list.iterator;
  b.moveNext();
  b.moveNext();
  show('two independent cursors', '${a.current} and ${b.current}');
  note('`get iterator` must return a NEW iterator each time. Caching one makes');
  note('a second for-in silently start where the first stopped.');

  topic('The raw protocol underneath');
  final cursor = list.iterator;
  final collected = <String>[];
  while (cursor.moveNext()) {
    collected.add(cursor.current);
  }
  show('moveNext/current by hand', collected);
  note('`for-in` is sugar for exactly this loop.');

  topic('Do NOT mutate during iteration');
  try {
    for (final _ in list) {
      list.add('boom'); // structural change mid-traversal
    }
  } on ConcurrentModificationError catch (_) {
    show('mutating while iterating', 'ConcurrentModificationError');
  }
  note('The generator checks a modification counter — the same protection');
  note('Dart\'s own List provides.');

  topic('Lazy generators: `sync*` vs `async*`');
  final firstFive = naturals().take(5).toList();
  show('infinite sequence, taken lazily', firstFive);
  show('lazily computed, nothing precomputed', 'naturals() never ends');
  note('sync*  -> Iterable<T>, pull-based, `for-in`      (this section)');
  note('async* -> Stream<T>,   push-based, `await for`    (Module 02)');
  note('Both are the Iterator pattern; one is synchronous, one is not.');

  flutterUse([
    'every `for-in`, `map`, `where` you write — Dart\'s Iterable IS this pattern',
    '`ListView.builder` pulling items on demand as you scroll',
    '`Element.visitChildren` walking the tree',
    'paginated API results exposed as a lazy sequence',
  ]);
  avoidWhen([
    'a plain List/Map already does the job — do not wrap it',
    'you need random access by index (an iterator is sequential by design)',
    'in Dart, hand-writing an Iterator class instead of using `sync*`',
  ]);
}

class _LinkNode<T> {
  final T value;
  _LinkNode<T>? next;
  _LinkNode(this.value);
}

/// Extending Iterable means implementing ONE member: `iterator`.
class SinglyLinkedList<T> extends Iterable<T> {
  _LinkNode<T>? _head;
  _LinkNode<T>? _tail;
  int _length = 0;
  int _modCount = 0;

  void add(T value) {
    final node = _LinkNode<T>(value);
    if (_head == null) {
      _head = _tail = node;
    } else {
      _tail!.next = node;
      _tail = node;
    }
    _length++;
    _modCount++;
  }

  @override
  int get length => _length;

  /// A NEW iterator every call, via a generator. Internals stay hidden.
  @override
  Iterator<T> get iterator => _walk().iterator;

  Iterable<T> _walk() sync* {
    final startMod = _modCount;
    var current = _head;
    while (current != null) {
      if (_modCount != startMod) throw ConcurrentModificationError(this);
      yield current.value;
      current = current.next;
    }
  }
}

/// An infinite lazy sequence — only as much is computed as you take.
Iterable<int> naturals() sync* {
  var n = 1;
  while (true) {
    yield n++;
  }
}

// =============================================================================
// SECTION 20 — REPOSITORY
// =============================================================================

void section20Repository() {
  section('20 · REPOSITORY  [application]');
  intent('Give the domain a clean, source-agnostic API for its data.');
  problem('ViewModels calling http and sqflite directly, juggling DTOs, cache '
      'invalidation and error shapes — and untestable as a result.');

  topic('Mini project: a users data layer');
  final remote = FakeRemoteUserApi(users: {
    '1': {'id': '1', 'full_name': 'Ada Lovelace', 'email_address': 'ada@x.test'},
  });
  final local = FakeLocalUserCache(maxEntries: 2);
  final repository = UserRepositoryImpl(remote: remote, local: local);
  final getUser = GetUser(repository: repository);

  show('1st call (remote)', getUser('1'));
  show('remote calls', remote.calls);
  show('2nd call (cache)', getUser('1'));
  show('remote calls after cache hit', remote.calls);
  show('missing user -> Err, not an exception', getUser('999'));
  show('remote error -> translated', getUser('boom'));

  topic('The repository returns ENTITIES, never DTOs');
  final result = repository.byId('1');
  result.fold(
    ok: (user) {
      show('entity type', user.runtimeType);
      show('domain-shaped fields', '${user.name} / ${user.email}');
      note('  the wire used snake_case `full_name` / `email_address`;');
      note('  the entity uses domain names. Mapping happened INSIDE the repo.');
    },
    err: (e) => show('unexpected', e),
  );
  show('does the domain know about `full_name`?', 'no');

  topic('What lives INSIDE a repository');
  note('V  choosing the source (cache vs network vs local db)');
  note('V  DTO <-> entity mapping');
  note('V  caching and invalidation');
  note('V  error translation (SocketException -> Err("offline"))');
  note('x  UI concerns, navigation, widget state');
  note('x  business rules that belong to entities/use cases');

  topic('The interface belongs to the DOMAIN (DIP)');
  note('domain/  user_repository.dart   <- the abstract interface + entity');
  note('data/    user_repository_impl.dart, dtos, api client, cache');
  note('The arrow points INWARD: data depends on domain, never the reverse.');
  show('GetUser depends on', 'UserRepository (abstract)');
  show('GetUser tested with', 'the fakes above — no HTTP, no sqlite');

  topic('Caching must be BOUNDED');
  repository.byId('1');
  show('cache entries after several ids', local.size);
  show('cache cap', local.maxEntries);
  note('An unbounded cache in a long-lived repository is a leak that grows with');
  note('session length. Cap by count, by TTL, or both.');

  topic('Repository vs DAO');
  note('Repository: DOMAIN-level, collection-like, returns entities/aggregates.');
  note('            `UserRepository.byId`, `.search`, `.save`');
  note('DAO       : QUERY-level, table-oriented, returns rows/DTOs.');
  note('            `UserDao.selectWhereEmailLike(...)`');
  note('A repository often USES one or more DAOs; they are not synonyms.');

  flutterUse([
    'the standard Flutter data layer: ViewModel -> Repository -> api + db',
    'offline-first: repository decides cache-then-network and merges',
    'swapping a fake repository into widget tests and previews',
    'feature-flagged sources (mock vs staging vs prod) chosen at wiring time',
  ]);
  avoidWhen([
    'a tiny app with one data source and no caching — the layer is pure overhead',
    'it would become a pass-through with one method per API endpoint (that is a',
    '  DAO wearing a repository name)',
    'you leak DTOs or `Response` objects through it — then it abstracts nothing',
  ]);
}

/// DOMAIN entity — no wire concerns.
class UserEntity {
  final String id;
  final String name;
  final String email;
  const UserEntity({required this.id, required this.name, required this.email});
  @override
  String toString() => 'UserEntity($id, $name)';
}

/// DATA-layer DTO — mirrors the wire exactly, stays inside the data layer.
class UserDto {
  final String id;
  final String fullName;
  final String emailAddress;
  const UserDto({
    required this.id,
    required this.fullName,
    required this.emailAddress,
  });

  factory UserDto.fromJson(Map<String, String> json) => UserDto(
        id: json['id']!,
        fullName: json['full_name']!,
        emailAddress: json['email_address']!,
      );

  UserEntity toEntity() =>
      UserEntity(id: id, name: fullName, email: emailAddress);
}

/// The interface the DOMAIN owns.
abstract interface class UserRepository {
  Result<UserEntity> byId(String id);
}

class FakeRemoteUserApi {
  final Map<String, Map<String, String>> users;
  int calls = 0;
  FakeRemoteUserApi({required this.users});

  Map<String, String> fetch(String id) {
    calls++;
    if (id == 'boom') throw StateError('socket closed');
    final json = users[id];
    if (json == null) throw ArgumentError('404 for $id');
    return json;
  }
}

class FakeLocalUserCache {
  final int maxEntries;
  final Map<String, UserEntity> _entries = {};
  FakeLocalUserCache({required this.maxEntries});

  int get size => _entries.length;

  UserEntity? read(String id) => _entries[id];

  void write(UserEntity user) {
    _entries[user.id] = user;
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first); // bounded
    }
  }
}

/// Cache-then-network, mapping, and error translation — all in here.
class UserRepositoryImpl implements UserRepository {
  final FakeRemoteUserApi remote;
  final FakeLocalUserCache local;

  UserRepositoryImpl({required this.remote, required this.local});

  @override
  Result<UserEntity> byId(String id) {
    final cached = local.read(id);
    if (cached != null) return Ok(cached);

    try {
      final dto = UserDto.fromJson(remote.fetch(id));
      final entity = dto.toEntity(); // DTO -> entity mapping
      local.write(entity);
      return Ok(entity);
    } on ArgumentError {
      return Err('user $id not found'); // translated, not leaked
    } on StateError {
      return Err('you appear to be offline');
    }
  }
}

/// Use case: depends on the ABSTRACTION only.
class GetUser {
  final UserRepository repository;
  const GetUser({required this.repository});

  String call(String id) => repository.byId(id).fold(
        ok: (user) => 'found ${user.name}',
        err: (e) => 'error: $e',
      );
}

// =============================================================================
// SECTION 21 — DEPENDENCY INJECTION
// =============================================================================

void section21DependencyInjection() {
  section('21 · DEPENDENCY INJECTION  [application]');
  intent('Supply a class\'s collaborators from OUTSIDE instead of letting it '
      'create them.');
  problem('A class that `new`s its own database and mail client cannot be '
      'tested, reused, or reconfigured.');

  topic('Mini project: a DI-wired order service');
  effects.clear();
  final injector = Injector()
    ..registerSingleton<DiOrderRepository>(() => InMemoryOrderRepository())
    ..registerSingleton<DiEmailSender>(() => RecordingEmailSender())
    ..registerSingleton<DiLogger>(() => CollectingLogger());

  final service = DiCompositionRoot.build(injector);
  show('place order', service.place('sku-1', 129900));
  show('place another', service.place('sku-2', 4900));
  final repo = injector.resolve<DiOrderRepository>();
  final mail = injector.resolve<DiEmailSender>();
  final logger = injector.resolve<DiLogger>();
  show('ASSERT orders saved', repo is InMemoryOrderRepository ? repo.saved : []);
  show('ASSERT emails sent', mail is RecordingEmailSender ? mail.sent : []);
  show('ASSERT log lines', logger is CollectingLogger ? logger.lines.length : 0);
  show('real infrastructure touched', effects.isEmpty ? 'none' : effects);
  show('`new` inside DiOrderService?', 'none — all three deps are injected');

  topic('Constructor injection is the default');
  note('V  constructor : dependencies are REQUIRED and visible in the signature;');
  note('   an incompletely-wired object cannot be constructed at all.');
  note('~  setter      : optional/replaceable deps; allows a half-built object.');
  note('~  method      : a dep needed by ONE method only — pass it as an arg.');
  note('x  service locator INSIDE a class (`GetIt.I<Foo>()`): compiles, but the');
  note('   dependency is invisible again. Use the locator at the ROOT only.');

  topic('One composition root');
  note('main() (or a single injector setup file) is the ONLY place that names');
  note('concrete classes. Everything downstream receives what it needs.');
  final testInjector = Injector()
    ..registerSingleton<DiOrderRepository>(() => FailingOrderRepository())
    ..registerSingleton<DiEmailSender>(() => RecordingEmailSender())
    ..registerSingleton<DiLogger>(() => CollectingLogger());
  final failing = DiCompositionRoot.build(testInjector);
  show('same service, a failing repo injected', failing.place('sku-9', 100));
  note('No production code changed — only the wiring.');

  topic('DIP vs DI vs a container');
  note('DIP       : the PRINCIPLE — depend on abstractions.');
  note('DI        : the TECHNIQUE — hand dependencies in from outside.');
  note('Container : the TOOL — automates the handing-in (get_it, injectable,');
  note('            Riverpod providers). Entirely optional.');
  note('You can have DI with no container (just constructors), and a container');
  note('with no DIP (registering concrete classes everywhere). Aim for DIP.');

  topic('Register singletons vs factories');
  final lifetimes = Injector()
    ..registerSingleton<DiLogger>(() => CollectingLogger())
    ..registerFactory<DiOrderRepository>(() => InMemoryOrderRepository());
  show('singleton -> same instance',
      identical(lifetimes.resolve<DiLogger>(), lifetimes.resolve<DiLogger>()));
  show('factory   -> new instance each time',
      !identical(lifetimes.resolve<DiOrderRepository>(),
          lifetimes.resolve<DiOrderRepository>()));
  note('Singleton: stateless services, clients, caches you WANT shared.');
  note('Factory  : anything holding per-use state (a form controller, a');
  note('           request-scoped unit of work).');

  topic('What to inject');
  note('INJECT  : repositories, api clients, databases, clock, random,');
  note('          analytics, feature flags — anything volatile or external');
  note('DO NOT  : value objects, pure functions, `String`s, enums, entities.');
  note('          Injecting a `DateTime` value (not a Clock) is just a parameter.');

  flutterUse([
    'get_it + injectable, Riverpod providers, Provider, or plain constructors',
    'InheritedWidget/`Theme.of(context)` — Flutter\'s own built-in injection',
    'overriding providers in tests and in `golden`/widget tests',
    'full treatment in Module 14 · Dependency Injection',
  ]);
  avoidWhen([
    'the dependency is trivial and stable (a pure helper function)',
    'you would inject 8 collaborators — that is an SRP problem, not a DI one',
    'a container is used as a global bag of state (that is a Singleton again)',
  ]);
}

abstract interface class DiOrderRepository {
  Result<String> save(String sku, int amountPaise);
}

abstract interface class DiEmailSender {
  void send(String to, String body);
}

abstract interface class DiLogger {
  void log(String line);
}

class InMemoryOrderRepository implements DiOrderRepository {
  final List<String> saved = [];
  @override
  Result<String> save(String sku, int amountPaise) {
    saved.add('$sku@${amountPaise}p');
    return Ok('order-${saved.length}');
  }
}

class FailingOrderRepository implements DiOrderRepository {
  @override
  Result<String> save(String sku, int amountPaise) => const Err('database down');
}

class RecordingEmailSender implements DiEmailSender {
  final List<String> sent = [];
  @override
  void send(String to, String body) => sent.add('$to: $body');
}

class CollectingLogger implements DiLogger {
  final List<String> lines = [];
  @override
  void log(String line) => lines.add(line);
}

/// No `new`, no locator lookups — three injected abstractions.
class DiOrderService {
  final DiOrderRepository repository;
  final DiEmailSender email;
  final DiLogger logger;

  const DiOrderService({
    required this.repository,
    required this.email,
    required this.logger,
  });

  String place(String sku, int amountPaise) {
    logger.log('placing $sku');
    return repository.save(sku, amountPaise).fold(
      ok: (orderId) {
        email.send('customer@x.test', 'order $orderId confirmed');
        logger.log('placed $orderId');
        return 'ok: $orderId';
      },
      err: (e) {
        logger.log('failed: $e');
        return 'failed: $e';
      },
    );
  }
}

/// A minimal container supporting both lifetimes.
class Injector {
  final Map<Type, Object Function()> _factories = {};
  final Map<Type, Object> _singletons = {};
  final Set<Type> _singletonTypes = {};

  void registerSingleton<T extends Object>(T Function() create) {
    _factories[T] = create;
    _singletonTypes.add(T);
  }

  void registerFactory<T extends Object>(T Function() create) =>
      _factories[T] = create;

  T resolve<T extends Object>() {
    if (_singletonTypes.contains(T)) {
      final existing = _singletons[T];
      if (existing != null) return existing as T;
    }
    final create = _factories[T];
    if (create == null) throw StateError('nothing registered for $T');
    final created = create();
    if (_singletonTypes.contains(T)) _singletons[T] = created;
    return created as T;
  }
}

/// The single place that resolves concretes.
class DiCompositionRoot {
  static DiOrderService build(Injector injector) => DiOrderService(
        repository: injector.resolve<DiOrderRepository>(),
        email: injector.resolve<DiEmailSender>(),
        logger: injector.resolve<DiLogger>(),
      );
}

// =============================================================================
// SECTION 22 — CHOOSING A PATTERN
// =============================================================================

void section22ChoosingAPattern() {
  section('22 · CHOOSING A PATTERN (and the confusable pairs)');

  topic('Start from the SMELL, not the pattern');
  for (final (smell, answer) in const [
    ('`new Concrete()` everywhere', 'Factory / DI'),
    ('constructor with 9 optional args + cross-field rules', 'Builder'),
    ('growing switch on a type or enum', 'Strategy / State / registry'),
    ('subclass per feature combination (2^n classes)', 'Decorator'),
    ('two axes multiplying into M x N classes', 'Bridge'),
    ('a vendor SDK whose shape does not fit', 'Adapter'),
    ('callers orchestrating 5 services in the right order', 'Facade'),
    ('`if (node is Dir) recurse else ...` when walking a tree', 'Composite'),
    ('expensive object built even when unused', 'Proxy (virtual)'),
    ('"add undo" / "queue these actions"', 'Command'),
    ('status string checked in every method', 'State'),
    ('copy-pasted workflow differing in two steps', 'Template Method'),
    ('nested ifs for auth, then limits, then routing', 'Chain of Responsibility'),
    ('N components each referencing the other N-1', 'Mediator'),
    ('a new operation over a stable type set every month', 'Visitor / sealed switch'),
    ('callers reaching into your internal storage', 'Iterator'),
    ('ViewModel calling http and sqflite directly', 'Repository'),
    ('cannot test a class without a real database', 'DI'),
  ]) {
    print('  ${smell.padRight(50)} -> $answer');
  }

  topic('The pairs everyone confuses');
  for (final (pair, distinction) in const [
    ('Decorator vs Proxy',
        'both wrap the same interface; a Decorator ALWAYS forwards and adds, a Proxy decides IF/WHEN to forward'),
    ('Strategy vs State',
        'same structure; the CLIENT picks a Strategy, the OBJECT picks a State and states transition'),
    ('Strategy vs Bridge',
        'Strategy swaps one algorithm at runtime; Bridge is a designed 2-axis structure held for the object\'s lifetime'),
    ('Adapter vs Facade',
        'Adapter CONVERTS one mismatched interface; Facade SIMPLIFIES many components'),
    ('Facade vs Mediator',
        'Facade is one-way, for outside callers; Mediator is two-way, between known peers'),
    ('Mediator vs Observer',
        'Mediator holds the rules and coordinates; Observer just broadcasts and holds none'),
    ('Template Method vs Strategy',
        'inheritance + compile-time vs composition + runtime swap'),
    ('CoR vs Decorator',
        'CoR handlers may STOP the request; Decorator layers all run'),
    ('Visitor vs sealed switch',
        'same goal; visitor is runtime-extensible, sealed switch is compiler-checked and shorter'),
    ('Factory vs Builder',
        'Factory picks WHICH class; Builder assembles HOW one instance is put together'),
    ('Repository vs DAO',
        'Repository is domain-level and returns entities; DAO is query-level and returns rows'),
    ('DIP vs DI vs container',
        'principle vs technique vs tool — you can do the first two with neither of the others'),
  ]) {
    print('  ${pair.padRight(28)} $distinction');
  }

  topic('Where Dart 3 replaces a classic pattern');
  note('Visitor          -> sealed classes + exhaustive `switch`');
  note('Strategy         -> a `typedef` + closure (no interface, no classes)');
  note('Prototype        -> immutable class + `copyWith`');
  note('Iterator         -> `extends Iterable` + `sync*`');
  note('Observer         -> `Stream.broadcast` / `ChangeNotifier`');
  note('Singleton        -> a single instance registered in a DI container');
  note('Builder          -> named parameters + `copyWith` + cascades');
  note('Command (simple) -> a pair of closures');
  note('Knowing the pattern is still what lets you recognise the problem — you');
  note('just implement it with less ceremony.');

  topic('The rule that matters most');
  note('A pattern is a RESPONSE to a pressure you can already feel, not a goal.');
  note('Write the simple thing first. When the second variant arrives, or the');
  note('switch grows a third arm, or a test needs a fake — THEN reach for the');
  note('pattern whose shape matches. Applying patterns pre-emptively produces');
  note('the same unmaintainable code you were trying to avoid, with more files.');

  print('\nAll 21 patterns demonstrated, each with its mini project. '
      'Read each notes file for UML, theory and interview questions.');
}
