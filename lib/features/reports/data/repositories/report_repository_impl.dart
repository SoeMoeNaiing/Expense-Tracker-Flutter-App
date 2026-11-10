import '../../../../core/utils/result.dart';
import '../../domain/entities/report_period.dart';
import '../../domain/entities/report_summary.dart';
import '../../domain/repositories/report_repository.dart';
import '../datasources/report_local_datasource.dart';

class ReportRepositoryImpl implements ReportRepository {
  final ReportLocalDataSource _ds;
  const ReportRepositoryImpl(this._ds);

  @override
  Future<Result<ReportSummary>> getSummary(ReportPeriod period) async {
    try {
      final fromMs = period.from.millisecondsSinceEpoch;
      final toMs = period.to.millisecondsSinceEpoch;

      final totals = await _ds.totalForRange(fromMs, toMs);
      final categories = await _ds.categoryBreakdown(fromMs, toMs);
      final details = await _ds.detailRowsForRange(fromMs, toMs);

      // Bucket detail rows by local calendar day.
      final buckets = <DateTime, ({int amount, int count})>{};
      for (final d in details) {
        final dt = DateTime.fromMillisecondsSinceEpoch(d.occurredAtMs);
        final day = DateTime(dt.year, dt.month, dt.day);
        final prev = buckets[day] ?? (amount: 0, count: 0);
        buckets[day] = (amount: prev.amount + d.amount, count: prev.count + 1);
      }
      final sortedDays = buckets.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      final daily = sortedDays
          .map(
            (e) => DailyPoint(
              day: e.key,
              amount: e.value.amount,
              count: e.value.count,
            ),
          )
          .toList(growable: false);

      final byCategory = categories
          .map(
            (r) => CategorySlice(
              categoryId: r.categoryId,
              amount: r.amount,
              count: r.count,
            ),
          )
          .toList(growable: false);

      return Success(
        ReportSummary(
          period: period,
          total: totals.total,
          count: totals.count,
          byCategory: byCategory,
          daily: daily,
        ),
      );
    } catch (e) {
      return Failure('Failed to build report', error: e);
    }
  }
}
