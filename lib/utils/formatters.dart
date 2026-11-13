import 'package:intl/intl.dart';

final NumberFormat _moneyFormat = NumberFormat('#,##0.##');
final DateFormat _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
final DateFormat _dayFormat = DateFormat('dd MMM yyyy');

String formatMoney(double amount) => '${_moneyFormat.format(amount)} Ks';

String formatDate(String iso) {
  final date = DateTime.tryParse(iso);
  return date == null ? iso : _dateFormat.format(date);
}

String formatDay(DateTime day) => _dayFormat.format(day);

/// Compact range label.
///   same day      → "14 Nov 2026"
///   same month    → "1 – 30 Nov 2026"
///   same year     → "1 Nov – 20 Dec 2026"
///   different yr  → "15 Dec 2025 – 15 Jan 2026"
String formatDateRange(DateTime from, DateTime to) {
  if (from.year == to.year && from.month == to.month) {
    if (from.day == to.day) return DateFormat('dd MMM yyyy').format(from);
    return '${from.day} – ${DateFormat('dd MMM yyyy').format(to)}';
  }
  if (from.year == to.year) {
    return '${DateFormat('d MMM').format(from)} – '
        '${DateFormat('d MMM yyyy').format(to)}';
  }
  return '${DateFormat('d MMM yyyy').format(from)} – '
      '${DateFormat('d MMM yyyy').format(to)}';
}
