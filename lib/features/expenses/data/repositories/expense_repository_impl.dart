import 'package:sqflite/sqflite.dart' show DatabaseException;

import '../../../../core/utils/result.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_local_datasource.dart';
import '../mappers/expense_mapper.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseLocalDataSource _ds;
  const ExpenseRepositoryImpl(this._ds);

  @override
  Future<Result<List<Expense>>> getAll() async {
    try {
      final rows = await _ds.getAll();
      return Success(rows.map(ExpenseMapper.toEntity).toList());
    } catch (e) {
      return Failure('Failed to load expenses', error: e);
    }
  }

  @override
  Future<Result<List<Expense>>> getBetween(DateTime from, DateTime to) async {
    try {
      final rows = await _ds.getBetween(
        from.millisecondsSinceEpoch,
        to.millisecondsSinceEpoch,
      );
      return Success(rows.map(ExpenseMapper.toEntity).toList());
    } catch (e) {
      return Failure('Failed to load expenses', error: e);
    }
  }

  @override
  Future<Result<Expense>> add(Expense draft) async {
    if (draft.id != null) {
      return const Failure('Cannot add an expense that already has an id');
    }
    try {
      final id = await _ds.insert(ExpenseMapper.toModel(draft));
      return Success(draft.withId(id));
    } on DatabaseException catch (e) {
      return Failure(_describeDbError(e), error: e);
    } catch (e) {
      return Failure('Unexpected error', error: e);
    }
  }

  @override
  Future<Result<Expense>> update(Expense existing) async {
    if (existing.id == null) {
      return const Failure('Cannot update an expense without an id');
    }
    try {
      final affected = await _ds.update(ExpenseMapper.toModel(existing));
      if (affected == 0) return const Failure('Expense not found');
      return Success(existing);
    } on DatabaseException catch (e) {
      return Failure(_describeDbError(e), error: e);
    } catch (e) {
      return Failure('Unexpected error', error: e);
    }
  }

  @override
  Future<Result<void>> delete(int id) async {
    try {
      final affected = await _ds.delete(id);
      if (affected == 0) return const Failure('Expense not found');
      return const Success(null);
    } catch (e) {
      return Failure('Unexpected error', error: e);
    }
  }

  String _describeDbError(DatabaseException e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('foreign key')) return 'Category does not exist';
    if (msg.contains('check constraint')) return 'Invalid amount';
    if (msg.contains('unique')) return 'Duplicate entry';
    return 'Database error';
  }

  @override
  Future<Result<List<Expense>>> addMany(List<Expense> drafts) async {
    if (drafts.any((d) => d.id != null)) {
      return const Failure('Cannot bulk-add expenses that already have ids');
    }
    if (drafts.isEmpty) return const Success([]);
    try {
      final models = drafts.map(ExpenseMapper.toModel).toList();
      final ids = await _ds.insertMany(models);
      return Success([
        for (var i = 0; i < drafts.length; i++) drafts[i].withId(ids[i]),
      ]);
    } on DatabaseException catch (e) {
      return Failure(_describeDbError(e), error: e);
    } catch (e) {
      return Failure('Unexpected error', error: e);
    }
  }
}
