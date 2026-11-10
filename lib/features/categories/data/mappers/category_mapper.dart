import '../../domain/entities/category.dart';
import '../models/category_model.dart';

abstract final class CategoryMapper {
  static Category toEntity(CategoryModel m) => Category(
    id: m.id,
    name: m.name,
    iconCode: m.iconCode,
    colorHex: m.colorHex,
    isDefault: m.isDefault,
  );

  static CategoryModel toModel(Category c) => CategoryModel(
    id: c.id,
    name: c.name,
    iconCode: c.iconCode,
    colorHex: c.colorHex,
    isDefault: c.isDefault,
    createdAtMs: DateTime.now().millisecondsSinceEpoch,
  );
}
