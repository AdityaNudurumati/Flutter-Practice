// =============================================================================
// Day 4 · Part 5 — CAPSTONE: Mini Store (covers Days 1–4)
// Run: dart run Day4/05_capstone_store.dart
// =============================================================================
//
// One program that exercises EVERYTHING from Days 1–4. Read it top-to-bottom;
// each block is labelled with the concept it demonstrates.
//
//  DATA TYPES / NULL SAFETY : int, double, String, bool, DateTime, T?, ?? , !
//  VARIABLES                : var / final / const
//  FUNCTIONS                : named/optional/required params, arrow, higher-order,
//                             closures, typedef
//  COLLECTIONS + FUNCTIONAL : List, Set, Map ; map/where/fold/reduce/firstWhere/toSet
//  OOP                      : encapsulation, abstract class, interface (implements),
//                             inheritance (extends), mixin, polymorphism
//  CONSTRUCTORS             : default, named, const, factory (fromJson), init list
//  GENERICS                 : Repository<T extends Identifiable>, generic function
//  ENUMS                    : enhanced enums (Category, OrderStatus)
//  EXTENSIONS               : num.asPrice, String.capitalized
//  EXCEPTIONS               : custom exceptions, try/catch/on/finally, throw
//  ASYNC                    : Future, async/await, Future.delayed, Future.wait
//  STREAMS                  : StreamController.broadcast, listen, live status feed
// =============================================================================

import 'dart:async';

Future<void> main() async {
  print('=== MINI STORE — Day 1–4 capstone ===\n');
  final api = StoreApi();

  // [1] ASYNC + Future.wait: load catalog and user profile IN PARALLEL.
  print('[1] Loading home screen (parallel fetch)...');
  final results = await Future.wait([api.fetchCatalog(), api.fetchUserProfile()]);
  final catalog = results[0] as List<Product>;
  final profile = results[1] as String;
  print('  welcome ${profile.capitalized} — ${catalog.length} products loaded\n');

  // GENERICS: a type-safe repository keyed by id.
  final repo = Repository<Product>()..addAll(catalog);

  // [2] COLLECTIONS + FUNCTIONAL programming.
  print('[2] Catalog analytics:');
  final inStock = catalog.where((p) => p.inStock).map((p) => p.name); // lazy
  print('  in stock: ${inStock.join(', ')}');

  final categories = catalog.map((p) => p.category).toSet(); // SET (unique)
  print('  categories: ${categories.map((c) => c.label).join(', ')}');

  // fold into a MAP to group by category.
  final byCategory = catalog.fold<Map<Category, List<Product>>>({}, (m, p) {
    m.putIfAbsent(p.category, () => []).add(p);
    return m;
  });
  byCategory.forEach((c, items) => print('  ${c.label}: ${items.length} item(s)'));

  // reduce to find extremes; fold to total stock.
  final cheapest = catalog.reduce((a, b) => a.price < b.price ? a : b);
  final totalUnits = catalog.fold<int>(0, (sum, p) => sum + p.stock);
  print('  cheapest: ${cheapest.name} @ ${cheapest.price.asPrice}, units in stock: $totalUnits\n');

  // [3] Build a cart with NULL-SAFE generic lookups.
  print('[3] Building cart:');
  final cart = Cart();
  final laptop = repo.findById(1); // Product?
  final book = repo.findById(3);
  if (laptop != null) cart.add(laptop, 1); // promotion after null check
  if (book != null) cart.add(book, 2);
  print('  missing product -> ${repo.findById(99)?.name ?? 'not found'}'); // ?? fallback
  for (final item in cart.items) {
    print('  ${item.quantity} x ${item.product.name} = ${item.subtotal.asPrice}');
  }
  print('  subtotal: ${cart.total.asPrice}');

  // FUNCTIONS: typedef + higher-order + closure (a discount rule).
  final DiscountRule tenPercent = percentOff(10);
  print('  after 10% off: ${applyDiscount(cart.total, tenPercent).asPrice}\n');

  // [4] STREAMS + async checkout + POLYMORPHIC payment.
  print('[4] Checkout (live status stream, credit card):');
  final orders = OrderService();
  final sub = orders.statusStream.listen((s) => print('   status -> ${s.label}'));

  PaymentMethod payment = CreditCard('4242'); // abstract type, concrete instance
  try {
    final order = await orders.checkout(cart, payment);
    print('  order #${order.id} complete -> ${order.status.label}\n');
  } on PaymentFailedException catch (e) {
    print('  $e\n');
  }

  // [5] EXCEPTION handling: wallet without enough balance -> payment fails.
  print('[5] Error handling (insufficient wallet balance):');
  final cart2 = Cart()..add(catalog.first, 1);
  try {
    await orders.checkout(cart2, Wallet(1.0));
  } on PaymentFailedException catch (e) {
    print('  handled: $e');
  } finally {
    print('  (finally) stock was released on failure');
  }
  print('  ${catalog.first.name} stock still ${catalog.first.stock}\n');

  // [6] EXCEPTION handling: ordering more than available -> OutOfStock.
  print('[6] Error handling (over-ordering):');
  final cart3 = Cart()..add(catalog.first, 999);
  try {
    await orders.checkout(cart3, CreditCard('0000'));
  } on OutOfStockException catch (e) {
    print('  handled: $e');
  }

  // Cleanup (Flutter: do this in State.dispose()).
  await Future.delayed(const Duration(milliseconds: 10));
  await sub.cancel();
  orders.dispose();
  print('\n=== done ===');
}

