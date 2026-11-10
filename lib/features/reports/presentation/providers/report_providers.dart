import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di.dart';
import '../../../../core/utils/result.dart';
import '../../data/datasources/report_local_datasource.dart';
import '../../data/repositories/report_repository_impl.dart';
import '../../domain/entities/report_period.dart';
import '../../domain/entities/report_summary.dart';
import '../../domain/usecases/get_report_summary.dart';

final reportDataSourceProvider = Provider<ReportLocalDataSource>(
  (ref) => ReportLocalDataSource(ref.watch(appDatabaseProvider)),
);

final reportRepositoryProvider = Provider<ReportRepositoryImpl>(
  (ref) => ReportRepositoryImpl(ref.watch(reportDataSourceProvider)),
);

final getReportSummaryProvider = Provider(
  (ref) => GetReportSummary(ref.watch(reportRepositoryProvider)),
);

/// UI-held period selection. Defaults to the current month.
class ReportPeriodNotifier extends Notifier<ReportPeriod> {
  @override
  ReportPeriod build() => ReportPeriod.currentMonth();

  void select(ReportPeriod period) => state = period;
}

final reportPeriodProvider =
    NotifierProvider<ReportPeriodNotifier, ReportPeriod>(
      ReportPeriodNotifier.new,
    );

final reportSummaryProvider = FutureProvider<ReportSummary>((ref) async {
  final period = ref.watch(reportPeriodProvider);
  final result = await ref.watch(getReportSummaryProvider)(period);
  return switch (result) {
    Success(:final value) => value,
    Failure(:final message) => throw Exception(message),
  };
});
