import '../../../../core/utils/result.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';
import 'add_expense.dart';

class UpdateExpense {
  final ExpenseRepository _repo;
  const UpdateExpense(this._repo);

  Future<Result<Expense>> call(Expense existing) async {
    if (existing.id == null) {
      return const Failure<Expense>('Cannot update an expense without an id');
    }
    if (existing.amount <= 0) {
      return const Failure<Expense>('Amount must be greater than zero');
    }
    if (existing.note != null &&
        existing.note!.length > AddExpense.maxNoteLength) {
      return const Failure<Expense>(
        'Note too long (max ${AddExpense.maxNoteLength} chars)',
      );
    }
    return _repo.update(existing);
  }
}