// =============================== EXTENSIONS ===================================
extension PriceX on num {
  String get asPrice => '\$${toStringAsFixed(2)}';
}

extension StringX on String {
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

// =============================== FUNCTIONS ====================================
// typedef for a callback type; percentOff returns a CLOSURE capturing `percent`.
typedef DiscountRule = double Function(double subtotal);
DiscountRule percentOff(double percent) =>
    (subtotal) => subtotal * (1 - percent / 100);
// higher-order function: takes a function as an argument.
double applyDiscount(double total, DiscountRule rule) => rule(total);

// ================================ ENUMS =======================================
enum Category {
  electronics('Electronics'),
  books('Books'),
  clothing('Clothing');

  final String label;
  const Category(this.label);
}

enum OrderStatus {
  pending('Pending'),
  processing('Processing'),
  shipped('Shipped'),
  delivered('Delivered'),
  failed('Failed');

  final String label;
  const OrderStatus(this.label);
}

// ============================ INTERFACE / GENERICS ============================
// An implicit interface: anything with an int id. Bounds the generic Repository.
abstract class Identifiable {
  int get id;
}

// GENERIC class bounded by Identifiable, storing items in a Map by id.
class Repository<T extends Identifiable> {
  final Map<int, T> _byId = {}; // encapsulated storage

  void add(T item) => _byId[item.id] = item;
  void addAll(Iterable<T> items) => items.forEach(add);
  T? findById(int id) => _byId[id]; // null-safe lookup
  List<T> get all => _byId.values.toList();
  int get count => _byId.length;
}

// ================================ MIXIN =======================================
mixin Logger {
  void log(String message) => print('  [$runtimeType] $message');
}

// ================================ MODELS ======================================
class Product implements Identifiable {
  @override
  final int id;
  final String name;
  final double price;
  final Category category;
  int _stock; // ENCAPSULATION: private, mutated only through methods

  // Default constructor + initializer list for the private field.
  Product(this.id, this.name, this.price, this.category, int stock)
      : _stock = stock;

  // FACTORY constructor: build from decoded JSON (the Flutter pattern).
  factory Product.fromJson(Map<String, dynamic> json) => Product(
        json['id'] as int,
        json['name'] as String,
        (json['price'] as num).toDouble(),
        Category.values.byName(json['category'] as String),
        json['stock'] as int,
      );

  int get stock => _stock; // getter
  bool get inStock => _stock > 0; // computed getter

  void reduceStock(int qty) {
    if (qty > _stock) {
      throw OutOfStockException(name, requested: qty, available: _stock);
    }
    _stock -= qty;
  }

  void restock(int qty) => _stock += qty;

  @override
  String toString() => '$name (${price.asPrice})';
}

// const constructor + computed getter.
class CartItem {
  final Product product;
  final int quantity;
  const CartItem(this.product, this.quantity);
  double get subtotal => product.price * quantity;
}

class Cart {
  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;

  void add(Product p, int qty) => _items.add(CartItem(p, qty));

