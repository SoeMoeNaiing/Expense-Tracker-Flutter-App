import '../../../../core/database/schema.dart';

class BudgetModel {
  final int? id;
  final int? categoryId;
  final int amount;
  final int createdAtMs;

  const BudgetModel({
    this.id,
    this.categoryId,
    required this.amount,
    required this.createdAtMs,
  });

  Map<String, Object?> toMap() => {
    if (id != null) BudgetCols.id: id,
    BudgetCols.categoryId: categoryId,
    BudgetCols.amount: amount,
    BudgetCols.createdAt: createdAtMs,
  };

  factory BudgetModel.fromMap(Map<String, Object?> m) => BudgetModel(
    id: m[BudgetCols.id] as int?,
    categoryId: m[BudgetCols.categoryId] as int?,
    amount: m[BudgetCols.amount] as int,
    createdAtMs: m[BudgetCols.createdAt] as int,
  );
}
