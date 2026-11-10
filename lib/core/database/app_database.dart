import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'migrations.dart';

class AppDatabase {
  final Database db;
  const AppDatabase._(this.db);

  static const String _fileName = 'ledger.db';

  /// Production entry point: opens in the app documents directory.
  static Future<AppDatabase> open() async {
    final docs = await getApplicationDocumentsDirectory();
    return openAt(p.join(docs.path, _fileName));
  }

  /// Opens at an explicit path. Shared by [open] (prod) and the test
  /// harness (which passes `:memory:` after configuring the ffi factory).
  static Future<AppDatabase> openAt(String path) async {
    final db = await openDatabase(
      path,
      version: Migrations.version,
      onCreate: Migrations.onCreate,
      onUpgrade: Migrations.onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
    return AppDatabase._(db);
  }

  Future<void> close() => db.close();
}
