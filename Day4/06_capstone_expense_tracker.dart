// =============================================================================
// Day 4 · Part 6 — CAPSTONE 2: Personal Expense Tracker (console app)
// Run (scripted demo):  dart run Day4/06_capstone_expense_tracker.dart
// Run (interactive menu): dart run Day4/06_capstone_expense_tracker.dart -i
// =============================================================================
//
// A console expense manager that exercises almost every Day 1–4 concept.
//
// Menu: 1 Add · 2 View · 3 Delete · 4 Search · 5 Total · 6 Category-wise
//       7 Monthly · 8 Exit
//
// Concept -> where it shows up:
//   variables / data types / null safety -> everywhere; Expense? + ?. + ??
//   functions / arrow / optional+named params / typedef -> service + ExpenseFilter
//   List / Map / Set -> storage, reports, distinct categories
//   where / map / fold / any / every / firstWhere / sort -> reports & search
//   classes / constructors / named ctor / factory ctor -> Expense (+ .today/.fromMap)
//   encapsulation / getters / setters -> ExpenseService._storage, monthlyBudget
//   inheritance / abstract / interface / mixin -> Entity, ExpenseRepository, LoggerMixin
//   generics -> Storage<T>, firstOrNullWhere<T>
//   enums -> ExpenseCategory (enhanced)
//   extensions -> double.toCurrency()
//   exception handling -> ExpenseNotFoundException, try/catch
//   async / Future -> every repository call awaits simulated I/O
// =============================================================================

import 'dart:async';
import 'dart:io';

Future<void> main(List<String> args) async {
  final app = ExpenseApp();
  if (args.contains('-i') || args.contains('--interactive')) {
    await app.runInteractive(); // real stdin menu
  } else {
    await app.runDemo(); // scripted walkthrough of all 8 actions
  }
}

// ================================ ENUM ========================================
enum ExpenseCategory {
  food,
  travel,
  shopping,
  bills,
  entertainment;

  // enhanced enum: a computed label and a safe parser (used by fromMap / input).
  String get label => '${name[0].toUpperCase()}${name.substring(1)}';
  static ExpenseCategory parse(String s) => values.byName(s.trim().toLowerCase());
}

// ===================== INHERITANCE: abstract base + subclass ==================
// Abstract base every stored thing shares (an id + a human description).
abstract class Entity {
  final int id;
  const Entity(this.id);
  String describe();
}

// ============================== MODEL =========================================
class Expense extends Entity {
  final String title;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;

  // Default constructor: required NAMED params; passes id up to Entity via super.
  Expense({
    required int id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  }) : super(id);

  // NAMED (redirecting) constructor: dated today.
  Expense.today({
    required int id,
    required String title,
    required double amount,
    required ExpenseCategory category,
  }) : this(
          id: id,
          title: title,
          amount: amount,
          category: category,
          date: DateTime.now(),
        );

  // FACTORY constructor: build from a Map (decoded JSON / DB row).
  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
        id: map['id'] as int,
        title: map['title'] as String,
        amount: (map['amount'] as num).toDouble(),
        category: map['category'] is ExpenseCategory
            ? map['category'] as ExpenseCategory
            : ExpenseCategory.parse(map['category'] as String),
        date: map['date'] is DateTime
            ? map['date'] as DateTime
            : DateTime.parse(map['date'] as String),
      );

  // Computed getters (encapsulated derived state).
  String get monthKey =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';
  bool get isLarge => amount > 10000;

  @override
  String describe() =>
      '#$id  $title — ${amount.toCurrency()}  [${category.label}]  ${monthKey}';
}

// Subclass demonstrating inheritance + super + override (polymorphism).
class RecurringExpense extends Expense {
  final String frequency;
  RecurringExpense({
    required super.id,
    required super.title,
    required super.amount,
    required super.category,
    required super.date,
    this.frequency = 'monthly',
  });

  @override
  String describe() => '${super.describe()}  (recurs $frequency)';
}

// ============================== INTERFACE =====================================
// An abstract class used as an INTERFACE (implemented, not extended).
abstract class ExpenseRepository {
  Future<void> addExpense(Expense expense);
  Future<List<Expense>> getExpenses();
  Future<void> deleteExpense(int id);
}

// ================================ MIXIN =======================================
mixin LoggerMixin {
  void log(String message) => print('LOG : $message');
}

// =============================== GENERICS =====================================
class Storage<T> {
  final List<T> _items = []; // encapsulated
  void add(T item) => _items.add(item);
  List<T> getAll() => List.unmodifiable(_items);
  void removeWhere(bool Function(T) test) => _items.removeWhere(test);
  int get length => _items.length;
}

// Generic helper function — null-safe "find first matching, else null".
T? firstOrNullWhere<T>(List<T> items, bool Function(T) test) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return null;
}

// =============================== TYPEDEF ======================================
typedef ExpenseFilter = bool Function(Expense expense);

// ============================= EXTENSION ======================================
extension CurrencyExtension on double {
  String toCurrency() => '₹${toStringAsFixed(2)}'; // ₹ rupee symbol
}

