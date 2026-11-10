import 'package:expense_tracker/core/utils/result.dart';
import 'package:expense_tracker/features/settings/data/backup_file_io.dart';

class FakeBackupFileIO implements BackupFileIO {
  String? lastWrittenContent;
  String? lastSuggestedName;
  String? nextImportContent;
  bool failWrite = false;

  @override
  Future<Result<void>> saveAndShareCsv(
    String content,
    String suggestedName,
  ) async {
    lastWrittenContent = content;
    lastSuggestedName = suggestedName;
    if (failWrite) return const Failure('write failed');
    return const Success(null);
  }

  @override
  Future<Result<String?>> pickCsv() async => Success(nextImportContent);
}
