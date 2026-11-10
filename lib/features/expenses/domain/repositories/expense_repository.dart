import '../../../../core/utils/result.dart';
import '../entities/expense.dart';

abstract interface class ExpenseRepository {
  Future<Result<List<Expense>>> getAll();
  Future<Result<List<Expense>>> getBetween(DateTime from, DateTime to);
  Future<Result<Expense>> add(Expense draft);
  Future<Result<List<Expense>>> addMany(List<Expense> drafts);
  Future<Result<Expense>> update(Expense existing);
  Future<Result<void>> delete(int id);
}
