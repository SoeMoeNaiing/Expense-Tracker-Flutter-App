import 'package:expense_tracker/features/reports/domain/entities/report_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReportPeriod.month', () {
    test('spans month boundaries', () {
      final p = ReportPeriod.month(2026, 1);
      expect(p.from, DateTime(2026, 1, 1));
      expect(p.to, DateTime(2026, 2, 1));
      expect(p.granularity, ReportGranularity.month);
    });

    test('rolls over December', () {
      final p = ReportPeriod.month(2026, 12);
      expect(p.from, DateTime(2026, 12, 1));
      expect(p.to, DateTime(2027, 1, 1));
    });
  });

  group('ReportPeriod.week', () {
    test('Monday is the boundary', () {
      final p = ReportPeriod.week(DateTime(2026, 1, 5));
      expect(p.from, DateTime(2026, 1, 5));
      expect(p.to, DateTime(2026, 1, 12));
    });

    test('mid-week collapses to Monday', () {
      final p = ReportPeriod.week(DateTime(2026, 1, 8, 14, 30));
      expect(p.from, DateTime(2026, 1, 5));
      expect(p.to, DateTime(2026, 1, 12));
    });

    test('Sunday collapses to previous Monday', () {
      final p = ReportPeriod.week(DateTime(2026, 1, 11, 23, 59));
      expect(p.from, DateTime(2026, 1, 5));
      expect(p.to, DateTime(2026, 1, 12));
    });
  });

  group('ReportPeriod.year', () {
    test('spans calendar year', () {
      final p = ReportPeriod.year(2026);
      expect(p.from, DateTime(2026, 1, 1));
      expect(p.to, DateTime(2027, 1, 1));
    });
  });

  group('Validation', () {
    test('custom with to <= from throws', () {
      expect(
        () => ReportPeriod.custom(DateTime(2026, 2), DateTime(2026, 1)),
        throwsArgumentError,
      );
      expect(
        () => ReportPeriod.custom(DateTime(2026), DateTime(2026)),
        throwsArgumentError,
      );
    });
  });
}
