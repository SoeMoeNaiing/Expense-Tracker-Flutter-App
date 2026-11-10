import '../../../../core/utils/result.dart';
import '../repositories/expense_repository.dart';

class DeleteExpense {
  final ExpenseRepository _repo;
  const DeleteExpense(this._repo);

  Future<Result<void>> call(int id) async {
    if (id <= 0) {
      return const Failure<void>('Invalid expense id');
    }
    return _repo.delete(id);
  }
}
