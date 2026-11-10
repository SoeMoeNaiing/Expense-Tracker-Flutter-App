import '../../domain/entities/expense.dart';
import '../models/expense_model.dart';

abstract final class ExpenseMapper {
  static Expense toEntity(ExpenseModel m) => Expense(
    id: m.id,
    amount: m.amount,
    categoryId: m.categoryId,
    note: m.note,
    occurredAt: DateTime.fromMillisecondsSinceEpoch(m.occurredAtMs),
    createdAt: DateTime.fromMillisecondsSinceEpoch(m.createdAtMs),
  );

  static ExpenseModel toModel(Expense e) => ExpenseModel(
    id: e.id,
    amount: e.amount,
    categoryId: e.categoryId,
    note: e.note,
    occurredAtMs: e.occurredAt.millisecondsSinceEpoch,
    createdAtMs: e.createdAt.millisecondsSinceEpoch,
  );
}
