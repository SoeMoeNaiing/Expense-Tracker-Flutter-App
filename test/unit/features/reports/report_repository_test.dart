import 'package:expense_tracker/core/database/app_database.dart';
import 'package:expense_tracker/core/database/schema.dart';
import 'package:expense_tracker/core/utils/result.dart';
import 'package:expense_tracker/features/reports/data/datasources/report_local_datasource.dart';
import 'package:expense_tracker/features/reports/data/repositories/report_repository_impl.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_period.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_summary.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_db.dart';

Future<int> _cat(AppDatabase db, String name) =>
    db.db.insert(Tables.categories, {
      CategoryCols.name: name,
      CategoryCols.iconCode: 0,
      CategoryCols.colorHex: 0xFFFF6B6B,
      CategoryCols.isDefault: 0,
      CategoryCols.createdAt: 0,
    });

Future<void> _exp(
  AppDatabase db, {
  required int amount,
  required int categoryId,
  required DateTime occurredAt,
}) => db.db.insert(Tables.expenses, {
  ExpenseCols.amount: amount,
  ExpenseCols.categoryId: categoryId,
  ExpenseCols.occurredAt: occurredAt.millisecondsSinceEpoch,
  ExpenseCols.createdAt: occurredAt.millisecondsSinceEpoch,
  ExpenseCols.paymentMethod: 'cash',
});

void main() {
  late AppDatabase appDb;
  late ReportRepositoryImpl repo;
  late int foodId;
  late int transportId;

  setUp(() async {
    appDb = await openTestDb();
    repo = ReportRepositoryImpl(ReportLocalDataSource(appDb));
    foodId = await _cat(appDb, 'Food');
    transportId = await _cat(appDb, 'Transport');

    // Fixture: 5 expenses in Jan 2026.
    //   Jan 5  Food       500
    //   Jan 5  Transport  200
    //   Jan 10 Food      1000
    //   Jan 10 Food       500
    //   Jan 20 Transport  300
    await _exp(
      appDb,
      amount: 500,
      categoryId: foodId,
      occurredAt: DateTime(2026, 1, 5, 12),
    );
    await _exp(
      appDb,
      amount: 200,
      categoryId: transportId,
      occurredAt: DateTime(2026, 1, 5, 18),
    );
    await _exp(
      appDb,
      amount: 1000,
      categoryId: foodId,
      occurredAt: DateTime(2026, 1, 10, 9),
    );
    await _exp(
      appDb,
      amount: 500,
      categoryId: foodId,
      occurredAt: DateTime(2026, 1, 10, 19),
    );
    await _exp(
      appDb,
      amount: 300,
      categoryId: transportId,
      occurredAt: DateTime(2026, 1, 20, 8),
    );
  });

  tearDown(() => appDb.close());

  group('month summary', () {
    test('total and count', () async {
      final result = await repo.getSummary(ReportPeriod.month(2026, 1));
      expect(result, isA<Success<ReportSummary>>());
      final s = (result as Success<ReportSummary>).value;
      expect(s.total, 2500);
      expect(s.count, 5);
      expect(s.averagePerExpense, 500);
    });

    test('byCategory sorted desc', () async {
      final r = await repo.getSummary(ReportPeriod.month(2026, 1));
      final s = (r as Success<ReportSummary>).value;
      expect(s.byCategory.length, 2);
      expect(s.byCategory[0].categoryId, foodId);
      expect(s.byCategory[0].amount, 2000);
      expect(s.byCategory[0].count, 3);
      expect(s.byCategory[1].categoryId, transportId);
      expect(s.byCategory[1].amount, 500);
      expect(s.byCategory[1].count, 2);
    });

    test('daily buckets', () async {
      final r = await repo.getSummary(ReportPeriod.month(2026, 1));
      final s = (r as Success<ReportSummary>).value;
      expect(s.daily.length, 3);
      expect(s.daily[0].day, DateTime(2026, 1, 5));
      expect(s.daily[0].amount, 700);
      expect(s.daily[0].count, 2);
      expect(s.daily[1].day, DateTime(2026, 1, 10));
      expect(s.daily[1].amount, 1500);
      expect(s.daily[2].day, DateTime(2026, 1, 20));
      expect(s.daily[2].amount, 300);
    });

    test('topCategories(1) is Food', () async {
      final r = await repo.getSummary(ReportPeriod.month(2026, 1));
      final s = (r as Success<ReportSummary>).value;
      final top = s.topCategories(1);
      expect(top.length, 1);
      expect(top.single.categoryId, foodId);
    });
  });

  group('period variants', () {
    test('week of 2026-01-05 -> 4 expenses, 2200', () async {
      final r = await repo.getSummary(ReportPeriod.week(DateTime(2026, 1, 5)));
      final s = (r as Success<ReportSummary>).value;
      expect(s.total, 2200);
      expect(s.count, 4);
    });

    test('year 2026 -> all 5', () async {
      final r = await repo.getSummary(ReportPeriod.year(2026));
      final s = (r as Success<ReportSummary>).value;
      expect(s.total, 2500);
      expect(s.count, 5);
    });

    test('custom Jan 8..15 -> only Jan 10', () async {
      final r = await repo.getSummary(
        ReportPeriod.custom(DateTime(2026, 1, 8), DateTime(2026, 1, 15)),
      );
      final s = (r as Success<ReportSummary>).value;
      expect(s.total, 1500);
      expect(s.count, 2);
      expect(s.daily.single.day, DateTime(2026, 1, 10));
    });

    test('month with no expenses -> empty', () async {
      final r = await repo.getSummary(ReportPeriod.month(2026, 6));
      final s = (r as Success<ReportSummary>).value;
      expect(s.total, 0);
      expect(s.count, 0);
      expect(s.byCategory, isEmpty);
      expect(s.daily, isEmpty);
      expect(s.isEmpty, true);
    });
  });

  group('boundary semantics', () {
    test('to is exclusive', () async {
      // Range [Jan 5 00:00, Jan 5 12:00). The 12:00 expense is excluded.
      final r = await repo.getSummary(
        ReportPeriod.custom(DateTime(2026, 1, 5), DateTime(2026, 1, 5, 12)),
      );
      expect((r as Success<ReportSummary>).value.count, 0);
    });

    test('from is inclusive', () async {
      // Range [Jan 5 12:00, Jan 5 13:00). Only the 12:00 expense falls
      // in this window. Confirms >= includes the row at exactly `from`.
      final r = await repo.getSummary(
        ReportPeriod.custom(DateTime(2026, 1, 5, 12), DateTime(2026, 1, 5, 13)),
      );
      final s = (r as Success<ReportSummary>).value;
      expect(s.count, 1);
      expect(s.total, 500);
    });
  });
}
