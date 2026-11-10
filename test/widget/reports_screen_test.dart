import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/presentation/providers/category_providers.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_period.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_summary.dart';
import 'package:expense_tracker/features/reports/presentation/providers/report_providers.dart';
import 'package:expense_tracker/features/reports/presentation/screens/reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCategoriesNotifier extends CategoriesNotifier {
  _FakeCategoriesNotifier(this.initial);
  final List<Category> initial;
  @override
  Future<List<Category>> build() async => initial;
}

Future<void> _pump(
  WidgetTester tester, {
  required ReportSummary summary,
  List<Category> categories = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        reportSummaryProvider.overrideWith((ref) async => summary),
        categoriesProvider.overrideWith(
          () => _FakeCategoriesNotifier(categories),
        ),
      ],
      child: const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: ReportsScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders empty state when summary is empty', (tester) async {
    final period = ReportPeriod.month(2026, 1);
    await _pump(tester, summary: ReportSummary.empty(period));

    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('No data for this period'), findsOneWidget);
    // No charts.
    expect(find.text('Daily trend'), findsNothing);
    expect(find.text('Top categories'), findsNothing);
  });

  testWidgets('renders donut + trend + bars with data', (tester) async {
    final period = ReportPeriod.month(2026, 1);
    const food = Category(
      id: 1,
      name: 'Food',
      iconCode: 0,
      colorHex: 0xFFFF6B6B,
      isDefault: true,
    );
    const transport = Category(
      id: 2,
      name: 'Transport',
      iconCode: 0,
      colorHex: 0xFF4EA8FF,
      isDefault: true,
    );
    final summary = ReportSummary(
      period: period,
      total: 2500,
      count: 3,
      byCategory: const [
        CategorySlice(categoryId: 1, amount: 2000, count: 2),
        CategorySlice(categoryId: 2, amount: 500, count: 1),
      ],
      daily: [
        DailyPoint(day: DateTime(2026, 1, 5), amount: 700, count: 2),
        DailyPoint(day: DateTime(2026, 1, 10), amount: 1500, count: 1),
      ],
    );

    await _pump(tester, summary: summary, categories: const [food, transport]);

    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Transport'), findsOneWidget);
    expect(find.text('Daily trend'), findsOneWidget);
    expect(find.text('Top categories'), findsOneWidget);
    expect(find.textContaining('2,500 Ks'), findsWidgets);
  });
}
