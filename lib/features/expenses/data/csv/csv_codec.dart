import '../../domain/entities/expense.dart';

/// Pure RFC 4180 codec for the expense CSV format.
///
/// Format spec:
///   header: date,category,amount,payment_method,note
///   date: YYYY-MM-DD (local calendar day — time-of-day is dropped on
///         import; use this format if you don't care about time fidelity)
///   amount: positive integer MMK
///   payment_method: cash | card | bank | other
///   note: RFC 4180 — quoted if it contains comma, quote, or newline
abstract final class CsvCodec {
  static const List<String> requiredColumns = [
    'date',
    'category',
    'amount',
    'payment_method',
    'note',
  ];

  /// Encodes expenses to CSV. `categoryNames` maps category ids to names
  /// so we emit names (human-readable) rather than numeric foreign keys.
  static String encode(List<Expense> expenses, Map<int, String> categoryNames) {
    final buf = StringBuffer()..writeln(requiredColumns.join(','));
    for (final e in expenses) {
      buf.writeln(
        [
          _isoDate(e.occurredAt),
          _escape(categoryNames[e.categoryId] ?? 'Unknown'),
          e.amount.toString(),
          e.paymentMethod.dbValue,
          _escape(e.note ?? ''),
        ].join(','),
      );
    }
    return buf.toString();
  }

  static String _isoDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  static String _escape(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  /// Splits CSV text into rows. Handles quoted fields, doubled quotes,
  /// `\r\n` and `\n` line endings, and skips fully-empty lines.
  static List<List<String>> parseRows(String input) {
    final rows = <List<String>>[];
    final fields = <String>[];
    final field = StringBuffer();
    bool inQuotes = false;
    bool fieldStarted = false;

    void endField() {
      fields.add(field.toString());
      field.clear();
      fieldStarted = false;
    }

    void endRow() {
      endField();
      // Skip blank lines.
      if (fields.length == 1 && fields[0].isEmpty) {
        fields.clear();
        return;
      }
      rows.add(List.of(fields));
      fields.clear();
    }

    for (var i = 0; i < input.length; i++) {
      final c = input[i];
      if (inQuotes) {
        if (c == '"') {
          if (i + 1 < input.length && input[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(c);
        }
      } else {
        if (c == '"' && !fieldStarted) {
          inQuotes = true;
          fieldStarted = true;
        } else if (c == ',') {
          endField();
        } else if (c == '\r') {
          if (i + 1 < input.length && input[i + 1] == '\n') i++;
          endRow();
        } else if (c == '\n') {
          endRow();
        } else {
          field.write(c);
          fieldStarted = true;
        }
      }
    }
    if (field.isNotEmpty || fields.isNotEmpty) endRow();
    return rows;
  }
}
