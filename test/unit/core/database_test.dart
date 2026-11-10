import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/database/schema.dart';

import '../../helpers/test_db.dart';

void main() {
  group('AppDatabase', () {
    test('opens with schema version 1', () async {
      final appDb = await openTestDb();
      final rows = await appDb.db.rawQuery('PRAGMA user_version');
      expect(rows.first.values.first, 1);
      await appDb.close();
    });

    test('creates categories and expenses tables', () async {
      final appDb = await openTestDb();
      final rows = await appDb.db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
      );
      final tables = rows.map((r) => r['name'] as String).toList();
      expect(tables, containsAll([Tables.categories, Tables.expenses]));
      await appDb.close();
    });

    test('inserts and reads a category', () async {
      final appDb = await openTestDb();
      final id = await appDb.db.insert(Tables.categories, {
        CategoryCols.name: 'Food',
        CategoryCols.iconCode: 0xE56C,
        CategoryCols.colorHex: 0xFFFF6B6B,
        CategoryCols.isDefault: 1,
        CategoryCols.createdAt: 0,
      });
      expect(id, greaterThan(0));

      final rows = await appDb.db.query(Tables.categories);
      expect(rows.length, 1);
      expect(rows.first[CategoryCols.name], 'Food');
      expect(rows.first[CategoryCols.isDefault], 1);
      await appDb.close();
    });

    test('rejects duplicate category name', () async {
      final appDb = await openTestDb();
      final row = {
        CategoryCols.name: 'Food',
        CategoryCols.iconCode: 0,
        CategoryCols.colorHex: 0xFF000000,
        CategoryCols.isDefault: 0,
        CategoryCols.createdAt: 0,
      };
      await appDb.db.insert(Tables.categories, row);
      expect(
        () => appDb.db.insert(Tables.categories, row),
        throwsA(isA<Exception>()),
      );
      await appDb.close();
    });

    test('enforces foreign key: expense without category fails', () async {
      final appDb = await openTestDb();
      expect(
        () => appDb.db.insert(Tables.expenses, {
          ExpenseCols.amount: 1000,
          ExpenseCols.categoryId: 999, // nonexistent
          ExpenseCols.occurredAt: 0,
          ExpenseCols.createdAt: 0,
        }),
        throwsA(isA<Exception>()),
      );
      await appDb.close();
    });

    test('inserts a full expense row linked to a category', () async {
      final appDb = await openTestDb();
      final catId = await appDb.db.insert(Tables.categories, {
        CategoryCols.name: 'Food',
        CategoryCols.iconCode: 0,
        CategoryCols.colorHex: 0xFFFF6B6B,
        CategoryCols.isDefault: 0,
        CategoryCols.createdAt: 0,
      });
      final id = await appDb.db.insert(Tables.expenses, {
        ExpenseCols.amount: 2500,
        ExpenseCols.categoryId: catId,
        ExpenseCols.note: 'Lunch',
        ExpenseCols.occurredAt: 1700000000000,
        ExpenseCols.createdAt: 1700000000000,
      });
      expect(id, greaterThan(0));

      final row = (await appDb.db.query(Tables.expenses)).single;
      expect(row[ExpenseCols.amount], 2500);
      expect(row[ExpenseCols.note], 'Lunch');
      expect(row[ExpenseCols.categoryId], catId);
      await appDb.close();
    });
  });
}
