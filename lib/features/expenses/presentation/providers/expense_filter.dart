import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/expense.dart';
import '../../domain/entities/payment_method.dart';

class ExpenseFilter {
  final String searchQuery;
  final int? categoryId;
  final PaymentMethod? paymentMethod;

  const ExpenseFilter({
    this.searchQuery = '',
    this.categoryId,
    this.paymentMethod,
  });

  bool get isActive =>
      searchQuery.isNotEmpty || categoryId != null || paymentMethod != null;

  ExpenseFilter copyWith({
    String? searchQuery,
    Object? categoryId = _sentinel,
    Object? paymentMethod = _sentinel,
  }) => ExpenseFilter(
    searchQuery: searchQuery ?? this.searchQuery,
    categoryId: categoryId == _sentinel ? this.categoryId : categoryId as int?,
    paymentMethod: paymentMethod == _sentinel
        ? this.paymentMethod
        : paymentMethod as PaymentMethod?,
  );

  List<Expense> apply(List<Expense> expenses, Map<int, String> names) {
    final q = searchQuery.trim().toLowerCase();
    return expenses
        .where((e) {
          if (categoryId != null && e.categoryId != categoryId) return false;
          if (paymentMethod != null && e.paymentMethod != paymentMethod) {
            return false;
          }
          if (q.isNotEmpty) {
            final note = (e.note ?? '').toLowerCase();
            final cat = (names[e.categoryId] ?? '').toLowerCase();
            if (!note.contains(q) && !cat.contains(q)) return false;
          }
          return true;
        })
        .toList(growable: false);
  }
}

const Object _sentinel = Object();

class ExpenseFilterNotifier extends Notifier<ExpenseFilter> {
  @override
  ExpenseFilter build() => const ExpenseFilter();

  void setSearch(String q) => state = state.copyWith(searchQuery: q);
  void setCategory(int? id) => state = state.copyWith(categoryId: id);
  void setPaymentMethod(PaymentMethod? m) =>
      state = state.copyWith(paymentMethod: m);
  void clear() => state = const ExpenseFilter();
}

final expenseFilterProvider =
    NotifierProvider<ExpenseFilterNotifier, ExpenseFilter>(
      ExpenseFilterNotifier.new,
    );
