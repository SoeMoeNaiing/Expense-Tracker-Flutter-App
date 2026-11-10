import '../../../../core/database/schema.dart';

class ExpenseModel {
  final int? id;
  final int amount;
  final int categoryId;
  final String? note;
  final int occurredAtMs;
  final int createdAtMs;
  final String paymentMethod;

  const ExpenseModel({
    this.id,
    required this.amount,
    required this.categoryId,
    this.note,
    required this.occurredAtMs,
    required this.createdAtMs,
    this.paymentMethod = 'cash',
  });

  Map<String, Object?> toMap() => {
    if (id != null) ExpenseCols.id: id,
    ExpenseCols.amount: amount,
    ExpenseCols.categoryId: categoryId,
    ExpenseCols.note: note,
    ExpenseCols.occurredAt: occurredAtMs,
    ExpenseCols.createdAt: createdAtMs,
    ExpenseCols.paymentMethod: paymentMethod,
  };

  factory ExpenseModel.fromMap(Map<String, Object?> m) => ExpenseModel(
    id: m[ExpenseCols.id] as int?,
    amount: m[ExpenseCols.amount] as int,
    categoryId: m[ExpenseCols.categoryId] as int,
    note: m[ExpenseCols.note] as String?,
    occurredAtMs: m[ExpenseCols.occurredAt] as int,
    createdAtMs: m[ExpenseCols.createdAt] as int,
    paymentMethod: (m[ExpenseCols.paymentMethod] as String?) ?? 'cash',
  );
}
