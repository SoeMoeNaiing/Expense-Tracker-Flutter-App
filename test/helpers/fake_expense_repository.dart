import 'package:expense_tracker/core/utils/result.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';

/// In-memory repo for widget tests. The state-side (AsyncNotifier)
/// behavior is what we're testing — this is a stand-in for persistence.
class FakeExpenseRepository implements ExpenseRepository {
  final List<Expense> items;
  FakeExpenseRepository([List<Expense>? initial]) : items = [...?initial];

  @override
  Future<Result<List<Expense>>> getAll() async => Success([...items]);

  @override
  Future<Result<List<Expense>>> getBetween(DateTime from, DateTime to) async {
    final filtered = items.where(
      (e) => !e.occurredAt.isBefore(from) && e.occurredAt.isBefore(to),
    );
    return Success(filtered.toList(growable: false));
  }

  @override
  Future<Result<Expense>> add(Expense draft) async {
    final saved = draft.withId(items.length + 1);
    items.add(saved);
    return Success(saved);
  }

  @override
  Future<Result<Expense>> update(Expense existing) async {
    final idx = items.indexWhere((e) => e.id == existing.id);
    if (idx < 0) return const Failure('not found');
    items[idx] = existing;
    return Success(existing);
  }

  @override
  Future<Result<void>> delete(int id) async {
    items.removeWhere((e) => e.id == id);
    return const Success(null);
  }
}
