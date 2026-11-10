import 'package:expense_tracker/core/database/schema.dart';
import 'package:expense_tracker/core/database/seed_demo_data.dart';
import 'package:expense_tracker/features/categories/data/seed/seed_categories.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_db.dart';

void main() {
  test('seeds when expenses table is empty', () async {
    final appDb = await openTestDb();
    await seedDefaultCategories(appDb);
    expect((await appDb.db.query(Tables.expenses)).length, 0);

    await seedDemoExpensesIfEmpty(appDb);

    final rows = await appDb.db.query(Tables.expenses);
    expect(rows.length, greaterThan(10));
    // Sanity: at least one row in each payment method.
    final pms = rows.map((r) => r[ExpenseCols.paymentMethod]).toSet();
    expect(pms.contains('cash'), true);
    expect(pms.contains('card'), true);

    await appDb.close();
  });

  test('does not run when any expense exists', () async {
    final appDb = await openTestDb();
    await seedDefaultCategories(appDb);
    final catRow = (await appDb.db.query(Tables.categories, limit: 1)).single;
    await appDb.db.insert(Tables.expenses, {
      ExpenseCols.amount: 100,
      ExpenseCols.categoryId: catRow[CategoryCols.id] as int,
      ExpenseCols.occurredAt: 0,
      ExpenseCols.createdAt: 0,
      ExpenseCols.paymentMethod: 'cash',
    });

    await seedDemoExpensesIfEmpty(appDb);

    expect((await appDb.db.query(Tables.expenses)).length, 1);
    await appDb.close();
  });

  test('resetWithDemoData wipes then re-seeds', () async {
    final appDb = await openTestDb();
    await seedDefaultCategories(appDb);
    final catRow = (await appDb.db.query(Tables.categories, limit: 1)).single;
    await appDb.db.insert(Tables.expenses, {
      ExpenseCols.amount: 999,
      ExpenseCols.categoryId: catRow[CategoryCols.id] as int,
      ExpenseCols.occurredAt: 0,
      ExpenseCols.createdAt: 0,
      ExpenseCols.paymentMethod: 'cash',
    });

    await resetWithDemoData(appDb);

    final rows = await appDb.db.query(Tables.expenses);
    expect(rows.length, greaterThan(10));
    expect(rows.any((r) => r[ExpenseCols.amount] == 999), false);

    await appDb.close();
  });
}
