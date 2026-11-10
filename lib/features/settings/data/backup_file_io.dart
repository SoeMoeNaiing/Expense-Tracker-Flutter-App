import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/result.dart';

/// Abstracts the platform file system so screens can be tested with a
/// fake. In production this hits the real share sheet / file picker.
abstract interface class BackupFileIO {
  /// Writes [content] to a temp file and opens the OS share sheet.
  /// [suggestedName] is the default file name shown to the user.
  Future<Result<void>> saveAndShareCsv(String content, String suggestedName);

  /// Opens the OS file picker. Returns Success(null) if the user
  /// cancelled, Success(text) with the file content, or Failure.
  Future<Result<String?>> pickCsv();
}

/// The concrete implementation is installed in `main.dart` via override.
final backupFileIOProvider = Provider<BackupFileIO>(
  (_) => throw UnimplementedError('backupFileIOProvider must be overridden'),
);
