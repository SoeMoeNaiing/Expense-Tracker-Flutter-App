import 'package:flutter/material.dart';

enum PaymentMethod {
  cash('cash', 'Cash', Icons.payments_outlined),
  card('card', 'Card', Icons.credit_card),
  bank('bank', 'Bank', Icons.account_balance_outlined),
  other('other', 'Other', Icons.more_horiz);

  final String dbValue;
  final String label;
  final IconData icon;
  const PaymentMethod(this.dbValue, this.label, this.icon);

  /// Lenient: unknown values fall back to cash. Use [tryParse] when you
  /// need to distinguish "was cash" from "unknown".
  static PaymentMethod fromDb(String? v) => tryParse(v) ?? cash;

  static PaymentMethod? tryParse(String? v) {
    for (final m in values) {
      if (m.dbValue == v) return m;
    }
    return null;
  }
}
