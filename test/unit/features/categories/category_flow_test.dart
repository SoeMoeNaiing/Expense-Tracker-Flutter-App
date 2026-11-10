import 'package:expense_tracker/core/utils/result.dart';
import 'package:expense_tracker/features/categories/data/datasources/category_local_datasource.dart';
import 'package:expense_tracker/features/categories/data/repositories/category_repository_impl.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/usecases/add_category.dart';
import 'package:expense_tracker/features/categories/domain/usecases/delete_category.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_db.dart';

void main() {
  test('add then delete a user category', () async {
    final appDb = await openTestDb();
    final repo = CategoryRepositoryImpl(CategoryLocalDataSource(appDb));

    final added = await AddCategory(repo)(
      name: 'Coffee',
      iconCode: CategoryIcons.palette.first.codePoint,
      colorHex: 0xFF7C5CFF,
    );
    expect(added, isA<Success<Category>>());
    final cat = (added as Success<Category>).value;
    expect(cat.name, 'Coffee');
    expect(cat.isDefault, false);

    final del = await DeleteCategory(repo)(id: cat.id!, isDefault: false);
    expect(del, isA<Success<void>>());

    await appDb.close();
  });

  test('cannot delete a default category', () async {
    final appDb = await openTestDb();
    final repo = CategoryRepositoryImpl(CategoryLocalDataSource(appDb));
    final r = await DeleteCategory(repo)(id: 1, isDefault: true);
    expect(r, isA<Failure<void>>());
    await appDb.close();
  });

  test('add rejects empty name', () async {
    final appDb = await openTestDb();
    final repo = CategoryRepositoryImpl(CategoryLocalDataSource(appDb));
    final r = await AddCategory(repo)(
      name: '   ',
      iconCode: 0,
      colorHex: 0xFF000000,
    );
    expect(r, isA<Failure<Category>>());
    await appDb.close();
  });
}
