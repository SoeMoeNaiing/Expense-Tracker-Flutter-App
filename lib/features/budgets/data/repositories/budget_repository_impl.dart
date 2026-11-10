import '../../../../core/utils/result.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/budget_local_datasource.dart';
import '../mappers/budget_mapper.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetLocalDataSource _ds;
  const BudgetRepositoryImpl(this._ds);

  @override
  Future<Result<List<Budget>>> getAll() async {
    try {
      final rows = await _ds.getAll();
      return Success(rows.map(BudgetMapper.toEntity).toList());
    } catch (e) {
      return Failure('Failed to load budgets', error: e);
    }
  }

  @override
  Future<Result<Budget>> upsert(Budget budget) async {
    try {
      final existing = await _ds.findFor(budget.categoryId);
      if (existing != null) {
        // Update amount only — id and category are fixed.
        final model = BudgetMapper.toModel(
          Budget(
            id: existing.id,
            categoryId: budget.categoryId,
            amount: budget.amount,
          ),
        );
        await _ds.update(model);
        return Success(
          model.id == null
              ? budget
              : Budget(
                  id: model.id,
                  categoryId: model.categoryId,
                  amount: model.amount,
                ),
        );
      }
      final id = await _ds.insert(BudgetMapper.toModel(budget));
      return Success(
        Budget(id: id, categoryId: budget.categoryId, amount: budget.amount),
      );
    } catch (e) {
      return Failure('Failed to save budget', error: e);
    }
  }

  @override
  Future<Result<void>> delete(int id) async {
    try {
      final affected = await _ds.delete(id);
      if (affected == 0) return const Failure('Budget not found');
      return const Success(null);
    } catch (e) {
      return Failure('Failed to delete budget', error: e);
    }
  }
}
