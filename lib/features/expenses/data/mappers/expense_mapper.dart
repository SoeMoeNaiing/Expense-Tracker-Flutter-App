import '../../domain/entities/expense.dart';
import '../../domain/entities/payment_method.dart';
import '../models/expense_model.dart';

abstract final class ExpenseMapper {
  static Expense toEntity(ExpenseModel m) => Expense(
    id: m.id,
    amount: m.amount,
    categoryId: m.categoryId,
    note: m.note,
    occurredAt: DateTime.fromMillisecondsSinceEpoch(m.occurredAtMs),
    createdAt: DateTime.fromMillisecondsSinceEpoch(m.createdAtMs),
    paymentMethod: PaymentMethod.fromDb(m.paymentMethod),
  );

  static ExpenseModel toModel(Expense e) => ExpenseModel(
    id: e.id,
    amount: e.amount,
    categoryId: e.categoryId,
    note: e.note,
    occurredAtMs: e.occurredAt.millisecondsSinceEpoch,
    createdAtMs: e.createdAt.millisecondsSinceEpoch,
    paymentMethod: e.paymentMethod.dbValue,
  );
}
