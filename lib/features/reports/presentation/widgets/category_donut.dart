import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/utils/money.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../domain/entities/report_summary.dart';

class CategoryDonut extends ConsumerWidget {
  final ReportSummary summary;
  const CategoryDonut({super.key, required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Subscribe so this rebuilds when categories finish loading.
    // Without this, ref.read(categoryByIdProvider(...)) inside the
    // legend would keep returning null on the first frame and the
    // legend would stay stuck on "Unknown".
    ref.watch(categoriesProvider);
    final text = Theme.of(context).textTheme;
    if (summary.byCategory.isEmpty) {
      return const SizedBox.shrink();
    }

    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final animDuration = reduceMotion ? Duration.zero : AppMotion.slow;

    // Take top 5 by amount, roll the rest into "Other".
    final slices = summary.byCategory.length > 5
        ? [
            ...summary.topCategories(5),
            CategorySlice(
              categoryId: -1,
              amount: summary.byCategory
                  .skip(5)
                  .fold<int>(0, (s, e) => s + e.amount),
              count: summary.byCategory
                  .skip(5)
                  .fold<int>(0, (s, e) => s + e.count),
            ),
          ]
        : summary.byCategory;

    Color colorFor(int catId) {
      if (catId == -1) return AppColors.textTertiary;
      final cat = ref.read(categoryByIdProvider(catId));
      return cat?.color ?? AppColors.primary;
    }

    IconData iconFor(int catId) {
      if (catId == -1) return Icons.more_horiz;
      final cat = ref.read(categoryByIdProvider(catId));
      return cat?.icon ?? Icons.category;
    }

    String nameFor(int catId) {
      if (catId == -1) return 'Other';
      final cat = ref.read(categoryByIdProvider(catId));
      return cat?.name ?? 'Unknown';
    }

    final total = summary.total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 68,
                  startDegreeOffset: -90,
                  borderData: FlBorderData(show: false),
                  pieTouchData: PieTouchData(enabled: false),
                  sections: [
                    for (final s in slices)
                      PieChartSectionData(
                        value: s.amount.toDouble(),
                        color: colorFor(s.categoryId),
                        radius: 32,
                        showTitle: total > 0 && s.amount / total > 0.08,
                        title:
                            '${((s.amount / (total == 0 ? 1 : total)) * 100).round()}%',
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
                duration: animDuration,
                curve: AppMotion.curveMedium,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total',
                    style: text.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Money(total).format(),
                    style: text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final s in slices)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colorFor(s.categoryId),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  iconFor(s.categoryId),
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    nameFor(s.categoryId),
                    style: text.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  Money(s.amount).format(),
                  style: text.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Text(
          '${NumberFormat.decimalPattern().format(summary.count)} expenses · '
          'avg ${Money(summary.averagePerExpense).format()}',
          style: text.labelSmall,
        ),
      ],
    );
  }
}
