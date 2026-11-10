import 'package:flutter/material.dart';
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
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                          sliver: SliverList.builder(
                            itemCount: expenses.length,
                            itemBuilder: (context, i) {
                              final e = expenses[i];
                              final category = ref.watch(
                                categoryByIdProvider(e.categoryId),
                              );
                              return Padding(
                                key: ValueKey(e.id),
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _StaggeredItem(
                                  index: i,
                                  child: ExpenseCard(
                                    expense: e,
                                    category: category,
                                    onTap: () => _confirmDelete(
                                      context,
                                      ref,
                                      e,
                                      category?.name,
                                    ),
                                  ),
                                ),
                              );
                            },
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

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Expense expense,
    String? categoryName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgRaised,
        title: const Text('Delete expense?'),
        content: Text(
          '${categoryName ?? 'Expense'} · ${Money(expense.amount).format()}',
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

class _SearchField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.value,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('search_field'),
      onChanged: onChanged,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: 'Search notes, categories',
        prefixIcon: const Icon(
          Icons.search,
          color: AppColors.textTertiary,
          size: 20,
        ),
        suffixIcon: value.isNotEmpty
            ? IconButton(
                icon: const Icon(
                  Icons.close,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
                onPressed: onClear,
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

class _Fab extends StatelessWidget {
  final VoidCallback onTap;
  const _Fab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
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
          onTap: onTap,
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
