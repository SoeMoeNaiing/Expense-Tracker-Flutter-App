import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/schema.dart';
import '../models/expense_model.dart';

class ExpenseLocalDataSource {
  final AppDatabase _appDb;
  const ExpenseLocalDataSource(this._appDb);

  Database get _db => _appDb.db;

  Future<int> insert(ExpenseModel m) => _db.insert(Tables.expenses, m.toMap());

  Future<List<ExpenseModel>> getAll() async {
    final rows = await _db.query(
      Tables.expenses,
      orderBy: '${ExpenseCols.occurredAt} DESC',
    );
    return rows.map(ExpenseModel.fromMap).toList();
  }

  Future<List<ExpenseModel>> getBetween(int startMs, int endMs) async {
    final rows = await _db.query(
      Tables.expenses,
      where: '${ExpenseCols.occurredAt} >= ? AND ${ExpenseCols.occurredAt} < ?',
      whereArgs: [startMs, endMs],
      orderBy: '${ExpenseCols.occurredAt} DESC',
    );
    return rows.map(ExpenseModel.fromMap).toList();
  }

  Future<int> update(ExpenseModel m) {
    assert(m.id != null, 'update requires a model with an id');
    return _db.update(
      Tables.expenses,
      m.toMap(),
      where: '${ExpenseCols.id} = ?',
      whereArgs: [m.id],
    );
  }

  Future<int> delete(int id) => _db.delete(
    Tables.expenses,
    where: '${ExpenseCols.id} = ?',
    whereArgs: [id],
  );

  /// Inserts all models atomically. Either all succeed or none do.
  Future<List<int>> insertMany(List<ExpenseModel> models) async {
    return await _db.transaction((txn) async {
      final ids = <int>[];
      for (final m in models) {
        ids.add(await txn.insert(Tables.expenses, m.toMap()));
      }
      return ids;
    });
  }
}
