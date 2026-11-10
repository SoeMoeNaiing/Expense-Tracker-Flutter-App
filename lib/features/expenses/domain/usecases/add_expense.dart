import '../../../../core/utils/result.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class AddExpense {
  static const int maxNoteLength = 500;

  final ExpenseRepository _repo;
  const AddExpense(this._repo);

  Future<Result<Expense>> call(Expense draft) async {
    if (draft.id != null) {
      return const Failure<Expense>('Draft is already persisted');
    }
    if (draft.amount <= 0) {
      return const Failure<Expense>('Amount must be greater than zero');
    }
    if (draft.note != null && draft.note!.length > maxNoteLength) {
      return const Failure<Expense>('Note too long (max $maxNoteLength chars)');
    }
    return _repo.add(draft);
  }
}
