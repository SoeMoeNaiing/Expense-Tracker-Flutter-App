import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/presentation/providers/budget_providers.dart';
import 'package:expense_tracker/features/budgets/presentation/screens/budgets_screen.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/presentation/providers/category_providers.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/presentation/providers/expense_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_expense_repository.dart';

class _FakeBudgetsNotifier extends BudgetsNotifier {
  _FakeBudgetsNotifier(this.initial);
  final List<Budget> initial;
  @override
  Future<List<Budget>> build() async => initial;
}

class _FakeCategoriesNotifier extends CategoriesNotifier {
  _FakeCategoriesNotifier(this.initial);
  final List<Category> initial;
  @override
  Future<List<Category>> build() async => initial;
}

class _FakeExpensesNotifier extends ExpensesNotifier {
  _FakeExpensesNotifier(this.initial);
  final List<Expense> initial;
  @override
  Future<List<Expense>> build() async => initial;
}

Future<void> _pump(
  WidgetTester tester, {
  List<Budget> budgets = const [],
  List<Category> categories = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        budgetsProvider.overrideWith(() => _FakeBudgetsNotifier(budgets)),
        categoriesProvider.overrideWith(
          () => _FakeCategoriesNotifier(categories),
        ),
        expensesProvider.overrideWith(() => _FakeExpensesNotifier(const [])),
        expenseRepositoryProvider.overrideWith((_) => FakeExpenseRepository()),
      ],
      child: const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: BudgetsScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders empty state when no budgets', (tester) async {
    await _pump(tester);
    expect(find.text('Budgets'), findsOneWidget);
    expect(find.text('No budgets yet'), findsOneWidget);
  });

  testWidgets('renders overall + category budget rows', (tester) async {
    const food = Category(
      id: 1,
      name: 'Food',
      iconCode: 0,
      colorHex: 0xFFFF6B6B,
      isDefault: true,
    );
    await _pump(
      tester,
      budgets: const [
        Budget(id: 1, amount: 200000),
        Budget(id: 2, categoryId: 1, amount: 50000),
      ],
      categories: const [food],
    );

    expect(find.text('Overall'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
