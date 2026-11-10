import '../../../../core/utils/result.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class GetExpenses {
  final ExpenseRepository _repo;
  const GetExpenses(this._repo);

  Future<Result<List<Expense>>> call({DateTime? from, DateTime? to}) async {
    if (from != null && to != null && to.isBefore(from)) {
      return const Failure<List<Expense>>(
        'Invalid range: end date is before start date',
      );
    }
    if (from != null && to != null) {
      return _repo.getBetween(from, to);
    }
    return _repo.getAll();
  }
}
