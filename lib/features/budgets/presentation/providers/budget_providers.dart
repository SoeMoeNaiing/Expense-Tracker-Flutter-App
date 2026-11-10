import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di.dart';
import '../../../../core/utils/result.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../../data/datasources/budget_local_datasource.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_progress.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/usecases/upsert_budget.dart';

final budgetDataSourceProvider = Provider<BudgetLocalDataSource>(
  (ref) => BudgetLocalDataSource(ref.watch(appDatabaseProvider)),
);

final budgetRepositoryProvider = Provider<BudgetRepository>(
  (ref) => BudgetRepositoryImpl(ref.watch(budgetDataSourceProvider)),
);

final upsertBudgetProvider = Provider(
  (ref) => UpsertBudget(ref.watch(budgetRepositoryProvider)),
);

class BudgetsNotifier extends AsyncNotifier<List<Budget>> {
  @override
  Future<List<Budget>> build() async {
    final result = await ref.watch(budgetRepositoryProvider).getAll();
    return switch (result) {
      Success(:final value) => value,
      Failure(:final message) => throw Exception(message),
    };
  }

  Future<Result<Budget>> upsert(Budget budget) async {
    final result = await ref.read(upsertBudgetProvider)(budget);
    if (result is Success<Budget>) {
      final current = state.value ?? const <Budget>[];
      final next = current.where((b) => b.id != result.value.id).toList()
        ..add(result.value);
      state = AsyncValue.data(next);
    }
    return result;
  }

  Future<Result<void>> delete(int id) async {
    final result = await ref.read(budgetRepositoryProvider).delete(id);
    if (result is Success<void>) {
      final current = state.value ?? const <Budget>[];
      state = AsyncValue.data(
        current.where((b) => b.id != id).toList(growable: false),
      );
    }
    return result;
  }
}

final budgetsProvider = AsyncNotifierProvider<BudgetsNotifier, List<Budget>>(
  BudgetsNotifier.new,
);

/// Unfiltered month spend — budget progress reflects total month spending,
/// not the filtered list.
final unfilteredMonthTotalProvider = Provider<int>((ref) {
  final expenses = ref.watch(expensesProvider).value ?? const <Expense>[];
  final now = DateTime.now();
  return expenses
      .where(
        (e) => e.occurredAt.year == now.year && e.occurredAt.month == now.month,
      )
      .fold<int>(0, (s, e) => s + e.amount);
});

int _sumForMonthInCategory(List<Expense> expenses, int categoryId) {
  final now = DateTime.now();
  return expenses
      .where((e) => e.categoryId == categoryId)
      .where(
        (e) => e.occurredAt.year == now.year && e.occurredAt.month == now.month,
      )
      .fold<int>(0, (s, e) => s + e.amount);
}

/// Progress list combining budgets + current month spend per category.
final budgetProgressProvider = Provider<List<BudgetProgress>>((ref) {
  final budgets = ref.watch(budgetsProvider).value ?? const <Budget>[];
  final expenses = ref.watch(expensesProvider).value ?? const <Expense>[];
  final overall = ref.watch(unfilteredMonthTotalProvider);

  return budgets
      .map((b) {
        final spent = b.isOverall
            ? overall
            : _sumForMonthInCategory(expenses, b.categoryId!);
        return BudgetProgress(budget: b, spent: spent);
      })
      .toList(growable: false);
});

/// The overall budget progress, if one exists. Used by the expenses header.
final overallBudgetProgressProvider = Provider<BudgetProgress?>((ref) {
  for (final p in ref.watch(budgetProgressProvider)) {
    if (p.budget.isOverall) return p;
  }
  return null;
});

/// Category lookup helper for budget rows.
final categoryForBudgetProvider = Provider.family<Category?, int?>((
  ref,
  categoryId,
) {
  if (categoryId == null) return null;
  return ref.watch(categoryByIdProvider(categoryId));
});
