import '../../../../core/utils/result.dart';
import '../entities/category.dart';
import '../../data/repositories/category_repository_impl.dart';

class AddCategory {
  final CategoryRepositoryImpl _repo;
  const AddCategory(this._repo);

  Future<Result<Category>> call({
    required String name,
    required int iconCode,
    required int colorHex,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return const Failure('Category name is required');
    if (trimmed.length > 40) return const Failure('Name too long (max 40)');
    final category = Category(
      name: trimmed,
      iconCode: iconCode,
      colorHex: colorHex,
      isDefault: false,
    );
    return _repo.add(category);
  }
}
