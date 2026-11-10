import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di.dart';
import '../../../../core/utils/result.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../data/datasources/expense_local_datasource.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/usecases/add_expense.dart';
import '../../domain/usecases/delete_expense.dart';
import '../../domain/usecases/get_expenses.dart';
import '../../domain/usecases/export_expenses_csv.dart';
import '../../domain/usecases/import_expenses_csv.dart';
import '../../domain/usecases/update_expense.dart';
import 'expense_filter.dart';

final expenseDataSourceProvider = Provider<ExpenseLocalDataSource>(
  (ref) => ExpenseLocalDataSource(ref.watch(appDatabaseProvider)),
);

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => ExpenseRepositoryImpl(ref.watch(expenseDataSourceProvider)),
);

final addExpenseProvider = Provider(
  (ref) => AddExpense(ref.watch(expenseRepositoryProvider)),
);
final updateExpenseProvider = Provider(
  (ref) => UpdateExpense(ref.watch(expenseRepositoryProvider)),
);
final deleteExpenseProvider = Provider(
  (ref) => DeleteExpense(ref.watch(expenseRepositoryProvider)),
);
final getExpensesProvider = Provider(
  (ref) => GetExpenses(ref.watch(expenseRepositoryProvider)),
);

class ExpensesNotifier extends AsyncNotifier<List<Expense>> {
  @override
  Future<List<Expense>> build() async {
    final result = await ref.watch(getExpensesProvider)();
    return switch (result) {
      Success(:final value) => value,
      Failure(:final message) => throw Exception(message),
    };
  }

  Future<Result<Expense>> add(Expense draft) async {
    final result = await ref.read(addExpenseProvider)(draft);
    if (result is Success<Expense>) {
      final current = state.value ?? const <Expense>[];
      state = AsyncValue.data([result.value, ...current]);
    }
    return result;
  }

  Future<Result<void>> delete(int id) async {
    final result = await ref.read(deleteExpenseProvider)(id);
    if (result is Success<void>) {
      final current = state.value ?? const <Expense>[];
      state = AsyncValue.data(
        current.where((e) => e.id != id).toList(growable: false),
      );
    }
    return result;
  }

  /// Removes an item from the UI immediately, without touching the DB.
  /// Returns the removed expense so the caller can offer undo.
  Expense? removeLocally(int id) {
    final current = state.value ?? const <Expense>[];
    final idx = current.indexWhere((e) => e.id == id);
    if (idx < 0) return null;
    final removed = current[idx];
    state = AsyncValue.data([...current]..removeAt(idx));
    return removed;
  }

  /// Re-adds an item to the UI, preserving sort order (newest first).
  void reinsertLocally(Expense e) {
    final current = state.value ?? const <Expense>[];
    final next = [...current, e]
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    state = AsyncValue.data(next);
  }

  /// Commits the deletion to the database. Called after the undo window
  /// expires (no snackbar action taken). The item is already gone from
  /// state via [removeLocally].
  Future<Result<void>> deletePermanently(int id) =>
      ref.read(deleteExpenseProvider)(id);
}

final expensesProvider = AsyncNotifierProvider<ExpensesNotifier, List<Expense>>(
  ExpensesNotifier.new,
);

final filteredExpensesProvider = Provider<AsyncValue<List<Expense>>>((ref) {
  final expenses = ref.watch(expensesProvider);
  final filter = ref.watch(expenseFilterProvider);
  final names = ref.watch(categoryNameMapProvider);
  return expenses.whenData((list) => filter.apply(list, names));
});

/// Derived: total spent for current month, from the *filtered* list.
final monthTotalProvider = Provider<int>((ref) {
  final expenses =
      ref.watch(filteredExpensesProvider).value ?? const <Expense>[];
  final now = DateTime.now();
  return expenses
      .where(
        (e) => e.occurredAt.year == now.year && e.occurredAt.month == now.month,
      )
      .fold<int>(0, (sum, e) => sum + e.amount);
});

final exportExpensesCsvProvider = Provider(
  (ref) => ExportExpensesCsv(
    ref.watch(expenseRepositoryProvider),
    ref.watch(categoryRepositoryProvider),
  ),
);

final importExpensesCsvProvider = Provider(
  (ref) => ImportExpensesCsv(
    ref.watch(expenseRepositoryProvider),
    ref.watch(categoryRepositoryProvider),
  ),
);
