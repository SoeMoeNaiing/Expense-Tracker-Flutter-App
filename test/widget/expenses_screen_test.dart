import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/presentation/providers/category_providers.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/presentation/providers/expense_providers.dart';
import 'package:expense_tracker/features/expenses/presentation/screens/expenses_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeExpensesNotifier extends ExpensesNotifier {
  _FakeExpensesNotifier(this.initial);
  final List<Expense> initial;
  @override
  Future<List<Expense>> build() async => initial;
}

class _FakeCategoriesNotifier extends CategoriesNotifier {
  _FakeCategoriesNotifier(this.initial);
  final List<Category> initial;
  @override
  Future<List<Category>> build() async => initial;
}

Future<void> _pump(WidgetTester tester, List<Expense> expenses) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        expensesProvider.overrideWith(() => _FakeExpensesNotifier(expenses)),
        categoriesProvider.overrideWith(
          () => _FakeCategoriesNotifier(const []),
        ),
      ],
      child: const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: ExpensesScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders empty state when no expenses', (tester) async {
    await _pump(tester, const []);
    expect(find.text('Ledger'), findsOneWidget);
    expect(find.text('No expenses yet'), findsOneWidget);
    expect(find.textContaining('0 Ks'), findsOneWidget);
  });
}
