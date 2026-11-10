import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:expense_tracker/core/database/app_database.dart';

/// Opens a fresh in-memory database for a single test.
/// Each call returns an independent DB — no shared state between tests.
Future<AppDatabase> openTestDb() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  return AppDatabase.openAt(inMemoryDatabasePath);
}
