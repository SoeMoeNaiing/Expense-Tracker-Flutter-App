import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../domain/entities/report_summary.dart';

class CategoryBars extends ConsumerWidget {
  final ReportSummary summary;
  const CategoryBars({super.key, required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // See CategoryDonut: ensure rebuild after categories load so
    // ref.read(categoryByIdProvider(...)) returns real data.
    ref.watch(categoriesProvider);
    final text = Theme.of(context).textTheme;
    final top = summary.topCategories(5);
    if (top.isEmpty) return const SizedBox.shrink();

    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final animDuration = reduceMotion ? Duration.zero : AppMotion.slow;

    final maxY =
        top.map((c) => c.amount).fold<int>(0, (a, b) => a > b ? a : b) * 1.15;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top categories', style: text.headlineMedium),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: maxY == 0 ? 100 : maxY.toDouble(),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(enabled: false),
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
                    reservedSize: 28,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= top.length) {
                        return const SizedBox.shrink();
                      }
                      final cat = ref.read(
                        categoryByIdProvider(top[i].categoryId),
                      );
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Icon(
                          cat?.icon ?? Icons.category,
                          size: 16,
                          color: cat?.color ?? AppColors.primary,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < top.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: top[i].amount.toDouble(),
                        width: 22,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppRadii.sm),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            (ref
                                        .read(
                                          categoryByIdProvider(
                                            top[i].categoryId,
                                          ),
                                        )
                                        ?.color ??
                                    AppColors.primary)
                                .withAlpha(140),
                            ref
                                    .read(
                                      categoryByIdProvider(top[i].categoryId),
                                    )
                                    ?.color ??
                                AppColors.primary,
                          ],
                        ),
                      ),
                    ],
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
