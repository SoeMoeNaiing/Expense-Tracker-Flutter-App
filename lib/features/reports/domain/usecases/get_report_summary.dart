import '../../../../core/utils/result.dart';
import '../entities/report_period.dart';
import '../entities/report_summary.dart';
import '../repositories/report_repository.dart';

class GetReportSummary {
  final ReportRepository _repo;
  const GetReportSummary(this._repo);

  Future<Result<ReportSummary>> call(ReportPeriod period) =>
      _repo.getSummary(period);
}
