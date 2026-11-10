import 'dart:io';

import 'package:expense_tracker/core/database/migrations.dart';
import 'package:expense_tracker/core/database/schema.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('v1 -> v2 adds payment_method with default cash', () async {
    final tmp = await Directory.systemTemp.createTemp('ledger_mig');
    final path = p.join(tmp.path, 'mig.db');
    try {
      // Seed a v1 database with one category + one expense (no PM column).
      final v1 = await openDatabase(
        path,
        version: 1,
        onCreate: (db, _) => Migrations.v1(db),
      );
      final catId = await v1.insert(Tables.categories, {
        CategoryCols.name: 'Food',
        CategoryCols.iconCode: 0,
        CategoryCols.colorHex: 0xFFFF6B6B,
        CategoryCols.isDefault: 1,
        CategoryCols.createdAt: 0,
      });
      await v1.insert(Tables.expenses, {
        ExpenseCols.amount: 2500,
        ExpenseCols.categoryId: catId,
        ExpenseCols.note: 'Lunch',
        ExpenseCols.occurredAt: 1000,
        ExpenseCols.createdAt: 1000,
      });
      await v1.close();

      // Reopen at v2 — triggers onUpgrade.
      final v2 = await openDatabase(
        path,
        version: 2,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onUpgrade: Migrations.onUpgrade,
      );
      final rows = await v2.query(Tables.expenses);
      expect(rows.length, 1);
      expect(rows.first[ExpenseCols.paymentMethod], 'cash');
      expect(await v2.getVersion(), 2);
      await v2.close();
    } finally {
      await tmp.delete(recursive: true);
    }
  });

  test('v2 -> v3 adds budgets table, keeps existing rows', () async {
    final tmp = await Directory.systemTemp.createTemp('ledger_mig23');
    final path = p.join(tmp.path, 'mig.db');
    try {
      // Simulate a v2 database.
      final v2 = await openDatabase(
        path,
        version: 2,
        onCreate: (db, _) async {
          await Migrations.v1(db);
          await Migrations.v2(db);
        },
      );
      final catId = await v2.insert(Tables.categories, {
        CategoryCols.name: 'Food',
        CategoryCols.iconCode: 0,
        CategoryCols.colorHex: 0xFFFF6B6B,
        CategoryCols.isDefault: 1,
        CategoryCols.createdAt: 0,
      });
      await v2.insert(Tables.expenses, {
        ExpenseCols.amount: 2500,
        ExpenseCols.categoryId: catId,
        ExpenseCols.note: 'Lunch',
        ExpenseCols.occurredAt: 1000,
        ExpenseCols.createdAt: 1000,
        ExpenseCols.paymentMethod: 'cash',
      });
      await v2.close();

      // Reopen at v3.
      final v3 = await openDatabase(
        path,
        version: 3,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onUpgrade: Migrations.onUpgrade,
      );
      final tables = await v3.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='budgets'",
      );
      expect(tables.length, 1);

      final expenses = await v3.query(Tables.expenses);
      expect(expenses.length, 1);
      expect(expenses.first[ExpenseCols.paymentMethod], 'cash');

      expect(await v3.getVersion(), 3);
      await v3.close();
    } finally {
      await tmp.delete(recursive: true);
    }
  });
}
