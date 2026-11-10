import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/schema.dart';
import '../models/budget_model.dart';

class BudgetLocalDataSource {
  final AppDatabase _appDb;
  const BudgetLocalDataSource(this._appDb);

  Database get _db => _appDb.db;

  Future<List<BudgetModel>> getAll() async {
    final rows = await _db.query(Tables.budgets);
    return rows.map(BudgetModel.fromMap).toList();
  }

  Future<BudgetModel?> findFor(int? categoryId) async {
    final rows = await _db.query(
      Tables.budgets,
      where: categoryId == null
          ? '${BudgetCols.categoryId} IS NULL'
          : '${BudgetCols.categoryId} = ?',
      whereArgs: categoryId == null ? null : [categoryId],
      limit: 1,
    );
    return rows.isEmpty ? null : BudgetModel.fromMap(rows.first);
  }

  Future<int> insert(BudgetModel m) => _db.insert(Tables.budgets, m.toMap());

  Future<int> update(BudgetModel m) => _db.update(
    Tables.budgets,
    m.toMap(),
    where: '${BudgetCols.id} = ?',
    whereArgs: [m.id],
  );

  Future<int> delete(int id) => _db.delete(
    Tables.budgets,
    where: '${BudgetCols.id} = ?',
    whereArgs: [id],
  );
}
