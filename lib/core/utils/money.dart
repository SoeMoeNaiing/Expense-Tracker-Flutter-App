import 'package:intl/intl.dart';

/// Immutable MMK money value. Always whole kyat (no cents).
class Money {
  final int amount;
  const Money(this.amount);

  static const Money zero = Money(0);

  static final NumberFormat _fmt = NumberFormat.decimalPattern();

  String format({String suffix = 'Ks'}) => '${_fmt.format(amount)} $suffix';

  Money operator +(Money other) => Money(amount + other.amount);
  Money operator -(Money other) => Money(amount - other.amount);

  @override
  bool operator ==(Object other) => other is Money && other.amount == amount;

  @override
  int get hashCode => amount.hashCode;

  @override
  String toString() => 'Money($amount)';
}
