import '../../../../core/utils/result.dart';
import '../../domain/entities/category.dart';
import '../datasources/category_local_datasource.dart';
import '../mappers/category_mapper.dart';

class CategoryRepositoryImpl {
  final CategoryLocalDataSource _ds;
  const CategoryRepositoryImpl(this._ds);

  Future<Result<List<Category>>> getAll() async {
    try {
      final rows = await _ds.getAll();
      return Success(rows.map(CategoryMapper.toEntity).toList());
    } catch (e) {
      return Failure('Failed to load categories', error: e);
    }
  }
}
