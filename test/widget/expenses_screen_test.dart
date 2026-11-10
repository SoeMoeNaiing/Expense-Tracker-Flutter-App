import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/presentation/providers/category_providers.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/entities/payment_method.dart';
import 'package:expense_tracker/features/expenses/presentation/providers/expense_providers.dart';
import 'package:expense_tracker/features/expenses/presentation/screens/expenses_screen.dart';
import 'package:expense_tracker/features/expenses/presentation/widgets/expense_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_expense_repository.dart';

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

const _food = Category(
  id: 1,
  name: 'Food',
  iconCode: 0,
  colorHex: 0xFFFF6B6B,
  isDefault: true,
);

Expense _sampleExpense() => Expense(
  id: 1,
  amount: 2500,
  categoryId: 1,
  note: 'Lunch',
  occurredAt: DateTime(2026, 1, 15),
  createdAt: DateTime(2026, 1, 15),
  paymentMethod: PaymentMethod.cash,
);

Future<FakeExpenseRepository> _pump(
  WidgetTester tester,
  List<Expense> expenses,
) async {
  final repo = FakeExpenseRepository(expenses);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        expensesProvider.overrideWith(() => _FakeExpensesNotifier(expenses)),
        categoriesProvider.overrideWith(
          () => _FakeCategoriesNotifier(const [_food]),
        ),
        expenseRepositoryProvider.overrideWith((_) => repo),
      ],
      child: const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: ExpensesScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('renders empty state when no expenses', (tester) async {
    await _pump(tester, const []);
    expect(find.text('Ledger'), findsOneWidget);
    expect(find.text('No expenses yet'), findsOneWidget);
    expect(find.textContaining('0 Ks'), findsOneWidget);
  });

  testWidgets('swipe deletes item and undo restores it', (tester) async {
    final repo = await _pump(tester, [_sampleExpense()]);
    expect(find.byType(ExpenseCard), findsOneWidget);

    await tester.drag(find.byType(ExpenseCard), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.byType(ExpenseCard), findsNothing);
    expect(find.text('Undo'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(find.byType(ExpenseCard), findsOneWidget);
    expect(repo.items, isNotEmpty); // DB untouched
  });

  testWidgets('swipe without undo commits deletion to repo', (tester) async {
    final repo = await _pump(tester, [_sampleExpense()]);
    expect(find.byType(ExpenseCard), findsOneWidget);
    expect(repo.items.length, 1);

    await tester.drag(find.byType(ExpenseCard), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.byType(ExpenseCard), findsNothing);
    expect(find.text('Undo'), findsOneWidget);

    // Don't rely on pump(Duration) to trigger the SnackBar's internal
    // 4-second timer — that timer chain is not reliably driven by the
    // test clock. Instead, hide the snackbar directly. This resolves
    // controller.closed with reason=hide, which is NOT action, so
    // deletePermanently runs — exactly the path the timeout takes.
    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
        .hideCurrentSnackBar();
    await tester.pumpAndSettle();

    expect(find.text('Undo'), findsNothing);
    expect(find.byType(ExpenseCard), findsNothing);
    expect(repo.items, isEmpty);
  });
}
