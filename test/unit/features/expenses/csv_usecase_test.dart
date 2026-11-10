import 'package:expense_tracker/core/database/app_database.dart';
import 'package:expense_tracker/core/database/schema.dart';
import 'package:expense_tracker/core/utils/result.dart';
import 'package:expense_tracker/features/categories/data/datasources/category_local_datasource.dart';
import 'package:expense_tracker/features/categories/data/repositories/category_repository_impl.dart';
import 'package:expense_tracker/features/expenses/data/datasources/expense_local_datasource.dart';
import 'package:expense_tracker/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/entities/import_summary.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/export_expenses_csv.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/import_expenses_csv.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_db.dart';

Future<int> _seedCategory(AppDatabase db, String name) =>
    db.db.insert(Tables.categories, {
      CategoryCols.name: name,
      CategoryCols.iconCode: 0,
      CategoryCols.colorHex: 0xFFFF6B6B,
      CategoryCols.isDefault: 0,
      CategoryCols.createdAt: 0,
    });

void main() {
  late AppDatabase appDb;
  late ExpenseRepositoryImpl expRepo;
  late CategoryRepositoryImpl catRepo;

  setUp(() async {
    appDb = await openTestDb();
    expRepo = ExpenseRepositoryImpl(ExpenseLocalDataSource(appDb));
    catRepo = CategoryRepositoryImpl(CategoryLocalDataSource(appDb));
  });

  tearDown(() => appDb.close());

  group('ExportExpensesCsv', () {
    test('empty DB yields header-only CSV', () async {
      final r = await ExportExpensesCsv(expRepo, catRepo)();
      expect(r, isA<Success<String>>());
      expect(
        (r as Success<String>).value.trim(),
        'date,category,amount,payment_method,note',
      );
    });

    test('fixture yields correct rows', () async {
      final foodId = await _seedCategory(appDb, 'Food');
      await expRepo.add(
        Expense.draft(
          amount: 2500,
          categoryId: foodId,
          occurredAt: DateTime(2026, 1, 15),
          note: 'Lunch',
        ),
      );
      final r = await ExportExpensesCsv(expRepo, catRepo)();
      final csv = (r as Success<String>).value;
      expect(csv, contains('2026-01-15,Food,2500,cash,Lunch'));
    });
  });

  group('ImportExpensesCsv', () {
    test('imports all valid rows', () async {
      await _seedCategory(appDb, 'Food');
      await _seedCategory(appDb, 'Transport');
      const csv =
          'date,category,amount,payment_method,note\n'
          '2026-01-15,Food,2500,cash,Lunch\n'
          '2026-01-16,Transport,500,card,Taxi\n';
      final r = await ImportExpensesCsv(expRepo, catRepo)(csv);
      expect(r, isA<Success<ImportSummary>>());
      final s = (r as Success<ImportSummary>).value;
      expect(s.imported, 2);
      expect(s.errors, isEmpty);

      final all = (await expRepo.getAll() as Success<List<Expense>>).value;
      expect(all.length, 2);
    });

    test('reports bad-date row but imports the rest', () async {
      await _seedCategory(appDb, 'Food');
      const csv =
          'date,category,amount,payment_method,note\n'
          'BAD-DATE,Food,100,cash,\n'
          '2026-01-15,Food,2500,cash,Lunch\n';
      final r = await ImportExpensesCsv(expRepo, catRepo)(csv);
      final s = (r as Success<ImportSummary>).value;
      expect(s.imported, 1);
      expect(s.failed, 1);
      expect(s.errors.single, contains('Invalid date'));
    });

    test('reports unknown category', () async {
      await _seedCategory(appDb, 'Food');
      const csv =
          'date,category,amount,payment_method,note\n'
          '2026-01-15,Ghost,100,cash,\n';
      final r = await ImportExpensesCsv(expRepo, catRepo)(csv);
      final s = (r as Success<ImportSummary>).value;
      expect(s.imported, 0);
      expect(s.errors.single, contains('Unknown category'));
    });

    test('reports invalid payment_method', () async {
      await _seedCategory(appDb, 'Food');
      const csv =
          'date,category,amount,payment_method,note\n'
          '2026-01-15,Food,100,bitcoin,\n';
      final r = await ImportExpensesCsv(expRepo, catRepo)(csv);
      final s = (r as Success<ImportSummary>).value;
      expect(s.failed, 1);
      expect(s.errors.single, contains('payment_method'));
    });

    test('rejects CSV missing a required column', () async {
      const csv =
          'date,category,amount\n'
          '2026-01-15,Food,100\n';
      final r = await ImportExpensesCsv(expRepo, catRepo)(csv);
      expect(r, isA<Failure<ImportSummary>>());
      expect(
        (r as Failure<ImportSummary>).message,
        contains('Missing required column'),
      );
    });

    test('rejects empty CSV', () async {
      final r = await ImportExpensesCsv(expRepo, catRepo)('');
      expect(r, isA<Failure<ImportSummary>>());
    });

    test('full round-trip: export then import preserves data', () async {
      final foodId = await _seedCategory(appDb, 'Food');
      await expRepo.add(
        Expense.draft(
          amount: 2500,
          categoryId: foodId,
          occurredAt: DateTime(2026, 1, 15),
          note: 'Lunch',
        ),
      );
      await expRepo.add(
        Expense.draft(
          amount: 800,
          categoryId: foodId,
          occurredAt: DateTime(2026, 1, 16),
          note: 'Snack',
        ),
      );

      final csv =
          (await ExportExpensesCsv(expRepo, catRepo)() as Success<String>)
              .value;

      // Wipe and re-import.
      await appDb.db.delete(Tables.expenses);
      final r = await ImportExpensesCsv(expRepo, catRepo)(csv);
      final s = (r as Success<ImportSummary>).value;
      expect(s.imported, 2);
      expect(s.errors, isEmpty);

      final all = (await expRepo.getAll() as Success<List<Expense>>).value;
      final amounts = all.map((e) => e.amount).toSet();
      final notes = all.map((e) => e.note).toSet();
      expect(amounts, {2500, 800});
      expect(notes, {'Lunch', 'Snack'});
    });
  });
}
