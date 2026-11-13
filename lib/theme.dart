import 'package:flutter/material.dart';

class AppColors {
  static const Color primary       = Color(0xFF6366F1);
  static const Color secondary     = Color(0xFF8B5CF6);
  static const Color accent        = Color(0xFF06B6D4);

  static const Color income        = Color(0xFF10B981);
  static const Color expense       = Color(0xFFEF4444);

  static const Color bg            = Color(0xFFF5F7FB);
  static const Color surface       = Colors.white;
  static const Color textPrimary   = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);

  static const LinearGradient balanceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
  );

  static const LinearGradient incomeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
  );

  static const LinearGradient expenseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF4444), Color(0xFFF87171)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );

  static const List<Color> chartPalette = [
    Color(0xFF6366F1), Color(0xFF10B981), Color(0xFFF59E0B),
    Color(0xFFEF4444), Color(0xFF06B6D4), Color(0xFF8B5CF6),
    Color(0xFFEC4899), Color(0xFF14B8A6), Color(0xFFF97316),
    Color(0xFF84CC16),
  ];

  static Color chartColor(int i) => chartPalette[i % chartPalette.length];
}

class AppShadows {
  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 20, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 10)),
  ];
  static List<BoxShadow> colored(Color c) => [
    BoxShadow(color: c.withAlpha(70), blurRadius: 20, offset: const Offset(0, 8)),
  ];
}

IconData categoryIcon(String category) {
  switch (category) {
    case 'Salary':    return Icons.work_rounded;
    case 'Business':  return Icons.storefront_rounded;
    case 'Gift':      return Icons.card_giftcard_rounded;
    case 'Food':      return Icons.restaurant_rounded;
    case 'Shopping':  return Icons.shopping_bag_rounded;
    case 'Transport': return Icons.directions_car_rounded;
    case 'Bills':     return Icons.receipt_long_rounded;
    default:          return Icons.category_rounded;
  }
}

const List<String> kIncomeCategories  = ['Salary', 'Business', 'Gift', 'Other'];
const List<String> kExpenseCategories = ['Food', 'Shopping', 'Transport', 'Bills', 'Other'];

/// Compact axis label: 1250000 → "1.3M", 42000 → "42K", 350 → "350".
String shortNumber(double v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000)    return '${(v / 1000).toStringAsFixed(0)}K';
  return v.toStringAsFixed(0);
}