  // FUNCTIONAL: fold the items into a running total.
  double get total => _items.fold(0.0, (sum, it) => sum + it.subtotal);
}

class Order implements Identifiable {
  @override
  final int id;
  final Cart cart;
  final DateTime placedAt; // DateTime data type
  OrderStatus status;
  Order(this.id, this.cart, this.placedAt, this.status);
}

// ====================== ABSTRACT CLASS + POLYMORPHISM =========================
// PaymentMethod is the abstraction; callers depend on it, not the concrete type.
abstract class PaymentMethod {
  String get name;
  Future<bool> pay(double amount); // async contract
}

// `extends` an abstract class (inherits the contract; could share code).
class CreditCard extends PaymentMethod {
  final String last4;
  CreditCard(this.last4);
  @override
  String get name => 'Credit Card ****$last4';
  @override
  Future<bool> pay(double amount) async {
    await Future.delayed(const Duration(milliseconds: 60)); // gateway latency
    return true; // pretend the charge always succeeds
  }
}

// `implements` the same abstraction — a different, independent implementation.
class Wallet implements PaymentMethod {
  double _balance;
  Wallet(this._balance);
  @override
  String get name => 'Wallet';
  @override
  Future<bool> pay(double amount) async {
    await Future.delayed(const Duration(milliseconds: 40));
    if (amount > _balance) return false; // insufficient funds
    _balance -= amount;
    return true;
  }
}

// =============================== EXCEPTIONS ===================================
class OutOfStockException implements Exception {
  final String product;
  final int requested;
  final int available;
  OutOfStockException(this.product,
      {required this.requested, required this.available});
  @override
  String toString() =>
      'OutOfStockException: $product (wanted $requested, have $available)';
}

class PaymentFailedException implements Exception {
  final String reason;
  PaymentFailedException(this.reason);
  @override
  String toString() => 'PaymentFailedException: $reason';
}

// ============================== SERVICES (async) =============================
// Fake API: async + Future.delayed + JSON parsing via the factory constructor.
class StoreApi with Logger {
  Future<List<Product>> fetchCatalog() async {
    log('GET /catalog');
    await Future.delayed(const Duration(milliseconds: 100));
    // Simulated JSON payload (List<Map>) like a real HTTP response body.
    const raw = <Map<String, dynamic>>[
      {'id': 1, 'name': 'Laptop', 'price': 1299.0, 'category': 'electronics', 'stock': 5},
      {'id': 2, 'name': 'Headphones', 'price': 199.0, 'category': 'electronics', 'stock': 0},
      {'id': 3, 'name': 'Clean Code', 'price': 39.5, 'category': 'books', 'stock': 12},
      {'id': 4, 'name': 'T-Shirt', 'price': 19.99, 'category': 'clothing', 'stock': 30},
    ];
    return raw.map(Product.fromJson).toList(); // collection map + factory
  }

  Future<String> fetchUserProfile() async {
    log('GET /me');
    await Future.delayed(const Duration(milliseconds: 100));
    return 'aditya';
  }
}

// Order workflow that emits live status through a broadcast StreamController.
class OrderService with Logger {
  final _statusController = StreamController<OrderStatus>.broadcast();
  Stream<OrderStatus> get statusStream => _statusController.stream;
  int _nextId = 100;

  Future<Order> checkout(Cart cart, PaymentMethod payment) async {
    if (cart.isEmpty) throw StateError('cart is empty');
    final order = Order(_nextId++, cart, DateTime.now(), OrderStatus.pending);
    await _emit(OrderStatus.pending);

    // 1) Reserve stock (throws OutOfStockException if not enough).
    for (final item in cart.items) {
      item.product.reduceStock(item.quantity);
    }
    await _emit(OrderStatus.processing);
    await Future.delayed(const Duration(milliseconds: 60));

    // 2) Take payment (polymorphic — any PaymentMethod).
    final paid = await payment.pay(cart.total);
    if (!paid) {
      for (final item in cart.items) {
        item.product.restock(item.quantity); // compensate on failure
      }
      await _emit(OrderStatus.failed);
      throw PaymentFailedException(
          '${payment.name} declined for ${cart.total.asPrice}');
    }

    // 3) Fulfil.
    await _emit(OrderStatus.shipped);
    await Future.delayed(const Duration(milliseconds: 40));
    await _emit(OrderStatus.delivered);
    order.status = OrderStatus.delivered;
    return order;
  }

  // Push a status and yield a turn so listeners print it in order before we
  // continue (keeps the demo output readable; not needed in real apps).
  Future<void> _emit(OrderStatus status) async {
    _statusController.add(status);
    await Future.delayed(Duration.zero);
  }

  void dispose() => _statusController.close();
}
