import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/schema.dart';
import '../models/category_model.dart';

class CategoryLocalDataSource {
  final AppDatabase _appDb;
  const CategoryLocalDataSource(this._appDb);

  Database get _db => _appDb.db;

  Future<List<CategoryModel>> getAll() async {
    final rows = await _db.query(
      Tables.categories,
      orderBy: '${CategoryCols.id} ASC',
    );
    return rows.map(CategoryModel.fromMap).toList();
  }

  Future<int> insert(CategoryModel m) =>
      _db.insert(Tables.categories, m.toMap());
}
