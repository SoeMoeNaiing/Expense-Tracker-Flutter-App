import 'package:sqflite/sqflite.dart';

import 'schema.dart';

abstract final class Migrations {
  static const int version = 1;

  static Future<void> onCreate(Database db, int version) async {
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

  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // v1 is the initial schema — no upgrades yet.
    // Future migrations append `if (oldVersion < N) { ... }` blocks here.
  }
}
