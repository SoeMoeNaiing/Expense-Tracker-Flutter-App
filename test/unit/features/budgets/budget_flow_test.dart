import 'package:expense_tracker/core/database/app_database.dart';
import 'package:expense_tracker/core/database/schema.dart';
import 'package:expense_tracker/core/utils/result.dart';
import 'package:expense_tracker/features/budgets/data/datasources/budget_local_datasource.dart';
import 'package:expense_tracker/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/upsert_budget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_db.dart';

Future<int> _cat(AppDatabase appDb, String name) =>
    appDb.db.insert(Tables.categories, {
      CategoryCols.name: name,
      CategoryCols.iconCode: 0,
      CategoryCols.colorHex: 0xFFFF6B6B,
      CategoryCols.isDefault: 0,
      CategoryCols.createdAt: 0,
    });

void main() {
  test('upsert overall budget (insert then update)', () async {
    final appDb = await openTestDb();
    final repo = BudgetRepositoryImpl(BudgetLocalDataSource(appDb));

    final first = await repo.upsert(const Budget(amount: 100000));
    expect(first, isA<Success<Budget>>());
    final b1 = (first as Success<Budget>).value;
    expect(b1.isOverall, true);
    expect(b1.amount, 100000);

    final second = await repo.upsert(const Budget(amount: 150000));
    final b2 = (second as Success<Budget>).value;
    expect(b2.amount, 150000);
    expect(b2.id, b1.id);

    final all = (await repo.getAll() as Success<List<Budget>>).value;
    expect(all.length, 1);
    expect(all.single.amount, 150000);

    await appDb.close();
  });

  test('upsert category budget', () async {
    final appDb = await openTestDb();
    final repo = BudgetRepositoryImpl(BudgetLocalDataSource(appDb));
    final catId = await _cat(appDb, 'Food');

    final r = await repo.upsert(Budget(categoryId: catId, amount: 50000));
    expect(r, isA<Success<Budget>>());
    final b = (r as Success<Budget>).value;
    expect(b.categoryId, catId);
    expect(b.amount, 50000);

    await appDb.close();
  });

  test('overall + category budgets coexist', () async {
    final appDb = await openTestDb();
    final repo = BudgetRepositoryImpl(BudgetLocalDataSource(appDb));
    final catId = await _cat(appDb, 'Food');

    await repo.upsert(const Budget(amount: 200000));
    await repo.upsert(Budget(categoryId: catId, amount: 50000));

    final all = (await repo.getAll() as Success<List<Budget>>).value;
    expect(all.length, 2);
    expect(all.where((b) => b.isOverall).length, 1);
    expect(all.where((b) => !b.isOverall).length, 1);

    await appDb.close();
  });

  test('delete removes budget', () async {
    final appDb = await openTestDb();
    final repo = BudgetRepositoryImpl(BudgetLocalDataSource(appDb));
    final added = (await repo.upsert(
      const Budget(amount: 100000),
    ) as Success<Budget>).value;
    final del = await repo.delete(added.id!);
    expect(del, isA<Success<void>>());
    expect((await repo.getAll() as Success<List<Budget>>).value, isEmpty);
    await appDb.close();
  });

  test('deleting a category cascades to its budget', () async {
    final appDb = await openTestDb();
    final repo = BudgetRepositoryImpl(BudgetLocalDataSource(appDb));
    final catId = await _cat(appDb, 'Food');
    await repo.upsert(Budget(categoryId: catId, amount: 50000));

    await appDb.db.delete(
      Tables.categories,
      where: '${CategoryCols.id} = ?',
      whereArgs: [catId],
    );

    final all = (await repo.getAll() as Success<List<Budget>>).value;
    expect(all, isEmpty);

    await appDb.close();
  });

  test('UpsertBudget rejects amount <= 0', () async {
    final appDb = await openTestDb();
    final repo = BudgetRepositoryImpl(BudgetLocalDataSource(appDb));
    final uc = UpsertBudget(repo);
    expect(await uc(const Budget(amount: 0)), isA<Failure<Budget>>());
    expect(await uc(const Budget(amount: -100)), isA<Failure<Budget>>());
    await appDb.close();
  });
}
