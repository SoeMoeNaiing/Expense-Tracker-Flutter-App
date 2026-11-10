/// Immutable expense entity. `id == null` means the expense has not yet
/// been persisted (a "draft"). `amount` is whole Myanmar Kyat.
class Expense {
  final int? id;
  final int amount;
  final int categoryId;
  final String? note;
  final DateTime occurredAt;
  final DateTime createdAt;

  const Expense({
    this.id,
    required this.amount,
    required this.categoryId,
    this.note,
    required this.occurredAt,
    required this.createdAt,
  });

  /// Builds a not-yet-persisted expense. `createdAt` defaults to now.
  /// `occurredAt` defaults to now so back-dating is optional.
  factory Expense.draft({
    required int amount,
    required int categoryId,
    String? note,
    DateTime? occurredAt,
  }) {
    final now = DateTime.now();
    return Expense(
      id: null,
      amount: amount,
      categoryId: categoryId,
      note: note,
      occurredAt: occurredAt ?? now,
      createdAt: now,
    );
  }

  bool get isPersisted => id != null;

  /// Returns a copy with the persisted id assigned. Only used by the
  /// repository immediately after insert.
  Expense withId(int newId) => Expense(
    id: newId,
    amount: amount,
    categoryId: categoryId,
    note: note,
    occurredAt: occurredAt,
    createdAt: createdAt,
  );

  @override
  bool operator ==(Object other) =>
      other is Expense &&
      other.id == id &&
      other.amount == amount &&
      other.categoryId == categoryId &&
      other.note == note &&
      other.occurredAt == occurredAt &&
      other.createdAt == createdAt;

  @override
  int get hashCode =>
      Object.hash(id, amount, categoryId, note, occurredAt, createdAt);

  @override
  String toString() =>
      'Expense(id: $id, amount: $amount, categoryId: $categoryId, '
      'note: $note, occurredAt: $occurredAt)';
}
