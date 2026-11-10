import '../../../../core/utils/result.dart';
import '../../data/repositories/category_repository_impl.dart';

class DeleteCategory {
  final CategoryRepositoryImpl _repo;
  const DeleteCategory(this._repo);

  Future<Result<void>> call({required int id, required bool isDefault}) async {
    if (isDefault) return const Failure('Default categories cannot be deleted');
    if (id <= 0) return const Failure('Invalid category id');
    return _repo.delete(id);
  }
}
