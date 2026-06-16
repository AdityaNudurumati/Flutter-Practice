// =============================================================================
// Day 3 · Part 10 — PRACTICE PROJECT: Student Management System
// Run: dart run Day3/10_student_management.dart
// =============================================================================
//
// Revises almost everything from Day 3 in one program:
//   - CLASS        : Student (immutable model)
//   - ENUM         : Grade (enhanced enum derived from marks)
//   - GENERICS     : Repository<T> reused as the base for StudentManager
//   - LIST + MAP   : storage + group-by-grade results
//   - FUNCTIONS    : add / remove / search / topper / average / groupByGrade
//   - ENCAPSULATION: private list behind a clean public API
//   - EXCEPTIONS   : meaningful errors for not-found / empty cases
// =============================================================================

void main() {
  final manager = StudentManager();

  // Add students
  manager.add(Student(1, 'Aditya', 92));
  manager.add(Student(2, 'Riya', 78));
  manager.add(Student(3, 'Sam', 55));
  manager.add(Student(4, 'Neha', 38));
  manager.add(Student(5, 'Karan', 88));
  print('Total students: ${manager.count}\n');

  // Search
  print('Search id=3: ${manager.search(3)}');
  print('Search id=99: ${manager.search(99)}\n'); // null — not found

  // Topper & average
  print('Topper: ${manager.topper()}');
  print('Average marks: ${manager.averageMarks().toStringAsFixed(2)}\n');

  // Group by grade (Map<Grade, List<Student>>)
  print('Grouped by grade:');
  manager.groupByGrade().forEach((grade, students) {
    final names = students.map((s) => s.name).join(', ');
    print('  ${grade.label} (${grade.range}): $names');
  });

  // Remove
  manager.remove(4);
  print('\nAfter removing id=4 -> ${manager.count} students');

  // Exception handling on empty / not-found
  try {
    StudentManager().topper(); // empty -> throws
  } on StateError catch (e) {
    print('Edge case: ${e.message}');
  }
}

// ---- ENUM (enhanced): grade buckets derived from marks --------------------
enum Grade {
  a('A', '90-100'),
  b('B', '75-89'),
  c('C', '60-74'),
  d('D', '40-59'),
  f('F', '0-39');

  final String label;
  final String range;
  const Grade(this.label, this.range);

  // Map a numeric mark to a Grade.
  static Grade fromMarks(double marks) {
    if (marks >= 90) return Grade.a;
    if (marks >= 75) return Grade.b;
    if (marks >= 60) return Grade.c;
    if (marks >= 40) return Grade.d;
    return Grade.f;
  }
}

// ---- CLASS (model): immutable Student -------------------------------------
class Student {
  final int id;
  final String name;
  final double marks;
  const Student(this.id, this.name, this.marks);

  Grade get grade => Grade.fromMarks(marks);

  @override
  String toString() => 'Student($id, $name, $marks, ${grade.label})';
}

// ---- GENERICS: a reusable in-memory repository ----------------------------
// Encapsulates a private List<T> behind a small typed API. StudentManager
// reuses this for free — the same base could store Orders, Products, etc.
class Repository<T> {
  final List<T> _items = []; // ENCAPSULATION: private storage

  void add(T item) => _items.add(item);
  List<T> get all => List.unmodifiable(_items);
  int get count => _items.length;
  bool get isEmpty => _items.isEmpty;

  void removeWhere(bool Function(T) test) => _items.removeWhere(test);
}

// ---- StudentManager: domain logic on top of the generic Repository --------
class StudentManager extends Repository<Student> {
  // FUNCTION: search by id — returns null if not found (safe, no throw).
  Student? search(int id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }

  void remove(int id) => removeWhere((s) => s.id == id);

  // FUNCTION: highest scorer. Throws on empty (an exceptional, not-null case).
  Student topper() {
    if (isEmpty) throw StateError('no students to rank');
    return all.reduce((best, s) => s.marks > best.marks ? s : best);
  }

  // FUNCTION: average marks via fold.
  double averageMarks() {
    if (isEmpty) return 0;
    final total = all.fold<double>(0, (sum, s) => sum + s.marks);
    return total / count;
  }

  // FUNCTION + MAP: group students by their grade bucket.
  Map<Grade, List<Student>> groupByGrade() {
    final map = <Grade, List<Student>>{};
    for (final s in all) {
      map.putIfAbsent(s.grade, () => []).add(s);
    }
    return map;
  }
}
