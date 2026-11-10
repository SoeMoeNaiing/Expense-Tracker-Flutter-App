import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/utils/money.dart';
import '../../domain/entities/budget_progress.dart';
import 'budget_color.dart';

class OverallBudgetBar extends StatelessWidget {
  final BudgetProgress progress;
  const OverallBudgetBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = budgetColor(progress.ratio);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress.displayRatio),
            duration: reduceMotion
                ? const Duration(milliseconds: 1)
                : const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, value, _) => Stack(
              children: [
                Container(height: 8, color: AppColors.borderSubtle),
                FractionallySizedBox(
                  widthFactor: value,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      boxShadow: [
                        BoxShadow(color: color.withAlpha(120), blurRadius: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '${Money(progress.spent).format()} of '
              '${Money(progress.budget.amount).format()}',
              style: text.labelSmall,
            ),
            const SizedBox(width: 8),
            if (progress.isOver)
              Text(
                '· over by ${Money(progress.overBy).format()}',
                style: text.labelSmall?.copyWith(
                  color: AppColors.coral,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Text(
                '· ${Money(progress.remaining).format()} left',
                style: text.labelSmall,
              ),
          ],
        ),
      ],
    );
  }
}
