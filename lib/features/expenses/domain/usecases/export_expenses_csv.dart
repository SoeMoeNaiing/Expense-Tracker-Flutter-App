import '../../../../core/utils/result.dart';
import '../../../categories/data/repositories/category_repository_impl.dart';
import '../../../categories/domain/entities/category.dart';
import '../../data/csv/csv_codec.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class ExportExpensesCsv {
  final ExpenseRepository _expenseRepo;
  final CategoryRepositoryImpl _categoryRepo;

  const ExportExpensesCsv(this._expenseRepo, this._categoryRepo);

  Future<Result<String>> call() async {
    final expensesResult = await _expenseRepo.getAll();
    if (expensesResult.isFailure) {
      return const Failure('Failed to load expenses');
    }
    final expenses = expensesResult.valueOrNull ?? const <Expense>[];

    final catResult = await _categoryRepo.getAll();
    if (catResult.isFailure) {
      return const Failure('Failed to load categories');
    }
    final catNames = <int, String>{
      for (final c in catResult.valueOrNull ?? const <Category>[])
        if (c.id != null) c.id!: c.name,
    };

    return Success(CsvCodec.encode(expenses, catNames));
  }
}
