import '../../../../core/database/schema.dart';

class CategoryModel {
  final int? id;
  final String name;
  final int iconCode;
  final int colorHex;
  final bool isDefault;
  final int createdAtMs;

  const CategoryModel({
    this.id,
    required this.name,
    required this.iconCode,
    required this.colorHex,
    required this.isDefault,
    required this.createdAtMs,
  });

  Map<String, Object?> toMap() => {
    if (id != null) CategoryCols.id: id,
    CategoryCols.name: name,
    CategoryCols.iconCode: iconCode,
    CategoryCols.colorHex: colorHex,
    CategoryCols.isDefault: isDefault ? 1 : 0,
    CategoryCols.createdAt: createdAtMs,
  };

  factory CategoryModel.fromMap(Map<String, Object?> m) => CategoryModel(
    id: m[CategoryCols.id] as int?,
    name: m[CategoryCols.name] as String,
    iconCode: m[CategoryCols.iconCode] as int,
    colorHex: m[CategoryCols.colorHex] as int,
    isDefault: (m[CategoryCols.isDefault] as int) == 1,
    createdAtMs: m[CategoryCols.createdAt] as int,
  );
}
