import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/animated_counter.dart';
import '../../../../core/widgets/mesh_background.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../categories/presentation/screens/categories_screen.dart';
import '../../../budgets/presentation/providers/budget_providers.dart';
import '../../../budgets/presentation/screens/budgets_screen.dart';
import '../../../budgets/presentation/widgets/overall_budget_bar.dart';
import '../../../reports/presentation/screens/reports_screen.dart';
import '../../domain/entities/expense.dart';
import '../providers/expense_filter.dart';
import '../providers/expense_providers.dart';
import '../widgets/add_expense_sheet.dart';
import '../widgets/expense_card.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final expensesAsync = ref.watch(filteredExpensesProvider);
    final total = ref.watch(monthTotalProvider);
    final filter = ref.watch(expenseFilterProvider);
    final categories =
        ref.watch(categoriesProvider).value ?? const <Category>[];
    final monthLabel = DateFormat.yMMMM().format(DateTime.now());

    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: _Fab(onTap: () => AddExpenseSheet.show(context)),
        body: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.bgRaised,
            onRefresh: () async => ref.invalidate(expensesProvider),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('Ledger', style: text.headlineLarge),
                            ),
                            IconButton(
                              key: const Key('budgets_button'),
                              icon: const Icon(
                                Icons.savings_outlined,
                                color: AppColors.textSecondary,
                              ),
                              tooltip: 'Budgets',
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const BudgetsScreen(),
                                ),
                              ),
                            ),
                            IconButton(
                              key: const Key('reports_button'),
                              icon: const Icon(
                                Icons.insights,
                                color: AppColors.textSecondary,
                              ),
                              tooltip: 'Reports',
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const ReportsScreen(),
                                ),
                              ),
                            ),
                            IconButton(
                              key: const Key('categories_button'),
                              icon: const Icon(
                                Icons.tune,
                                color: AppColors.textSecondary,
                              ),
                              tooltip: 'Categories',
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const CategoriesScreen(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(monthLabel, style: text.labelSmall),
                        const SizedBox(height: 24),
                        Text(
                          'Spent this month',
                          style: text.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ShaderMask(
                          shaderCallback: (b) =>
                              AppGradients.moneyText.createShader(b),
                          child: AnimatedCounter(
                            value: total,
                            formatter: (v) => Money(v).format(),
                            style: text.displayLarge?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _SearchField(
                          value: filter.searchQuery,
                          onChanged: (q) => ref
                              .read(expenseFilterProvider.notifier)
                              .setSearch(q),
                          onClear: () {
                            ref
                                .read(expenseFilterProvider.notifier)
                                .setSearch('');
                          },
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _Chip(
                                label: 'All',
                                selected: filter.categoryId == null,
                                accent: AppColors.primary,
                                onTap: () => ref
                                    .read(expenseFilterProvider.notifier)
                                    .setCategory(null),
                              ),
                              for (final c in categories) ...[
                                const SizedBox(width: 8),
                                _Chip(
                                  label: c.name,
                                  selected: filter.categoryId == c.id,
                                  accent: c.color,
                                  onTap: () => ref
                                      .read(expenseFilterProvider.notifier)
                                      .setCategory(c.id),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                expensesAsync.when(
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
                    child: _ErrorState(message: e.toString()),
                  ),
                  data: (expenses) => expenses.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyState(filtered: filter.isActive),
                        )
                      : _buildExpenseList(context, ref, expenses),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SliverPadding _buildExpenseList(
    BuildContext context,
    WidgetRef ref,
    List<Expense> expenses,
  ) {
    final items = <_ListItem>[];
    String? lastLabel;
    var stagger = 0;
    for (final e in expenses) {
      final label = DateFormat.yMMMMEEEEd().format(e.occurredAt);
      if (label != lastLabel) {
        items.add(_HeaderItem(label));
        lastLabel = label;
      }
      items.add(_ExpenseItem(e, stagger++));
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      sliver: SliverList.builder(
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          return switch (item) {
            _HeaderItem(:final label) => _DateHeader(
              key: ValueKey('h-$label'),
              label: label,
            ),
            _ExpenseItem(:final expense, :final index) => _SwipeableExpense(
              key: ValueKey('e-${expense.id}'),
              expense: expense,
              index: index,
              onTap: () => _confirmDelete(context, ref, expense),
            ),
            _ => const SizedBox.shrink(),
          };
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Expense expense,
  ) async {
    final category = ref.read(categoryByIdProvider(expense.categoryId));
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgRaised,
        title: const Text('Delete expense?'),
        content: Text(
          '${category?.name ?? 'Expense'} · ${Money(expense.amount).format()}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.coral),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && expense.id != null) {
      await ref.read(expensesProvider.notifier).delete(expense.id!);
    }
  }
}

sealed class _ListItem {
  const _ListItem();
}

class _HeaderItem extends _ListItem {
  final String label;
  const _HeaderItem(this.label);
}

class _ExpenseItem extends _ListItem {
  final Expense expense;
  final int index;
  const _ExpenseItem(this.expense, this.index);
}

class _SwipeableExpense extends ConsumerWidget {
  final Expense expense;
  final int index;
  final VoidCallback onTap;

  const _SwipeableExpense({
    super.key,
    required this.expense,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(categoryByIdProvider(expense.categoryId));
    return Dismissible(
      key: ValueKey('dismiss-${expense.id}'),
      direction: DismissDirection.endToStart,
      background: const _SwipeBackground(),
      confirmDismiss: (_) async {
        unawaited(HapticFeedback.mediumImpact());
        return true;
      },
      onDismissed: (_) => _handleDismiss(context, ref),
      child: _StaggeredItem(
        index: index,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ExpenseCard(
            expense: expense,
            category: category,
            onTap: onTap,
          ),
        ),
      ),
    );
  }

  Future<void> _handleDismiss(BuildContext context, WidgetRef ref) async {
    if (expense.id == null) return;
    final notifier = ref.read(expensesProvider.notifier);
    notifier.removeLocally(expense.id!);

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    final controller = messenger.showSnackBar(
      SnackBar(
        content: Text('${Money(expense.amount).format()} deleted'),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.primary,
          onPressed: () => notifier.reinsertLocally(expense),
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.bgRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
    );

    final reason = await controller.closed;
    if (reason == SnackBarClosedReason.action) return;
    await notifier.deletePermanently(expense.id!);
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.coral.withAlpha(80),
            AppColors.coral.withAlpha(200),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final String label;
  const _DateHeader({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        label,
        style: text.labelSmall?.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _Fab extends StatefulWidget {
  final VoidCallback onTap;
  const _Fab({required this.onTap});

  @override
  State<_Fab> createState() => _FabState();
}

class _FabState extends State<_Fab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            gradient: AppGradients.fab,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(_pressed ? 40 : 85),
                blurRadius: _pressed ? 16 : 24,
                offset: Offset(0, _pressed ? 4 : 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Add expense',
                    style: text.labelLarge?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.value,
    required this.onChanged,
    required this.onClear,
  });

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_SearchField old) {
    super.didUpdateWidget(old);
    if (widget.value != _ctrl.text) {
      _ctrl.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('search_field'),
      controller: _ctrl,
      onChanged: widget.onChanged,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: 'Search notes, categories',
        prefixIcon: const Icon(
          Icons.search,
          color: AppColors.textTertiary,
          size: 20,
        ),
        suffixIcon: widget.value.isNotEmpty
            ? IconButton(
                icon: const Icon(
                  Icons.close,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
                onPressed: widget.onClear,
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? accent.withAlpha(38) : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: selected ? accent : AppColors.borderSubtle,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: text.labelLarge?.copyWith(
            fontSize: 13,
            color: selected ? accent : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _StaggeredItem extends StatelessWidget {
  final int index;
  final Widget child;
  const _StaggeredItem({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final stagger = Duration(milliseconds: 40 * (index > 8 ? 8 : index));
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.medium + stagger,
      curve: AppMotion.curveMedium,
      builder: (_, t, c) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 20 * (1 - t)), child: c),
      ),
      child: child,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool filtered;
  const _EmptyState({required this.filtered});

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
                  child: Icon(
                    filtered ? Icons.search_off : Icons.receipt_long,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        filtered ? 'No matches' : 'No expenses yet',
                        style: text.bodyLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        filtered
                            ? 'Try clearing the search or filter'
                            : 'Tap + to log your first expense',
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

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.coral, size: 40),
            const SizedBox(height: 12),
            Text('Something went wrong', style: text.bodyLarge),
            const SizedBox(height: 4),
            Text(message, style: text.labelSmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
