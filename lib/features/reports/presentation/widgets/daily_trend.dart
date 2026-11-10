import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../domain/entities/report_period.dart';
import '../../domain/entities/report_summary.dart';

class DailyTrend extends StatelessWidget {
  final ReportSummary summary;
  const DailyTrend({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final points = summary.filledDaily();
    if (points.isEmpty) return const SizedBox.shrink();

    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final animDuration = reduceMotion ? Duration.zero : AppMotion.slow;

    final maxY =
        points
            .map((p) => p.amount)
            .fold<int>(0, (a, b) => a > b ? a : b)
            .toDouble() *
        1.15;
    final spots = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].amount.toDouble()),
    ];

    final labelFmt = switch (summary.period.granularity) {
      ReportGranularity.week => DateFormat.E(),
      ReportGranularity.month => DateFormat.d(),
      ReportGranularity.year => DateFormat.MMM(),
      ReportGranularity.custom => DateFormat.MMMd(),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Daily trend', style: text.headlineMedium),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (points.length - 1).toDouble(),
              minY: 0,
              maxY: maxY == 0 ? 100 : maxY,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: points.length <= 7
                        ? 1
                        : (points.length / 4).ceilToDouble(),
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= points.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          labelFmt.format(points[i].day),
                          style: text.labelSmall?.copyWith(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.25,
                  color: AppColors.primary,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x507C5CFF), Color(0x007C5CFF)],
                    ),
                  ),
                ),
              ],
            ),
            duration: animDuration,
            curve: AppMotion.curveMedium,
          ),
        ),
      ],
    );
  }
}