// =============================== EXCEPTION ====================================
class ExpenseNotFoundException implements Exception {
  final int id;
  ExpenseNotFoundException(this.id);
  @override
  String toString() => 'ExpenseNotFoundException: no expense with id $id';
}

// ====================== SERVICE: mixin + implements interface =================
class ExpenseService with LoggerMixin implements ExpenseRepository {
  final Storage<Expense> _storage = Storage<Expense>(); // GENERICS + encapsulation
  double _monthlyBudget = 0;

  // GETTER + SETTER with validation (encapsulation).
  double get monthlyBudget => _monthlyBudget;
  set monthlyBudget(double value) {
    if (value < 0) throw ArgumentError('budget cannot be negative');
    _monthlyBudget = value;
  }

  @override
  Future<void> addExpense(Expense expense) async {
    await Future.delayed(const Duration(milliseconds: 20)); // simulate I/O
    _storage.add(expense);
    log('Expense Added: ${expense.title}');
  }

  @override
  Future<List<Expense>> getExpenses() async {
    await Future.delayed(const Duration(milliseconds: 10));
    return _storage.getAll();
  }

  @override
  Future<void> deleteExpense(int id) async {
    final before = _storage.length;
    _storage.removeWhere((e) => e.id == id);
    if (_storage.length == before) throw ExpenseNotFoundException(id);
    log('Expense Deleted: #$id');
  }

  // SEARCH using a typedef filter + where().
  Future<List<Expense>> search(ExpenseFilter filter) async {
    final all = await getExpenses();
    return all.where(filter).toList();
  }

  // TOTAL via fold().
  Future<double> totalSpending() async {
    final all = await getExpenses();
    return all.fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  // CATEGORY-WISE via fold() into a Map.
  Future<Map<ExpenseCategory, double>> categoryWise() async {
    final all = await getExpenses();
    return all.fold<Map<ExpenseCategory, double>>({}, (map, e) {
      map.update(e.category, (v) => v + e.amount, ifAbsent: () => e.amount);
      return map;
    });
  }

  // MONTHLY via fold() into a Map keyed by YYYY-MM.
  Future<Map<String, double>> monthlySpending() async {
    final all = await getExpenses();
    return all.fold<Map<String, double>>({}, (map, e) {
      map.update(e.monthKey, (v) => v + e.amount, ifAbsent: () => e.amount);
      return map;
    });
  }

  // TOP category via reduce() over map entries.
  Future<MapEntry<ExpenseCategory, double>?> topCategory() async {
    final cat = await categoryWise();
    if (cat.isEmpty) return null;
    return cat.entries.reduce((a, b) => a.value >= b.value ? a : b);
  }
}

// ================================ APP =========================================
class ExpenseApp {
  final ExpenseService _service = ExpenseService();
  int _seq = 0;
  int get _nextId => ++_seq;

  // ---- shared feature methods (used by BOTH demo and interactive menu) ----
  Future<void> viewExpenses() async {
    final all = await _service.getExpenses();
    if (all.isEmpty) {
      print('  (no expenses)');
      return;
    }
    for (final e in all) {
      print('  ${e.describe()}');
    }
    // map(): titles only
    print('  titles: ${all.map((e) => e.title).join(', ')}');
    // Set: distinct categories used
    print('  categories used: '
        '${all.map((e) => e.category.label).toSet().join(', ')}');
  }

  Future<void> showTotal() async {
    final total = await _service.totalSpending();
    print('  Total spending: ${total.toCurrency()}');
    print('  Budget: ${_service.monthlyBudget.toCurrency()} -> '
        '${total > _service.monthlyBudget ? 'OVER budget' : 'within budget'}');
  }

  Future<void> showCategoryWise() async {
    final report = await _service.categoryWise();
    // sort entries by amount descending for a clean report.
    final entries = report.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final e in entries) {
      print('  ${e.key.label.padRight(14)} -> ${e.value.toCurrency()}');
    }
    final top = await _service.topCategory();
    if (top != null) {
      print('  Top category: ${top.key.label} (${top.value.toCurrency()})');
    }
  }

  Future<void> showMonthly() async {
    final report = await _service.monthlySpending();
    final keys = report.keys.toList()..sort();
    for (final k in keys) {
      print('  $k -> ${report[k]!.toCurrency()}');
    }
  }

  Future<void> searchByTitle(String query) async {
    final results =
        await _service.search((e) => e.title.toLowerCase().contains(query.toLowerCase()));
    if (results.isEmpty) {
      print('  no matches for "$query"');
    } else {
      for (final e in results) {
        print('  ${e.describe()}');
      }
    }
  }

