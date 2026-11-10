import 'package:expense_tracker/core/utils/result.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';

class FakeCategoryRepository implements CategoryRepository {
  final List<Category> items;
  FakeCategoryRepository([List<Category>? initial]) : items = [...?initial];

  @override
  Future<Result<List<Category>>> getAll() async => Success([...items]);

  @override
  Future<Result<Category>> add(Category category) async {
    final saved = Category(
      id: items.length + 1,
      name: category.name,
      iconCode: category.iconCode,
      colorHex: category.colorHex,
      isDefault: category.isDefault,
    );
    items.add(saved);
    return Success(saved);
  }

  @override
  Future<Result<void>> delete(int id) async {
    items.removeWhere((c) => c.id == id);
    return const Success(null);
  }
}
