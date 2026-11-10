import 'package:sqflite/sqflite.dart' show DatabaseException;

import '../../../../core/utils/result.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_local_datasource.dart';
import '../mappers/category_mapper.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryLocalDataSource _ds;
  const CategoryRepositoryImpl(this._ds);

  @override
  Future<Result<List<Category>>> getAll() async {
    try {
      final rows = await _ds.getAll();
      return Success(rows.map(CategoryMapper.toEntity).toList());
    } catch (e) {
      return Failure('Failed to load categories', error: e);
    }
  }

  @override
  Future<Result<Category>> add(Category category) async {
    if (category.id != null) {
      return const Failure('Cannot add a category that already has an id');
    }
    try {
      final id = await _ds.insert(CategoryMapper.toModel(category));
      return Success(
        Category(
          id: id,
          name: category.name,
          iconCode: category.iconCode,
          colorHex: category.colorHex,
          isDefault: category.isDefault,
        ),
      );
    } on DatabaseException catch (e) {
      if (e.toString().toLowerCase().contains('unique')) {
        return const Failure('A category with that name already exists');
      }
      return Failure('Database error', error: e);
    }
  }

  @override
  Future<Result<void>> delete(int id) async {
    try {
      final affected = await _ds.delete(id);
      if (affected == 0) return const Failure('Category not found');
      return const Success(null);
    } on DatabaseException catch (e) {
      if (e.toString().toLowerCase().contains('foreign key')) {
        return const Failure('Cannot delete: expenses still use this category');
      }
      return Failure('Database error', error: e);
    }
  }
}
