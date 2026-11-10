import 'payment_method.dart';

class Expense {
  final int? id;
  final int amount;
  final int categoryId;
  final String? note;
  final DateTime occurredAt;
  final DateTime createdAt;
  final PaymentMethod paymentMethod;

  const Expense({
    this.id,
    required this.amount,
    required this.categoryId,
    this.note,
    required this.occurredAt,
    required this.createdAt,
    this.paymentMethod = PaymentMethod.cash,
  });

  factory Expense.draft({
    required int amount,
    required int categoryId,
    String? note,
    DateTime? occurredAt,
    PaymentMethod paymentMethod = PaymentMethod.cash,
  }) {
    final now = DateTime.now();
    return Expense(
      amount: amount,
      categoryId: categoryId,
      note: note,
      occurredAt: occurredAt ?? now,
      createdAt: now,
      paymentMethod: paymentMethod,
    );
  }

  bool get isPersisted => id != null;

  Expense withId(int newId) => Expense(
    id: newId,
    amount: amount,
    categoryId: categoryId,
    note: note,
    occurredAt: occurredAt,
    createdAt: createdAt,
    paymentMethod: paymentMethod,
  );

  @override
  bool operator ==(Object other) =>
      other is Expense &&
      other.id == id &&
      other.amount == amount &&
      other.categoryId == categoryId &&
      other.note == note &&
      other.occurredAt == occurredAt &&
      other.createdAt == createdAt &&
      other.paymentMethod == paymentMethod;

  @override
  int get hashCode => Object.hash(
    id,
    amount,
    categoryId,
    note,
    occurredAt,
    createdAt,
    paymentMethod,
  );

  @override
  String toString() =>
      'Expense(id: $id, amount: $amount, categoryId: $categoryId, '
      'note: $note, pm: ${paymentMethod.dbValue})';
}
