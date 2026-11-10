import '../../../../core/utils/result.dart';
import '../entities/report_period.dart';
import '../entities/report_summary.dart';

abstract interface class ReportRepository {
  Future<Result<ReportSummary>> getSummary(ReportPeriod period);
}
