import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/mesh_background.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../domain/entities/budget_progress.dart';
import '../providers/budget_providers.dart';
import '../widgets/budget_color.dart';
import '../widgets/budget_ring.dart';
import '../widgets/edit_budget_sheet.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final budgets = ref.watch(budgetsProvider);
    final progress = ref.watch(budgetProgressProvider);

    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: Container(
          decoration: BoxDecoration(
            gradient: AppGradients.fab,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(85),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              onTap: () => EditBudgetSheet.show(context),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Icon(Icons.add, color: Colors.white, size: 22),
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 24, 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 4),
                    Text('Budgets', style: text.headlineLarge),
                  ],
                ),
              ),
              Expanded(
                child: budgets.when(
                  loading: () => const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  error: (e, _) =>
                      Center(child: Text('Error: $e', style: text.bodyMedium)),
                  data: (list) => list.isEmpty
                      ? const _EmptyBudgets()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                          itemCount: progress.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) =>
                              _BudgetRow(progress: progress[i]),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetRow extends ConsumerWidget {
  final BudgetProgress progress;
  const _BudgetRow({required this.progress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final b = progress.budget;
    final color = budgetColor(progress.ratio);

    String label;
    IconData icon;
    Color iconColor;
    if (b.isOverall) {
      label = 'Overall';
      icon = Icons.account_balance_wallet;
      iconColor = AppColors.primary;
    } else {
      final cat = ref.watch(categoryByIdProvider(b.categoryId!));
      label = cat?.name ?? 'Category';
      icon = cat?.icon ?? Icons.category;
      iconColor = cat?.color ?? AppColors.primary;
    }

    return GestureDetector(
      onTap: () => EditBudgetSheet.show(context, existing: b),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppGradients.glass,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            BudgetRing(
              ratio: progress.ratio,
              color: color,
              over: progress.isOver,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 14, color: iconColor),
                      const SizedBox(width: 6),
                      Text(label, style: text.bodyLarge),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    progress.isOver
                        ? '${Money(progress.spent).format()} of '
                              '${Money(b.amount).format()} · '
                              'over by ${Money(progress.overBy).format()}'
                        : '${Money(progress.spent).format()} of '
                              '${Money(b.amount).format()} · '
                              '${Money(progress.remaining).format()} left',
                    style: text.labelSmall?.copyWith(
                      color: progress.isOver
                          ? AppColors.coral
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBudgets extends StatelessWidget {
  const _EmptyBudgets();

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
                  child: const Icon(
                    Icons.savings_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('No budgets yet', style: text.bodyLarge),
                      const SizedBox(height: 2),
                      Text(
                        'Tap + to add a monthly budget',
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
