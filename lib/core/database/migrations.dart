import 'package:sqflite/sqflite.dart';

import 'schema.dart';

abstract final class Migrations {
  static const int version = 3;

  static Future<void> onCreate(Database db, int _) async {
    await v1(db);
    await v2(db);
    await v3(db);
  }

  static Future<void> onUpgrade(Database db, int old, int _) async {
    if (old < 2) await v2(db);
    if (old < 3) await v3(db);
  }

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

  static Future<void> v2(Database db) async {
    await db.execute(
      'ALTER TABLE ${Tables.expenses} '
      "ADD COLUMN ${ExpenseCols.paymentMethod} TEXT NOT NULL DEFAULT 'cash'",
    );
  }

  static Future<void> v3(Database db) async {
    await db.execute('''
      CREATE TABLE ${Tables.budgets} (
        ${BudgetCols.id}         INTEGER PRIMARY KEY AUTOINCREMENT,
        ${BudgetCols.categoryId} INTEGER,
        ${BudgetCols.amount}     INTEGER NOT NULL CHECK (${BudgetCols.amount} > 0),
        ${BudgetCols.createdAt}  INTEGER NOT NULL,
        FOREIGN KEY (${BudgetCols.categoryId})
          REFERENCES ${Tables.categories} (${CategoryCols.id})
          ON DELETE CASCADE
      )
    ''');
    // One budget per category, plus one overall (NULL category) — the
    // COALESCE expression maps NULL to 0 for uniqueness enforcement.
    await db.execute(
      'CREATE UNIQUE INDEX uq_budgets_all ON ${Tables.budgets} '
      '(COALESCE(${BudgetCols.categoryId}, 0))',
    );
  }
}
