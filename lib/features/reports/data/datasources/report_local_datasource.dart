import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/schema.dart';

/// Raw aggregate rows returned by this data source. The repository
/// converts them into domain entities.
class CategoryAggregateRow {
  final int categoryId;
  final int amount;
  final int count;
  const CategoryAggregateRow({
    required this.categoryId,
    required this.amount,
    required this.count,
  });
}

class ExpenseRowLite {
  final int occurredAtMs;
  final int amount;
  const ExpenseRowLite({required this.occurredAtMs, required this.amount});
}

class ReportLocalDataSource {
  final AppDatabase _appDb;
  const ReportLocalDataSource(this._appDb);

  Database get _db => _appDb.db;

  Future<({int total, int count})> totalForRange(int fromMs, int toMs) async {
    final rows = await _db.rawQuery(
      '''
      SELECT COALESCE(SUM(${ExpenseCols.amount}), 0) AS s,
             COUNT(*) AS c
      FROM ${Tables.expenses}
      WHERE ${ExpenseCols.occurredAt} >= ? AND ${ExpenseCols.occurredAt} < ?
      ''',
      [fromMs, toMs],
    );
    final row = rows.first;
    return (total: (row['s'] as num).toInt(), count: (row['c'] as num).toInt());
  }

  Future<List<CategoryAggregateRow>> categoryBreakdown(
    int fromMs,
    int toMs,
  ) async {
    final rows = await _db.rawQuery(
      '''
      SELECT ${ExpenseCols.categoryId} AS cid,
             SUM(${ExpenseCols.amount}) AS s,
             COUNT(*) AS c
      FROM ${Tables.expenses}
      WHERE ${ExpenseCols.occurredAt} >= ? AND ${ExpenseCols.occurredAt} < ?
      GROUP BY ${ExpenseCols.categoryId}
      ORDER BY s DESC
      ''',
      [fromMs, toMs],
    );
    return rows
        .map(
          (r) => CategoryAggregateRow(
            categoryId: (r['cid'] as num).toInt(),
            amount: (r['s'] as num).toInt(),
            count: (r['c'] as num).toInt(),
          ),
        )
        .toList();
  }

  Future<List<ExpenseRowLite>> detailRowsForRange(int fromMs, int toMs) async {
    final rows = await _db.rawQuery(
      '''
      SELECT ${ExpenseCols.occurredAt} AS oa,
             ${ExpenseCols.amount} AS amt
      FROM ${Tables.expenses}
      WHERE ${ExpenseCols.occurredAt} >= ? AND ${ExpenseCols.occurredAt} < ?
      ''',
      [fromMs, toMs],
    );
    return rows
        .map(
          (r) => ExpenseRowLite(
            occurredAtMs: (r['oa'] as num).toInt(),
            amount: (r['amt'] as num).toInt(),
          ),
        )
        .toList();
  }
}
