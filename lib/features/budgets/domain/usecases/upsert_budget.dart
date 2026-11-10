import '../../../../core/utils/result.dart';
import '../entities/budget.dart';
import '../repositories/budget_repository.dart';

class UpsertBudget {
  final BudgetRepository _repo;
  const UpsertBudget(this._repo);

  Future<Result<Budget>> call(Budget budget) async {
    if (budget.amount <= 0) {
      return const Failure('Budget amount must be greater than zero');
    }
    return _repo.upsert(budget);
  }
}
