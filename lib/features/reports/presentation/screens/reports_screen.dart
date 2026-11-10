import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/animated_counter.dart';
import '../../../../core/widgets/mesh_background.dart';
import '../../domain/entities/report_period.dart';
import '../providers/report_providers.dart';
import '../widgets/category_bars.dart';
import '../widgets/category_donut.dart';
import '../widgets/daily_trend.dart';
import '../widgets/period_selector.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final summaryAsync = ref.watch(reportSummaryProvider);
    final period = ref.watch(reportPeriodProvider);

    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.bgRaised,
            onRefresh: () async => ref.invalidate(reportSummaryProvider),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 4),
                        Text('Reports', style: text.headlineLarge),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_periodLabel(period), style: text.labelSmall),
                        const SizedBox(height: 6),
                        summaryAsync.when(
                          loading: () => Text(
                            '...',
                            style: text.displayLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          error: (e, _) => Text(
                            'Error',
                            style: text.displayLarge?.copyWith(
                              color: AppColors.coral,
                            ),
                          ),
                          data: (s) => ShaderMask(
                            shaderCallback: (b) =>
                                AppGradients.moneyText.createShader(b),
                            child: AnimatedCounter(
                              value: s.total,
                              formatter: (v) => Money(v).format(),
                              style: text.displayLarge?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const PeriodSelector(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                summaryAsync.when(
                  loading: () => const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  error: (e, _) => SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'Failed to load report',
                        style: text.bodyMedium,
                      ),
                    ),
                  ),
                  data: (s) => s.isEmpty
                      ? const SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyState(),
                        )
                      : SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _GlassCard(child: CategoryDonut(summary: s)),
                                const SizedBox(height: 16),
                                _GlassCard(child: DailyTrend(summary: s)),
                                const SizedBox(height: 16),
                                _GlassCard(child: CategoryBars(summary: s)),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _periodLabel(ReportPeriod p) {
    switch (p.granularity) {
      case ReportGranularity.week:
        final end = p.to.subtract(const Duration(days: 1));
        return 'Week of ${DateFormat.MMMd().format(p.from)} '
            '– ${DateFormat.MMMd().format(end)}';
      case ReportGranularity.month:
        return DateFormat.yMMMM().format(p.from);
      case ReportGranularity.year:
        return DateFormat.y().format(p.from);
      case ReportGranularity.custom:
        return '${DateFormat.yMMMd().format(p.from)} – '
            '${DateFormat.yMMMd().format(p.to)}';
    }
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.glass,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: child,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppGradients.glass,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(38),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: const Icon(Icons.insights, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('No data for this period', style: text.bodyLarge),
                      const SizedBox(height: 2),
                      Text(
                        'Add expenses or pick another range',
                        style: text.labelSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
