import '../../../../core/utils/result.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/domain/repositories/category_repository.dart';
import '../../data/csv/csv_codec.dart';
import '../entities/expense.dart';
import '../entities/import_summary.dart';
import '../entities/payment_method.dart';
import '../repositories/expense_repository.dart';

class ImportExpensesCsv {
  final ExpenseRepository _expenseRepo;
  final CategoryRepository _categoryRepo;

  const ImportExpensesCsv(this._expenseRepo, this._categoryRepo);

  /// Parses without inserting. The returned summary's `imported` field is
  /// the number of rows that *would* import.
  Future<Result<ImportSummary>> preview(String csv) async {
    final parsed = await _parseAll(csv);
    return switch (parsed) {
      Success(:final value) => Success(
        ImportSummary(imported: value.valid.length, errors: value.errors),
      ),
      Failure(:final message, :final error) => Failure(message, error: error),
    };
  }

  /// Parses + inserts valid rows atomically.
  /// Parses + inserts valid rows atomically.
  Future<Result<ImportSummary>> call(String csv) async {
    final parsed = await _parseAll(csv);
    switch (parsed) {
      case Failure(:final message, :final error):
        return Failure(message, error: error);
      case Success(:final value):
        if (value.valid.isNotEmpty) {
          final insert = await _expenseRepo.addMany(value.valid);
          if (insert.isFailure) {
            return Failure(
              'Failed to insert rows: ${insert.messageOrNull ?? 'unknown'}',
            );
          }
        }
        return Success(
          ImportSummary(imported: value.valid.length, errors: value.errors),
        );
    }
  }

  Future<Result<({List<Expense> valid, List<String> errors})>> _parseAll(
    String csv,
  ) async {
    final rows = CsvCodec.parseRows(csv);
    if (rows.isEmpty) return const Failure('CSV is empty');

    final header = rows[0];
    for (final col in CsvCodec.requiredColumns) {
      if (!header.contains(col)) {
        return Failure('Missing required column: "$col"');
      }
    }
    final colIdx = {for (var i = 0; i < header.length; i++) header[i]: i};

    final catResult = await _categoryRepo.getAll();
    if (catResult.isFailure) {
      return const Failure('Failed to load categories');
    }
    final nameToId = <String, int>{
      for (final c in catResult.valueOrNull ?? const <Category>[])
        if (c.id != null) c.name: c.id!,
    };

    final valid = <Expense>[];
    final errors = <String>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      final lineNo = i + 1;
      if (row.length < header.length) {
        errors.add(
          'Line $lineNo: expected ${header.length} columns, got ${row.length}',
        );
        continue;
      }
      final record = <String, String>{
        for (final k in colIdx.keys) k: row[colIdx[k]!],
      };
      final parsed = _parseRecord(record, nameToId);
      switch (parsed) {
        case Success(:final value):
          valid.add(value);
        case Failure(:final message):
          errors.add('Line $lineNo: $message');
      }
    }

    return Success((valid: valid, errors: errors));
  }

  Result<Expense> _parseRecord(
    Map<String, String> r,
    Map<String, int> nameToId,
  ) {
    final dateStr = r['date']?.trim() ?? '';
    final parts = dateStr.split('-');
    if (parts.length != 3) {
      return const Failure('Invalid date (expected YYYY-MM-DD)');
    }
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) {
      return const Failure('Invalid date (expected YYYY-MM-DD)');
    }
    final occurredAt = DateTime(y, m, d);
    if (occurredAt.year != y || occurredAt.month != m || occurredAt.day != d) {
      return const Failure('Invalid date (out of range)');
    }

    final amount = int.tryParse(r['amount']?.trim() ?? '');
    if (amount == null || amount <= 0) {
      return const Failure('Invalid amount (must be a positive integer)');
    }

    final categoryName = r['category']?.trim() ?? '';
    final categoryId = nameToId[categoryName];
    if (categoryId == null) {
      return Failure('Unknown category: "$categoryName"');
    }

    final pmRaw = r['payment_method']?.trim() ?? '';
    final pm = PaymentMethod.tryParse(pmRaw);
    if (pm == null) {
      return Failure(
        'Invalid payment_method "$pmRaw" (expected cash|card|bank|other)',
      );
    }

    final noteRaw = r['note']?.trim() ?? '';
    final note = noteRaw.isEmpty ? null : noteRaw;

    return Success(
      Expense.draft(
        amount: amount,
        categoryId: categoryId,
        occurredAt: occurredAt,
        paymentMethod: pm,
        note: note,
      ),
    );
  }
}