  Future<void> _seed() async {
    final rows = <Map<String, dynamic>>[
      {'id': _nextId, 'title': 'Lunch', 'amount': 350.0, 'category': 'food', 'date': '2026-06-01'},
      {'id': _nextId, 'title': 'Cab', 'amount': 220.0, 'category': 'travel', 'date': '2026-06-03'},
      {'id': _nextId, 'title': 'Shoes', 'amount': 7000.0, 'category': 'shopping', 'date': '2026-06-10'},
      {'id': _nextId, 'title': 'Electricity', 'amount': 1500.0, 'category': 'bills', 'date': '2026-05-15'},
      {'id': _nextId, 'title': 'Movie', 'amount': 600.0, 'category': 'entertainment', 'date': '2026-05-20'},
      {'id': _nextId, 'title': 'Groceries', 'amount': 1200.0, 'category': 'food', 'date': '2026-06-12'},
    ];
    for (final row in rows) {
      await _service.addExpense(Expense.fromMap(row)); // factory + async
    }
  }

  // -------------------------- scripted demo --------------------------------
  Future<void> runDemo() async {
    print('=== PERSONAL EXPENSE TRACKER (scripted demo) ===');
    print('(run with `-i` for the interactive menu)\n');

    _service.monthlyBudget = 8000; // setter

    print('[1] Add expenses (async + factory):');
    await _seed();
    // also add a recurring expense to show inheritance + polymorphism
    await _service.addExpense(RecurringExpense(
      id: _nextId,
      title: 'Netflix',
      amount: 499.0,
      category: ExpenseCategory.entertainment,
      date: DateTime.parse('2026-06-05'),
    ));

    print('\n[2] View expenses:');
    await viewExpenses();

    print('\n[5] Total spending (fold):');
    await showTotal();

    print('\n[6] Category-wise (fold -> Map, reduce -> top):');
    await showCategoryWise();

    print('\n[7] Monthly spending (group by month):');
    await showMonthly();

    print('\n[4] Search ("gro"):');
    await searchByTitle('gro');

    final all = await _service.getExpenses();
    print('\nCollection insights:');
    print('  any expense > 10000? ${all.any((e) => e.amount > 10000)}');
    print('  every amount > 0?    ${all.every((e) => e.amount > 0)}');
    final sorted = [...all]..sort((a, b) => b.amount.compareTo(a.amount));
    print('  most expensive: ${sorted.first.title} (${sorted.first.amount.toCurrency()})');
    final byId = all.firstWhere((e) => e.id == 1);
    print('  firstWhere id==1: ${byId.title}');

    print('\nNull safety (generic firstOrNullWhere):');
    final Expense? found = firstOrNullWhere(all, (e) => e.id == 2);
    final Expense? missing = firstOrNullWhere(all, (e) => e.id == 999);
    print('  id 2  -> ${found?.title ?? 'No Expense'}');
    print('  id 999 -> ${missing?.title ?? 'No Expense'}');

    print('\n[3] Delete + exception handling:');
    await _service.deleteExpense(1); // ok
    try {
      await _service.deleteExpense(100); // not found -> throws
    } catch (e) {
      print('  caught: $e');
    }
    print('  remaining: ${(await _service.getExpenses()).length} expenses');

    print('\n[8] Exit. (Setter validation demo:)');
    try {
      _service.monthlyBudget = -5;
    } on ArgumentError catch (e) {
      print('  rejected bad budget: ${e.message}');
    }
    print('\n=== done ===');
  }

  // ------------------------- interactive menu ------------------------------
  Future<void> runInteractive() async {
    await _seed();
    while (true) {
      _printMenu();
      stdout.write('Choose (1-8): ');
      final choice = stdin.readLineSync()?.trim();
      print('');
      switch (choice) {
        case '1':
          await _promptAdd();
        case '2':
          await viewExpenses();
        case '3':
          await _promptDelete();
        case '4':
          stdout.write('Search title: ');
          await searchByTitle(stdin.readLineSync() ?? '');
        case '5':
          await showTotal();
        case '6':
          await showCategoryWise();
        case '7':
          await showMonthly();
        case '8':
          print('Goodbye!');
          return;
        default:
          print('Invalid choice, try again.');
      }
      print('');
    }
  }

  void _printMenu() {
    print('----------------------------------------');
    print(' 1) Add   2) View   3) Delete   4) Search');
    print(' 5) Total 6) Category 7) Monthly 8) Exit');
    print('----------------------------------------');
  }

  Future<void> _promptAdd() async {
    stdout.write('Title: ');
    final title = stdin.readLineSync() ?? '';
    stdout.write('Amount: ');
    final amountStr = stdin.readLineSync() ?? '';
    stdout.write('Category (${ExpenseCategory.values.map((c) => c.name).join('/')}): ');
    final catStr = stdin.readLineSync() ?? '';
    try {
      final expense = Expense.today(
        id: _nextId,
        title: title,
        amount: double.parse(amountStr),
        category: ExpenseCategory.parse(catStr),
      );
      await _service.addExpense(expense);
      print('Added: ${expense.describe()}');
    } catch (e) {
      print('Could not add expense: $e');
    }
  }

  Future<void> _promptDelete() async {
    stdout.write('Delete id: ');
    final idStr = stdin.readLineSync() ?? '';
    try {
      await _service.deleteExpense(int.parse(idStr));
      print('Deleted.');
    } catch (e) {
      print('Could not delete: $e');
    }
  }
}
