import 'package:expense_tracker/core/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/mesh_background.dart';
import '../../domain/entities/category.dart';
import '../providers/category_providers.dart';
import '../widgets/add_category_sheet.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final categories = ref.watch(categoriesProvider);

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
              onTap: () => AddCategorySheet.show(context),
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
                    Text('Categories', style: text.headlineLarge),
                  ],
                ),
              ),
              Expanded(
                child: categories.when(
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
                      ? Center(
                          child: Text(
                            'No categories yet',
                            style: text.bodyMedium,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                          itemCount: list.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) =>
                              _CategoryRow(category: list[i]),
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

class _CategoryRow extends ConsumerWidget {
  final Category category;
  const _CategoryRow({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final accent = category.color;
    return Container(
      padding: const EdgeInsets.all(14),
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
              color: accent.withAlpha(38),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(category.icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(category.name, style: text.bodyLarge)),
          if (!category.isDefault)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () => _confirmDelete(context, ref),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text('Default', style: text.labelSmall),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgRaised,
        title: const Text('Delete category?'),
        content: Text(category.name),
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
    if (confirmed != true || category.id == null) return;

    final result = await ref
        .read(categoriesProvider.notifier)
        .delete(category.id!, isDefault: category.isDefault);
    if (!context.mounted) return;
    if (result is Failure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((result as Failure).message),
          backgroundColor: AppColors.bgRaised,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
