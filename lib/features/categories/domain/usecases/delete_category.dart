import '../../../../core/utils/result.dart';
import '../repositories/category_repository.dart';

class DeleteCategory {
  final CategoryRepository _repo;
  const DeleteCategory(this._repo);

  Future<Result<void>> call({required int id, required bool isDefault}) async {
    if (isDefault) return const Failure('Default categories cannot be deleted');
    if (id <= 0) return const Failure('Invalid category id');
    return _repo.delete(id);
  }
}
