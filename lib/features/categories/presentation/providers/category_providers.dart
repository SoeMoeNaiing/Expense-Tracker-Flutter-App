import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di.dart';
import '../../../../core/utils/result.dart';
import '../../data/datasources/category_local_datasource.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/usecases/add_category.dart';
import '../../domain/usecases/delete_category.dart';

final categoryDataSourceProvider = Provider<CategoryLocalDataSource>(
  (ref) => CategoryLocalDataSource(ref.watch(appDatabaseProvider)),
);

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepositoryImpl(ref.watch(categoryDataSourceProvider)),
);

final addCategoryProvider = Provider(
  (ref) => AddCategory(ref.watch(categoryRepositoryProvider)),
);
final deleteCategoryProvider = Provider(
  (ref) => DeleteCategory(ref.watch(categoryRepositoryProvider)),
);

class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    final result = await ref.watch(categoryRepositoryProvider).getAll();
    return switch (result) {
      Success(:final value) => value,
      Failure(:final message) => throw Exception(message),
    };
  }

  Future<Result<Category>> add({
    required String name,
    required int iconCode,
    required int colorHex,
  }) async {
    final result = await ref.read(addCategoryProvider)(
      name: name,
      iconCode: iconCode,
      colorHex: colorHex,
    );
    if (result is Success<Category>) {
      final current = state.value ?? const <Category>[];
      state = AsyncValue.data([...current, result.value]);
    }
    return result;
  }

  Future<Result<void>> delete(int id, {required bool isDefault}) async {
    final result = await ref.read(deleteCategoryProvider)(
      id: id,
      isDefault: isDefault,
    );
    if (result is Success<void>) {
      final current = state.value ?? const <Category>[];
      state = AsyncValue.data(
        current.where((c) => c.id != id).toList(growable: false),
      );
    }
    return result;
  }
}

final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<Category>>(
      CategoriesNotifier.new,
    );

final categoryByIdProvider = Provider.family<Category?, int>((ref, id) {
  final list = ref.watch(categoriesProvider).value ?? const [];
  for (final c in list) {
    if (c.id == id) return c;
  }
  return null;
});

final categoryNameMapProvider = Provider<Map<int, String>>((ref) {
  final list = ref.watch(categoriesProvider).value ?? const [];
  return {
    for (final c in list)
      if (c.id != null) c.id!: c.name,
  };
});
