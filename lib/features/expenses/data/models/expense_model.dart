import '../../../../core/database/schema.dart';

/// Mirrors the `expenses` table row exactly. Timestamps are epoch millis.
class ExpenseModel {
  final int? id;
  final int amount;
  final int categoryId;
  final String? note;
  final int occurredAtMs;
  final int createdAtMs;

  const ExpenseModel({
    this.id,
    required this.amount,
    required this.categoryId,
    this.note,
    required this.occurredAtMs,
    required this.createdAtMs,
  });

  Map<String, Object?> toMap() => {
    if (id != null) ExpenseCols.id: id,
    ExpenseCols.amount: amount,
    ExpenseCols.categoryId: categoryId,
    ExpenseCols.note: note,
    ExpenseCols.occurredAt: occurredAtMs,
    ExpenseCols.createdAt: createdAtMs,
  };

  factory ExpenseModel.fromMap(Map<String, Object?> map) => ExpenseModel(
    id: map[ExpenseCols.id] as int?,
    amount: map[ExpenseCols.amount] as int,
    categoryId: map[ExpenseCols.categoryId] as int,
    note: map[ExpenseCols.note] as String?,
    occurredAtMs: map[ExpenseCols.occurredAt] as int,
    createdAtMs: map[ExpenseCols.createdAt] as int,
  );
}
