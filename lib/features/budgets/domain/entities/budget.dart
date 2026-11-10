class Budget {
  final int? id;
  final int? categoryId; // null = overall budget
  final int amount;

  const Budget({this.id, this.categoryId, required this.amount});

  bool get isOverall => categoryId == null;

  Budget copyWith({int? id, int? amount}) => Budget(
    id: id ?? this.id,
    categoryId: categoryId,
    amount: amount ?? this.amount,
  );

  @override
  bool operator ==(Object other) =>
      other is Budget &&
      other.id == id &&
      other.categoryId == categoryId &&
      other.amount == amount;

  @override
  int get hashCode => Object.hash(id, categoryId, amount);

  @override
  String toString() =>
      'Budget(id: $id, categoryId: $categoryId, amount: $amount)';
}
