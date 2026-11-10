import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/entities/payment_method.dart';
import 'package:expense_tracker/features/expenses/presentation/providers/expense_filter.dart';
import 'package:flutter_test/flutter_test.dart';

Expense _e({
  int id = 1,
  int amount = 100,
  int categoryId = 1,
  String? note,
  PaymentMethod pm = PaymentMethod.cash,
}) => Expense(
  id: id,
  amount: amount,
  categoryId: categoryId,
  note: note,
  occurredAt: DateTime(2026),
  createdAt: DateTime(2026),
  paymentMethod: pm,
);

void main() {
  final expenses = [
    _e(id: 1, categoryId: 1, note: 'Lunch', pm: PaymentMethod.cash),
    _e(id: 2, categoryId: 2, note: 'Taxi', pm: PaymentMethod.card),
    _e(id: 3, categoryId: 1, note: 'Coffee', pm: PaymentMethod.card),
  ];
  const names = {1: 'Food', 2: 'Transport'};

  group('ExpenseFilter.apply', () {
    test('empty filter returns all', () {
      expect(const ExpenseFilter().apply(expenses, names).length, 3);
    });

    test('search matches note', () {
      const f = ExpenseFilter(searchQuery: 'taxi');
      final r = f.apply(expenses, names);
      expect(r.length, 1);
      expect(r.single.id, 2);
    });

    test('search matches category name', () {
      const f = ExpenseFilter(searchQuery: 'food');
      final r = f.apply(expenses, names);
      expect(r.map((e) => e.id).toSet(), {1, 3});
    });

    test('category filter', () {
      const f = ExpenseFilter(categoryId: 1);
      expect(f.apply(expenses, names).length, 2);
    });

    test('payment method filter', () {
      const f = ExpenseFilter(paymentMethod: PaymentMethod.card);
      expect(f.apply(expenses, names).length, 2);
    });

    test('combined filters intersect', () {
      const f = ExpenseFilter(categoryId: 1, paymentMethod: PaymentMethod.card);
      final r = f.apply(expenses, names);
      expect(r.length, 1);
      expect(r.single.id, 3);
    });
  });
}
