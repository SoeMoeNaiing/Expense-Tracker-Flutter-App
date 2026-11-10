import 'package:flutter/material.dart';

class Category {
  final int? id;
  final String name;
  final int iconCode;
  final int colorHex;
  final bool isDefault;

  const Category({
    this.id,
    required this.name,
    required this.iconCode,
    required this.colorHex,
    required this.isDefault,
  });

  IconData get icon => CategoryIcons.resolve(iconCode);
  Color get color => Color(colorHex);

  @override
  bool operator ==(Object other) =>
      other is Category &&
      other.id == id &&
      other.name == name &&
      other.iconCode == iconCode &&
      other.colorHex == colorHex &&
      other.isDefault == isDefault;

  @override
  int get hashCode => Object.hash(id, name, iconCode, colorHex, isDefault);
}

/// Const list of every icon categories are allowed to use. Being const
/// and referenced here keeps them safe from IconData tree-shaking in
/// release builds.
abstract final class CategoryIcons {
  static const List<IconData> palette = [
    Icons.restaurant,
    Icons.directions_car,
    Icons.shopping_bag,
    Icons.receipt_long,
    Icons.favorite,
    Icons.movie,
    Icons.more_horiz,
    Icons.work,
    Icons.school,
    Icons.fitness_center,
    Icons.flight,
    Icons.home,
    Icons.local_cafe,
    Icons.pets,
    Icons.category,
  ];

  static IconData resolve(int codePoint) {
    for (final icon in palette) {
      if (icon.codePoint == codePoint) return icon;
    }
    return Icons.category;
  }
}
