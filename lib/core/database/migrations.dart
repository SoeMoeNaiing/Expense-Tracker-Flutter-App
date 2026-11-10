import 'package:sqflite/sqflite.dart';

import 'schema.dart';

abstract final class Migrations {
  static const int version = 2;

  static Future<void> onCreate(Database db, int _) async {
    await v1(db);
    await v2(db);
  }

  static Future<void> onUpgrade(Database db, int old, int _) async {
    if (old < 2) await v2(db);
    // Future migrations append here: if (old < 3) await v3(db); ...
  }

  /// Initial schema. Public so the migration test can seed a v1 database.
  static Future<void> v1(Database db) async {
    await db.execute('''
      CREATE TABLE ${Tables.categories} (
        ${CategoryCols.id}        INTEGER PRIMARY KEY AUTOINCREMENT,
        ${CategoryCols.name}      TEXT NOT NULL UNIQUE,
        ${CategoryCols.iconCode}  INTEGER NOT NULL,
        ${CategoryCols.colorHex}  INTEGER NOT NULL,
        ${CategoryCols.isDefault} INTEGER NOT NULL DEFAULT 0,
        ${CategoryCols.createdAt} INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE ${Tables.expenses} (
        ${ExpenseCols.id}         INTEGER PRIMARY KEY AUTOINCREMENT,
        ${ExpenseCols.amount}     INTEGER NOT NULL CHECK (${ExpenseCols.amount} >= 0),
        ${ExpenseCols.categoryId} INTEGER NOT NULL,
        ${ExpenseCols.note}       TEXT,
        ${ExpenseCols.occurredAt} INTEGER NOT NULL,
        ${ExpenseCols.createdAt}  INTEGER NOT NULL,
        FOREIGN KEY (${ExpenseCols.categoryId})
          REFERENCES ${Tables.categories} (${CategoryCols.id})
          ON DELETE RESTRICT
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_expenses_occurred ON ${Tables.expenses} (${ExpenseCols.occurredAt})',
    );
    await db.execute(
      'CREATE INDEX idx_expenses_category ON ${Tables.expenses} (${ExpenseCols.categoryId})',
    );
  }

  /// Adds payment_method column with a safe default for existing rows.
  static Future<void> v2(Database db) async {
    await db.execute(
      'ALTER TABLE ${Tables.expenses} '
      "ADD COLUMN ${ExpenseCols.paymentMethod} TEXT NOT NULL DEFAULT 'cash'",
    );
  }
}
