import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/result.dart';
import 'backup_file_io.dart';

class RealBackupFileIO implements BackupFileIO {
  const RealBackupFileIO();

  static const _csvGroup = XTypeGroup(
    label: 'CSV',
    extensions: ['csv'],
    mimeTypes: ['text/csv'],
  );

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
          subject: 'Zay CSV export',
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
      final file = await openFile(acceptedTypeGroups: [_csvGroup]);
      if (file == null) return const Success(null);
      final content = await file.readAsString();
      return Success(content);
    } catch (e) {
      return Failure('Failed to read file', error: e);
    }
  }
}
