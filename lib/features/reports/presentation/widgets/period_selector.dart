import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../domain/entities/report_period.dart';
import '../providers/report_providers.dart';

class PeriodSelector extends ConsumerWidget {
  const PeriodSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(reportPeriodProvider);
    return Row(
      children: [
        Expanded(
          child: _Chip(
            label: 'Week',
            selected: current.granularity == ReportGranularity.week,
            onTap: () => ref
                .read(reportPeriodProvider.notifier)
                .select(ReportPeriod.week(DateTime.now())),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Chip(
            label: 'Month',
            selected: current.granularity == ReportGranularity.month,
            onTap: () {
              final n = DateTime.now();
              ref
                  .read(reportPeriodProvider.notifier)
                  .select(ReportPeriod.month(n.year, n.month));
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Chip(
            label: 'Year',
            selected: current.granularity == ReportGranularity.year,
            onTap: () => ref
                .read(reportPeriodProvider.notifier)
                .select(ReportPeriod.year(DateTime.now().year)),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withAlpha(38)
              : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderSubtle,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: text.labelLarge?.copyWith(
            color: selected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
