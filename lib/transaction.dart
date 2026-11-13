class Transaction {
  final int? id;
  final String title;
  final double amount;
  final String type;
  final String category;
  final String date;

  Transaction({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      'date': date,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      category: map['category'] as String,
      date: map['date'] as String,
    );
  }
}
