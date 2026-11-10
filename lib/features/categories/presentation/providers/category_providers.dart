import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di.dart';
import '../../../../core/utils/result.dart';
import '../../data/datasources/category_local_datasource.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/entities/category.dart';

final categoryDataSourceProvider = Provider<CategoryLocalDataSource>(
  (ref) => CategoryLocalDataSource(ref.watch(appDatabaseProvider)),
);

final categoryRepositoryProvider = Provider<CategoryRepositoryImpl>(
  (ref) => CategoryRepositoryImpl(ref.watch(categoryDataSourceProvider)),
);

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final result = await ref.watch(categoryRepositoryProvider).getAll();
  return switch (result) {
    Success(:final value) => value,
    Failure(:final message) => throw Exception(message),
  };
});

final categoryByIdProvider = Provider.family<Category?, int>((ref, id) {
  final list = ref.watch(categoriesProvider).value ?? const [];
  for (final c in list) {
    if (c.id == id) return c;
  }
  return null;
});
