import 'package:sqflite/sqflite.dart';

import 'app_database.dart';
import 'schema.dart';

/// Seeds 17 demo expenses across the current and previous month.
/// Only runs when the expenses table is empty. Safe to call on every
/// app start — a no-op once you have any real expense.
Future<void> seedDemoExpensesIfEmpty(AppDatabase appDb) async {
  final existing = await appDb.db.query(Tables.expenses, limit: 1);
  if (existing.isNotEmpty) return;
  await _seed(appDb);
}

/// Wipes existing expenses and re-seeds. Use this to reset the demo.
Future<void> resetWithDemoData(AppDatabase appDb) async {
  await appDb.db.delete(Tables.expenses);
  await _seed(appDb);
}

Future<void> _seed(AppDatabase appDb) async {
  final cats = await appDb.db.query(Tables.categories);
  final byName = <String, int>{
    for (final row in cats)
      row[CategoryCols.name] as String: row[CategoryCols.id] as int,
  };
  int catId(String name) => byName[name] ?? byName['Other']!;

  final now = DateTime.now();
  final rows = <Map<String, Object?>>[];

  void add({
    required int amount,
    required String category,
    required DateTime occurredAt,
    required String paymentMethod,
    String? note,
  }) {
    rows.add({
      ExpenseCols.amount: amount,
      ExpenseCols.categoryId: catId(category),
      ExpenseCols.note: note,
      ExpenseCols.occurredAt: occurredAt.millisecondsSinceEpoch,
      ExpenseCols.createdAt: now.millisecondsSinceEpoch,
      ExpenseCols.paymentMethod: paymentMethod,
    });
  }

  // Today — 2
  add(
    amount: 3500,
    category: 'Food',
    occurredAt: now,
    paymentMethod: 'cash',
    note: 'Shan noodles',
  );
  add(
    amount: 1500,
    category: 'Transport',
    occurredAt: now.subtract(const Duration(hours: 3)),
    paymentMethod: 'cash',
    note: 'Grab to office',
  );

  // Yesterday — 2
  add(
    amount: 12000,
    category: 'Food',
    occurredAt: now.subtract(const Duration(days: 1, hours: 4)),
    paymentMethod: 'card',
    note: 'Dinner with family',
  );
  add(
    amount: 8000,
    category: 'Shopping',
    occurredAt: now.subtract(const Duration(days: 1, hours: 8)),
    paymentMethod: 'card',
    note: 'T-shirt',
  );

  // This week — 3
  add(
    amount: 45000,
    category: 'Bills',
    occurredAt: now.subtract(const Duration(days: 3)),
    paymentMethod: 'bank',
    note: 'Internet',
  );
  add(
    amount: 2500,
    category: 'Food',
    occurredAt: now.subtract(const Duration(days: 4)),
    paymentMethod: 'cash',
    note: 'Coffee',
  );
  add(
    amount: 20000,
    category: 'Entertainment',
    occurredAt: now.subtract(const Duration(days: 5)),
    paymentMethod: 'card',
    note: 'Cinema',
  );

  // Earlier this month — 5
  add(
    amount: 25000,
    category: 'Health',
    occurredAt: now.subtract(const Duration(days: 8)),
    paymentMethod: 'cash',
    note: 'Pharmacy',
  );
  add(
    amount: 6000,
    category: 'Transport',
    occurredAt: now.subtract(const Duration(days: 10)),
    paymentMethod: 'cash',
    note: 'Fuel',
  );
  add(
    amount: 95000,
    category: 'Shopping',
    occurredAt: now.subtract(const Duration(days: 12)),
    paymentMethod: 'card',
    note: 'Shoes',
  );
  add(
    amount: 18000,
    category: 'Food',
    occurredAt: now.subtract(const Duration(days: 14)),
    paymentMethod: 'cash',
    note: 'Groceries',
  );
  add(
    amount: 30000,
    category: 'Bills',
    occurredAt: now.subtract(const Duration(days: 16)),
    paymentMethod: 'bank',
    note: 'Phone bill',
  );

  // Last month — 5 (so year/trend charts have two months)
  final lm = DateTime(now.year, now.month - 1);
  add(
    amount: 250000,
    category: 'Bills',
    occurredAt: DateTime(lm.year, lm.month, 1, 10),
    paymentMethod: 'bank',
    note: 'Rent',
  );
  add(
    amount: 52000,
    category: 'Food',
    occurredAt: DateTime(lm.year, lm.month, 8, 12),
    paymentMethod: 'card',
    note: 'Groceries',
  );
  add(
    amount: 18000,
    category: 'Transport',
    occurredAt: DateTime(lm.year, lm.month, 15, 9),
    paymentMethod: 'cash',
    note: 'Fuel',
  );
  add(
    amount: 35000,
    category: 'Entertainment',
    occurredAt: DateTime(lm.year, lm.month, 20, 19),
    paymentMethod: 'card',
    note: 'Concert',
  );
  add(
    amount: 22000,
    category: 'Health',
    occurredAt: DateTime(lm.year, lm.month, 25, 15),
    paymentMethod: 'cash',
    note: 'Clinic visit',
  );

  await appDb.db.transaction((txn) async {
    for (final row in rows) {
      await txn.insert(Tables.expenses, row);
    }
  });
}
