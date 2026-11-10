import 'budget.dart';

/// Immutable view-model combining a budget with its current spend.
class BudgetProgress {
  final Budget budget;
  final int spent;

  const BudgetProgress({required this.budget, required this.spent});

  double get ratio => budget.amount == 0 ? 0 : spent / budget.amount;

  bool get isOver => spent > budget.amount;

  bool get isNear => !isOver && ratio >= 0.8;

  int get remaining {
    final r = budget.amount - spent;
    return r < 0 ? 0 : r;
  }

  int get overBy {
    final o = spent - budget.amount;
    return o < 0 ? 0 : o;
  }

  double get displayRatio => ratio.clamp(0.0, 1.0);

  @override
  String toString() =>
      'BudgetProgress(amount: ${budget.amount}, spent: $spent, '
      'ratio: ${ratio.toStringAsFixed(2)})';
}
