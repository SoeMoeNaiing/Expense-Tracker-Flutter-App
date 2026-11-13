import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';

import 'transaction.dart';

class DatabaseService {
  DatabaseService._init();
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'money_management.db');
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            type TEXT NOT NULL,
            category TEXT NOT NULL,
            date TEXT NOT NULL
          )
        ''');
      },
    );
    return _database!;
  }

  Future<int> insertTransaction(Transaction t) async {
    final db = await database;
    return db.insert('transactions', t.toMap());
  }

  Future<List<Transaction>> getTransactions() async {
    final db = await database;
    final rows = await db.query('transactions', orderBy: 'date DESC, id DESC');
    return rows.map(Transaction.fromMap).toList();
  }

  Future<double> getTotalIncome() async {
    final db = await database;
    final r = await db.rawQuery(
      "SELECT SUM(amount) AS total FROM transactions WHERE type = 'Income'",
    );
    return (r.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTotalExpense() async {
    final db = await database;
    final r = await db.rawQuery(
      "SELECT SUM(amount) AS total FROM transactions WHERE type = 'Expense'",
    );
    return (r.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTotalBalance() async =>
      (await getTotalIncome()) - (await getTotalExpense());

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}
