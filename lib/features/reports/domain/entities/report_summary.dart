import 'report_period.dart';

class CategorySlice {
  final int categoryId;
  final int amount;
  final int count;

  const CategorySlice({
    required this.categoryId,
    required this.amount,
    required this.count,
  });

  @override
  bool operator ==(Object other) =>
      other is CategorySlice &&
      other.categoryId == categoryId &&
      other.amount == amount &&
      other.count == count;

  @override
  int get hashCode => Object.hash(categoryId, amount, count);

  @override
  String toString() => 'CategorySlice($categoryId: $amount x$count)';
}

class DailyPoint {
  final DateTime day;
  final int amount;
  final int count;

  const DailyPoint({
    required this.day,
    required this.amount,
    required this.count,
  });

  @override
  bool operator ==(Object other) =>
      other is DailyPoint &&
      other.day == day &&
      other.amount == amount &&
      other.count == count;

  @override
  int get hashCode => Object.hash(day, amount, count);

  @override
  String toString() => 'DailyPoint(${day.toIso8601String()}: $amount x$count)';
}

class ReportSummary {
  final ReportPeriod period;
  final int total;
  final int count;
  final List<CategorySlice> byCategory;
  final List<DailyPoint> daily;

  const ReportSummary({
    required this.period,
    required this.total,
    required this.count,
    required this.byCategory,
    required this.daily,
  });

  static ReportSummary empty(ReportPeriod period) => ReportSummary(
    period: period,
    total: 0,
    count: 0,
    byCategory: const [],
    daily: const [],
  );

  bool get isEmpty => count == 0;

  int get averagePerExpense => count == 0 ? 0 : total ~/ count;

  /// Every day in the period, filling missing days with zero.
  List<DailyPoint> filledDaily() {
    final map = <DateTime, DailyPoint>{for (final p in daily) p.day: p};
    final start = DateTime(
      period.from.year,
      period.from.month,
      period.from.day,
    );
    final end = DateTime(period.to.year, period.to.month, period.to.day);
    final out = <DailyPoint>[];
    var cur = start;
    while (cur.isBefore(end)) {
      out.add(map[cur] ?? DailyPoint(day: cur, amount: 0, count: 0));
      cur = cur.add(const Duration(days: 1));
    }
    return out;
  }

  List<CategorySlice> topCategories(int limit) =>
      byCategory.take(limit).toList(growable: false);

  @override
  String toString() =>
      'ReportSummary(total: $total, count: $count, '
      'cats: ${byCategory.length}, days: ${daily.length})';
}
