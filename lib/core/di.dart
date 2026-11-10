import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database/app_database.dart';

/// Overridden in `main.dart` with the real opened database.
/// Tests override it with an in-memory `AppDatabase.openAt(inMemoryDatabasePath)`.
final appDatabaseProvider = Provider<AppDatabase>(
  (_) => throw UnimplementedError('appDatabaseProvider must be overridden'),
);
