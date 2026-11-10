import '../../../../core/utils/result.dart';
import '../entities/category.dart';

abstract interface class CategoryRepository {
  Future<Result<List<Category>>> getAll();
  Future<Result<Category>> add(Category category);
  Future<Result<void>> delete(int id);
}
