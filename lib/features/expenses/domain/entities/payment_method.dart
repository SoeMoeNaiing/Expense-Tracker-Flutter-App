import 'package:flutter/material.dart';

/// How an expense was paid. `dbValue` is what lives in the DB; never
/// persist anything else.
enum PaymentMethod {
  cash('cash', 'Cash', Icons.payments_outlined),
  card('card', 'Card', Icons.credit_card),
  bank('bank', 'Bank', Icons.account_balance_outlined),
  other('other', 'Other', Icons.more_horiz);

  final String dbValue;
  final String label;
  final IconData icon;
  const PaymentMethod(this.dbValue, this.label, this.icon);

  static PaymentMethod fromDb(String? v) {
    for (final m in values) {
      if (m.dbValue == v) return m;
    }
    return cash;
  }
}
