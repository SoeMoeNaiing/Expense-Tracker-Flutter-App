import '../../../../core/utils/result.dart';
import '../entities/budget.dart';

abstract interface class BudgetRepository {
  Future<Result<List<Budget>>> getAll();
  Future<Result<Budget>> upsert(Budget budget);
  Future<Result<void>> delete(int id);
}
