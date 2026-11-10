import '../../domain/entities/budget.dart';
import '../models/budget_model.dart';

abstract final class BudgetMapper {
  static Budget toEntity(BudgetModel m) =>
      Budget(id: m.id, categoryId: m.categoryId, amount: m.amount);

  static BudgetModel toModel(Budget b) => BudgetModel(
    id: b.id,
    categoryId: b.categoryId,
    amount: b.amount,
    createdAtMs: DateTime.now().millisecondsSinceEpoch,
  );
}
