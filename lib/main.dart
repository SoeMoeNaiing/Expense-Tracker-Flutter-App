import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/database/app_database.dart';
import 'core/di.dart';
import 'core/theme/app_colors.dart';
import 'features/categories/data/seed/seed_categories.dart';
import 'features/settings/data/backup_file_io.dart';
import 'features/settings/data/real_backup_file_io.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bgBase,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final appDb = await AppDatabase.open();
  await seedDefaultCategories(appDb);

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(appDb),
        backupFileIOProvider.overrideWithValue(const RealBackupFileIO()),
      ],
      child: const App(),
    ),
  );
}
