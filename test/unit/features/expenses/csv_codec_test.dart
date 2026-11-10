import 'package:expense_tracker/features/expenses/data/csv/csv_codec.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/entities/payment_method.dart';
import 'package:flutter_test/flutter_test.dart';

Expense _e({
  int amount = 2500,
  int categoryId = 1,
  String? note,
  DateTime? occurredAt,
  PaymentMethod pm = PaymentMethod.cash,
}) => Expense(
  amount: amount,
  categoryId: categoryId,
  note: note,
  occurredAt: occurredAt ?? DateTime(2026, 1, 15),
  createdAt: DateTime(2026, 1, 15),
  paymentMethod: pm,
);

void main() {
  group('encode', () {
    test('empty list emits only header', () {
      final out = CsvCodec.encode(const [], const {});
      expect(out, 'date,category,amount,payment_method,note\n');
    });

    test('simple row', () {
      final out = CsvCodec.encode(
        [_e(amount: 2500, note: 'Lunch')],
        {1: 'Food'},
      );
      expect(
        out,
        'date,category,amount,payment_method,note\n'
        '2026-01-15,Food,2500,cash,Lunch\n',
      );
    });

    test('note with comma is quoted', () {
      final out = CsvCodec.encode([_e(note: 'Lunch, with tea')], {1: 'Food'});
      expect(out, contains('"Lunch, with tea"'));
    });

    test('note with quote is doubled inside quotes', () {
      final out = CsvCodec.encode([_e(note: 'He said "hi"')], {1: 'Food'});
      expect(out, contains('"He said ""hi"""'));
    });

    test('note with newline is quoted', () {
      final out = CsvCodec.encode([_e(note: 'line1\nline2')], {1: 'Food'});
      expect(out, contains('"line1\nline2"'));
    });

    test('unicode passes through', () {
      final out = CsvCodec.encode([_e(note: 'မြန်မာ ကျပ်')], {1: 'Food'});
      expect(out, contains('မြန်မာ ကျပ်'));
    });

    test('unknown category becomes "Unknown"', () {
      final out = CsvCodec.encode([_e(categoryId: 99)], const {});
      expect(out, contains(',Unknown,'));
    });

    test('card payment method emitted', () {
      final out = CsvCodec.encode([_e(pm: PaymentMethod.card)], {1: 'Food'});
      expect(out, contains(',card,'));
    });
  });

  group('parseRows', () {
    test('simple two-row CSV', () {
      final rows = CsvCodec.parseRows('a,b,c\n1,2,3\n4,5,6\n');
      expect(rows.length, 3);
      expect(rows[0], ['a', 'b', 'c']);
      expect(rows[1], ['1', '2', '3']);
      expect(rows[2], ['4', '5', '6']);
    });

    test('quoted comma stays one field', () {
      final rows = CsvCodec.parseRows('h1,h2\na,"b,c"\n');
      expect(rows[1], ['a', 'b,c']);
    });

    test('escaped quote inside quoted field', () {
      final rows = CsvCodec.parseRows('h1,h2\na,"He said ""hi"""\n');
      expect(rows[1], ['a', 'He said "hi"']);
    });

    test('quoted newline stays one row', () {
      final rows = CsvCodec.parseRows('h1,h2\na,"line1\nline2"\n');
      expect(rows.length, 2);
      expect(rows[1], ['a', 'line1\nline2']);
    });

    test('CRLF endings', () {
      final rows = CsvCodec.parseRows('a,b\r\n1,2\r\n3,4\r\n');
      expect(rows.length, 3);
      expect(rows[1], ['1', '2']);
    });

    test('blank lines skipped', () {
      final rows = CsvCodec.parseRows('a,b\n\n1,2\n\n');
      expect(rows.length, 2);
      expect(rows[1], ['1', '2']);
    });

    test('empty input returns empty', () {
      expect(CsvCodec.parseRows(''), isEmpty);
    });

    test('round-trip encode -> parse preserves note', () {
      final original = _e(note: 'He said "hi, \\"there\\""\nthen paused');
      final encoded = CsvCodec.encode([original], {1: 'Food'});
      final parsed = CsvCodec.parseRows(encoded);
      expect(parsed.length, 2); // header + 1 row
      expect(parsed[1][4], original.note); // note column
    });
  });
}
