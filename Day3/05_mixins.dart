// =============================================================================
// Day 3 · Part 5 — Mixins
// Run: dart run Day3/05_mixins.dart
// =============================================================================
//
// A MIXIN bundles methods/fields to REUSE across unrelated classes WITHOUT
// inheritance. Declared with `mixin`, applied with `with`.
//   - Use `with` (not `extends`): flying/logging is a CAPABILITY to share, not
//     an identity, and you can mix in MANY but extend only ONE class.
//   - `on Type` restricts a mixin to certain hosts and unlocks their members.
// =============================================================================

void main() {
  final user = User('Aditya');
  user.log('User created: ${user.name}'); // log() comes from the Logger mixin

  // The SAME mixin reused by a totally unrelated class — that's the point.
  final order = Order(42);
  order.log('Order #${order.id} placed');

  // Multiple mixins at once. Both capabilities composed in.
  final service = ApiService();
  service.log('fetching...');
  service.cache('GET /posts', '[...]');
  print('cached: ${service.read('GET /posts')}');
}

// A reusable logging capability.
mixin Logger {
  void log(String message) => print('[${DateTime.now().toIso8601String()}] $message');
}

// A reusable in-memory cache capability.
mixin CacheMixin {
  final Map<String, String> _store = {};
  void cache(String key, String value) => _store[key] = value;
  String? read(String key) => _store[key];
}

// Unrelated classes, each mixing in shared behavior with `with`.
class User with Logger {
  final String name;
  User(this.name);
}

class Order with Logger {
  final int id;
  Order(this.id);
}

// Compose MULTIPLE mixins: ApiService gains both logging and caching.
class ApiService with Logger, CacheMixin {}
