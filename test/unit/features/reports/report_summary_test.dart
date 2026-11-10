import 'package:expense_tracker/features/reports/domain/entities/report_period.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final monthPeriod = ReportPeriod.month(2026, 1);

  test('empty summary metrics', () {
    final s = ReportSummary.empty(monthPeriod);
    expect(s.averagePerExpense, 0);
    expect(s.isEmpty, true);
  });

  test('averagePerExpense', () {
    final s = ReportSummary(
      period: monthPeriod,
      total: 2500,
      count: 5,
      byCategory: const [],
      daily: const [],
    );
    expect(s.averagePerExpense, 500);
  });

  test('topCategories preserves order and limits', () {
    final s = ReportSummary(
      period: monthPeriod,
      total: 0,
      count: 0,
      byCategory: const [
        CategorySlice(categoryId: 1, amount: 100, count: 1),
        CategorySlice(categoryId: 2, amount: 80, count: 1),
        CategorySlice(categoryId: 3, amount: 60, count: 1),
      ],
      daily: const [],
    );
    final top2 = s.topCategories(2);
    expect(top2.length, 2);
    expect(top2[0].categoryId, 1);
    expect(top2[1].categoryId, 2);
  });

  test('filledDaily inserts zero-days', () {
    final period = ReportPeriod.custom(
      DateTime(2026, 1, 1),
      DateTime(2026, 1, 5),
    );
    final s = ReportSummary(
      period: period,
      total: 300,
      count: 2,
      byCategory: const [],
      daily: [
        DailyPoint(day: DateTime(2026, 1, 1), amount: 100, count: 1),
        DailyPoint(day: DateTime(2026, 1, 3), amount: 200, count: 1),
      ],
    );
    final filled = s.filledDaily();
    expect(filled.length, 4); // Jan 1..4; to exclusive
    expect(filled[0].amount, 100);
    expect(filled[1].amount, 0);
    expect(filled[2].amount, 200);
    expect(filled[3].amount, 0);
  });
}
