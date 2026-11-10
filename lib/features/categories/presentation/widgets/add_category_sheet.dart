import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/category.dart';
import '../providers/category_providers.dart';

class AddCategorySheet extends ConsumerStatefulWidget {
  const AddCategorySheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (_) => const AddCategorySheet(),
    );
  }

  @override
  ConsumerState<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends ConsumerState<AddCategorySheet> {
  final _nameCtrl = TextEditingController();
  int _iconCode = CategoryIcons.palette.first.codePoint;
  int _colorHex = AppColors.categoryPalette.first.toARGB32();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final result = await ref
        .read(categoriesProvider.notifier)
        .add(name: _nameCtrl.text, iconCode: _iconCode, colorHex: _colorHex);
    if (!mounted) return;
    setState(() => _saving = false);
    if (result is Success) {
      Navigator.of(context).pop(true);
    } else {
      final msg = result.messageOrNull ?? 'Save failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.bgRaised,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
            ),
            Text('New category', style: text.headlineMedium),
            const SizedBox(height: 20),
            TextField(
              key: const Key('category_name_field'),
              controller: _nameCtrl,
              maxLength: 40,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Name (e.g. Coffee)',
                counterText: '',
              ),
            ),
            const SizedBox(height: 20),
            Text('Icon', style: text.labelSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final icon in CategoryIcons.palette)
                  _IconChoice(
                    icon: icon,
                    selected: icon.codePoint == _iconCode,
                    accent: Color(_colorHex),
                    onTap: () => setState(() => _iconCode = icon.codePoint),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Color', style: text.labelSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final color in AppColors.categoryPalette)
                  _ColorChoice(
                    color: color,
                    selected: color.toARGB32() == _colorHex,
                    onTap: () => setState(() => _colorHex = color.toARGB32()),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _saving ? null : _save,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppGradients.fab,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(85),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save',
                          style: text.labelLarge?.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconChoice extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _IconChoice({
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: selected ? accent.withAlpha(51) : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: selected ? accent : AppColors.borderSubtle,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: selected ? accent : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _ColorChoice extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorChoice({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: selected
              ? [BoxShadow(color: color.withAlpha(128), blurRadius: 12)]
              : null,
        ),
      ),
    );
  }
}
