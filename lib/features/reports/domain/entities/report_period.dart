enum ReportGranularity { week, month, year, custom }

/// Half-open range [from, to). Invalid periods (to <= from) throw
/// immediately — that's a programmer error, not a runtime condition.
class ReportPeriod {
  final DateTime from;
  final DateTime to;
  final ReportGranularity granularity;

  ReportPeriod._(this.from, this.to, this.granularity) {
    if (!to.isAfter(from)) {
      throw ArgumentError('ReportPeriod requires to > from');
    }
  }

  factory ReportPeriod.month(int year, int month) => ReportPeriod._(
    DateTime(year, month, 1),
    DateTime(year, month + 1, 1),
    ReportGranularity.month,
  );

  /// Week containing [ref], starting Monday 00:00 local.
  factory ReportPeriod.week(DateTime ref) {
    final midnight = DateTime(ref.year, ref.month, ref.day);
    final monday = midnight.subtract(Duration(days: ref.weekday - 1));
    return ReportPeriod._(
      monday,
      monday.add(const Duration(days: 7)),
      ReportGranularity.week,
    );
  }

  factory ReportPeriod.year(int year) => ReportPeriod._(
    DateTime(year, 1, 1),
    DateTime(year + 1, 1, 1),
    ReportGranularity.year,
  );

  factory ReportPeriod.custom(DateTime from, DateTime to) =>
      ReportPeriod._(from, to, ReportGranularity.custom);

  factory ReportPeriod.currentMonth({DateTime? now}) {
    final n = now ?? DateTime.now();
    return ReportPeriod.month(n.year, n.month);
  }

  int get dayCount => to.difference(from).inDays;

  @override
  bool operator ==(Object other) =>
      other is ReportPeriod &&
      other.from == from &&
      other.to == to &&
      other.granularity == granularity;

  @override
  int get hashCode => Object.hash(from, to, granularity);

  @override
  String toString() => 'ReportPeriod($from .. $to, ${granularity.name})';
}
