import 'package:expense_tracker/core/database/app_database.dart';
import 'package:expense_tracker/core/database/schema.dart';
import 'package:expense_tracker/core/utils/result.dart';
import 'package:expense_tracker/features/expenses/data/datasources/expense_local_datasource.dart';
import 'package:expense_tracker/features/expenses/data/mappers/expense_mapper.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/add_expense.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/delete_expense.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/get_expenses.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/update_expense.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_db.dart';

Future<int> _seedCategory(AppDatabase appDb, {String name = 'Food'}) async {
  return appDb.db.insert(Tables.categories, {
    CategoryCols.name: name,
    CategoryCols.iconCode: 0,
    CategoryCols.colorHex: 0xFFFF6B6B,
    CategoryCols.isDefault: 0,
    CategoryCols.createdAt: 0,
  });
}

void main() {
  late AppDatabase appDb;
  late ExpenseLocalDataSource ds;
  late ExpenseRepositoryImpl repo;

  setUp(() async {
    appDb = await openTestDb();
    ds = ExpenseLocalDataSource(appDb);
    repo = ExpenseRepositoryImpl(ds);
  });

  tearDown(() => appDb.close());

  group('ExpenseMapper', () {
    test('entity -> model -> entity round-trip', () {
      // Local datetime with zero microseconds round-trips through millis.
      final original = Expense(
        id: 7,
        amount: 2500,
        categoryId: 3,
        note: 'Lunch',
        occurredAt: DateTime(2026, 1, 15, 12, 30),
        createdAt: DateTime(2026, 1, 15, 12, 35),
      );
      final roundTripped = ExpenseMapper.toEntity(
        ExpenseMapper.toModel(original),
      );
      expect(roundTripped, original);
    });

    test('null note survives round-trip', () {
      final original = Expense(
        id: 1,
        amount: 100,
        categoryId: 1,
        note: null,
        occurredAt: DateTime(2026),
        createdAt: DateTime(2026),
      );
      final rt = ExpenseMapper.toEntity(ExpenseMapper.toModel(original));
      expect(rt.note, isNull);
    });

    test('null id survives round-trip (draft)', () {
      final draft = Expense.draft(amount: 100, categoryId: 1);
      final model = ExpenseMapper.toModel(draft);
      expect(model.id, isNull);
      expect(ExpenseMapper.toEntity(model).id, isNull);
    });
  });

  group('ExpenseLocalDataSource', () {
    test('insert + getAll returns row', () async {
      final catId = await _seedCategory(appDb);
      final id = await ds.insert(
        ExpenseModel(
          amount: 2500,
          categoryId: catId,
          note: 'Lunch',
          occurredAtMs: 1000,
          createdAtMs: 1000,
        ),
      );
      expect(id, greaterThan(0));
      final rows = await ds.getAll();
      expect(rows.single.amount, 2500);
    });

    test(
      'getBetween filters by occurredAt (inclusive start, exclusive end)',
      () async {
        final catId = await _seedCategory(appDb);
        for (final ms in [500, 1000, 1500, 2000]) {
          await ds.insert(
            ExpenseModel(
              amount: ms,
              categoryId: catId,
              note: null,
              occurredAtMs: ms,
              createdAtMs: 0,
            ),
          );
        }
        final rows = await ds.getBetween(1000, 2000);
        expect(rows.map((r) => r.amount).toSet(), {1000, 1500});
      },
    );

    test('update modifies row', () async {
      final catId = await _seedCategory(appDb);
      final id = await ds.insert(
        ExpenseModel(
          amount: 100,
          categoryId: catId,
          note: 'old',
          occurredAtMs: 0,
          createdAtMs: 0,
        ),
      );
      final affected = await ds.update(
        ExpenseModel(
          id: id,
          amount: 999,
          categoryId: catId,
          note: 'new',
          occurredAtMs: 0,
          createdAtMs: 0,
        ),
      );
      expect(affected, 1);
      final row = (await ds.getAll()).single;
      expect(row.amount, 999);
      expect(row.note, 'new');
    });

    test('delete removes row', () async {
      final catId = await _seedCategory(appDb);
      final id = await ds.insert(
        ExpenseModel(
          amount: 100,
          categoryId: catId,
          note: null,
          occurredAtMs: 0,
          createdAtMs: 0,
        ),
      );
      expect(await ds.delete(id), 1);
      expect(await ds.getAll(), isEmpty);
    });
  });

  group('ExpenseRepositoryImpl', () {
    test('add persists and returns entity with id', () async {
      final catId = await _seedCategory(appDb);
      final draft = Expense.draft(
        amount: 2500,
        categoryId: catId,
        note: 'Lunch',
      );
      final result = await repo.add(draft);
      expect(result, isA<Success<Expense>>());
      final saved = (result as Success<Expense>).value;
      expect(saved.id, isNotNull);
      expect(saved.amount, 2500);
    });

    test('add with nonexistent category -> Failure', () async {
      final draft = Expense.draft(amount: 100, categoryId: 999);
      final result = await repo.add(draft);
      expect(result, isA<Failure<Expense>>());
      expect(
        (result as Failure<Expense>).message.toLowerCase(),
        contains('category'),
      );
    });

    test('add with existing id -> Failure', () async {
      final catId = await _seedCategory(appDb);
      final draft = Expense.draft(amount: 100, categoryId: catId).withId(5);
      final result = await repo.add(draft);
      expect(result, isA<Failure<Expense>>());
    });

    test('getAll returns empty list initially', () async {
      final result = await repo.getAll();
      expect((result as Success<List<Expense>>).value, isEmpty);
    });

    test('delete nonexistent -> Failure', () async {
      final result = await repo.delete(999);
      expect(result, isA<Failure<void>>());
    });
  });

  group('UseCases', () {
    test('AddExpense rejects amount <= 0', () async {
      final catId = await _seedCategory(appDb);
      final uc = AddExpense(repo);
      final r1 = await uc(Expense.draft(amount: 0, categoryId: catId));
      expect(r1, isA<Failure<Expense>>());
      final r2 = await uc(Expense.draft(amount: -100, categoryId: catId));
      expect(r2, isA<Failure<Expense>>());
    });

    test('AddExpense rejects > 500 char note', () async {
      final catId = await _seedCategory(appDb);
      final draft = Expense.draft(
        amount: 100,
        categoryId: catId,
        note: 'x' * 501,
      );
      final r = await AddExpense(repo)(draft);
      expect(r, isA<Failure<Expense>>());
    });

    test('AddExpense succeeds for valid draft', () async {
      final catId = await _seedCategory(appDb);
      final draft = Expense.draft(amount: 2500, categoryId: catId, note: 'ok');
      final r = await AddExpense(repo)(draft);
      expect(r, isA<Success<Expense>>());
    });

    test('UpdateExpense round-trip', () async {
      final catId = await _seedCategory(appDb);
      final added = await AddExpense(repo)(
        Expense.draft(amount: 100, categoryId: catId),
      );
      final saved = (added as Success<Expense>).value;
      final updated = Expense(
        id: saved.id,
        amount: 500,
        categoryId: catId,
        note: 'updated',
        occurredAt: saved.occurredAt,
        createdAt: saved.createdAt,
      );
      final r = await UpdateExpense(repo)(updated);
      expect(r, isA<Success<Expense>>());
      final list = (await repo.getAll() as Success<List<Expense>>).value;
      expect(list.single.amount, 500);
      expect(list.single.note, 'updated');
    });

    test('GetExpenses returns all when no range', () async {
      final catId = await _seedCategory(appDb);
      await AddExpense(repo)(Expense.draft(amount: 100, categoryId: catId));
      final r = await GetExpenses(repo)();
      expect((r as Success<List<Expense>>).value.length, 1);
    });

    test('GetExpenses rejects inverted range', () async {
      final r = await GetExpenses(repo)(
        from: DateTime(2026, 2),
        to: DateTime(2026, 1),
      );
      expect(r, isA<Failure<List<Expense>>>());
    });

    test('DeleteExpense rejects invalid id', () async {
      final r = await DeleteExpense(repo)(0);
      expect(r, isA<Failure<void>>());
    });
  });
}
