import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/result.dart';
import 'backup_file_io.dart';

class RealBackupFileIO implements BackupFileIO {
  const RealBackupFileIO();

  @override
  Future<Result<void>> saveAndShareCsv(
    String content,
    String suggestedName,
  ) async {
    try {
      final tmp = await getTemporaryDirectory();
      final file = File('${tmp.path}/$suggestedName');
      await file.writeAsString(content);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/csv')],
          subject: 'Ledger CSV export',
        ),
      );
      return const Success(null);
    } catch (e) {
      return Failure('Failed to save file', error: e);
    }
  }

  @override
  Future<Result<String?>> pickCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result == null || result.files.isEmpty) {
        return const Success(null);
      }
      final path = result.files.single.path;
      if (path == null) {
        return const Failure('Could not read the selected file');
      }
      final content = await File(path).readAsString();
      return Success(content);
    } catch (e) {
      return Failure('Failed to read file', error: e);
    }
  }
}
